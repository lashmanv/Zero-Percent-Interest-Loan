// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ICommunityIssuance { 
    
    // --- Events ---
    
    event ZQTYTokenAddressSet(address _zqtyTokenAddress);
    event StabilityPoolAddressSet(address _stabilityPoolAddress);
    event TotalZQTYIssuedUpdated(uint _totalZQTYIssued);

    // --- Functions ---

    function setAddresses(address _zqtyTokenAddress, address _stabilityPoolAddress) external;

    function issueZQTY() external returns (uint);

    function sendZQTY(address _account, uint _ZQTYamount) external;
}
