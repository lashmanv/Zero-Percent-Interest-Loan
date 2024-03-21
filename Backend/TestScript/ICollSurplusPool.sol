// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManager1AddressChanged(address _newTroveManagerAddress);
    event TroveManager2AddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollSurplusPoolBalanceUpdated(uint _collId, uint _newAmount);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event CollateralSent(address _to, uint[] _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManager1Address,
        address _troveManager2Address,
        address _troveManager3Address,
        address _activePoolAddress
    ) external;

    function setCollTokenAddress(address _collToken) external;

    function receiveCollToken(uint _collTokenId, uint _collAmount) external;

    function getCollateral(address _account) external view returns (uint[] memory);

    function accountSurplus(address _account, uint _collId, uint _collAmount) external;

    function claimColl(address _account) external;
}
