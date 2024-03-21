// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./../ActivePool.sol";

contract ActivePoolTester is ActivePool {
    
    function unprotectedIncreaseZUSDDebt(uint _amount) external {
        ZUSDDebt  = ZUSDDebt + _amount;
    }

    function unprotectedPayable() external payable {
        ETH = ETH + msg.value;
    }
}
