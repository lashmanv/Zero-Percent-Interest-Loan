// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './Interfaces/IActivePool.sol';
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/console.sol";
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
    address public troveManagerAddress;
    address public stabilityPoolAddress;
    address public defaultPoolAddress;
    uint256 internal ETH;  // deposited ether tracker
    uint256 internal ZUSDDebt;

    uint[] internal tokenIds;

    mapping(uint => uint) internal tokenBalance;

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_defaultPoolAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);

        _renounceOwnership();
    }

    function setCollTokenIds(uint _collTokenId) external override {
        _requireCallerIsBorrowerOperations();

        tokenIds.push(_collTokenId);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the ETH state variable.
    *
    *Not necessarily equal to the the contract's raw ETH balance - ether can be forcibly sent to contracts.
    */
    function getETH() external view override returns (uint) {
        return ETH;
    }

    // function optionC() external {
    //     uint _totalFunds;
    //     uint[] memory _arrayFunds = arrayFunds;
    //     for (uint i = 0; i < _arrayFunds.length; i++){
    //         _totalFunds = _totalFunds + _arrayFunds[i];
    //     }
    //     totalFunds = _totalFunds;
    // }

    function getTokenBalances() external view override returns (uint[] memory) {
        uint[] memory balances = new uint[](tokenIds.length);
        uint256 j;
        for (uint i = 0; i < balances.length; i++){
            tokenBalance[i] > 0 ? balances[j] = tokenBalance[i] : balances[j] = 0;
            j++;
        }

        return balances;
    }

    function getZUSDDebt() external view override returns (uint) {
        return ZUSDDebt;
    }

    // --- Pool functionality ---

    function sendETH(address _account, uint _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        ETH = ETH - _amount;
        emit ActivePoolETHBalanceUpdated(ETH);
        emit EtherSent(_account, _amount);

        (bool success, ) = _account.call{ value: _amount }("");
        require(success, "ActivePool: sending ETH failed");
    }

    function sendToken(address _account, address _collTokenAddrs, uint _collTokenId, uint _collAmount) external override {
        _requireCallerIsBOorTroveMorSP();
        tokenBalance[_collTokenId] = tokenBalance[_collTokenId] - _collAmount;

        emit ActivePoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
        emit TokenSent(_account, _collTokenId, _collAmount);

        bool success = IERC20(_collTokenAddrs).transfer(_account, _collAmount);
        require(success, "ActivePool: sending ETH failed");
    }

    function increaseZUSDDebt(uint _amount) external override {
        _requireCallerIsBOorTroveM();
        ZUSDDebt  = ZUSDDebt + _amount;
        emit ActivePoolZUSDDebtUpdated(ZUSDDebt);
    }

    function decreaseZUSDDebt(uint _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        ZUSDDebt = ZUSDDebt - _amount;
        emit ActivePoolZUSDDebtUpdated(ZUSDDebt);
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "ActivePool: Caller is neither Borrower Operations");
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
            msg.sender == troveManagerAddress ||
            msg.sender == stabilityPoolAddress,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager nor StabilityPool");
    }

    function _requireCallerIsBOorTroveM() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
            msg.sender == troveManagerAddress,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager");
    }

    function receiveCollToken(uint _collTokenId, uint _collAmount) external override{
        _requireCallerIsBorrowerOperationsOrDefaultPool();

        tokenBalance[_collTokenId] = tokenBalance[_collTokenId] + _collAmount;
        emit ActivePoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
    }
    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsBorrowerOperationsOrDefaultPool();
        ETH = ETH + msg.value;
        emit ActivePoolETHBalanceUpdated(ETH);
    }
}
