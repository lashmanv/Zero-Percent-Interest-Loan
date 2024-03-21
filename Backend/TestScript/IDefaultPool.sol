// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPool.sol";


interface IDefaultPool is IPool {

    // --- Events ---
    
    event DefaultPoolETHBalanceUpdated(uint _ETH);
    event DefaultPoolZUSDDebtUpdated(uint _ZUSDDebt);
    event DefaultPoolTokenBalanceUpdated(uint _collTokenId, uint _collAmount);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event TroveManager1AddressChanged(address _newTroveManagerAddress);
    event TroveManager2AddressChanged(address _newTroveManagerAddress);
    event TroveManager3AddressChanged(address _newTroveManagerAddress);

    // --- Functions ---
    function setCollTokenAddress(address _collToken) external;

    function sendETHToActivePool(uint _amount) external;
    
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManager1Address,
        address _troveManager2Address,
        address _troveManager3Address,
        address _activePoolAddress
    ) external;

    function sendTokenToActivePool(uint _collTokenId, uint _collAmount) external;

}
