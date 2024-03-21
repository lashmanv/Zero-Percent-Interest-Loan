// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ITroveManager1.sol";
import "./ITroveManager3.sol";
import "./IStabilityPool.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./LiquityBase.sol";
import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./IZUSDToken.sol";
import "./IZQTYToken.sol";
import "./IZQTYStaking.sol";

// Common interface for the Trove Manager.
interface ITroveManager2 is ILiquityBase {

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    /*
    * --- Variable container structs for liquidations ---
    *
    * These structs are used to hold, return and assign variables inside the liquidation functions,
    * in order to avoid the error: "CompilerError: Stack too deep".
    **/

    struct ContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        IZUSDToken zusdToken;
        IZQTYStaking zqtyStaking;
        ISortedTroves sortedTroves;
        ICollSurplusPool collSurplusPool;
        address gasPoolAddress;
    }
    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint[] price;
        uint collId;
        uint remainingZUSD;
        uint totalZUSDToRedeem;
        uint totalCollDrawn;
        uint collFee;
        uint collToSendToRedeemer;
        uint decayedBaseRate;
        uint totalZUSDSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint ZUSDLot;
        uint collLot;
        bool cancelledPartial;
    }

    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManager1AddressChanged(address _newTroveManagerAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event ZUSDTokenAddressChanged(address _newZUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event ZQTYTokenAddressChanged(address _zqtyTokenAddress);
    event ZQTYStakingAddressChanged(address _zqtyStakingAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _ZUSDGasCompensation);
    event Redemption(uint _attemptedZUSDAmount, uint _actualZUSDAmount, uint _collSent, uint _collFee);
    
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_Coll, uint _L_ZUSDDebt);
    event TroveSnapshotsUpdated(uint[] _L_Coll, uint _L_ZUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint _stake, TroveManagerOperation _operation);

    // --- Functions ---

    function setCollTokenAddress(address _collToken) external ;

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
    ) external;

    function stabilityPool() external view returns (IStabilityPool);
    function zusdToken() external view returns (IZUSDToken);
    function zqtyToken() external view returns (IZQTYToken);
    function zqtyStaking() external view returns (IZQTYStaking);

    function redeemCollateral(
        uint _collId,
        uint _ZUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function getTokenAddresses() external view returns(address[] memory);

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _collDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint ZUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _ZUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

}
