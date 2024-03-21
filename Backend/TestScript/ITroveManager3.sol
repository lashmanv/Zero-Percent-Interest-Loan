// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ITroveManager1.sol";
import "./ITroveManager2.sol";
import "./IStabilityPool.sol";
import "./ICollSurplusPool.sol";
import "./IZUSDToken.sol";
import "./ISortedTroves.sol";
import "./IZQTYToken.sol";
import "./IZQTYStaking.sol";
import "./LiquityBase.sol";

// Common interface for the Trove Manager.
interface ITroveManager3 {
    
    enum TroveManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
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
    }
   
    struct LocalVariables_OuterLiquidationFunction {
        uint[] price;
        address[] troveArray;
        uint liquidatedDebt;
        uint liquidatedColl;
        uint i;
        uint j;
        uint k;
        uint givenLength;
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
        uint collId;
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
        uint TCR;
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
    event TroveManager1AddressChanged(address _newTroveManagerAddress);
    event TroveManager2AddressChanged(address _newTroveManagerAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event ZUSDTokenAddressChanged(address _newZUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event ZQTYTokenAddressChanged(address _zqtyTokenAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _ZUSDGasCompensation);
    event Redemption(uint _attemptedZUSDAmount, uint _actualZUSDAmount, uint _ETHSent, uint _ETHFee);
    
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint[] _totalStakesSnapshot, uint[] _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_ZUSDDebt);
    event TroveSnapshotsUpdated(uint[] _L_ETH, uint _L_ZUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint _stake, TroveManagerOperation _operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, TroveManagerOperation _operation);

    // --- Functions ---
    function setCollTokenAddress(address _collToken) external ;

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
    ) external;

    function stabilityPool() external view returns (IStabilityPool);
    function zusdToken() external view returns (IZUSDToken);
    function zqtyToken() external view returns (IZQTYToken);

    function getTokenAddresses() external view returns(address[] memory);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _collId, uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function checkRecoveryMode(uint[] memory _price) external view returns (bool);
}
