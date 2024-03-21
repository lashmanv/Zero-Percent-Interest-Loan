// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
   
    // --- Function ---
    function fetchEntirePrice() external returns (uint[] memory);
    function fetchCollPrice(uint _collateralTokenId) external returns (uint);
}
