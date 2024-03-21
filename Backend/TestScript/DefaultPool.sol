// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IDefaultPool.sol";
import "./IActivePool.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * The Default Pool holds the ETH and ZUSD debt (but not ZUSD tokens) from liquidations that have been redistributed
 * to active troves but not yet "applied", i.e. not yet recorded on a recipient active trove's struct.
 *
 * When a trove makes an operation that applies its pending ETH and ZUSD debt, its pending ETH and ZUSD debt is moved
 * from the Default Pool to the Active Pool.
 */
contract DefaultPool is Ownable, CheckContract, IDefaultPool {
    string constant public NAME = "DefaultPool";

    address public borrowerOperationsAddress;
    address public troveManager1Address;
    address public troveManager2Address;
    address public troveManager3Address;
    IActivePool public activePoolAddress;
    
    uint256 internal ZUSDDebt;  // debt

    IERC20[] internal collateralTokens;

    uint[] internal tokenBalance; // deposited ether and token tracker

    // --- Dependency setters ---

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
        checkContract(_troveManager3Address);
        checkContract(_activePoolAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManager1Address = _troveManager1Address;
        troveManager2Address = _troveManager2Address;
        troveManager3Address = _troveManager3Address;
        activePoolAddress = IActivePool(_activePoolAddress);

        collateralTokens.push(IERC20(address(0)));
        tokenBalance.push(0);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit TroveManager3AddressChanged(_troveManager3Address);
        emit ActivePoolAddressChanged(_activePoolAddress);

        _renounceOwnership();
    }

    function setCollTokenAddress(address _collToken) external override {
        _requireCallerIsBorrowerOperations();

        collateralTokens.push(IERC20(_collToken));
        tokenBalance.push(0);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the ETH state variable.
    *
    * Not necessarily equal to the the contract's raw ETH balance - ether can be forcibly sent to contracts.
    */

    function getTokenBalances() external view override returns (uint[] memory) {
        return tokenBalance;
    }

    function getZUSDDebt() external view override returns (uint) {
        return ZUSDDebt;
    }

    // --- Pool functionality ---

    function sendETHToActivePool(uint _amount) external override {
        _requireCallerIsTroveManager();
        require(tokenBalance[0] >= _amount, "DefaultPool: eth underflow");

        address activePool = address(activePoolAddress); // cache to save an SLOAD
        tokenBalance[0] = tokenBalance[0] - _amount;
        emit DefaultPoolETHBalanceUpdated(tokenBalance[0]);
        emit EtherSent(activePool, _amount);

        activePoolAddress.receiveCollToken(0, _amount);

        (bool success, ) = activePool.call{ value: _amount }("");
        require(success, "DefaultPool: sending ETH failed");
    }

    function sendTokenToActivePool(uint _collTokenId, uint _collAmount) external override {
        _requireCallerIsTroveManager();
        require(tokenBalance[_collTokenId] >= _collAmount, "DefaultPool: token underflow");

        address activePool = address(activePoolAddress); // cache to save an SLOAD
        
        tokenBalance[_collTokenId] = tokenBalance[_collTokenId] - _collAmount;

        emit DefaultPoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
        emit TokenSent(activePool, _collTokenId, _collAmount);

        activePoolAddress.receiveCollToken(_collTokenId, _collAmount);

        bool success = collateralTokens[_collTokenId].transfer(activePool, _collAmount);
        require(success, "DefaultPool: sending Token failed");
    }

    function increaseZUSDDebt(uint _amount) external override {
        _requireCallerIsTroveManager();
        ZUSDDebt = ZUSDDebt + _amount;
        emit DefaultPoolZUSDDebtUpdated(ZUSDDebt);
    }

    function decreaseZUSDDebt(uint _amount) external override {
        _requireCallerIsTroveManager();

        require(ZUSDDebt >= _amount, "DefaultPool: zusd underflow");
        ZUSDDebt = ZUSDDebt - _amount;
        emit DefaultPoolZUSDDebtUpdated(ZUSDDebt);
    }

    // --- 'require' functions ---
    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "DefaultPool: Caller is neither Borrower Operations");
    }

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == address(activePoolAddress), "DefaultPool: Caller is not the ActivePool");
    }

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == troveManager1Address ||
        msg.sender == troveManager2Address ||
        msg.sender == troveManager3Address,"DefaultPool: Caller is not the TroveManager");
    }

    function receiveCollToken(uint _collTokenId, uint _collAmount) external override{
        _requireCallerIsTroveManager();

        if(_collTokenId > 0) {
            tokenBalance[_collTokenId] = tokenBalance[_collTokenId] + _collAmount;
            emit DefaultPoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
        }
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        tokenBalance[0] = tokenBalance[0] + msg.value;
        emit DefaultPoolETHBalanceUpdated(tokenBalance[0]);
    }
}
