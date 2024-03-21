// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ITroveManager3.sol";
import "./LiquityBase.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

contract TroveManager3 is LiquityBase, Ownable, CheckContract, ITroveManager3 {
    string constant public NAME = "TroveManager";

    address[] internal collateralTokens;

    // --- Connected contract declarations ---
    ITroveManager1 public troveManager1;
    ITroveManager2 public troveManager2;

    address public borrowerOperationsAddress;

    IStabilityPool public override stabilityPool;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    IZUSDToken public override zusdToken;

    IZQTYToken public override zqtyToken;

    // A doubly linked list of Troves, sorted by their sorted by their collateral ratios
    ISortedTroves public sortedTroves;    

    // Error trackers for the trove redistribution calculation
    uint[] public lastTokenError_Redistribution;
    uint[] public lastZUSDDebtError_Redistribution;

    // --- Dependency setter ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManager1Address,
        address _troveManager2Address,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _zusdTokenAddress,
        address _sortedTrovesAddress,
        address _zqtyTokenAddress
    )
        external
        override
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManager1Address);
        checkContract(_troveManager2Address);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_zusdTokenAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_zqtyTokenAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManager1 = ITroveManager1(_troveManager1Address);
        troveManager2 = ITroveManager2(_troveManager2Address);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        zusdToken = IZUSDToken(_zusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        zqtyToken = IZQTYToken(_zqtyTokenAddress);

        collateralTokens.push(address(0));
        lastTokenError_Redistribution.push(0);
        lastZUSDDebtError_Redistribution.push(0);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit ZUSDTokenAddressChanged(_zusdTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit ZQTYTokenAddressChanged(_zqtyTokenAddress);

        _renounceOwnership();
    }

    function setCollTokenAddress(address _collToken) external override {
        _requireCallerIsBorrowerOperations();

        collateralTokens.push(_collToken);
        lastTokenError_Redistribution.push(0);
        lastZUSDDebtError_Redistribution.push(0);
    }

    // --- Trove Liquidation functions ---

    // Single liquidation function. Closes the trove if its ICR is lower than the minimum collateral ratio.
    function liquidate(address _borrower) external override {
        _requireTroveIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateTroves(borrowers);
    }

    // --- Inner single liquidation functions ---

    // Liquidate one trove, in Normal Mode.
    function _liquidateNormalMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint _ZUSDInStabPool
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;

        (singleLiquidation.entireTroveDebt,
        singleLiquidation.entireTroveColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = troveManager1.getEntireDebtAndColl(_borrower);

        uint _collId = troveManager1.getTroveCollId(_borrower);
        
        _movePendingTroveRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, _collId, vars.pendingCollReward);
        
        troveManager1.removeStake(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireTroveColl);
        singleLiquidation.ZUSDGasCompensation = ZUSD_GAS_COMPENSATION;
        uint collToLiquidate = singleLiquidation.entireTroveColl - singleLiquidation.collGasCompensation;

        (singleLiquidation.debtToOffset,
        singleLiquidation.collToSendToSP,
        singleLiquidation.debtToRedistribute,
        singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireTroveDebt, collToLiquidate, _ZUSDInStabPool);

        troveManager1.closeTrove(_borrower, ITroveManager1.Status.closedByLiquidation);
        emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, TroveManagerOperation.liquidateInNormalMode);
        emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInNormalMode);
        return singleLiquidation;
    }

    // Liquidate one trove, in Recovery Mode.
    function _liquidateRecoveryMode(
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        address _borrower,
        uint _ICR,
        uint _ZUSDInStabPool,
        uint _TCR,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {
        LocalVariables_InnerSingleLiquidateFunction memory vars;
        if (troveManager1.getTroveOwnersCount() <= 1) {return singleLiquidation;} // don't liquidate if last trove
        (singleLiquidation.entireTroveDebt,
        singleLiquidation.entireTroveColl,
        vars.pendingDebtReward,
        vars.pendingCollReward) = troveManager1.getEntireDebtAndColl(_borrower);

        singleLiquidation.collGasCompensation = _getCollGasCompensation(singleLiquidation.entireTroveColl);
        singleLiquidation.ZUSDGasCompensation = ZUSD_GAS_COMPENSATION;
        vars.collToLiquidate = singleLiquidation.entireTroveColl - singleLiquidation.collGasCompensation;

        uint _collId = troveManager1.getTroveCollId(_borrower);

        // If ICR <= 100%, purely redistribute the Trove across all active Troves
        if (_ICR <= _100pct) {        
            _movePendingTroveRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, _collId, vars.pendingCollReward);

            troveManager1.removeStake(_borrower);
           
            singleLiquidation.debtToOffset = 0;
            singleLiquidation.collToSendToSP = 0;
            singleLiquidation.debtToRedistribute = singleLiquidation.entireTroveDebt;
            singleLiquidation.collToRedistribute = vars.collToLiquidate;

            troveManager1.closeTrove(_borrower, ITroveManager1.Status.closedByLiquidation);
            emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, TroveManagerOperation.liquidateInRecoveryMode);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInRecoveryMode);
            
        // If 100% < ICR < MCR, offset as much as possible, and redistribute the remainder
        } else if ((_ICR > _100pct) && (_ICR < MCR)) {
            _movePendingTroveRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, _collId, vars.pendingCollReward);

            troveManager1.removeStake(_borrower);

            (singleLiquidation.debtToOffset,
            singleLiquidation.collToSendToSP,
            singleLiquidation.debtToRedistribute,
            singleLiquidation.collToRedistribute) = _getOffsetAndRedistributionVals(singleLiquidation.entireTroveDebt, vars.collToLiquidate, _ZUSDInStabPool);

            troveManager1.closeTrove(_borrower, ITroveManager1.Status.closedByLiquidation);
            emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, TroveManagerOperation.liquidateInRecoveryMode);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInRecoveryMode);
        /*
        * If 110% <= ICR < current TCR (accounting for the preceding liquidations in the current sequence)
        * and there is ZUSD in the Stability Pool, only offset, with no redistribution,
        * but at a capped rate of 1.1 and only if the whole debt can be liquidated.
        * The remainder due to the capped rate will be claimable as collateral surplus.
        */
        } else if ((_ICR >= MCR) && (_ICR < _TCR) && (singleLiquidation.entireTroveDebt <= _ZUSDInStabPool)) {
            _movePendingTroveRewardsToActivePool(_activePool, _defaultPool, vars.pendingDebtReward, _collId, vars.pendingCollReward);
            
            assert(_ZUSDInStabPool != 0);

            troveManager1.removeStake(_borrower);
            singleLiquidation = _getCappedOffsetVals(singleLiquidation.entireTroveDebt, singleLiquidation.entireTroveColl, _price);

            troveManager1.closeTrove(_borrower, ITroveManager1.Status.closedByLiquidation);
            
            vars.collId = troveManager1.getTroveCollId(_borrower);
            if (singleLiquidation.collSurplus > 0) {
                collSurplusPool.accountSurplus(_borrower, vars.collId, singleLiquidation.collSurplus);
            }

            emit TroveLiquidated(_borrower, singleLiquidation.entireTroveDebt, singleLiquidation.collToSendToSP, TroveManagerOperation.liquidateInRecoveryMode);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.liquidateInRecoveryMode);

        } else { // if (_ICR >= MCR && ( _ICR >= _TCR || singleLiquidation.entireTroveDebt > _ZUSDInStabPool))
            LiquidationValues memory zeroVals;
            return zeroVals;
        }

        return singleLiquidation;
    }

    /* In a full liquidation, returns the values for a trove's coll and debt to be offset, and coll and debt to be
    * redistributed to active troves.
    */
    function _getOffsetAndRedistributionVals
    (
        uint _debt,
        uint _coll,
        uint _ZUSDInStabPool
    )
        internal
        pure
        returns (uint debtToOffset, uint collToSendToSP, uint debtToRedistribute, uint collToRedistribute)
    {
        if (_ZUSDInStabPool > 0) {
        /*
        * Offset as much debt & collateral as possible against the Stability Pool, and redistribute the remainder
        * between all active troves.
        *
        *  If the trove's debt is larger than the deposited ZUSD in the Stability Pool:
        *
        *  - Offset an amount of the trove's debt equal to the ZUSD in the Stability Pool
        *  - Send a fraction of the trove's collateral to the Stability Pool, equal to the fraction of its offset debt
        *
        */
            debtToOffset = LiquityMath._min(_debt, _ZUSDInStabPool);
            collToSendToSP = (_coll * debtToOffset) / _debt;
            debtToRedistribute = _debt - debtToOffset;
            collToRedistribute = _coll - collToSendToSP;
        } else {
            debtToOffset = 0;
            collToSendToSP = 0;
            debtToRedistribute = _debt;
            collToRedistribute = _coll;
        }
    }

    /*
    *  Get its offset coll/debt and ETH gas comp, and close the trove.
    */
    function _getCappedOffsetVals
    (
        uint _entireTroveDebt,
        uint _entireTroveColl,
        uint _price
    )
        internal
        pure
        returns (LiquidationValues memory singleLiquidation)
    {
        singleLiquidation.entireTroveDebt = _entireTroveDebt;
        singleLiquidation.entireTroveColl = _entireTroveColl;
        uint cappedCollPortion = (_entireTroveDebt * MCR) / _price;

        singleLiquidation.collGasCompensation = _getCollGasCompensation(cappedCollPortion);
        singleLiquidation.ZUSDGasCompensation = ZUSD_GAS_COMPENSATION;

        singleLiquidation.debtToOffset = _entireTroveDebt;
        singleLiquidation.collToSendToSP = cappedCollPortion - singleLiquidation.collGasCompensation;
        singleLiquidation.collSurplus = _entireTroveColl - cappedCollPortion;
        singleLiquidation.debtToRedistribute = 0;
        singleLiquidation.collToRedistribute = 0;
    }

    /*
    * Liquidate a sequence of troves. Closes a maximum number of n under-collateralized Troves,
    * starting from the one with the lowest collateral ratio in the system, and moving upwards
    */

    function liquidateTroves(uint _collId, uint _n) external override {
        require(_n > 0, "TroveManager: n cannot be zero");

        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            sortedTroves
        );

        require(_n < contractsCache.sortedTroves.getSize(_collId), "TroveManager: n greater than the number of troves");

        IStabilityPool stabilityPoolCached = stabilityPool;

        LocalVariables_OuterLiquidationFunction memory vars;

        LiquidationTotals memory totals;

        vars.price = new uint[] (collateralTokens.length);
        vars.price = priceFeed.fetchEntirePrice();

        vars.ZUSDInStabPool = stabilityPoolCached.getTotalZUSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        vars.recoveryModeAtStart ?
        totals = _getTotalsFromLiquidateTrovesSequence_RecoveryMode(contractsCache, vars.price, vars.ZUSDInStabPool, _collId, _n) :            
        totals = _getTotalsFromLiquidateTrovesSequence_NormalMode(contractsCache.activePool, contractsCache.defaultPool, vars.price, vars.ZUSDInStabPool, _collId, _n);

        require(totals.totalDebtInSequence > 0, "TroveManager: nothing to liquidate");

        // Move liquidated ETH and ZUSD to the appropriate pools
        stabilityPoolCached.offset(totals.totalDebtToOffset, _collId, totals.totalCollToSendToSP);

        _redistributeDebtAndColl(contractsCache.activePool, contractsCache.defaultPool, totals.totalDebtToRedistribute, _collId, totals.totalCollToRedistribute);
        
        if (totals.totalCollSurplus > 0) {
            _collId == 0 ? 
            contractsCache.activePool.sendETH(address(collSurplusPool), totals.totalCollSurplus) :
            contractsCache.activePool.sendToken(address(collSurplusPool), _collId, totals.totalCollSurplus);

            collSurplusPool.receiveCollToken(_collId,totals.totalCollSurplus);
        }

        // Update system snapshots
        troveManager1.updateSystemSnapshots_excludeCollRemainder(contractsCache.activePool, _collId, totals.totalCollGasCompensation);

        vars.liquidatedDebt = totals.totalDebtInSequence;
        vars.liquidatedColl = totals.totalCollInSequence - totals.totalCollGasCompensation - totals.totalCollSurplus;
        emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals.totalCollGasCompensation, totals.totalZUSDGasCompensation);

        // Send gas compensation to caller
        _sendGasCompensation(contractsCache.activePool, msg.sender, _collId, totals.totalZUSDGasCompensation, totals.totalCollGasCompensation);
    }

    /*
    * This function is used when the liquidateTroves sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalsFromLiquidateTrovesSequence_RecoveryMode
    (
        ContractsCache memory _contractsCache,
        uint[] memory _price,
        uint _ZUSDInStabPool,
        uint _collId,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingZUSDInStabPool = _ZUSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt();
        vars.entireSystemColl = getEntireCollPrice(0, 0, false, _price);

        vars.user = _contractsCache.sortedTroves.getLast(_collId);
        address firstUser = _contractsCache.sortedTroves.getFirst(_collId);

        for (vars.i = 0; vars.i < _n && vars.user != firstUser; vars.i++) {
            // we need to cache it, because current user is likely going to be deleted
            address nextUser = _contractsCache.sortedTroves.getPrev(vars.user, _collId);
            
            vars.ICR = troveManager1.getCurrentICR(vars.user, _price[_collId]);

            if (!vars.backToNormalMode) {
                // Break the loop if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingZUSDInStabPool == 0) { break; }

                vars.TCR = LiquityMath._computeEntireCR(vars.entireSystemColl, vars.entireSystemDebt);

                singleLiquidation = _liquidateRecoveryMode(_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.ICR, vars.remainingZUSDInStabPool, vars.TCR, _price[_collId]);

                // Update aggregate trackers
                vars.remainingZUSDInStabPool = vars.remainingZUSDInStabPool - singleLiquidation.debtToOffset;
                vars.entireSystemDebt = vars.entireSystemDebt - singleLiquidation.debtToOffset;
                vars.entireSystemColl = vars.entireSystemColl - singleLiquidation.collToSendToSP - singleLiquidation.collGasCompensation - singleLiquidation.collSurplus;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price[_collId]);
            }
            else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_contractsCache.activePool, _contractsCache.defaultPool, vars.user, vars.remainingZUSDInStabPool);

                vars.remainingZUSDInStabPool = vars.remainingZUSDInStabPool - singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            }  else break;  // break if the loop reaches a Trove with ICR >= MCR

            vars.user = nextUser;
        }
    }

    function _getTotalsFromLiquidateTrovesSequence_NormalMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint[] memory _price,
        uint _ZUSDInStabPool,
        uint _collId,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;
        ISortedTroves sortedTrovesCached = sortedTroves;

        vars.remainingZUSDInStabPool = _ZUSDInStabPool;

        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = sortedTrovesCached.getLast(_collId);

            vars.ICR = troveManager1.getCurrentICR(vars.user, _price[_collId]);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingZUSDInStabPool);

                vars.remainingZUSDInStabPool = vars.remainingZUSDInStabPool - singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else break;  // break if the loop reaches a Trove with ICR >= MCR
        }
    }

    /*
    * Attempt to liquidate a custom list of troves provided by the caller.
    */
    function batchLiquidateTroves(address[] memory _troveArray) public override {
        require(_troveArray.length != 0, "TroveManager: Calldata address array must not be empty");

        IActivePool activePoolCached = activePool;
        IDefaultPool defaultPoolCached = defaultPool;
        IStabilityPool stabilityPoolCached = stabilityPool;

        LocalVariables_BatchLiquidationFunction[] memory batch = new LocalVariables_BatchLiquidationFunction[](collateralTokens.length);
        LocalVariables_OuterLiquidationFunction memory vars;
        LiquidationTotals[] memory totals = new LiquidationTotals[](collateralTokens.length);

        vars.price = priceFeed.fetchEntirePrice();
        vars.ZUSDInStabPool = stabilityPoolCached.getTotalZUSDDeposits();
        vars.recoveryModeAtStart = _checkRecoveryMode(vars.price);

        for(vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.collId = troveManager1.getTroveCollId(_troveArray[vars.i]);
            batch[vars.collId].batchLength++;
        }

        for(vars.i = 0; vars.i < collateralTokens.length; vars.i++) {
            if(batch[vars.i].batchLength > 0) {
                batch[vars.i].batchAddress = new address[](batch[vars.i].batchLength);
            }
        }

        for(vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.collId = troveManager1.getTroveCollId(_troveArray[vars.i]);
            if(batch[vars.collId].batchLength > 0) {
                batch[vars.collId].batchAddress[--batch[vars.collId].batchLength] = _troveArray[vars.i];
            }
        }

        bool isTotalDebtInSequence;

        for (vars.i = 0; vars.i < collateralTokens.length; vars.i++) {
            if(batch[vars.i].batchLength > 0) {
                totals[vars.i] = vars.recoveryModeAtStart ?
                    _getTotalFromBatchLiquidate_RecoveryMode(activePoolCached, defaultPoolCached, vars.price, vars.ZUSDInStabPool, batch[vars.i].batchAddress) :
                    _getTotalsFromBatchLiquidate_NormalMode(activePoolCached, defaultPoolCached, vars.price[vars.i], vars.ZUSDInStabPool, batch[vars.i].batchAddress);

                if(totals[vars.i].totalDebtInSequence > 0) {
                    isTotalDebtInSequence = true;
                }
            }
        }

        require(isTotalDebtInSequence, "TroveManager: nothing to liquidate");

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        for (vars.i = 0; vars.i < collateralTokens.length; vars.i++) {
            if(batch[vars.i].batchLength > 0) {
                // Move liquidated ETH and ZUSD to the appropriate pools
                stabilityPoolCached.offset(totals[vars.i].totalDebtToOffset, vars.i, totals[vars.i].totalCollToSendToSP);
                _redistributeDebtAndColl(activePoolCached, defaultPoolCached, totals[vars.i].totalDebtToRedistribute, vars.i, totals[vars.i].totalCollToRedistribute);

                if (totals[vars.i].totalCollSurplus > 0) {
                    if (vars.i == 0) {
                        activePool.sendETH(address(collSurplusPool), totals[vars.i].totalCollSurplus);
                    } else {
                        activePool.sendToken(address(collSurplusPool), vars.i, totals[vars.i].totalCollSurplus);
                    }
                    collSurplusPool.receiveCollToken(vars.i, totals[vars.i].totalCollSurplus);
                }

                // Update system snapshots
                troveManager1.updateSystemSnapshots_excludeCollRemainder(activePoolCached, vars.i, totals[vars.i].totalCollGasCompensation);

                vars.liquidatedDebt = totals[vars.i].totalDebtInSequence;
                vars.liquidatedColl = totals[vars.i].totalCollInSequence - totals[vars.i].totalCollGasCompensation - totals[vars.i].totalCollSurplus;
                emit Liquidation(vars.liquidatedDebt, vars.liquidatedColl, totals[vars.i].totalCollGasCompensation, totals[vars.i].totalZUSDGasCompensation);

                // Send gas compensation to caller
                _sendGasCompensation(activePoolCached, msg.sender, vars.i, totals[vars.i].totalZUSDGasCompensation, totals[vars.i].totalCollGasCompensation);
            }
        }
    }
        

    /*
    * This function is used when the batch liquidation sequence starts during Recovery Mode. However, it
    * handle the case where the system *leaves* Recovery Mode, part way through the liquidation sequence
    */
    function _getTotalFromBatchLiquidate_RecoveryMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint[] memory _price,
        uint _ZUSDInStabPool,
        address[] memory _troveArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingZUSDInStabPool = _ZUSDInStabPool;
        vars.backToNormalMode = false;
        vars.entireSystemDebt = getEntireSystemDebt();
        vars.entireSystemColl = getEntireCollPrice(0, 0, false, _price);

        for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.user = _troveArray[vars.i];
            vars.collId = troveManager1.getTroveCollId(vars.user);
            // Skip non-active troves
            if (troveManager1.getTroveStatus(vars.user) != uint(ITroveManager1.Status.active)) { continue; }

            vars.ICR = troveManager1.getCurrentICR(vars.user, _price[vars.collId]);

            if (!vars.backToNormalMode) {

                // Skip this trove if ICR is greater than MCR and Stability Pool is empty
                if (vars.ICR >= MCR && vars.remainingZUSDInStabPool == 0) { continue; }

                uint TCR = LiquityMath._computeEntireCR(vars.entireSystemColl, vars.entireSystemDebt);

                singleLiquidation = _liquidateRecoveryMode(_activePool, _defaultPool, vars.user, vars.ICR, vars.remainingZUSDInStabPool, TCR, _price[vars.collId]);

                // Update aggregate trackers
                vars.remainingZUSDInStabPool = vars.remainingZUSDInStabPool - (singleLiquidation.debtToOffset);
                vars.entireSystemDebt = vars.entireSystemDebt - singleLiquidation.debtToOffset;
                vars.entireSystemColl = vars.entireSystemColl - singleLiquidation.collToSendToSP - singleLiquidation.collGasCompensation -singleLiquidation.collSurplus;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

                vars.backToNormalMode = !_checkPotentialRecoveryMode(vars.entireSystemColl, vars.entireSystemDebt, _price[vars.collId]);
            }

            else if (vars.backToNormalMode && vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingZUSDInStabPool);
                vars.remainingZUSDInStabPool = vars.remainingZUSDInStabPool - singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else continue; // In Normal Mode skip troves with ICR >= MCR
        }
    }

    function _getTotalsFromBatchLiquidate_NormalMode
    (
        IActivePool _activePool,
        IDefaultPool _defaultPool,
        uint _price,
        uint _ZUSDInStabPool,
        address[] memory _troveArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;

        vars.remainingZUSDInStabPool = _ZUSDInStabPool;

        for (vars.i = 0; vars.i < _troveArray.length; vars.i++) {
            vars.user = _troveArray[vars.i];
            vars.ICR = troveManager1.getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidateNormalMode(_activePool, _defaultPool, vars.user, vars.remainingZUSDInStabPool);
                vars.remainingZUSDInStabPool = vars.remainingZUSDInStabPool - singleLiquidation.debtToOffset;

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

    // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(LiquidationTotals memory oldTotals, LiquidationValues memory singleLiquidation)
    internal pure returns(LiquidationTotals memory newTotals) {

        // Tally all the values with their respective running totals
        newTotals.totalCollGasCompensation = oldTotals.totalCollGasCompensation + singleLiquidation.collGasCompensation;
        newTotals.totalZUSDGasCompensation = oldTotals.totalZUSDGasCompensation + singleLiquidation.ZUSDGasCompensation;
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence + singleLiquidation.entireTroveDebt;
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence + singleLiquidation.entireTroveColl;
        newTotals.totalDebtToOffset = oldTotals.totalDebtToOffset + singleLiquidation.debtToOffset;
        newTotals.totalCollToSendToSP = oldTotals.totalCollToSendToSP + singleLiquidation.collToSendToSP;
        newTotals.totalDebtToRedistribute = oldTotals.totalDebtToRedistribute + singleLiquidation.debtToRedistribute;
        newTotals.totalCollToRedistribute = oldTotals.totalCollToRedistribute + singleLiquidation.collToRedistribute;
        newTotals.totalCollSurplus = oldTotals.totalCollSurplus + singleLiquidation.collSurplus;

        return newTotals;
    }

    function _sendGasCompensation(IActivePool _activePool, address _liquidator, uint _collId, uint _ZUSD, uint _collAmount) internal {
        if (_ZUSD > 0) {
            zusdToken.returnFromPool(gasPoolAddress, _liquidator, _ZUSD);
        }

        if (_collAmount > 0) {
            _collId == 0 ? _activePool.sendETH(_liquidator, _collAmount) : _activePool.sendToken(_liquidator, _collId, _collAmount);
        }
    }

    // Move a Trove's pending debt and collateral rewards from distributions, from the Default Pool to the Active Pool
    function _movePendingTroveRewardsToActivePool(IActivePool _activePool, IDefaultPool _defaultPool, uint _ZUSD, uint _collId, uint _collAmount) internal {
        _defaultPool.decreaseZUSDDebt(_ZUSD);
        _activePool.increaseZUSDDebt(_ZUSD);

        _collId == 0 ? defaultPool.sendETHToActivePool(_collAmount) : _defaultPool.sendTokenToActivePool(_collId, _collAmount);
    }

    // --- Helper functions ---
    function _redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, uint _collId, uint _coll) internal {
        if (_debt == 0) { return; }

        /*
        * Add distributed coll and debt rewards-per-unit-staked to the running totals. Division uses a "feedback"
        * error correction, to keep the cumulative error low in the running totals L_COLL and L_ZUSDDebt:
        *
        * 1) Form numerators which compensate for the floor division errors that occurred the last time this function was called.
        * 2) Calculate "per-unit-staked" ratios.
        * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
        * 4) Store these errors for use in the next correction when this function is called.
        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
        */
        uint totalStakes = troveManager1.getTotalStakes(_collId);

        uint TokenNumerator = (_coll * DECIMAL_PRECISION) + lastTokenError_Redistribution[_collId];
        uint ZUSDDebtNumerator = (_debt * DECIMAL_PRECISION) + lastZUSDDebtError_Redistribution[_collId];

        require(TokenNumerator > totalStakes , "Potential underflow in TokenNumerator");
        require(ZUSDDebtNumerator > totalStakes , "Potential underflow in ZUSDDebtNumerator");
        
        // Get the per-unit-staked terms
        uint TokenRewardPerUnitStaked = TokenNumerator / totalStakes;
        uint ZUSDDebtRewardPerUnitStaked = ZUSDDebtNumerator / totalStakes;

        require(TokenNumerator >= (TokenRewardPerUnitStaked * totalStakes), "Potential underflow");
        require(ZUSDDebtNumerator >= (ZUSDDebtRewardPerUnitStaked * totalStakes), "Potential underflow");

        lastTokenError_Redistribution[_collId] = TokenNumerator - (TokenRewardPerUnitStaked * totalStakes);
        lastZUSDDebtError_Redistribution[_collId] = ZUSDDebtNumerator - (ZUSDDebtRewardPerUnitStaked * totalStakes);

        // Add per-unit-staked terms to the running totals
        uint lColl = troveManager1.getL_Coll(_collId) + TokenRewardPerUnitStaked;
        uint lDebt = troveManager1.getL_ZUSDDebt(_collId) + ZUSDDebtRewardPerUnitStaked;

        troveManager1.liquidationColl(_collId, lColl);
        troveManager1.liquidationDebt(_collId, lDebt);

        emit LTermsUpdated(troveManager1.getL_Coll(_collId), troveManager1.getL_ZUSDDebt(_collId));

        // Transfer coll and debt from ActivePool to DefaultPool
        _activePool.decreaseZUSDDebt(_debt);
        _defaultPool.increaseZUSDDebt(_debt);

        _collId == 0 ? _activePool.sendETH(address(_defaultPool), _coll) : _activePool.sendToken(address(_defaultPool), _collId, _coll) ;
        _defaultPool.receiveCollToken(_collId, _coll);
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperationsAddress, "TroveManager: Caller is not the BorrowerOperations contract");
    }

    function _requireTroveIsActive(address _borrower) internal view {
        require(troveManager1.getTroveStatus(_borrower) == uint(Status.active), "TroveManager: Trove does not exist or is closed");
    }

    function getTokenAddresses() external view override returns(address[] memory) {
        return collateralTokens;
    }

    function checkRecoveryMode(uint[] memory _price) external view override returns (bool) {
        return _checkRecoveryMode(_price);
    }

     // Check whether or not the system *would be* in Recovery Mode, given an ETH:USD price, and the entire system coll and debt.
    function _checkPotentialRecoveryMode(
        uint _entireSystemColl,
        uint _entireSystemDebt,
        uint _price
    )
        internal
        pure
    returns (bool)
    {
        uint TCR = LiquityMath._computeCR(_entireSystemColl, _entireSystemDebt, _price);

        return TCR < CCR;
    }


}
