// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ITroveManager1.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

contract TroveManager1 is LiquityBase, Ownable, CheckContract, ITroveManager1 {
    string constant public NAME = "Liquidation - TroveManager";

    address[] internal collateralTokens;

    // --- Connected contract declarations ---

    address public borrowerOperationsAddress;

    address public troveManager2Address;
    address public troveManager3Address;

    IStabilityPool public override stabilityPool;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    IZUSDToken public override zusdToken;

    IZQTYToken public override zqtyToken;

    IZQTYStaking public override zqtyStaking;

    // A doubly linked list of Troves, sorted by their sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    mapping (address => Trove) public Troves;

    uint[] internal totalStakes;

    // Snapshot of the value of totalStakes, taken immediately after the latest liquidation
    uint[] public totalStakesSnapshot;

    // Snapshot of the total collateral across the ActivePool and DefaultPool, immediately after the latest liquidation.
    uint[] public totalCollateralSnapshot;

    /*
    * L_COLL and L_ZUSDDebt track the sums of accumulated liquidation rewards per unit staked. During its lifetime, each stake earns:
    *
    * An ETH gain of ( stake * [L_COLL - L_COLL(0)] )
    * A ZUSDDebt increase  of ( stake * [L_ZUSDDebt - L_ZUSDDebt(0)] )
    *
    * Where L_COLL(0) and L_ZUSDDebt(0) are snapshots of L_COLL and L_ZUSDDebt for the active Trove taken at the instant the stake was made
    */
    uint[] internal L_COLL;
    uint[] internal L_ZUSDDebt;

    // Map addresses with active troves to their RewardSnapshot
    mapping (address => RewardSnapshot) rewardSnapshots;

    // Object containing the ETH and ZUSD snapshots for a given active trove
    struct RewardSnapshot {uint Coll; uint ZUSDDebt;}

    // Array of all active trove addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] internal TroveOwners;

    // --- Dependency setter ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManager2Address,
        address _troveManager3Address,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _zusdTokenAddress,
        address _sortedTrovesAddress,
        address _zqtyTokenAddress,
        address _zqtyStakingAddress
    )
        external
        override
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManager2Address);
        checkContract(_troveManager3Address);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_zusdTokenAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_zqtyTokenAddress);
        checkContract(_zqtyStakingAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManager2Address = _troveManager2Address;
        troveManager3Address = _troveManager3Address;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        zusdToken = IZUSDToken(_zusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        zqtyToken = IZQTYToken(_zqtyTokenAddress);
        zqtyStaking = IZQTYStaking(_zqtyStakingAddress);

        collateralTokens.push(address(0));
        L_COLL.push(0);
        L_ZUSDDebt.push(0);
        totalStakes.push(0);
        totalStakesSnapshot.push(0);
        totalCollateralSnapshot.push(0);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManager2AddressChanged(troveManager2Address);
        emit TroveManager3AddressChanged(troveManager3Address);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit ZUSDTokenAddressChanged(_zusdTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit ZQTYTokenAddressChanged(_zqtyTokenAddress);
        emit ZQTYStakingAddressChanged(_zqtyStakingAddress);

        _renounceOwnership();
    }

    function setCollTokenAddress(address _collToken) external override {
        _requireCallerIsBOorTM2orTM3();

        collateralTokens.push(_collToken);
        L_COLL.push(0);
        L_ZUSDDebt.push(0);
        totalStakes.push(0);
        totalStakesSnapshot.push(0);
        totalCollateralSnapshot.push(0);
    }

    // --- Getters ---

    function getTroveOwnersCount() external view override returns(uint) {
        return TroveOwners.length;
    }

    function getTroveFromTroveOwnersArray(uint _index) external view override returns(address) {
        return TroveOwners[_index];
    }

    function getTokenAddresses() external view override returns(address[] memory) {
        return collateralTokens;
    }

    function getCollateralTokensLength() external view override returns(uint) {
        return collateralTokens.length;
    } 

    // Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    function _movePendingTroveRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _ZUSD, uint _collId, uint _collAmount) internal {
        _defaultPool.decreaseZUSDDebt(_ZUSD);
        _activePool.increaseZUSDDebt(_ZUSD);

        _collId == 0 ? _defaultPool.sendETHToActivePool(_collAmount) : _defaultPool.sendTokenToActivePool(_collId, _collAmount);
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Trove, without the price. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _borrower) public view override returns (uint) {
        (uint currentETH, uint currentZUSDDebt) = _getCurrentTroveAmounts(_borrower);

        uint NICR = LiquityMath._computeNominalCR(currentETH, currentZUSDDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Trove. Takes a trove's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower, uint _price) public view override returns (uint ICR) {
        (uint currentColl, uint currentZUSDDebt) = _getCurrentTroveAmounts(_borrower);

        ICR = LiquityMath._computeCR(currentColl, currentZUSDDebt, _price);
    }

    function _getCurrentTroveAmounts(address _borrower) internal view returns (uint currentColl, uint currentZUSDDebt) {
        uint pendingTokenReward = getPendingTokenReward(_borrower);
        uint pendingZUSDDebtReward = getPendingZUSDDebtReward(_borrower);

        currentColl = Troves[_borrower].coll + pendingTokenReward;
        currentZUSDDebt = Troves[_borrower].debt + pendingZUSDDebtReward;
    }

    function applyPendingRewards(address _borrower) external override {
        _requireCallerIsBOorTM2orTM3();
        return _applyPendingRewards(activePool, defaultPool, _borrower);
    }

    // Add the borrowers's coll and debt rewards earned from redistributions, to their Trove
    function _applyPendingRewards(IActivePool _activePool, IDefaultPool _defaultPool, address _borrower) internal {
        if (hasPendingRewards(_borrower)) {
            _requireTroveIsActive(_borrower);

            // Compute pending rewards
            uint pendingTokenReward = getPendingTokenReward(_borrower);
            uint pendingZUSDDebtReward = getPendingZUSDDebtReward(_borrower);

            // Apply pending rewards to trove's state
            Troves[_borrower].pendingColl = Troves[_borrower].pendingColl + pendingTokenReward;
            Troves[_borrower].pendingDebt = Troves[_borrower].pendingDebt + pendingZUSDDebtReward;

            _updateTroveRewardSnapshots(_borrower);

            // Transfer from DefaultPool to ActivePool

            //IActivePool _activePool, IDefaultPool _defaultPool, address _collTokenAddrs, uint _ZUSD, uint _collId, uint _collAmount
            _movePendingTroveRewardsToActivePool(_activePool, _defaultPool, pendingZUSDDebtReward, Troves[_borrower].collId, pendingTokenReward);

            emit TroveUpdated(
                _borrower,
                Troves[_borrower].debt,
                Troves[_borrower].coll,
                Troves[_borrower].stake,
                TroveManagerOperation.applyPendingRewards
            );
        }
    }

    // Update borrower's snapshots of L_COLL and L_ZUSDDebt to reflect the current values
    function updateTroveRewardSnapshots(address _borrower) external override {
        _requireCallerIsBOorTM2orTM3();
       return _updateTroveRewardSnapshots(_borrower);
    }

    function _updateTroveRewardSnapshots(address _borrower) internal {

        uint _collId = Troves[_borrower].collId;
    
        rewardSnapshots[_borrower].Coll = L_COLL[_collId];
        rewardSnapshots[_borrower].ZUSDDebt = L_ZUSDDebt[_collId];
        
        emit TroveSnapshotsUpdated(L_COLL, L_ZUSDDebt);
    }

    // Get the borrower's pending accumulated ETH reward, earned by their stake
    function getPendingTokenReward(address _borrower) public view override returns (uint) {
        uint _collId = Troves[_borrower].collId;
        uint snapshotToken = rewardSnapshots[_borrower].Coll;
        uint rewardPerUnitStaked = L_COLL[_collId] - snapshotToken;

        if (rewardPerUnitStaked == 0 || Troves[_borrower].status != Status.active) { return 0; }

        uint stake = Troves[_borrower].stake;

        uint pendingTokenReward = (stake * rewardPerUnitStaked) / DECIMAL_PRECISION;

        return pendingTokenReward;
    }
    
    // Get the borrower's pending accumulated ZUSD reward, earned by their stake
    function getPendingZUSDDebtReward(address _borrower) public view override returns (uint) {
        uint _collId = Troves[_borrower].collId;
        uint snapshotLUSDDebt = rewardSnapshots[_borrower].ZUSDDebt;
        uint rewardPerUnitStaked = L_ZUSDDebt[_collId] - snapshotLUSDDebt;

        if ( rewardPerUnitStaked == 0 || Troves[_borrower].status != Status.active) { return 0; }

        uint stake =  Troves[_borrower].stake;

        uint pendingLUSDDebtReward = (stake * rewardPerUnitStaked) / DECIMAL_PRECISION;

        return pendingLUSDDebtReward;
    }

    function hasPendingRewards(address _borrower) public view override returns (bool) {
        /*
        * A Trove has pending rewards if its snapshot is less than the current rewards per-unit-staked sum:
        * this indicates that rewards have occured since the snapshot was made, and the user therefore has
        * pending rewards
        */
        if (Troves[_borrower].status != Status.active) {return false;}

        uint _collId = Troves[_borrower].collId;

        return (rewardSnapshots[_borrower].Coll < L_COLL[_collId]);
    }

    // Return the Troves entire debt and coll, including pending rewards from redistributions.
    function getEntireDebtAndColl(address _borrower) public view override returns (uint debt, uint coll, uint pendingZUSDDebtReward, uint pendingTokenReward) {
        debt = Troves[_borrower].debt;
        coll = Troves[_borrower].coll;

        pendingZUSDDebtReward = getPendingZUSDDebtReward(_borrower);
        pendingTokenReward = getPendingTokenReward(_borrower);

        debt = debt + pendingZUSDDebtReward;
        coll = coll + pendingTokenReward;
    }

    function removeStake(address _borrower) external override {
        _requireCallerIsBOorTM2orTM3();
        return _removeStake(_borrower);
    }

    // Remove borrower's stake from the totalStakes sum, and set their stake to 0
    function _removeStake(address _borrower) internal {
        uint stake = Troves[_borrower].stake;
        uint collId = Troves[_borrower].collId; 
        totalStakes[collId] = totalStakes[collId] - stake;
        Troves[_borrower].stake = 0;
    }

    function updateStakeAndTotalStakes(address _borrower, uint _collId) external override returns (uint) {
        _requireCallerIsBOorTM2orTM3();
        return _updateStakeAndTotalStakes(_borrower, _collId);
    }

    // Update borrower's stake based on their latest collateral value
    function _updateStakeAndTotalStakes(address _borrower, uint _collId) internal returns (uint) {
        uint newStake = _computeNewStake(Troves[_borrower].coll, _collId);
        uint oldStake = Troves[_borrower].stake;
        Troves[_borrower].stake = newStake;

        totalStakes[_collId] = (totalStakes[_collId] - oldStake) + newStake;
        emit TotalStakesUpdated(totalStakes[_collId]);

        return newStake;
    }

    // Calculate a new stake based on the snapshots of the totalStakes and totalCollateral taken at the last liquidation
    function _computeNewStake(uint _coll, uint _collId) internal view returns (uint) {
        uint stake;
        if (totalCollateralSnapshot[_collId] == 0) {
            stake = _coll;
        } else {
            /*
            * The following assert() holds true because:
            * - The system always contains >= 1 trove
            * - When we close or liquidate a trove, we redistribute the pending rewards, so if all troves were closed/liquidated,
            * rewards would’ve been emptied and totalCollateralSnapshot would be zero too.
            */
            assert(totalStakesSnapshot[_collId] > 0);
            stake = (_coll * totalStakesSnapshot[_collId]) / totalCollateralSnapshot[_collId];
        }
        return stake;
    }

    function closeTrove(address _borrower, Status closedStatus) public override {
        _requireCallerIsBOorTM2orTM3();
       
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint TroveOwnersArrayLength = TroveOwners.length;
        uint collId = Troves[_borrower].collId;

        _requireMoreThanOneTroveInSystem(collId, TroveOwnersArrayLength);

        Troves[_borrower].status = closedStatus;
        Troves[_borrower].coll = 0;
        Troves[_borrower].debt = 0;

        rewardSnapshots[_borrower].Coll = 0;
        
        rewardSnapshots[_borrower].ZUSDDebt = 0;

        _removeTroveOwner(_borrower, TroveOwnersArrayLength);
        sortedTroves.remove(_borrower,collId);
    }

    /*
    * Updates snapshots of system total stakes and total collateral, excluding a given collateral remainder from the calculation.
    * Used in a liquidation sequence.
    *
    * The calculation excludes a portion of collateral that is in the ActivePool:
    *
    * the total ETH gas compensation from the liquidation sequence
    *
    * The ETH as compensation must be excluded as it is always sent out at the very end of the liquidation sequence.
    */
    function updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool,uint _collId, uint _collRemainder) public override {
        _requireCallerIsBOorTM2orTM3();
        
        totalStakesSnapshot = totalStakes;

        uint[] memory activeColl = new uint[] (collateralTokens.length);
        uint[] memory liquidatedColl = new uint[] (collateralTokens.length);

        activeColl = _activePool.getTokenBalances();
        liquidatedColl = defaultPool.getTokenBalances();
        totalCollateralSnapshot[_collId] = (activeColl[_collId] - _collRemainder) + liquidatedColl[_collId];

        emit SystemSnapshotsUpdated(totalStakesSnapshot, totalCollateralSnapshot);
    }

    // Push the owner's address to the Trove owners list, and record the corresponding array index on the Trove struct
    function addTroveOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBOorTM2orTM3();
        return _addTroveOwnerToArray(_borrower);
    }

    function _addTroveOwnerToArray(address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 troves. No risk of overflow, since troves have minimum ZUSD
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 ZUSD dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the Troveowner to the array
        TroveOwners.push(_borrower);

        // Record the index of the new Troveowner on their Trove struct
        index = uint128(TroveOwners.length - 1);
        Troves[_borrower].arrayIndex = index;

        return index;
    }

    function removeTroveOwner(address _borrower, uint TroveOwnersArrayLength) external override {
        _requireCallerIsBOorTM2orTM3();
        _removeTroveOwner(_borrower, TroveOwnersArrayLength);
    }

    /*
    * Remove a Trove owner from the TroveOwners array, not preserving array order. Removing owner 'B' does the following:
    * [A B C D E] => [A E C D], and updates E's Trove struct to point to its new array index.
    */
    function _removeTroveOwner(address _borrower, uint TroveOwnersArrayLength) internal {
        Status troveStatus = Troves[_borrower].status;
        // It’s set in caller function `_closeTrove`
        assert(troveStatus != Status.nonExistent && troveStatus != Status.active);

        uint128 index = Troves[_borrower].arrayIndex;
        uint length = TroveOwnersArrayLength;
        uint idxLast = length - 1;

        assert(index <= idxLast);

        address addressToMove = TroveOwners[idxLast];

        TroveOwners[index] = addressToMove;
        Troves[addressToMove].arrayIndex = index;
        emit TroveIndexUpdated(addressToMove, index);

        TroveOwners.pop();
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBOorTM2orTM3() internal view {
        require(msg.sender == borrowerOperationsAddress || 
        msg.sender == troveManager2Address ||
        msg.sender == troveManager3Address, "TroveManager: Caller is not the BorrowerOperations contract");
    }

    function _requireTroveIsActive(address _borrower) internal view {
        require(Troves[_borrower].status == Status.active, "TroveManager: Trove does not exist or is closed");
    }

    function _requireMoreThanOneTroveInSystem(uint _collId, uint TroveOwnersArrayLength) internal view {
        require (TroveOwnersArrayLength > 1 && sortedTroves.getSize(_collId) > 1, "TroveManager: Only one trove in the system");
    }

    // --- Recovery Mode and TCR functions ---

    function getTCR(uint[] memory _price) external view override returns (uint) {
        return _getTCR(_price);
    }
    
    function getTotalStakes(uint collId) external view override returns (uint) {
        return totalStakes[collId];
    }
    
     // --- Liquidation helper functions ---

    function getL_Coll(uint _collId) external override view returns (uint) {
        return L_COLL[_collId];
    }

    function getL_ZUSDDebt(uint _collId) external override view returns (uint) {
        return L_ZUSDDebt[_collId];
    }

    // --- Trove property getters ---
    function getTroveStatus(address _borrower) external view override returns (uint) {
        return uint(Troves[_borrower].status);
    }

    function getTroveStake(address _borrower) external view override returns (uint) {
        require(Troves[_borrower].status != Status.nonExistent, "TroveManager: Trove does not exist");
        return Troves[_borrower].stake;
    }

    function getTroveDebt(address _borrower) external view override returns (uint) {
        require(Troves[_borrower].status != Status.nonExistent, "TroveManager: Trove does not exist");
        return Troves[_borrower].debt;
    }

    function getTroveCollId(address _borrower) public view override returns (uint) {
        require(Troves[_borrower].status != Status.nonExistent, "TroveManager: Trove does not exist");
        return Troves[_borrower].collId;
    }

    function getTroveColl(address _borrower) external view override returns (uint) {
        require(Troves[_borrower].status != Status.nonExistent, "TroveManager: Trove does not exist");
        return Troves[_borrower].coll;
    }

    function getRewardColl(address _borrower) public view override returns (uint) {
        if(rewardSnapshots[_borrower].Coll == 0){
            return 0;
        }
        else {
            return rewardSnapshots[_borrower].Coll;
        }
    }

    function getRewardDebt(address _borrower) public view override returns (uint) {
        if(rewardSnapshots[_borrower].ZUSDDebt == 0) {
            return 0;
        }  
        else {
            return rewardSnapshots[_borrower].ZUSDDebt;
        }
    }

    function getRewardSnapshots(address _addrs) public view returns(uint, uint) {
        return(rewardSnapshots[_addrs].Coll, rewardSnapshots[_addrs].ZUSDDebt);
    }

    // --- Trove property setters, called by BorrowerOperations ---

    function setTroveStatus(address _borrower, uint _collateralTokenId, uint _num) external override {
        _requireCallerIsBOorTM2orTM3();
        Troves[_borrower].collId = _collateralTokenId;
        Troves[_borrower].status = Status(_num);
    }

    function increaseTroveColl(address _borrower, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBOorTM2orTM3();
        uint newColl = Troves[_borrower].coll + _collIncrease;
        Troves[_borrower].coll = newColl;
        return newColl;
    }

    function decreaseTroveColl(address _borrower, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBOorTM2orTM3();
        uint newColl = Troves[_borrower].coll - _collDecrease;
        Troves[_borrower].coll = newColl;
        return newColl;
    }

    function liquidationColl(uint _collId, uint _newLColl) external override {
        L_COLL[_collId] = L_COLL[_collId] + _newLColl;
    }

    function liquidationDebt(uint _collId, uint _newLDebt) external override {
        L_ZUSDDebt[_collId] = L_ZUSDDebt[_collId] + _newLDebt;
    }


    function redemptionTroveDebt(address _borrower, uint _newDebt) external override returns (uint) {
        _requireCallerIsBOorTM2orTM3();
        Troves[_borrower].debt = _newDebt;
        return _newDebt;
    }

    function redemptionTroveColl(address _borrower, uint _newColl) external override returns (uint) {
        _requireCallerIsBOorTM2orTM3();
        Troves[_borrower].coll = _newColl;
        return _newColl;
    }

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBOorTM2orTM3();
        uint newDebt = Troves[_borrower].debt + _debtIncrease;
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseTroveDebt(address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBOorTM2orTM3();
        uint newDebt = Troves[_borrower].debt - _debtDecrease;
        Troves[_borrower].debt = newDebt;
        return newDebt;
    }
}
