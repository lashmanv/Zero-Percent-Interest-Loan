// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./BaseMath.sol";
import "./LiquityMath.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";
import "./ILiquityBase.sol";

/* 
* Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
* common functions. 
*/
contract LiquityBase is BaseMath, ILiquityBase {

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual troves
    uint constant public MCR = 1100000000000000000; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint constant public CCR = 1500000000000000000; // 150%

    // Amount of ZUSD to be locked in gas pool on opening troves
    uint constant public ZUSD_GAS_COMPENSATION = 200e18;

    // Minimum amount of net ZUSD debt a trove must have
    uint constant public MIN_NET_DEBT = 1800e18;
    // uint constant public MIN_NET_DEBT = 0; 

    uint constant public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint constant public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool public activePool;

    IDefaultPool public defaultPool;

    IPriceFeed public override priceFeed;

    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return _debt + ZUSD_GAS_COMPENSATION;
    }

    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return _debt - ZUSD_GAS_COMPENSATION;
    }

    // Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal pure returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }

    function getEntireSystemColl() public view returns (uint[] memory, uint[] memory) {
        uint[] memory activeTokenColl = activePool.getTokenBalances();
        uint[] memory liquidatedTokens = defaultPool.getTokenBalances();

        return (activeTokenColl, liquidatedTokens) ;
    }

    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getZUSDDebt();
        uint closedDebt = defaultPool.getZUSDDebt();

        return activeDebt + closedDebt;
    }

    function getEntireCollPrice(uint _collId, uint _collAmount, bool _isCollIncrease, uint[] memory price) public view returns(uint) {
        (uint[] memory activeTokens, uint[] memory liquidatedTokens) = getEntireSystemColl();

        if(_collAmount > 0) {
            _isCollIncrease ? (activeTokens[_collId] = activeTokens[_collId] + _collAmount) : (activeTokens[_collId] = activeTokens[_collId] - _collAmount);
        }

        uint[] memory activeTokenPrice = new uint[](activeTokens.length);        
        uint[] memory liquidatedTokenPrice = new uint[](liquidatedTokens.length);

        for(uint i = 0; i < price.length; i++){
            activeTokenPrice[i] = activeTokens[i] * price[i];
            liquidatedTokenPrice[i] = liquidatedTokens[i] * price[i];
        }
        
        uint _totalFunds;

        for (uint i = 0; i < price.length; i++){
            _totalFunds = _totalFunds + (activeTokenPrice[i] + liquidatedTokenPrice[i]);
        }

        return (_totalFunds);
    }

    function _getTCR(uint[] memory _price) internal view returns (uint) {
        uint entireSystemPrice = getEntireCollPrice(0,0,false,_price);
        uint entireSystemDebt = getEntireSystemDebt();

        uint TCR = LiquityMath._computeEntireCR(entireSystemPrice, entireSystemDebt);

        return TCR;
    }

    function _checkRecoveryMode(uint[] memory _price) internal view returns (bool) {
        uint TCR = _getTCR(_price);

        return TCR < CCR;
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee * DECIMAL_PRECISION / _amount;
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }
}
