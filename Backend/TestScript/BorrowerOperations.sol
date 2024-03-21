// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IBorrowerOperations.sol";
import "./IActivePool.sol";
import "./IZUSDToken.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IZQTYStaking.sol";
import "./LiquityBase.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

contract BorrowerOperations is LiquityBase, Ownable, CheckContract, IBorrowerOperations {
    string constant public NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ITroveManager1 public troveManager1;
    ITroveManager2 public troveManager2;
    ITroveManager3 public troveManager3;

    address stabilityPoolAddress;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    IZQTYStaking public zqtyStaking;
    address public zqtyStakingAddress;

    IZUSDToken public zusdToken;

    // A doubly linked list of Troves, sorted by their collateral ratios
    ISortedTroves public sortedTroves;

    // Array of token addresses
    IERC20[] public collateralTokens;

    // --- Dependency setters ---

    function setAddresses(
        address _troveManager1Address,
        address _troveManager2Address,
        address _troveManager3Address,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _zusdTokenAddress,
        address _zqtyStakingAddress
    )
        external
        override
        onlyOwner
    {
        // This makes impossible to open a trove with zero withdrawn ZUSD
        assert(MIN_NET_DEBT > 0);

        checkContract(_troveManager1Address);
        checkContract(_troveManager2Address);
        checkContract(_troveManager3Address);
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_gasPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_priceFeedAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_zusdTokenAddress);
        checkContract(_zqtyStakingAddress);

        troveManager1 = ITroveManager1(_troveManager1Address);
        troveManager2 = ITroveManager2(_troveManager2Address);
        troveManager3 = ITroveManager3(_troveManager3Address);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        zusdToken = IZUSDToken(_zusdTokenAddress);
        zqtyStakingAddress = _zqtyStakingAddress;
        zqtyStaking = IZQTYStaking(_zqtyStakingAddress);

        collateralTokens.push(IERC20((address(0))));

        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit TroveManager3AddressChanged(_troveManager3Address);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit ZUSDTokenAddressChanged(_zusdTokenAddress);
        emit ZQTYStakingAddressChanged(_zqtyStakingAddress);

        _renounceOwnership();
    }

    function addCollTokenAddress(address[] memory _tokens) external override{
        uint256 length = _tokens.length;
        require(length > 0, "NO_TOKENS_TO_ADD");
        IActivePool activePoolCached = activePool;
        IDefaultPool defaultPoolCached = defaultPool;
        ISortedTroves sortedTrovesCached = sortedTroves;
        ITroveManager1 troveManager1Cached = troveManager1;
        ITroveManager2 troveManager2Cached = troveManager2;
        ITroveManager3 troveManager3Cached = troveManager3;
        IStabilityPool stabilityPoolCached = IStabilityPool(stabilityPoolAddress);
        ICollSurplusPool collSurplusPoolCached = collSurplusPool;
        IZQTYStaking zqtyStakingCached = zqtyStaking;

        for (uint256 i = 0; i < length; i++) {
            collateralTokens.push(IERC20(_tokens[i]));
            activePoolCached.setCollTokenAddress(_tokens[i]);
            defaultPoolCached.setCollTokenAddress(_tokens[i]);
            zqtyStakingCached.setCollTokenAddress(_tokens[i]);
            sortedTrovesCached.setCollTokenAddress(_tokens[i]);
            troveManager1Cached.setCollTokenAddress(_tokens[i]);
            troveManager2Cached.setCollTokenAddress(_tokens[i]);
            troveManager3Cached.setCollTokenAddress(_tokens[i]);
            stabilityPoolCached.setCollTokenAddress(_tokens[i]);
            collSurplusPoolCached.setCollTokenAddress(_tokens[i]);
        }
    }

    // --- Borrower Trove Operations ---

    function openTrovewithEth(uint _maxFeePercentage, uint _ZUSDAmount, address _upperHint, address _lowerHint) external payable override {
        ContractsCache memory contractsCache = ContractsCache(troveManager1,troveManager2,troveManager3,activePool, zusdToken);
        LocalVariables_openTrove memory vars;

        vars.price = priceFeed.fetchEntirePrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireTroveisNotActive(contractsCache.troveManager1, msg.sender);

        vars.ZUSDFee;
        vars.netDebt = _ZUSDAmount;

        if (!isRecoveryMode) {
            vars.ZUSDFee = _triggerBorrowingFee(contractsCache.troveManager2, contractsCache.zusdToken, _ZUSDAmount, _maxFeePercentage);
            vars.netDebt = vars.netDebt + vars.ZUSDFee;
        }
        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested ZUSD amount + ZUSD borrowing fee + ZUSD gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);
        
        vars.ICR = LiquityMath._computeCR(msg.value, vars.compositeDebt, vars.price[0]);
        vars.NICR = LiquityMath._computeNominalCR(msg.value, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint newTCR = _getNewTCRFromTroveChange(0, msg.value, true, vars.compositeDebt, true, vars.price);  // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR); 
        }

        // Set the trove struct's properties
        contractsCache.troveManager1.setTroveStatus(msg.sender,0, 1);
        contractsCache.troveManager1.increaseTroveColl(msg.sender, msg.value);
        contractsCache.troveManager1.increaseTroveDebt(msg.sender, vars.compositeDebt);

        contractsCache.troveManager1.updateTroveRewardSnapshots(msg.sender);
        vars.stake = contractsCache.troveManager1.updateStakeAndTotalStakes(msg.sender, 0);

        sortedTroves.insert(msg.sender, 0, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager1.addTroveOwnerToArray(msg.sender);
        emit TroveCreated(msg.sender, vars.arrayIndex);

        // Move the ether to the Active Pool, and mint the ZUSDAmount to the borrower
        _activePoolAddEthColl(contractsCache.activePool, msg.value);
        _withdrawZUSD(contractsCache.activePool, contractsCache.zusdToken, msg.sender, _ZUSDAmount, vars.netDebt);
        // Move the ZUSD gas compensation to the Gas Pool
        _withdrawZUSD(contractsCache.activePool, contractsCache.zusdToken, gasPoolAddress, ZUSD_GAS_COMPENSATION, ZUSD_GAS_COMPENSATION);

        emit TroveUpdated(msg.sender, vars.compositeDebt, msg.value, vars.stake, BorrowerOperation.openTrove);
        emit ZUSDBorrowingFeePaid(msg.sender, vars.ZUSDFee);
    }

    function openTrovewithTokens(uint _maxFeePercentage,uint _collateralTokenId,uint _collateralAmount, uint _ZUSDAmount, address _upperHint, address _lowerHint) external override {
        _requireNonZeroAmount(_collateralAmount);
        _requireValidCollateralToken(_collateralTokenId);

        ContractsCache memory contractsCache = ContractsCache(troveManager1, troveManager2,troveManager3, activePool, zusdToken);
        LocalVariables_openTrove memory vars;

        vars.price = priceFeed.fetchEntirePrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireTroveisNotActive(contractsCache.troveManager1, msg.sender);

        vars.ZUSDFee;
        vars.netDebt = _ZUSDAmount;

        if (!isRecoveryMode) {
            vars.ZUSDFee = _triggerBorrowingFee(contractsCache.troveManager2, contractsCache.zusdToken, _ZUSDAmount, _maxFeePercentage);
            vars.netDebt = vars.netDebt + vars.ZUSDFee;
        }
        _requireAtLeastMinNetDebt(vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested ZUSD amount + ZUSD borrowing fee + ZUSD gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);
        assert(vars.compositeDebt > 0);
        
        vars.ICR = LiquityMath._computeCR(_collateralAmount, vars.compositeDebt, vars.price[_collateralTokenId]);
        vars.NICR = LiquityMath._computeNominalCR(_collateralAmount, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            uint newTCR = _getNewTCRFromTroveChange(_collateralTokenId, _collateralAmount, true, vars.compositeDebt, true, vars.price);  // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR); 
        }

        // Set the trove struct's properties
        contractsCache.troveManager1.setTroveStatus(msg.sender,_collateralTokenId, 1);
        contractsCache.troveManager1.increaseTroveColl(msg.sender, _collateralAmount);
        contractsCache.troveManager1.increaseTroveDebt(msg.sender, vars.compositeDebt);

        contractsCache.troveManager1.updateTroveRewardSnapshots(msg.sender);
        vars.stake = contractsCache.troveManager1.updateStakeAndTotalStakes(msg.sender, _collateralTokenId);

        sortedTroves.insert(msg.sender, _collateralTokenId, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager1.addTroveOwnerToArray(msg.sender);
        emit TroveCreated(msg.sender, vars.arrayIndex);

        // Move the ether to the Active Pool, and mint the ZUSDAmount to the borrower
        _activePoolAddTokenColl(msg.sender, _collateralTokenId, _collateralAmount);
        _withdrawZUSD(contractsCache.activePool, contractsCache.zusdToken, msg.sender, _ZUSDAmount, vars.netDebt);
        // Move the ZUSD gas compensation to the Gas Pool
        _withdrawZUSD(contractsCache.activePool, contractsCache.zusdToken, gasPoolAddress, ZUSD_GAS_COMPENSATION, ZUSD_GAS_COMPENSATION);

        emit TroveUpdated(msg.sender, vars.compositeDebt, _collateralAmount, vars.stake, BorrowerOperation.openTrove);
        emit ZUSDBorrowingFeePaid(msg.sender, vars.ZUSDFee);
    }

    // Send ETH as collateral to a trove
    function addColl(uint _collateralAmount, address _upperHint, address _lowerHint) external payable override {
        _adjustTrove(msg.sender, _collateralAmount, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Send Token as collateral to a trove. Called by only the Stability Pool.
    function moveTokenGainToTrove(uint _collateralAmount, address _borrower, address _upperHint, address _lowerHint) external payable override {
        _requireCallerIsStabilityPool();
        _adjustTrove(_borrower, _collateralAmount, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ETH collateral from a trove
    function withdrawColl(uint _collWithdrawal, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, 0,_collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ZUSD tokens from a trove: mint new ZUSD tokens to the owner, and increase the trove's debt accordingly
    function withdrawZUSD(uint _maxFeePercentage, uint _ZUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, 0, 0, _ZUSDAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay ZUSD tokens to a Trove: Burn the repaid ZUSD tokens, and reduce the trove's debt accordingly
    function repayZUSD(uint _ZUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(msg.sender, 0, 0, _ZUSDAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustTrove(uint _maxFeePercentage, uint _collWithdrawal, uint _ZUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint) external payable override {
        _adjustTrove(msg.sender, 0, _collWithdrawal, _ZUSDChange, _isDebtIncrease, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // function Approvetokens(uint _collateralTokenId, uint _collateralAmount) external returns(bool){
    //     IERC20 collateralAddress = collateralTokens[_collateralTokenId];
    //     bool success = collateralAddress.approve(address(this), _collateralAmount);
    //     require(success, "BorrowerOps: Sending ETH to ActivePool failed");
    //     return success;
    // }

    /*
    * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal. 
    *
    * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
    *
    * If both are positive, it will revert.
    */
    function _adjustTrove(address _borrower,uint _collAmount, uint _collWithdrawal, uint _ZUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint, uint _maxFeePercentage) internal {
        ContractsCache memory contractsCache = ContractsCache(troveManager1, troveManager2, troveManager3, activePool, zusdToken);
        LocalVariables_adjustTrove memory vars;

        vars.collId = contractsCache.troveManager1.getTroveCollId(msg.sender);

        if(vars.collId != 0) { 
            require(msg.value == 0,"BorrowerOperations: Invalid collateral");
        }

        vars.price = new uint[] (collateralTokens.length);
        vars.price = priceFeed.fetchEntirePrice();
        bool isRecoveryMode = _checkRecoveryMode(vars.price);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_ZUSDChange);
        }
        _requireSingularCollChange(_collWithdrawal);
        _requireNonZeroAdjustment(_collAmount, _collWithdrawal, _ZUSDChange);
        _requireTroveisActive(contractsCache.troveManager1, _borrower);

        // Confirm the operation is either a borrower adjusting their own trove, or a pure ETH transfer from the Stability Pool to a trove
        assert(msg.sender == _borrower || (msg.sender == stabilityPoolAddress && msg.value > 0 && _ZUSDChange == 0));

        contractsCache.troveManager1.applyPendingRewards(_borrower);

        // Get the collChange based on whether or not ETH was sent in the transaction
        vars.collId == 0 ? (vars.collChange, vars.isCollIncrease) = _getCollChange(msg.value, _collWithdrawal) : (vars.collChange, vars.isCollIncrease) = _getCollChange(_collAmount, _collWithdrawal);

        vars.zusdChange = _ZUSDChange;
        vars.netDebtChange = _ZUSDChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) { 
            vars.ZUSDFee = _triggerBorrowingFee(contractsCache.troveManager2, contractsCache.zusdToken, _ZUSDChange, _maxFeePercentage);
            vars.netDebtChange = vars.netDebtChange + vars.ZUSDFee; // The raw debt change includes the fee
        }

        vars.debt = contractsCache.troveManager1.getTroveDebt(_borrower);
        vars.coll = contractsCache.troveManager1.getTroveColl(_borrower);
        
        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.coll, vars.debt, vars.price[vars.collId]);
        vars.newICR = _getNewICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.price[vars.collId]);
        assert(_collWithdrawal <= vars.coll); 

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars);
    
        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough ZUSD
        if (!_isDebtIncrease && _ZUSDChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt) - vars.netDebtChange);
            _requireValidZUSDRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientZUSDBalance(contractsCache.zusdToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateTroveFromAdjustment(contractsCache.troveManager1, _borrower, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        vars.stake = contractsCache.troveManager1.updateStakeAndTotalStakes(_borrower, vars.collId);

        // Re-insert trove in to the sorted list
        uint newNICR = _getNewNominalICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        sortedTroves.reInsert(_borrower, vars.collId, newNICR, _upperHint, _lowerHint);

        emit TroveUpdated(_borrower, vars.newDebt, vars.newColl, vars.stake, BorrowerOperation.adjustTrove);
        emit ZUSDBorrowingFeePaid(msg.sender,  vars.ZUSDFee);

        // Use the unmodified _ZUSDChange here, as we don't send the fee to the user
        _moveTokensAndETHfromAdjustment(
            contractsCache.activePool,
            contractsCache.zusdToken,
            msg.sender,
            vars.collId,
            vars.collChange,
            vars.isCollIncrease,
            vars.zusdChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeTrove() external override {
        ITroveManager1 troveManagerCached = troveManager1;
        IActivePool activePoolCached = activePool;
        IZUSDToken zusdTokenCached = zusdToken;

        _requireTroveisActive(troveManagerCached, msg.sender);

        uint _collateralTokenId = troveManagerCached.getTroveCollId(msg.sender);

        uint[] memory price = priceFeed.fetchEntirePrice();

        _requireNotInRecoveryMode(price);

        troveManagerCached.applyPendingRewards(msg.sender);

        uint coll = troveManagerCached.getTroveColl(msg.sender);
        uint debt = troveManagerCached.getTroveDebt(msg.sender);

        _requireSufficientZUSDBalance(zusdTokenCached, msg.sender, debt - ZUSD_GAS_COMPENSATION);

        uint newTCR = _getNewTCRFromTroveChange(_collateralTokenId, coll, false, debt, false, price);
        _requireNewTCRisAboveCCR(newTCR);

        troveManagerCached.removeStake(msg.sender);
        troveManagerCached.closeTrove(msg.sender, ITroveManager1.Status.closedByOwner);

        emit TroveUpdated(msg.sender, 0, 0, 0, BorrowerOperation.closeTrove);

        // Burn the repaid ZUSD from the user's balance and the gas compensation from the Gas Pool
        _repayZUSD(activePoolCached, zusdTokenCached, msg.sender, debt - ZUSD_GAS_COMPENSATION);
        _repayZUSD(activePoolCached, zusdTokenCached, gasPoolAddress, ZUSD_GAS_COMPENSATION);

        // Send the collateral back to the user
        _collateralTokenId == 0 ? activePoolCached.sendETH(msg.sender, coll) : activePoolCached.sendToken(msg.sender, _collateralTokenId, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral() external override {
        // send ETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(ITroveManager2 _troveManager2, IZUSDToken _zusdToken, uint _ZUSDAmount, uint _maxFeePercentage) internal returns (uint) {
        _troveManager2.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint ZUSDFee = _troveManager2.getBorrowingFee(_ZUSDAmount);

        _requireUserAcceptsFee(ZUSDFee, _ZUSDAmount, _maxFeePercentage);
        
        // Send fee to ZQTY staking contract
        zqtyStaking.increaseF_ZUSD(ZUSDFee);
        _zusdToken.mint(zqtyStakingAddress, ZUSDFee);

        return ZUSDFee;
    }

    function _getUSDValue(uint _coll, uint _price) internal pure returns (uint) {
        uint usdValue = _price * _coll / DECIMAL_PRECISION;

        return usdValue;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment
    (
        ITroveManager1 _troveManager1,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        returns (uint, uint)
    {
        uint newColl = (_isCollIncrease) ? _troveManager1.increaseTroveColl(_borrower, _collChange)
                                        : _troveManager1.decreaseTroveColl(_borrower, _collChange);
        uint newDebt = (_isDebtIncrease) ? _troveManager1.increaseTroveDebt(_borrower, _debtChange)
                                        : _troveManager1.decreaseTroveDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndETHfromAdjustment
    (
        IActivePool _activePool,
        IZUSDToken _zusdToken,
        address _borrower,
        uint _collTokenId,
        uint _collChange,
        bool _isCollIncrease,
        uint _ZUSDChange,
        bool _isDebtIncrease,
        uint _netDebtChange
    )
        internal
    {
        if (_isDebtIncrease) {
            _withdrawZUSD(_activePool, _zusdToken, _borrower, _ZUSDChange, _netDebtChange);
        } else {
            _repayZUSD(_activePool, _zusdToken, _borrower, _ZUSDChange);
        }

        if (_isCollIncrease) {
            _collTokenId == 0 ? _activePoolAddEthColl(_activePool, _collChange) : _activePoolAddTokenColl(_borrower, _collTokenId, _collChange);
        } else {
            _collTokenId == 0 ? _activePool.sendETH(_borrower, _collChange) : _activePool.sendToken(_borrower, _collTokenId, _collChange);
        }
    }

    // Send ETH to Active Pool and increase its recorded ETH balance
    function _activePoolAddEthColl(IActivePool _activePool, uint _amount) internal {
        (bool success, ) = address(_activePool).call{value: _amount}("");
        require(success, "BorrowerOps: Sending ETH to ActivePool failed");
    }

    // Send ERC20 Tokens to Active Pool and increase its recorded Token balance
    function _activePoolAddTokenColl(address _address,uint _collateralTokenId, uint _collateralAmount) internal {
        IActivePool activePoolCached = activePool;
        activePoolCached.receiveCollToken(_collateralTokenId, _collateralAmount);
        bool success = collateralTokens[_collateralTokenId].transferFrom(_address, address(activePoolCached), _collateralAmount);
        require(success, "BorrowerOps: Sending ETH to ActivePool failed");
    }

    // Issue the specified amount of ZUSD to _account and increases the total active debt (_netDebtIncrease potentially includes a ZUSDFee)
    function _withdrawZUSD(IActivePool _activePool, IZUSDToken _zusdToken, address _account, uint _ZUSDAmount, uint _netDebtIncrease) internal {
        _activePool.increaseZUSDDebt(_netDebtIncrease);
        _zusdToken.mint(_account, _ZUSDAmount);
    }

    // Burn the specified amount of ZUSD from _account and decreases the total active debt
    function _repayZUSD(IActivePool _activePool, IZUSDToken _zusdToken, address _account, uint _ZUSD) internal {
        _activePool.decreaseZUSDDebt(_ZUSD);
        _zusdToken.burn(_account, _ZUSD);
    }

    // --- 'Require' wrapper functions ---

    function _requireValidCollateralToken(uint _collateralTokenId) internal view {
        require(_collateralTokenId > 0 && _collateralTokenId < collateralTokens.length, "BorrowerOperations: Invalid collateral token id");
    }

    function _requireSingularCollChange(uint _collWithdrawal) internal view {
        require(msg.value == 0 || _collWithdrawal == 0, "BorrowerOperations: Cannot withdraw and add coll");
    }

    function _requireCallerIsBorrower(address _borrower) internal view {
        require(msg.sender == _borrower, "BorrowerOps: Caller must be the borrower for a withdrawal");
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, 'StabilityPool: Amount must be non-zero');
    }

    function _requireNonZeroAdjustment(uint _collAmount, uint _collWithdrawal, uint _ZUSDChange) internal view {
        require(msg.value != 0 || _collAmount != 0 || _collWithdrawal != 0 || _ZUSDChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");
    }

    function _requireTroveisActive(ITroveManager1 _troveManager1, address _borrower) internal view {
        uint status = _troveManager1.getTroveStatus(_borrower);
        require(status == 1, "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(ITroveManager1 _troveManager1, address _borrower) internal view {
        uint status = _troveManager1.getTroveStatus(_borrower);
        require(status != 1, "BorrowerOps: Trove is active");
    }

    function _requireNonZeroDebtChange(uint _ZUSDChange) internal pure {
        require(_ZUSDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }
   
    function _requireNotInRecoveryMode(uint[] memory _price) internal view {
        require(!_checkRecoveryMode(_price), "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireNoCollWithdrawal(uint _collWithdrawal) internal pure {
        require(_collWithdrawal == 0, "BorrowerOps: Collateral withdrawal not permitted Recovery Mode");
    }

    function _requireValidAdjustmentInCurrentMode 
    (
        bool _isRecoveryMode,
        uint _collWithdrawal,
        bool _isDebtIncrease, 
        LocalVariables_adjustTrove memory _vars
    ) 
        internal 
        view 
    {
        /* 
        *In Recovery Mode, only allow:
        *
        * - Pure collateral top-up
        * - Pure debt repayment
        * - Collateral top-up with debt repayment
        * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
        *
        * In Normal Mode, ensure:
        *
        * - The new ICR is above MCR
        * - The adjustment won't pull the TCR below CCR
        */
        if (_isRecoveryMode) {
            _requireNoCollWithdrawal(_collWithdrawal);
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_vars.newICR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }
        } else { // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR);
            _vars.newTCR = _getNewTCRFromTroveChange(_vars.collId, _vars.collChange, _vars.isCollIncrease, _vars.netDebtChange, _isDebtIncrease, _vars.price);
            _requireNewTCRisAboveCCR(_vars.newTCR);  
        }
    }

    function _requireICRisAboveMCR(uint _newICR) internal pure {
        require(_newICR >= MCR, "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireICRisAboveCCR(uint _newICR) internal pure {
        require(_newICR >= CCR, "BorrowerOps: Operation must leave trove with ICR >= CCR");
    }

    function _requireNewICRisAboveOldICR(uint _newICR, uint _oldICR) internal pure {
        require(_newICR >= _oldICR, "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode");
    }

    function _requireNewTCRisAboveCCR(uint _newTCR) internal pure {
        require(_newTCR >= CCR, "BorrowerOps: An operation that would result in TCR < CCR is not permitted");
    }

    function _requireAtLeastMinNetDebt(uint _netDebt) internal pure {
        require (_netDebt >= MIN_NET_DEBT, "BorrowerOps: Trove's net debt must be greater than minimum");
    }

    function _requireValidZUSDRepayment(uint _currentDebt, uint _debtRepayment) internal pure {
        require(_debtRepayment <= _currentDebt - ZUSD_GAS_COMPENSATION, "BorrowerOps: Amount repaid must not be larger than the Trove's debt");
    }

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "BorrowerOps: Caller is not Stability Pool");
    }

     function _requireSufficientZUSDBalance(IZUSDToken _zusdToken, address _borrower, uint _debtRepayment) internal view {
        require(_zusdToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough ZUSD to make repayment");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage, bool _isRecoveryMode) internal pure {
        if (_isRecoveryMode) {
            require(_maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%");
        } else {
            require(_maxFeePercentage >= BORROWING_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%");
        }
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromTroveChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newICR = LiquityMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewTroveAmounts(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        pure
        returns (uint, uint)
    {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll + _collChange :  _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }

    function _getNewTCRFromTroveChange
    (
        uint _collId,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint[] memory _price
    )
        public
        view
        returns (uint)
    {
        uint price;
        uint totalDebt = getEntireSystemDebt();

        _isCollIncrease ? price = getEntireCollPrice(_collId, _collChange, _isCollIncrease, _price) : price = getEntireCollPrice(_collId, _collChange, _isCollIncrease,_price);
        _isDebtIncrease ? totalDebt = totalDebt + _debtChange : totalDebt = totalDebt - _debtChange;

        uint newTCR = LiquityMath._computeEntireCR(price, totalDebt);
        return newTCR;
    }

    function getCompositeDebt(uint _debt) external pure override returns (uint) {
        return _getCompositeDebt(_debt);
    }
}
