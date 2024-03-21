// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPriceFeed.sol";

/*
* PriceFeed placeholder for testnet and development. The price is simply set manually and saved in a state 
* variable. The contract does not connect to a live Chainlink price feed. 
*/
contract PriceFeedTestnet is IPriceFeed {
    
    uint[] private _price = [2000 * 1e18, 2000 * 1e18, 21000 * 1e18, 300 * 1e18, 20 * 1e18, 1 * 1e18];

    // --- Functions ---

    // View price getter for simplicity in tests
    function getPrice() external view returns (uint256[] memory) {
        return _price;
    }

    function fetchCollPrice(uint _collateralTokenId) external view override returns (uint256) {
        // Fire an event just like the mainnet version would.
        // This lets the subgraph rely on events to get the latest price even when developing locally.
        //emit LastGoodPriceUpdated(_price);
        return _price[_collateralTokenId];
    }

    function fetchEntirePrice() external view override returns (uint256[] memory) {
        // Fire an event just like the mainnet version would.
        // This lets the subgraph rely on events to get the latest price even when developing locally.
        //emit LastGoodPriceUpdated(_price);
        return _price;
    }

    function setPrice(uint[] memory price) external returns (bool) {
        _price = price;
        return true;
    }

    // Manual external price setter.
    function setTokenPrice(uint id, uint price) external returns (bool) {
        _price[id] = price;
        return true;
    }


}
