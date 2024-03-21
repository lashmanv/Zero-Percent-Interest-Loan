// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IActivePool.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/*
 * The Active Pool holds the ETH collateral and ZUSD debt (but not ZUSD tokens) for all active troves.
 *
 * When a trove is liquidated, it's ETH and ZUSD debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 *
 */
contract ActivePool is Ownable, CheckContract, IActivePool {

    string constant public NAME = "ActivePool";

    address public borrowerOperationsAddress;
    address public troveManager1Address;
    address public troveManager2Address;
    address public troveManager3Address;
    address public stabilityPoolAddress;
    address public defaultPoolAddress;

    uint256 internal ZUSDDebt;

    // Array of token addresses
    IERC20[] public collateralTokens;

    uint[] internal tokenBalance; // deposited ether & token tracker

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManager1Address,
        address _troveManager2Address,
        address _troveManager3Address,
        address _stabilityPoolAddress,
        address _defaultPoolAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManager1Address);
        checkContract(_troveManager2Address);
        checkContract(_troveManager3Address);
        checkContract(_stabilityPoolAddress);
        checkContract(_defaultPoolAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManager1Address = _troveManager1Address;
        troveManager2Address = _troveManager2Address;
        troveManager3Address = _troveManager3Address;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;

        collateralTokens.push(IERC20(address(0)));
        tokenBalance.push(0);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit TroveManager3AddressChanged(_troveManager3Address);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);

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
    *Not necessarily equal to the the contract's raw ETH balance - ether can be forcibly sent to contracts.
    */
    function getTokenBalances() external view override returns (uint[] memory) {
        return tokenBalance;
    }

    function getZUSDDebt() external view override returns (uint) {
        return ZUSDDebt;
    }

    // --- Pool functionality ---

    function sendETH(address _account, uint _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        require(tokenBalance[0] >= _amount, "ActivePool: eth underflow");

        tokenBalance[0] = tokenBalance[0] - _amount;
        emit ActivePoolETHBalanceUpdated(tokenBalance[0]);
        emit EtherSent(_account, _amount);

        (bool success, ) = _account.call{ value: _amount }("");
        require(success, "ActivePool: sending ETH failed");
    }

    function sendToken(address _account, uint _collTokenId, uint _collAmount) external override {
        _requireCallerIsBOorTroveMorSP();
        require(tokenBalance[_collTokenId] >= _collAmount, "ActivePool: token underflow");

        tokenBalance[_collTokenId] = tokenBalance[_collTokenId] - _collAmount;

        emit ActivePoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
        emit TokenSent(_account, _collTokenId, _collAmount);

        bool success = collateralTokens[_collTokenId].transfer(_account, _collAmount);
        require(success, "ActivePool: sending Token failed");
    }

    function increaseZUSDDebt(uint _amount) external override {
        _requireCallerIsBOorTroveM();
        ZUSDDebt  = ZUSDDebt + _amount;
        emit ActivePoolZUSDDebtUpdated(ZUSDDebt);
    }

    function decreaseZUSDDebt(uint _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        require(ZUSDDebt >= _amount, "ActivePool: zusd underflow");

        ZUSDDebt = ZUSDDebt - _amount;
        emit ActivePoolZUSDDebtUpdated(ZUSDDebt);
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "ActivePool: Caller is not Borrower Operations");
    }

    function _requireCallerIsBorrowerOperationsOrDefaultPool() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
            msg.sender == defaultPoolAddress,
            "ActivePool: Caller is neither BO nor Default Pool");
    }

    function _requireCallerIsBOorTroveMorSP() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
            msg.sender == troveManager1Address ||
            msg.sender == troveManager2Address ||
            msg.sender == troveManager3Address ||
            msg.sender == stabilityPoolAddress,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager nor StabilityPool");
    }

    function _requireCallerIsBOorTroveM() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
            msg.sender == troveManager1Address ||
            msg.sender == troveManager2Address ||
            msg.sender == troveManager3Address,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager");
    }

    function receiveCollToken(uint _collTokenId, uint _collAmount) external override{
        _requireCallerIsBorrowerOperationsOrDefaultPool();

        if(_collTokenId > 0) {
            tokenBalance[_collTokenId] = tokenBalance[_collTokenId] + _collAmount;
            emit ActivePoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
        }
    }
    
    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsBorrowerOperationsOrDefaultPool();
        tokenBalance[0] = tokenBalance[0] + msg.value;
        emit ActivePoolETHBalanceUpdated(tokenBalance[0]);
    }
}
