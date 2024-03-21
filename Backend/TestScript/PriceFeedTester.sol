// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./PriceFeed.sol";

contract PriceFeedTester is PriceFeed {

    function setLastGoodPrice(uint[] memory _lastGoodPrice) external {
        lastGoodPrice = _lastGoodPrice;
    }

    function setStatus(Status[] memory _status) external {
        status = _status;
    }
}