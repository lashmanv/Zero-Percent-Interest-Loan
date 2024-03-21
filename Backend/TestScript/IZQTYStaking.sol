// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IZQTYStaking {

    // --- Events --
    
    event ZQTYTokenAddressChanged(address _zqtyTokenAddress);
    event ZUSDTokenAddressChanged(address _zusdTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event TroveManager1AddressChanged(address _troveManager1Address);
    event TroveManager2AddressChanged(address _troveManager2Address);
    event TroveManager3AddressChanged(address _troveManager3Address);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    
    event F_TokenUpdated(uint _F_token);
    event F_ZUSDUpdated(uint _F_ZUSD);
    event EtherSent(address _account, uint _amount);
    event TokenSent(address _account, uint _collId, uint _amount);
    event TotalZQTYStakedUpdated(uint _totalZQTYStaked);
    event StakerSnapshotsUpdated(uint[] _F_token, uint _F_ZUSD, address _staker);
    event StakeChanged(address indexed staker, uint newStake);
    event StakingGainsWithdrawn(uint[] tokenGain, uint ZUSDGain, address indexed staker );

    event ZQTYStakingTokenBalanceUpdated(uint, uint);
    event ZQTYStakingETHBalanceUpdated(uint);

    // --- Functions ---

    function setAddresses
    (
        address _zqtyTokenAddress,
        address _zusdTokenAddress,
        address _troveManager1Address,
        address _troveManager2Address,
        address _troveManager3Address,
        address _borrowerOperationsAddress,
        address _activePoolAddress
    )  external;

    function setCollTokenAddress(address _collToken) external;

    function stake(uint _ZQTYamount) external;

    function unstake(uint _ZQTYamount) external;

    function increaseF_Token(uint _collId, uint _tokenFee) external; 

    function increaseF_ZUSD(uint _ZQTYFee) external;  

    function getPendingTokenGain(address _user) external view returns (uint[] memory);

    function getPendingZUSDGain(address _user) external view returns (uint);

    function receiveCollToken(uint _collTokenId, uint _collAmount) external;
        
}
