// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolZUSDDebtUpdated(uint _ZUSDDebt);
    event ActivePoolETHBalanceUpdated(uint _ETH);
    event ActivePoolTokenBalanceUpdated(uint _collTokenId, uint _collAmount);

    // --- Functions ---
    function setCollTokenIds(uint _collTokenId) external ;
    function sendETH(address _account, uint _amount) external;
    function sendToken(address _account, address _collTokenAddrs, uint _collTokenId, uint _collAmount) external;
}
