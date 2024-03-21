// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./BaseMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./console.sol";
import "./IZQTYToken.sol";
import "./IZQTYStaking.sol";
import "./LiquityMath.sol";
import "./IZUSDToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ZQTYStaking is IZQTYStaking, Ownable, CheckContract, BaseMath {

    // --- Data ---
    string constant public NAME = "ZQTYStaking";

    // Array of token addresses
    IERC20[] public collateralTokens;

    uint[] internal tokenBalance; // deposited ether and token tracker

    mapping(address => uint) public stakes;
    uint public totalZQTYStaked;

    uint[] public F_Token; // Running sum of Token fees per-ZQTY-staked
    uint public F_ZUSD; // Running sum of ZQTY fees per-ZQTY-staked

    // User snapshots of F_token and F_ZUSD, taken at the point at which their latest deposit was made
    mapping (address => Snapshot) public snapshots; 

    struct Snapshot {
        uint[] F_Token_Snapshot;
        uint F_ZUSD_Snapshot;
    }
    
    IZQTYToken public zqtyToken;
    IZUSDToken public zusdToken;

    address public troveManager1Address;
    address public troveManager2Address;
    address public troveManager3Address;
    address public borrowerOperationsAddress;
    address public activePoolAddress;

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
    ) 
        external 
        onlyOwner 
        override 
    {
        checkContract(_zqtyTokenAddress);
        checkContract(_zusdTokenAddress);
        checkContract(_troveManager1Address);
        checkContract(_troveManager2Address);
        checkContract(_troveManager3Address);
        checkContract(_borrowerOperationsAddress);
        checkContract(_activePoolAddress);

        zqtyToken = IZQTYToken(_zqtyTokenAddress);
        zusdToken = IZUSDToken(_zusdTokenAddress);
        troveManager1Address = _troveManager1Address;
        troveManager2Address = _troveManager2Address;
        troveManager3Address = _troveManager3Address;
        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePoolAddress = _activePoolAddress;

        collateralTokens.push(IERC20(address(0)));
        tokenBalance.push(0);
        F_Token.push(0);

        emit ZQTYTokenAddressChanged(_zqtyTokenAddress);
        emit ZQTYTokenAddressChanged(_zusdTokenAddress);
        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit TroveManager3AddressChanged(_troveManager3Address);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);

        _renounceOwnership();
    }

    function setCollTokenAddress(address _collToken) external override {
        _requireCallerIsBorrowerOperations();

        collateralTokens.push(IERC20(_collToken));
        tokenBalance.push(0);
        F_Token.push(0);
    }

    // If caller has a pre-existing stake, send any accumulated token and ZUSD gains to them. 
    function stake(uint _ZQTYamount) external override {
        _requireNonZeroAmount(_ZQTYamount);

        uint currentStake = stakes[msg.sender];

        uint length = collateralTokens.length;

        uint[] memory tokenGain = new uint[] (length);

        uint ZUSDGain;
        // Grab any accumulated token and ZUSD gains from the current stake
        if (currentStake != 0) {
            tokenGain = _getPendingTokenGain(msg.sender);
            ZUSDGain = _getPendingZUSDGain(msg.sender);
        }
    
       _updateUserSnapshots(msg.sender);

        uint newStake = currentStake + _ZQTYamount;

        // Increase user’s stake and total ZQTY staked
        stakes[msg.sender] = newStake;
        totalZQTYStaked = totalZQTYStaked + _ZQTYamount;
        emit TotalZQTYStakedUpdated(totalZQTYStaked);

        // Transfer ZQTY from caller to this contract
        zqtyToken.sendToZQTYStaking(msg.sender, _ZQTYamount);

        emit StakeChanged(msg.sender, newStake);

        // Send accumulated ZUSD and token gains to the caller
        if (currentStake != 0) {
            zusdToken.transfer(msg.sender, ZUSDGain);
            _sendEthGainToUser(tokenGain[0]);
            for(uint i = 1; i < length; i++) {
                if(tokenGain[i] > 0 ) {
                    _sendTokenGainToUser(i, tokenGain[i]);
                }
            }

            emit StakingGainsWithdrawn(tokenGain, ZUSDGain, msg.sender);
        }
    }

    // Unstake the ZQTY and send the it back to the caller, along with their accumulated ZUSD & token gains. 
    // If requested amount > stake, send their entire stake.
    function unstake(uint _ZQTYamount) external override {
        uint currentStake = stakes[msg.sender];
        _requireUserHasStake(currentStake);

        // Grab any accumulated token and ZUSD gains from the current stake
        uint length = collateralTokens.length;

        uint[] memory tokenGain = new uint[] (length);
        
        tokenGain = _getPendingTokenGain(msg.sender);
        uint ZUSDGain = _getPendingZUSDGain(msg.sender);
        
        _updateUserSnapshots(msg.sender);

        if (_ZQTYamount > 0) {
            uint ZQTYToWithdraw = LiquityMath._min(_ZQTYamount, currentStake);

            uint newStake = currentStake - ZQTYToWithdraw;

            // Decrease user's stake and total ZQTY staked
            stakes[msg.sender] = newStake;
            totalZQTYStaked = totalZQTYStaked - ZQTYToWithdraw;
            emit TotalZQTYStakedUpdated(totalZQTYStaked);

            // Transfer unstaked ZQTY to user
            zqtyToken.transfer(msg.sender, ZQTYToWithdraw);

            emit StakeChanged(msg.sender, newStake);
        }

        // Send accumulated ZUSD and token gains to the caller
        zusdToken.transfer(msg.sender, ZUSDGain);
        _sendEthGainToUser(tokenGain[0]);
        for(uint i = 1; i < length; i++) {
            if(tokenGain[i] > 0 ) {
                _sendTokenGainToUser(i, tokenGain[i]);
            }
        }

        emit StakingGainsWithdrawn(tokenGain, ZUSDGain, msg.sender );
    }

    // --- Reward-per-unit-staked increase functions. Called by Liquity core contracts ---

    function increaseF_Token(uint _collId, uint _tokenFee) external override {
        _requireCallerIsTroveManager();
        uint tokenFeePerZQTYStaked;
     
        if (totalZQTYStaked > 0) {tokenFeePerZQTYStaked = (_tokenFee * DECIMAL_PRECISION / totalZQTYStaked);}

        F_Token[_collId] = F_Token[_collId] + tokenFeePerZQTYStaked; 
        emit F_TokenUpdated(F_Token[_collId]);
    }

    function increaseF_ZUSD(uint _ZUSDFee) external override {
        _requireCallerIsBorrowerOperations();
        uint ZUSDFeePerZQTYStaked;
        
        if (totalZQTYStaked > 0) {ZUSDFeePerZQTYStaked = (_ZUSDFee * DECIMAL_PRECISION / totalZQTYStaked);}
        
        F_ZUSD = F_ZUSD + ZUSDFeePerZQTYStaked;
        emit F_ZUSDUpdated(F_ZUSD);
    }

    // --- Pending reward functions ---

    function getPendingTokenGain(address _user) external view override returns (uint[] memory) {
        return _getPendingTokenGain(_user);
    }

    function _getPendingTokenGain(address _user) internal view returns (uint[] memory) {
        uint length = collateralTokens.length;
        uint[] memory F_Token_Snapshot = new uint[] (length);
        F_Token_Snapshot = snapshots[_user].F_Token_Snapshot;
        
        uint[] memory tokenGain = new uint[] (length);
        
        for(uint i = 0; i < length; i++) {
            tokenGain[i] = (stakes[_user] * (F_Token[i] - F_Token_Snapshot[i]) / DECIMAL_PRECISION);  
        }
        
        return tokenGain;
    }

    function getPendingZUSDGain(address _user) external view override returns (uint) {
        return _getPendingZUSDGain(_user);
    }

    function _getPendingZUSDGain(address _user) internal view returns (uint) {
        uint F_ZUSD_Snapshot = snapshots[_user].F_ZUSD_Snapshot;
        uint ZUSDGain = (stakes[_user] * (F_ZUSD - F_ZUSD_Snapshot) / DECIMAL_PRECISION);
        return ZUSDGain;
    }

    // --- Internal helper functions ---

    function _updateUserSnapshots(address _user) internal {
        snapshots[_user].F_Token_Snapshot = F_Token;
        snapshots[_user].F_ZUSD_Snapshot = F_ZUSD;

        emit StakerSnapshotsUpdated(F_Token, F_ZUSD, _user);
    }

    function _sendEthGainToUser(uint _tokenGain) internal {
        emit EtherSent(msg.sender, _tokenGain);

        (bool success, ) = msg.sender.call{value: _tokenGain}("");
        require(success, "ZQTYStaking: Failed to send accumulated ETH Gain");
    }

    function _sendTokenGainToUser(uint _collId, uint _tokenGain) internal {
        emit TokenSent(msg.sender, _collId, _tokenGain);

        bool success = collateralTokens[_collId].transfer(msg.sender, _tokenGain);
        require(success, "ZQTYStaking: Failed to send accumulated token Gain");
    }

    // --- 'require' functions ---

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == troveManager1Address ||
        msg.sender == troveManager2Address ||
        msg.sender == troveManager3Address, "ZQTYStaking: caller is not TroveM");
    }

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperationsAddress, "ZQTYStaking: caller is not BorrowerOps");
    }

     function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "ZQTYStaking: caller is not ActivePool");
    }

    function _requireUserHasStake(uint currentStake) internal pure {  
        require(currentStake > 0, "ZQTYStaking: User must have a non-zero stake");  
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, "ZQTYStaking: Amount must be non-zero");
    }

    function receiveCollToken(uint _collTokenId, uint _collAmount) external override{
        _requireCallerIsTroveManager();

        if(_collTokenId > 0) {
            tokenBalance[_collTokenId] = tokenBalance[_collTokenId] + _collAmount;
            emit ZQTYStakingTokenBalanceUpdated(_collTokenId,tokenBalance[_collTokenId]);
        }
    }

    receive() external payable {
        _requireCallerIsActivePool();

        tokenBalance[0] = tokenBalance[0] + msg.value;
        emit ZQTYStakingETHBalanceUpdated(tokenBalance[0]);
    }
}
