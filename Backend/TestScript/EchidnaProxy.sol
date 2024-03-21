// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./TroveManager1.sol";
import "./TroveManager2.sol";
import "./TroveManager3.sol";
import "./BorrowerOperations.sol";
import "./StabilityPool.sol";
import "./ZUSDToken.sol";

contract EchidnaProxy {
    TroveManager1 troveManager1;
    TroveManager2 troveManager2;
    TroveManager3 troveManager3;
    BorrowerOperations borrowerOperations;
    StabilityPool stabilityPool;
    ZUSDToken zusdToken;

    constructor(
        BorrowerOperations _borrowerOperations,
        TroveManager1 _troveManager1,
        TroveManager2 _troveManager2,
        TroveManager3 _troveManager3,
        StabilityPool _stabilityPool,
        ZUSDToken _zusdToken
    ) {
        borrowerOperations = _borrowerOperations;        
        troveManager1 = _troveManager1;
        troveManager2 = _troveManager2;
        troveManager3 = _troveManager3;
        stabilityPool = _stabilityPool;
        zusdToken = _zusdToken;
    }

    receive() external payable {
        // do nothing
    }

    // TroveManager

    function liquidatePrx(address _user) external {
        troveManager3.liquidate(_user);
    }

    function liquidateTrovesPrx(uint _collId,uint _n) external {
        troveManager3.liquidateTroves(_collId, _n);
    }

    function batchLiquidateTrovesPrx(address[] calldata _troveArray) external {
        troveManager3.batchLiquidateTroves(_troveArray);
    }

    function redeemCollateralPrx(
        uint _collId,
        uint _ZUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external {
        troveManager2.redeemCollateral(_collId, _ZUSDAmount, _firstRedemptionHint, _upperPartialRedemptionHint, _lowerPartialRedemptionHint, _partialRedemptionHintNICR, _maxIterations, _maxFee);
    }

    // Borrower Operations
    function openTrovePrx(uint _ETH, uint _ZUSDAmount, address _upperHint, address _lowerHint, uint _maxFee) external payable {
        borrowerOperations.openTrovewithEth{value: _ETH}(_maxFee, _ZUSDAmount, _upperHint, _lowerHint);
    }

    function addCollPrx(uint _ETH, address _upperHint, address _lowerHint) external payable {
        borrowerOperations.addColl{value: _ETH}(_ETH,_upperHint, _lowerHint);
    }

    function withdrawCollPrx(uint _amount, address _upperHint, address _lowerHint) external {
        borrowerOperations.withdrawColl(_amount, _upperHint, _lowerHint);
    }

    function withdrawZUSDPrx(uint _amount, address _upperHint, address _lowerHint, uint _maxFee) external {
        borrowerOperations.withdrawZUSD(_maxFee, _amount, _upperHint, _lowerHint);
    }

    function repayZUSDPrx(uint _amount, address _upperHint, address _lowerHint) external {
        borrowerOperations.repayZUSD(_amount, _upperHint, _lowerHint);
    }

    function closeTrovePrx() external {
        borrowerOperations.closeTrove();
    }

    function adjustTrovePrx(uint _ETH, uint _collWithdrawal, uint _debtChange, bool _isDebtIncrease, address _upperHint, address _lowerHint, uint _maxFee) external payable {
        borrowerOperations.adjustTrove{value: _ETH}(_maxFee, _collWithdrawal, _debtChange, _isDebtIncrease, _upperHint, _lowerHint);
    }

    // Pool Manager
    function provideToSPPrx(uint _amount, address _frontEndTag) external {
        stabilityPool.provideToSP(_amount, _frontEndTag);
    }

    function withdrawFromSPPrx(uint _amount) external {
        stabilityPool.withdrawFromSP(_amount);
    }

    // ZUSD Token

    function transferPrx(address recipient, uint256 amount) external returns (bool) {
        return zusdToken.transfer(recipient, amount);
    }

    function approvePrx(address spender, uint256 amount) external returns (bool) {
        return zusdToken.approve(spender, amount);
    }

    function transferFromPrx(address sender, address recipient, uint256 amount) external returns (bool) {
        return zusdToken.transferFrom(sender, recipient, amount);
    }

    function increaseAllowancePrx(address spender, uint256 addedValue) external returns (bool) {
        return zusdToken.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowancePrx(address spender, uint256 subtractedValue) external returns (bool) {
        return zusdToken.decreaseAllowance(spender, subtractedValue);
    }
}
