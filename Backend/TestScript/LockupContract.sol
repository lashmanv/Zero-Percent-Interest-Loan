// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IZQTYToken.sol";

/*
* The lockup contract architecture utilizes a single LockupContract, with an unlockTime. The unlockTime is passed as an argument 
* to the LockupContract's constructor. The contract's balance can be withdrawn by the beneficiary when block.timestamp > unlockTime. 
* At construction, the contract checks that unlockTime is at least one year later than the Liquity system's deployment time. 

* Within the first year from deployment, the deployer of the ZQTYToken (Liquity AG's address) may transfer ZQTY only to valid 
* LockupContracts, and no other addresses (this is enforced in ZQTYToken.sol's transfer() function).
* 
* The above two restrictions ensure that until one year after system deployment, ZQTY tokens originating from Liquity AG cannot 
* enter circulating supply and cannot be staked to earn system revenue.
*/
contract LockupContract {

    // --- Data ---
    string constant public NAME = "LockupContract";

    uint constant public SECONDS_IN_ONE_YEAR = 31536000; 

    address public immutable beneficiary;

    IZQTYToken public zqtyToken;

    // Unlock time is the Unix point in time at which the beneficiary can withdraw.
    uint public unlockTime;

    // --- Events ---

    event LockupContractCreated(address _beneficiary, uint _unlockTime);
    event LockupContractEmptied(uint _ZQTYwithdrawal);

    // --- Functions ---

    constructor 
    (
        address _zqtyTokenAddress, 
        address _beneficiary, 
        uint _unlockTime
    )
    {
        zqtyToken = IZQTYToken(_zqtyTokenAddress);

        /*
        * Set the unlock time to a chosen instant in the future, as long as it is at least 1 year after
        * the system was deployed 
        */
        _requireUnlockTimeIsAtLeastOneYearAfterSystemDeployment(_unlockTime);
        unlockTime = _unlockTime;
        
        beneficiary =  _beneficiary;
        emit LockupContractCreated(_beneficiary, _unlockTime);
    }

    function withdrawZQTY() external {
        _requireCallerIsBeneficiary();
        _requireLockupDurationHasPassed();

        IZQTYToken zqtyTokenCached = zqtyToken;
        uint ZQTYBalance = zqtyTokenCached.balanceOf(address(this));
        zqtyTokenCached.transfer(beneficiary, ZQTYBalance);
        emit LockupContractEmptied(ZQTYBalance);
    }

    // --- 'require' functions ---

    function _requireCallerIsBeneficiary() internal view {
        require(msg.sender == beneficiary, "LockupContract: caller is not the beneficiary");
    }

    function _requireLockupDurationHasPassed() internal view {
        require(block.timestamp >= unlockTime, "LockupContract: The lockup duration must have passed");
    }

    function _requireUnlockTimeIsAtLeastOneYearAfterSystemDeployment(uint _unlockTime) internal view {
        uint systemDeploymentTime = zqtyToken.getDeploymentStartTime();
        require(_unlockTime >= systemDeploymentTime + SECONDS_IN_ONE_YEAR, "LockupContract: unlock time must be at least one year after system deployment");
    }
}
