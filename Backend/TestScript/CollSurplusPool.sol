// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ICollSurplusPool.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CollSurplusPool is Ownable, CheckContract, ICollSurplusPool {

    string constant public NAME = "CollSurplusPool";

    IERC20[] internal collateralTokens;

    address public borrowerOperationsAddress;
    address public troveManager1Address;
    address public troveManager2Address;
    address public troveManager3Address;
    address public activePoolAddress;

    // deposited ether and token tracker
    uint[] public tokenBalance;


    // Collateral surplus claimable by trove owners
    mapping (address => uint[]) internal balances;

    
    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManager1Address,
        address _troveManager2Address,
        address _troveManager3Address,
        address _activePoolAddress
    )
        external
        override
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManager1Address);
        checkContract(_troveManager2Address);
        checkContract(_activePoolAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManager1Address = _troveManager1Address;
        troveManager2Address = _troveManager2Address;
        troveManager3Address = _troveManager3Address;
        activePoolAddress = _activePoolAddress;

        collateralTokens.push(IERC20(address(0)));
        tokenBalance.push(0);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit ActivePoolAddressChanged(_activePoolAddress);

        _renounceOwnership();
    }

    function setCollTokenAddress(address _collToken) external override {
        _requireCallerIsBorrowerOperations();

        collateralTokens.push(IERC20(_collToken));
        tokenBalance.push(0);
    }

    /* Returns the ETH state variable at ActivePool address.
       Not necessarily equal to the raw ether balance - ether can be forcibly sent to contracts. */
    
    function getCollateral(address _account) public view override returns (uint[] memory) {
        uint[] memory tokenBal = new uint[] (collateralTokens.length);

        for(uint i = 0; i < collateralTokens.length; i++) {
            if(balances[_account].length == 0) {
                tokenBal[i] = 0;
            }
            else{
                tokenBal[i] = balances[_account][i];
            }
        }

        return tokenBal;
    }

    // --- Pool functionality ---

    function accountSurplus(address _account, uint _collId, uint _collAmount) external override {
        _requireCallerIsTroveManager();

        for(uint i = 0; i < collateralTokens.length; i++) {
            balances[_account].push(0);
        }

        uint newAmount = balances[_account][_collId] + _collAmount;
        balances[_account][_collId] = newAmount;

        emit CollBalanceUpdated(_account, newAmount);
    }

    function claimColl(address _account) external override {
        _requireCallerIsBorrowerOperations();
        uint[] memory claimableColl = new uint[] (collateralTokens.length);

        claimableColl = getCollateral(_account);

        bool isClaimable;

        for(uint i = 0; i < claimableColl.length; i++) {
            if(claimableColl[i] > 0) {
                isClaimable = true;
                balances[_account][i] = 0;
                tokenBalance[i] = tokenBalance[i] - claimableColl[i];
            }
        }

        require(isClaimable, "CollSurplusPool: No collateral available to claim");

        emit CollBalanceUpdated(_account, 0);

        tokenBalance[0] = tokenBalance[0] - claimableColl[0];

        emit CollateralSent(_account, claimableColl);

        (bool success, ) = _account.call{ value: claimableColl[0] }("");
        require(success, "CollSurplusPool: sending ETH failed");

        for(uint i = 1; i < claimableColl.length; i++) {
            if(claimableColl[i] > 0) {
                bool succ = collateralTokens[i].transfer(_account, claimableColl[i]);
                require(succ, "CollSurplusPool: sending Token failed");
            }
        }    
    }

    function receiveCollToken(uint _collTokenId, uint _collAmount) external override{
        _requireCallerIsTroveManager();

        if(_collTokenId > 0) {
            tokenBalance[_collTokenId] = tokenBalance[_collTokenId] + _collAmount;
            emit CollSurplusPoolBalanceUpdated(_collTokenId, tokenBalance[_collTokenId]);
        }
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "CollSurplusPool: Caller is not Borrower Operations");
    }

    function _requireCallerIsTroveManager() internal view {
        require(
            msg.sender == troveManager1Address ||
            msg.sender == troveManager2Address ||
            msg.sender == troveManager3Address, "CollSurplusPool: Caller is not TroveManager");
    }

    function _requireCallerIsActivePool() internal view {
        require(
            msg.sender == activePoolAddress,
            "CollSurplusPool: Caller is not Active Pool");
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        tokenBalance[0] = tokenBalance[0] + msg.value;
    }
}
