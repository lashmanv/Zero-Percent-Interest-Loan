// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity 0.8.10;

contract Pool {
    uint a;
    function set() public {
        a = a-10;
    }
}
