// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IZQTYStaking {

    // --- Events --
    
    event ZQTYTokenAddressSet(address _zqtyTokenAddress);
    event ZUSDTokenAddressSet(address _zusdTokenAddress);
    event TroveManagerAddressSet(address _troveManager);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event ActivePoolAddressSet(address _activePoolAddress);

    event StakeChanged(address indexed staker, uint newStake);
    event StakingGainsWithdrawn(address indexed staker, uint ZUSDGain, uint ETHGain);
    event F_ETHUpdated(uint _F_ETH);
    event F_ZUSDUpdated(uint _F_ZUSD);
    event TotalZQTYStakedUpdated(uint _totalZQTYStaked);
    event EtherSent(address _account, uint _amount);
    event StakerSnapshotsUpdated(address _staker, uint _F_ETH, uint _F_ZUSD);

    // --- Functions ---

    function setAddresses
    (
        address _zqtyTokenAddress,
        address _zusdTokenAddress,
        address _troveManagerAddress, 
        address _borrowerOperationsAddress,
        address _activePoolAddress
    )  external;

    function stake(uint _ZQTYamount) external;

    function unstake(uint _ZQTYamount) external;

    function increaseF_ETH(uint _ETHFee) external; 

    function increaseF_ZUSD(uint _ZQTYFee) external;  

    function getPendingETHGain(address _user) external view returns (uint);

    function getPendingZUSDGain(address _user) external view returns (uint);
}
