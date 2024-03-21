// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./DefaultPool.sol";

contract DefaultPoolTester is DefaultPool {
    
    function unprotectedIncreaseZUSDDebt(uint _amount) external {
        ZUSDDebt  = ZUSDDebt + _amount;
    }

    function unprotectedPayable() external payable {
        tokenBalance[0] = tokenBalance[0] + msg.value;
    }
}
