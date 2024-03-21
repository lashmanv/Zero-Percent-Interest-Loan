// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./CommunityIssuance.sol";

contract CommunityIssuanceTester is CommunityIssuance {
    function obtainZQTY(uint _amount) external {
        zqtyToken.transfer(msg.sender, _amount);
    }

    function getCumulativeIssuanceFraction() external view returns (uint) {
       return _getCumulativeIssuanceFraction();
    }

    function unprotectedIssueZQTY() external returns (uint) {
        // No checks on caller address
       
        uint latestTotalZQTYIssued = ZQTYSupplyCap * _getCumulativeIssuanceFraction() / DECIMAL_PRECISION;
        uint issuance = latestTotalZQTYIssued - totalZQTYIssued;
      
        totalZQTYIssued = latestTotalZQTYIssued;
        return issuance;
    }
}
