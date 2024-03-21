// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IStabilityPool.sol";
import "./ICollSurplusPool.sol";
import "./IZUSDToken.sol";
import "./ISortedTroves.sol";
import "./IZQTYToken.sol";
import "./IZQTYStaking.sol";
import "./LiquityBase.sol";

// Common interface for the Trove Manager.
interface ITroveManager1 is ILiquityBase {

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

    // Store the necessary data for a trove
    struct Trove {
        uint debt;
        uint collId;
        uint coll;
        uint stake;
        Status status;
        uint128 arrayIndex;
        uint pendingColl;
        uint pendingDebt;
    }
   
    struct LocalVariables_OuterLiquidationFunction {
        uint[] price;
        uint liquidatedDebt;
        uint liquidatedColl;
        uint i;
        uint collId;
        uint ZUSDInStabPool;
        bool recoveryModeAtStart;
    }

    struct LocalVariables_BatchLiquidationFunction {
        address[] batchAddress;
        uint batchLength;
        uint index;
    }


    struct LocalVariables_InnerSingleLiquidateFunction {
        uint collToLiquidate;
        uint pendingDebtReward;
        uint pendingCollReward;
    }

    struct LocalVariables_LiquidationSequence {
        uint remainingZUSDInStabPool;
        uint i;
        uint collId;
        uint price;
        uint ICR;
        address user;
        bool backToNormalMode;
        uint entireSystemDebt;
        uint entireSystemColl;
    }

    struct LiquidationValues {
        uint entireTroveDebt;
        uint entireTroveColl;
        uint collGasCompensation;
        uint ZUSDGasCompensation;
        uint debtToOffset;
        uint collToSendToSP;
        uint debtToRedistribute;
        uint collToRedistribute;
        uint collSurplus;
    }

    struct LiquidationTotals {
        uint totalCollId;
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalCollGasCompensation;
        uint totalZUSDGasCompensation;
        uint totalDebtToOffset;
        uint totalCollToSendToSP;
        uint totalDebtToRedistribute;
        uint totalCollToRedistribute;
        uint totalCollSurplus;
    }

    struct ContractsCache {
        IActivePool activePool;
        IDefaultPool defaultPool;
        ISortedTroves sortedTroves;
    }

    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManager2AddressChanged(address _newTroveManagerAddress);
    event TroveManager3AddressChanged(address _newTroveManagerAddress);
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
    event Redemption(uint _attemptedZUSDAmount, uint _actualZUSDAmount, uint _ETHSent, uint _ETHFee);
    
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint[] _totalStakesSnapshot, uint[] _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_ZUSDDebt);
    event TroveSnapshotsUpdated(uint[] _L_ETH, uint[] _L_ZUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint _stake, TroveManagerOperation _operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, TroveManagerOperation _operation);

    // --- Functions ---
    function setCollTokenAddress(address _collToken) external ;

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
    ) external;

    function stabilityPool() external view returns (IStabilityPool);
    function zusdToken() external view returns (IZUSDToken);
    function zqtyToken() external view returns (IZQTYToken);
    function zqtyStaking() external view returns (IZQTYStaking);

    function getTokenAddresses() external view returns(address[] memory);

    function getCollateralTokensLength() external view returns(uint);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function updateStakeAndTotalStakes(address _borrower, uint _collId) external returns (uint);

    function updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool,uint _collId, uint _collRemainder) external;

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingTokenReward(address _borrower) external view returns (uint);

    function getPendingZUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (uint debt, uint coll, uint pendingZUSDDebtReward, uint pendingTokenReward);

    function closeTrove(address _borrower, Status closedStatus) external;

    function removeStake(address _borrower) external;

    function removeTroveOwner(address _borrower, uint TroveOwnersArrayLength) external;

    function getTCR(uint[] memory _price) external view returns (uint) ;

    function getTotalStakes(uint collId) external view returns (uint);

    function getL_Coll(uint _collId) external view returns (uint);

    function getL_ZUSDDebt(uint _collId) external view returns (uint);

    function getTroveStatus(address _borrower) external view returns (uint);
    
    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveCollId(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function getRewardColl(address _borrower) external view returns (uint);

    function getRewardDebt(address _borrower) external view returns (uint);

    function liquidationColl(uint _collId, uint _newLColl) external;

    function liquidationDebt(uint _collId, uint _newLDebt) external;

    function redemptionTroveDebt(address _borrower, uint _newDebt) external returns (uint);

    function redemptionTroveColl(address _borrower, uint _newDebt) external returns (uint);

    function setTroveStatus(address _borrower, uint _collateralTokenId, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint); 

}
