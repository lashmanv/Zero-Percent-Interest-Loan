// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
    
interface ILockupContractFactory {
    
    // --- Events ---

    event ZQTYTokenAddressSet(address _zqtyTokenAddress);
    event LockupContractDeployedThroughFactory(address _lockupContractAddress, address _beneficiary, uint _unlockTime, address _deployer);

    // --- Functions ---

    function setZQTYTokenAddress(address _zqtyTokenAddress) external;

    function deployLockupContract(address _beneficiary, uint _unlockTime) external;

    function isRegisteredLockup(address _addr) external view returns (bool);
}
