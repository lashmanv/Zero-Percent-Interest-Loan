// SPDX-License-Identifier: MIT
import "./ITroveManager1.sol";
import "./ITroveManager2.sol";
import "./ITroveManager3.sol";

pragma solidity 0.8.10;

// Common interface for the Trove Manager.
interface IBorrowerOperations {

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

     struct LocalVariables_adjustTrove {
        uint[] price;
        uint collChange;
        uint zusdChange;
        uint netDebtChange;
        bool isCollIncrease;
        uint debt;
        uint collId;
        uint coll;
        uint oldICR;
        uint newICR;
        uint newTCR;
        uint ZUSDFee;
        uint newDebt;
        uint newColl;
        uint stake;
        bool isDebtIncrease;
    }

    struct LocalVariables_openTrove {
        uint[] price;
        uint ZUSDFee;
        uint netDebt;
        uint compositeDebt;
        uint ICR;
        uint NICR;
        uint stake;
        uint arrayIndex;
    }

    struct ContractsCache {
        ITroveManager1 troveManager1;
        ITroveManager2 troveManager2;
        ITroveManager3 troveManager3;
        IActivePool activePool;
        IZUSDToken zusdToken;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    // --- Events ---

    event TroveManager1AddressChanged(address _newTroveManagerAddress);
    event TroveManager2AddressChanged(address _newTroveManagerAddress);
    event TroveManager3AddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event ZUSDTokenAddressChanged(address _zusdTokenAddress);
    event ZQTYStakingAddressChanged(address _zqtyStakingAddress);
    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event ZUSDBorrowingFeePaid(address indexed _borrower, uint _ZUSDFee);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, BorrowerOperation _operation);

    // --- Functions ---

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
    ) external;

    function addCollTokenAddress(address[] memory _tokenAddresses) external;

    function openTrovewithEth(uint _maxFee, uint _ZUSDAmount, address _upperHint, address _lowerHint) external payable;

    function openTrovewithTokens(uint _maxFee,uint _collateralTokenId, uint _collateralAmount, uint _ZUSDAmount, address _upperHint, address _lowerHint) external;

    function addColl(uint _collateralAmount,address _upperHint, address _lowerHint) external payable;

    function moveTokenGainToTrove(uint _collAmount, address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawZUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayZUSD(uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}
