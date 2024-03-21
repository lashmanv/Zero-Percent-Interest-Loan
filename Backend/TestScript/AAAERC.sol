// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor() ERC20("Nothing Token", "NTG") {mint();}

    function mint() public {
        _mint(msg.sender, 1000000*10**18);
    }
}

//contract:0xd348cddE168896c5514d25e8E51dC8a525A1C305