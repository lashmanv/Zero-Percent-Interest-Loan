// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../ZQTY/ZQTYStaking.sol";


contract ZQTYStakingTester is ZQTYStaking {
    function requireCallerIsTroveManager() external view {
        _requireCallerIsTroveManager();
    }
}
