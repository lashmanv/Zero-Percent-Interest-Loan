// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPool.sol";


interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManager1AddressChanged(address _newTroveManagerAddress);
    event TroveManager2AddressChanged(address _newTroveManagerAddress);
    event TroveManager3AddressChanged(address _newTroveManagerAddress);
    event ActivePoolZUSDDebtUpdated(uint _ZUSDDebt);
    event ActivePoolETHBalanceUpdated(uint _ETH);
    event ActivePoolTokenBalanceUpdated(uint _collTokenId, uint _collAmount);

    // --- Functions ---
    function setCollTokenAddress(address _collToken) external;
    function sendETH(address _account, uint _amount) external;
    function sendToken(address _account, uint _collTokenId, uint _collAmount) external;
}
