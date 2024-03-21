// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./CheckContract.sol";
import "./Ownable.sol";
import "./ILockupContractFactory.sol";
import "./LockupContract.sol";
import "./console.sol";

/*
* The LockupContractFactory deploys LockupContracts - its main purpose is to keep a registry of valid deployed 
* LockupContracts. 
* 
* This registry is checked by ZQTYToken when the Liquity deployer attempts to transfer ZQTY tokens. During the first year 
* since system deployment, the Liquity deployer is only allowed to transfer ZQTY to valid LockupContracts that have been 
* deployed by and recorded in the LockupContractFactory. This ensures the deployer's ZQTY can't be traded or staked in the
* first year, and can only be sent to a verified LockupContract which unlocks at least one year after system deployment.
*
* LockupContracts can of course be deployed directly, but only those deployed through and recorded in the LockupContractFactory 
* will be considered "valid" by ZQTYToken. This is a convenient way to verify that the target address is a genuine 
* LockupContract.
*/

contract LockupContractFactory is ILockupContractFactory, Ownable, CheckContract {

    // --- Data ---
    string constant public NAME = "LockupContractFactory";

    uint constant public SECONDS_IN_ONE_YEAR = 31536000;

    address public zqtyTokenAddress;
    
    mapping (address => address) public lockupContractToDeployer;

   
    // --- Functions ---

    function setZQTYTokenAddress(address _zqtyTokenAddress) external override onlyOwner {
        checkContract(_zqtyTokenAddress);

        zqtyTokenAddress = _zqtyTokenAddress;
        emit ZQTYTokenAddressSet(_zqtyTokenAddress);

        _renounceOwnership();
    }

    function deployLockupContract(address _beneficiary, uint _unlockTime) external override {
        address zqtyTokenAddressCached = zqtyTokenAddress;
        _requireZQTYAddressIsSet(zqtyTokenAddressCached);
        LockupContract lockupContract = new LockupContract(
                                                        zqtyTokenAddressCached,
                                                        _beneficiary, 
                                                        _unlockTime);

        lockupContractToDeployer[address(lockupContract)] = msg.sender;
        emit LockupContractDeployedThroughFactory(address(lockupContract), _beneficiary, _unlockTime, msg.sender);
    }

    function isRegisteredLockup(address _contractAddress) public view override returns (bool) {
        return lockupContractToDeployer[_contractAddress] != address(0);
    }

    // --- 'require'  functions ---
    function _requireZQTYAddressIsSet(address _zqtyTokenAddress) internal pure {
        require(_zqtyTokenAddress != address(0), "LCF: ZQTY Address is not set");
    }
}
