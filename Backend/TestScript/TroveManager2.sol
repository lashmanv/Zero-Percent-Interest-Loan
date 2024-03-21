// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ITroveManager2.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

contract TroveManager2 is LiquityBase, Ownable, CheckContract, ITroveManager2 {
    string constant public NAME = "Redemption - TroveManager";

    address[] internal collateralTokens;

    // --- Connected contract declarations ---

    address public borrowerOperationsAddress;

    IStabilityPool public override stabilityPool;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    IZUSDToken public override zusdToken;

    IZQTYToken public override zqtyToken;

    IZQTYStaking public override zqtyStaking;

    ITroveManager1 public troveManager1;

    // A doubly linked list of Troves, sorted by their sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    // --- Data structures ---

    uint constant public SECONDS_IN_ONE_MINUTE = 60;
    /*
     * Half-life of 12h. 12h = 720 min
     * (1/2) = d^720 => d = (1/2)^(1/720)
     */
    uint constant public MINUTE_DECAY_FACTOR = 999037758833783000;
    uint constant public REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%
    uint constant public MAX_BORROWING_FEE = DECIMAL_PRECISION / 100 * 5; // 5%

    // During bootsrap period redemptions are not allowed
    uint constant public BOOTSTRAP_PERIOD = 0 days;

    /*
    * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
    * Corresponds to (1 / ALPHA) in the white paper.
    */
    uint constant public BETA = 2;

    uint public baseRate;

    // The timestamp of the latest fee operation (redemption or new ZUSD issuance)
    uint public lastFeeOperationTime;

    // --- Dependency setter ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManager1Address,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
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
        checkContract(_troveManager1Address);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_zusdTokenAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_zqtyTokenAddress);
        checkContract(_zqtyStakingAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManager1 = ITroveManager1(_troveManager1Address);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        zusdToken = IZUSDToken(_zusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        zqtyToken = IZQTYToken(_zqtyTokenAddress);
        zqtyStaking = IZQTYStaking(_zqtyStakingAddress);

        collateralTokens.push(address(0));

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManager1AddressChanged(_troveManager1Address);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit ZUSDTokenAddressChanged(_zusdTokenAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit ZQTYTokenAddressChanged(_zqtyTokenAddress);
        emit ZQTYStakingAddressChanged(_zqtyStakingAddress);

        _renounceOwnership();
    }

    function setCollTokenAddress(address _collToken) external override {
        _requireCallerIsBorrowerOperations();

        collateralTokens.push(_collToken);
    }

    // --- Redemption functions ---

    // Redeem as much collateral as possible from _borrower's Trove in exchange for ZUSD up to _maxZUSDamount
    function _redeemCollateralFromTrove(
        ContractsCache memory _contractsCache,
        address _borrower,
        uint _maxZUSDamount,
        uint _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR
    )
        internal returns (SingleRedemptionValues memory singleRedemption)
    {
        uint debt = troveManager1.getTroveDebt(_borrower);
        uint coll = troveManager1.getTroveColl(_borrower);
        uint collId = troveManager1.getTroveCollId(_borrower);

        // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Trove minus the liquidation reserve
        singleRedemption.ZUSDLot = LiquityMath._min(_maxZUSDamount, (debt - ZUSD_GAS_COMPENSATION));

        // Get the collLot of equivalent value in USD
        singleRedemption.collLot = singleRedemption.ZUSDLot * DECIMAL_PRECISION / _price;

        // Decrease the debt and collateral of the current Trove according to the ZUSD lot and corresponding coll to send
        uint newDebt = debt - singleRedemption.ZUSDLot;
        uint newColl = coll - singleRedemption.collLot;

        if (newDebt == ZUSD_GAS_COMPENSATION) {
            // No debt left in the Trove (except for the liquidation reserve), therefore the trove gets closed
            troveManager1.removeStake(_borrower);
            troveManager1.closeTrove(_borrower, ITroveManager1.Status.closedByRedemption);
            _redeemCloseTrove(_contractsCache, _borrower, ZUSD_GAS_COMPENSATION, collId, newColl);
            emit TroveUpdated(_borrower, 0, 0, 0, TroveManagerOperation.redeemCollateral);

        } else {
            uint newNICR = LiquityMath._computeNominalCR(newColl, newDebt);

            /*
            * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
            * certainly result in running out of gas. 
            *
            * If the resultant net debt of the partial is less than the minimum, net debt we bail.
            */
            if (newNICR != _partialRedemptionHintNICR || _getNetDebt(newDebt) < MIN_NET_DEBT) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            _contractsCache.sortedTroves.reInsert(_borrower, collId, newNICR, _upperPartialRedemptionHint, _lowerPartialRedemptionHint);

            troveManager1.redemptionTroveDebt(_borrower,newDebt);
            troveManager1.redemptionTroveColl(_borrower,newColl);
            troveManager1.updateStakeAndTotalStakes(_borrower,collId);

            uint stake = troveManager1.getTroveStake(_borrower);

            emit TroveUpdated(
                _borrower,
                newDebt, newColl,
                stake,
                TroveManagerOperation.redeemCollateral
            );
        }

        return singleRedemption;
    }

    /*
    * Called when a full redemption occurs, and closes the trove.
    * The redeemer swaps (debt - liquidation reserve) ZUSD for (debt - liquidation reserve) worth of coll, so the ZUSD liquidation reserve left corresponds to the remaining debt.
    * In order to close the trove, the ZUSD liquidation reserve is burned, and the corresponding debt is removed from the active pool.
    * The debt recorded on the trove's struct is zero'd elswhere, in _closeTrove.
    * Any surplus coll left in the trove, is sent to the Coll surplus pool, and can be later claimed by the borrower.
    */
    function _redeemCloseTrove(ContractsCache memory _contractsCache, address _borrower, uint _ZUSD, uint _collId, uint _collAmount) internal {
        _contractsCache.zusdToken.burn(gasPoolAddress, _ZUSD);
        // Update Active Pool ZUSD, and send coll to account
        _contractsCache.activePool.decreaseZUSDDebt(_ZUSD);

        // send coll from Active Pool to CollSurplus Pool
        _contractsCache.collSurplusPool.accountSurplus(_borrower, _collId ,_collAmount);
        _contractsCache.collSurplusPool.receiveCollToken(_collId, _collAmount);
        _collId == 0 ? _contractsCache.activePool.sendETH(address(_contractsCache.collSurplusPool), _collAmount) : _contractsCache.activePool.sendToken(address(_contractsCache.collSurplusPool), _collId, _collAmount) ;
    }

    function _isValidFirstRedemptionHint(ISortedTroves _sortedTroves, address _firstRedemptionHint, uint collId, uint _price) internal view returns (bool) {
        if (_firstRedemptionHint == address(0) ||
            !_sortedTroves.contains(_firstRedemptionHint, collId) ||
            troveManager1.getCurrentICR(_firstRedemptionHint, _price) < MCR
        ) {
            return false;
        }

        address nextTrove = _sortedTroves.getNext(_firstRedemptionHint, collId);
        return nextTrove == address(0) || troveManager1.getCurrentICR(nextTrove, _price) < MCR;
    }

    //

    /* Send _ZUSDamount ZUSD to the system and redeem the corresponding amount of collateral from as many Troves as are needed to fill the redemption
    * request.  Applies pending rewards to a Trove before reducing its debt and coll.
    *
    * Note that if _amount is very large, this function can run out of gas, specially if traversed troves are small. This can be easily avoided by
    * splitting the total _amount in appropriate chunks and calling the function multiple times.
    *
    * Param `_maxIterations` can also be provided, so the loop through Troves is capped (if it’s zero, it will be ignored).This makes it easier to
    * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
    * of the trove list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
    * costs can vary.
    *
    * All Troves that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
    * If the last Trove does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
    * A frontend should use getRedemptionHints() to calculate what the ICR of this Trove will be after redemption, and pass a hint for its position
    * in the sortedTroves list along with the ICR value that the hint was found for.
    *
    * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
    * is very likely that the last (partially) redeemed Trove would end up with a different ICR than what the hint is for. In this case the
    * redemption will stop after the last completely redeemed Trove and the sender will keep the remaining ZUSD amount, which they can attempt
    * to redeem later.
    */
    function redeemCollateral(
        uint _collId,
        uint _ZUSDamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    )
        external
        override
    {
        ContractsCache memory contractsCache = ContractsCache(
            activePool,
            defaultPool,
            zusdToken,
            zqtyStaking,
            sortedTroves,
            collSurplusPool,
            gasPoolAddress
        );
        RedemptionTotals memory totals;

        _requireValidMaxFeePercentage(_maxFeePercentage);
        _requireAfterBootstrapPeriod();
        totals.price = priceFeed.fetchEntirePrice();
        _requireTCRoverMCR(totals.price);
        _requireAmountGreaterThanZero(_ZUSDamount);
        _requireZUSDBalanceCoversRedemption(contractsCache.zusdToken, msg.sender, _ZUSDamount);

        totals.totalZUSDSupplyAtStart = getEntireSystemDebt();
        // Confirm redeemer's balance is less than total ZUSD supply
        assert(contractsCache.zusdToken.balanceOf(msg.sender) <= totals.totalZUSDSupplyAtStart);

        totals.remainingZUSD = _ZUSDamount;
        address currentBorrower;
        totals.collId = _collId;

        if (_isValidFirstRedemptionHint(contractsCache.sortedTroves, _firstRedemptionHint, totals.collId, totals.price[totals.collId])) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedTroves.getLast(totals.collId);
            // Find the first trove with ICR >= MCR
            while (currentBorrower != address(0) && troveManager1.getCurrentICR(currentBorrower, totals.price[totals.collId]) < MCR) {
                currentBorrower = contractsCache.sortedTroves.getPrev(currentBorrower, totals.collId);
            }
        }

        // Loop through the Troves starting from the one with lowest collateral ratio until _amount of ZUSD is exchanged for collateral
        if (_maxIterations == 0) { _maxIterations = type(uint).max; }
        while (currentBorrower != address(0) && totals.remainingZUSD > 0 && _maxIterations > 0) {
            _maxIterations--;
            // Save the address of the Trove preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedTroves.getPrev(currentBorrower, totals.collId);

            troveManager1.applyPendingRewards(currentBorrower);

            SingleRedemptionValues memory singleRedemption = _redeemCollateralFromTrove(
                contractsCache,
                currentBorrower,
                totals.remainingZUSD,
                totals.price[totals.collId],
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNICR
            );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Trove

            totals.totalZUSDToRedeem  = totals.totalZUSDToRedeem + singleRedemption.ZUSDLot;
            totals.totalCollDrawn = totals.totalCollDrawn + singleRedemption.collLot;

            totals.remainingZUSD = totals.remainingZUSD - singleRedemption.ZUSDLot;
            currentBorrower = nextUserToCheck;
        }
        require(totals.totalCollDrawn > 0, "TroveManager: Unable to redeem any amount");

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total ZUSD supply value, from before it was reduced by the redemption.
        _updateBaseRateFromRedemption(totals.totalCollDrawn, totals.price[_collId], totals.totalZUSDSupplyAtStart);

        // Calculate the coll fee
        totals.collFee = _getRedemptionFee(totals.totalCollDrawn);

        _requireUserAcceptsFee(totals.collFee, totals.totalCollDrawn, _maxFeePercentage);

        // Send the coll fee to the ZQTY staking contract
        zqtyStaking.receiveCollToken(totals.collId, totals.collFee);
        totals.collId == 0 ? contractsCache.activePool.sendETH(address(contractsCache.zqtyStaking), totals.collFee) :
        contractsCache.activePool.sendToken(address(contractsCache.zqtyStaking), totals.collId, totals.collFee);

        contractsCache.zqtyStaking.increaseF_Token(totals.collId, totals.collFee);

        totals.collToSendToRedeemer = totals.totalCollDrawn - totals.collFee;

        emit Redemption(_ZUSDamount, totals.totalZUSDToRedeem, totals.totalCollDrawn, totals.collFee);

        // Burn the total ZUSD that is cancelled with debt, and send the redeemed coll to msg.sender
        contractsCache.zusdToken.burn(msg.sender, totals.totalZUSDToRedeem);
        // Update Active Pool ZUSD, and send coll to account
        contractsCache.activePool.decreaseZUSDDebt(totals.totalZUSDToRedeem);

        totals.collId == 0 ? contractsCache.activePool.sendETH(msg.sender, totals.collToSendToRedeemer) :
        contractsCache.activePool.sendToken(msg.sender, totals.collId, totals.collToSendToRedeemer);
    }

    // --- Helper functions ---

    function getTokenAddresses() external view override returns(address[] memory) {
        return collateralTokens;
    }

    // --- Redemption fee functions ---

    /*
    * This function has two impacts on the baseRate state variable:
    * 1) decays the baseRate based on time passed since last redemption or ZUSD borrowing operation.
    * then,
    * 2) increases the baseRate based on the amount redeemed, as a proportion of total supply
    */
    function _updateBaseRateFromRedemption(uint _collDrawn,  uint _price, uint _totalZUSDSupply) internal returns (uint) {
        uint decayedBaseRate = _calcDecayedBaseRate();

        /* Convert the drawn coll back to ZUSD at face value rate (1 ZUSD:1 USD), in order to get
        * the fraction of total supply that was redeemed at face value. */
        uint redeemedZUSDFraction = _collDrawn * _price / _totalZUSDSupply;

        uint newBaseRate = decayedBaseRate + (redeemedZUSDFraction / BETA);
        newBaseRate = LiquityMath._min(newBaseRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%
        //assert(newBaseRate <= DECIMAL_PRECISION); // This is already enforced in the line above
        assert(newBaseRate > 0); // Base rate is always non-zero after redemption

        // Update the baseRate state variable
        baseRate = newBaseRate;
        emit BaseRateUpdated(newBaseRate);
        
        _updateLastFeeOpTime();

        return newBaseRate;
    }

    function getRedemptionRate() public view override returns (uint) {
        return _calcRedemptionRate(baseRate);
    }

    function getRedemptionRateWithDecay() public view override returns (uint) {
        return _calcRedemptionRate(_calcDecayedBaseRate());
    }

    function _calcRedemptionRate(uint _baseRate) internal pure returns (uint) {
        return LiquityMath._min(
            REDEMPTION_FEE_FLOOR + _baseRate,
            DECIMAL_PRECISION // cap at a maximum of 100%
        );
    }

    function _getRedemptionFee(uint _collDrawn) internal view returns (uint) {
        return _calcRedemptionFee(getRedemptionRate(), _collDrawn);
    }

    function getRedemptionFeeWithDecay(uint _collDrawn) external view override returns (uint) {
        return _calcRedemptionFee(getRedemptionRateWithDecay(), _collDrawn);
    }

    function _calcRedemptionFee(uint _redemptionRate, uint _collDrawn) internal pure returns (uint) {
        uint redemptionFee = _redemptionRate * _collDrawn / DECIMAL_PRECISION;
        require(redemptionFee < _collDrawn, "TroveManager: Fee would eat up all returned collateral");
        return redemptionFee;
    }

    // --- Borrowing fee functions ---

    function getBorrowingRate() public view override returns (uint) {
        return _calcBorrowingRate(baseRate);
    }

    function getBorrowingRateWithDecay() public view override returns (uint) {
        return _calcBorrowingRate(_calcDecayedBaseRate());
    }

    function _calcBorrowingRate(uint _baseRate) internal pure returns (uint) {
        return LiquityMath._min(
            BORROWING_FEE_FLOOR + _baseRate,
            MAX_BORROWING_FEE
        );
    }

    function getBorrowingFee(uint _ZUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRate(), _ZUSDDebt);
    }

    function getBorrowingFeeWithDecay(uint _ZUSDDebt) external view override returns (uint) {
        return _calcBorrowingFee(getBorrowingRateWithDecay(), _ZUSDDebt);
    }

    function _calcBorrowingFee(uint _borrowingRate, uint _ZUSDDebt) internal pure returns (uint) {
        return _borrowingRate * _ZUSDDebt / DECIMAL_PRECISION;
    }


    // Updates the baseRate state variable based on time elapsed since the last redemption or ZUSD borrowing operation.
    function decayBaseRateFromBorrowing() external override {
        _requireCallerIsBorrowerOperations();

        uint decayedBaseRate = _calcDecayedBaseRate();
        assert(decayedBaseRate <= DECIMAL_PRECISION);  // The baseRate can decay to 0

        baseRate = decayedBaseRate;
        emit BaseRateUpdated(decayedBaseRate);

        _updateLastFeeOpTime();
    }

    // --- Internal fee functions ---

    // Update the last fee operation time only if time passed >= decay interval. This prevents base rate griefing.
    function _updateLastFeeOpTime() internal {
        uint timePassed = block.timestamp - lastFeeOperationTime;

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastFeeOperationTime = block.timestamp;
            emit LastFeeOpTimeUpdated(block.timestamp);
        }
    }

    function _calcDecayedBaseRate() internal view returns (uint) {
        uint minutesPassed = _minutesPassedSinceLastFeeOp();
        uint decayFactor = LiquityMath._decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        return baseRate * decayFactor / DECIMAL_PRECISION;
    }

    function _minutesPassedSinceLastFeeOp() internal view returns (uint) {
        return (block.timestamp - lastFeeOperationTime) / SECONDS_IN_ONE_MINUTE;
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperationsAddress, "TroveManager: Caller is not the BorrowerOperations contract");
    }

    function _requireZUSDBalanceCoversRedemption(IZUSDToken _zusdToken, address _redeemer, uint _amount) internal view {
        require(_zusdToken.balanceOf(_redeemer) >= _amount, "TroveManager: Requested redemption amount must be <= user's ZUSD token balance");
    }

    function _requireMoreThanOneTroveInSystem(uint _collId, uint TroveOwnersArrayLength) internal view {
        require (TroveOwnersArrayLength > 1 && sortedTroves.getSize(_collId) > 1, "TroveManager: Only one trove in the system");
    }

    function _requireAmountGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "TroveManager: Amount must be greater than zero");
    }

    function _requireTCRoverMCR(uint[] memory _price) internal view {
        require(_getTCR(_price) >= MCR, "TroveManager: Cannot redeem when TCR < MCR");
    }

    function _requireAfterBootstrapPeriod() internal view {
        uint systemDeploymentTime = zqtyToken.getDeploymentStartTime();
        require(block.timestamp >= systemDeploymentTime + BOOTSTRAP_PERIOD, "TroveManager: Redemptions are not allowed during bootstrap phase");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage) internal pure {
        require(_maxFeePercentage >= REDEMPTION_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
            "Max fee percentage must be between 0.5% and 100%");
    }
}
