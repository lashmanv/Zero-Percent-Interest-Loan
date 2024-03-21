// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event ETHBalanceUpdated(uint _newBalance);
    event ZUSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event EtherSent(address _to, uint _amount);
    event TokenSent(address _to, uint _collTokenId, uint _collAmount);

    // --- Functions ---
    function getTokenBalances() external view returns (uint[] memory);

    function getZUSDDebt() external view returns (uint);

    function increaseZUSDDebt(uint _amount) external;

    function decreaseZUSDDebt(uint _amount) external;

    function receiveCollToken(uint _collTokenId, uint _collAmount) external;
}
