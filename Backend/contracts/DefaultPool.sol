// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Interfaces/IDefaultPool.sol";
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/console.sol";
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
    address public troveManagerAddress;
    address public activePoolAddress;
    uint256 internal ETH;  // deposited ETH tracker
    uint256 internal ZUSDDebt;  // debt

    uint[] internal tokenIds;

    mapping(uint => uint) internal tokenBalance;

    // --- Dependency setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        activePoolAddress = _activePoolAddress;

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);

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
    * Not necessarily equal to the the contract's raw ETH balance - ether can be forcibly sent to contracts.
    */
    function getETH() external view override returns (uint) {
        return ETH;
    }

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

    function sendETHToActivePool(uint _amount) external override {
        _requireCallerIsTroveManager();
        address activePool = activePoolAddress; // cache to save an SLOAD
        ETH = ETH - _amount;
        emit DefaultPoolETHBalanceUpdated(ETH);
        emit EtherSent(activePool, _amount);

        (bool success, ) = activePool.call{ value: _amount }("");
        require(success, "DefaultPool: sending ETH failed");
    }

    function sendTokenToActivePool(address _collTokenAddrs, uint _collTokenId, uint _collAmount) external override {
        _requireCallerIsTroveManager();
        address activePool = activePoolAddress;
        
        tokenBalance[_collTokenId] = tokenBalance[_collTokenId] - _collAmount;

        emit DefaultPoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
        emit TokenSent(activePool, _collTokenId, _collAmount);

        bool success = IERC20(_collTokenAddrs).transfer(msg.sender, _collAmount);
        require(success, "ActivePool: sending ETH failed");
    }

    function increaseZUSDDebt(uint _amount) external override {
        _requireCallerIsTroveManager();
        ZUSDDebt = ZUSDDebt + _amount;
        emit DefaultPoolZUSDDebtUpdated(ZUSDDebt);
    }

    function decreaseZUSDDebt(uint _amount) external override {
        _requireCallerIsTroveManager();
        ZUSDDebt = ZUSDDebt - _amount;
        emit DefaultPoolZUSDDebtUpdated(ZUSDDebt);
    }

    // --- 'require' functions ---
    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "ActivePool: Caller is neither Borrower Operations");
    }

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "DefaultPool: Caller is not the ActivePool");
    }

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == troveManagerAddress, "DefaultPool: Caller is not the TroveManager");
    }

    function receiveCollToken(uint _collTokenId, uint _collAmount) external override{
        _requireCallerIsBorrowerOperations();

        tokenBalance[_collTokenId] = tokenBalance[_collTokenId] + _collAmount;
        emit DefaultPoolTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
    }

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        ETH = ETH + msg.value;
        emit DefaultPoolETHBalanceUpdated(ETH);
    }
}
