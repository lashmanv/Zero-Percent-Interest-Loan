// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./../Dependencies/BaseMath.sol";
import "./../Dependencies/Ownable.sol";
import "./../Dependencies/CheckContract.sol";
import "./../Dependencies/console.sol";
import "./../Interfaces/IZQTYToken.sol";
import "./../Interfaces/IZQTYStaking.sol";
import "./../Dependencies/LiquityMath.sol";
import "./../Interfaces/IZUSDToken.sol";

contract ZQTYStaking is IZQTYStaking, Ownable, CheckContract, BaseMath {

    // --- Data ---
    string constant public NAME = "ZQTYStaking";

    mapping( address => uint) public stakes;
    uint public totalZQTYStaked;

    uint public F_ETH;  // Running sum of ETH fees per-ZQTY-staked
    uint public F_ZUSD; // Running sum of ZQTY fees per-ZQTY-staked

    // User snapshots of F_ETH and F_ZUSD, taken at the point at which their latest deposit was made
    mapping (address => Snapshot) public snapshots; 

    struct Snapshot {
        uint F_ETH_Snapshot;
        uint F_ZUSD_Snapshot;
    }
    
    IZQTYToken public zqtyToken;
    IZUSDToken public zusdToken;

    address public troveManagerAddress;
    address public borrowerOperationsAddress;
    address public activePoolAddress;

    // --- Functions ---

    function setAddresses
    (
        address _zqtyTokenAddress,
        address _zusdTokenAddress,
        address _troveManagerAddress, 
        address _borrowerOperationsAddress,
        address _activePoolAddress
    ) 
        external 
        onlyOwner 
        override 
    {
        checkContract(_zqtyTokenAddress);
        checkContract(_zusdTokenAddress);
        checkContract(_troveManagerAddress);
        checkContract(_borrowerOperationsAddress);
        checkContract(_activePoolAddress);

        zqtyToken = IZQTYToken(_zqtyTokenAddress);
        zusdToken = IZUSDToken(_zusdTokenAddress);
        troveManagerAddress = _troveManagerAddress;
        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePoolAddress = _activePoolAddress;

        emit ZQTYTokenAddressSet(_zqtyTokenAddress);
        emit ZQTYTokenAddressSet(_zusdTokenAddress);
        emit TroveManagerAddressSet(_troveManagerAddress);
        emit BorrowerOperationsAddressSet(_borrowerOperationsAddress);
        emit ActivePoolAddressSet(_activePoolAddress);

        _renounceOwnership();
    }

    // If caller has a pre-existing stake, send any accumulated ETH and ZUSD gains to them. 
    function stake(uint _ZQTYamount) external override {
        _requireNonZeroAmount(_ZQTYamount);

        uint currentStake = stakes[msg.sender];

        uint ETHGain;
        uint ZUSDGain;
        // Grab any accumulated ETH and ZUSD gains from the current stake
        if (currentStake != 0) {
            ETHGain = _getPendingETHGain(msg.sender);
            ZUSDGain = _getPendingZUSDGain(msg.sender);
        }
    
       _updateUserSnapshots(msg.sender);

        uint newStake = currentStake + (_ZQTYamount);

        // Increase user’s stake and total ZQTY staked
        stakes[msg.sender] = newStake;
        totalZQTYStaked = totalZQTYStaked + (_ZQTYamount);
        emit TotalZQTYStakedUpdated(totalZQTYStaked);

        // Transfer ZQTY from caller to this contract
        zqtyToken.sendToZQTYStaking(msg.sender, _ZQTYamount);

        emit StakeChanged(msg.sender, newStake);
        emit StakingGainsWithdrawn(msg.sender, ZUSDGain, ETHGain);

         // Send accumulated ZUSD and ETH gains to the caller
        if (currentStake != 0) {
            zusdToken.transfer(msg.sender, ZUSDGain);
            _sendETHGainToUser(ETHGain);
        }
    }

    // Unstake the ZQTY and send the it back to the caller, along with their accumulated ZUSD & ETH gains. 
    // If requested amount > stake, send their entire stake.
    function unstake(uint _ZQTYamount) external override {
        uint currentStake = stakes[msg.sender];
        _requireUserHasStake(currentStake);

        // Grab any accumulated ETH and ZUSD gains from the current stake
        uint ETHGain = _getPendingETHGain(msg.sender);
        uint ZUSDGain = _getPendingZUSDGain(msg.sender);
        
        _updateUserSnapshots(msg.sender);

        if (_ZQTYamount > 0) {
            uint ZQTYToWithdraw = LiquityMath._min(_ZQTYamount, currentStake);

            uint newStake = currentStake - (ZQTYToWithdraw);

            // Decrease user's stake and total ZQTY staked
            stakes[msg.sender] = newStake;
            totalZQTYStaked = totalZQTYStaked - (ZQTYToWithdraw);
            emit TotalZQTYStakedUpdated(totalZQTYStaked);

            // Transfer unstaked ZQTY to user
            zqtyToken.transfer(msg.sender, ZQTYToWithdraw);

            emit StakeChanged(msg.sender, newStake);
        }

        emit StakingGainsWithdrawn(msg.sender, ZUSDGain, ETHGain);

        // Send accumulated ZUSD and ETH gains to the caller
        zusdToken.transfer(msg.sender, ZUSDGain);
        _sendETHGainToUser(ETHGain);
    }

    // --- Reward-per-unit-staked increase functions. Called by Liquity core contracts ---

    function increaseF_ETH(uint _ETHFee) external override {
        _requireCallerIsTroveManager();
        uint ETHFeePerZQTYStaked;
     
        if (totalZQTYStaked > 0) {ETHFeePerZQTYStaked = _ETHFee * (DECIMAL_PRECISION) / (totalZQTYStaked);}

        F_ETH = F_ETH + (ETHFeePerZQTYStaked); 
        emit F_ETHUpdated(F_ETH);
    }

    function increaseF_ZUSD(uint _ZUSDFee) external override {
        _requireCallerIsBorrowerOperations();
        uint ZUSDFeePerZQTYStaked;
        
        if (totalZQTYStaked > 0) {ZUSDFeePerZQTYStaked = _ZUSDFee * (DECIMAL_PRECISION) / (totalZQTYStaked);}
        
        F_ZUSD = F_ZUSD + (ZUSDFeePerZQTYStaked);
        emit F_ZUSDUpdated(F_ZUSD);
    }

    // --- Pending reward functions ---

    function getPendingETHGain(address _user) external view override returns (uint) {
        return _getPendingETHGain(_user);
    }

    function _getPendingETHGain(address _user) internal view returns (uint) {
        uint F_ETH_Snapshot = snapshots[_user].F_ETH_Snapshot;
        uint ETHGain = stakes[_user] * (F_ETH - (F_ETH_Snapshot)) / (DECIMAL_PRECISION);
        return ETHGain;
    }

    function getPendingZUSDGain(address _user) external view override returns (uint) {
        return _getPendingZUSDGain(_user);
    }

    function _getPendingZUSDGain(address _user) internal view returns (uint) {
        uint F_ZUSD_Snapshot = snapshots[_user].F_ZUSD_Snapshot;
        uint ZUSDGain = stakes[_user] * (F_ZUSD - (F_ZUSD_Snapshot)) / (DECIMAL_PRECISION);
        return ZUSDGain;
    }

    // --- Internal helper functions ---

    function _updateUserSnapshots(address _user) internal {
        snapshots[_user].F_ETH_Snapshot = F_ETH;
        snapshots[_user].F_ZUSD_Snapshot = F_ZUSD;
        emit StakerSnapshotsUpdated(_user, F_ETH, F_ZUSD);
    }

    function _sendETHGainToUser(uint ETHGain) internal {
        emit EtherSent(msg.sender, ETHGain);
        (bool success, ) = msg.sender.call{value: ETHGain}("");
        require(success, "ZQTYStaking: Failed to send accumulated ETHGain");
    }

    // --- 'require' functions ---

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == troveManagerAddress, "ZQTYStaking: caller is not TroveM");
    }

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperationsAddress, "ZQTYStaking: caller is not BorrowerOps");
    }

     function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "ZQTYStaking: caller is not ActivePool");
    }

    function _requireUserHasStake(uint currentStake) internal pure {  
        require(currentStake > 0, 'ZQTYStaking: User must have a non-zero stake');  
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, 'ZQTYStaking: Amount must be non-zero');
    }

    receive() external payable {
        _requireCallerIsActivePool();
    }
}
