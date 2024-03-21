// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPool.sol";


interface IDefaultPool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolZUSDDebtUpdated(uint _ZUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint _ETH);
    event DefaultPoolTokenBalanceUpdated(uint _collTokenId, uint _collAmount);

    // --- Functions ---
    function setCollTokenIds(uint _collTokenId) external;
    function sendETHToActivePool(uint _amount) external;
    function sendTokenToActivePool(address _collTokenAddrs, uint _collTokenId, uint _collAmount) external;

}
