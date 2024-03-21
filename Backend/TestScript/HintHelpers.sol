// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ITroveManager1.sol";
import "./ITroveManager2.sol";
import "./ITroveManager3.sol";
import "./ISortedTroves.sol";
import "./LiquityBase.sol";
import "./Ownable.sol";
import "./CheckContract.sol";

contract HintHelpers is LiquityBase, Ownable, CheckContract {
    string constant public NAME = "HintHelpers";

    ISortedTroves public sortedTroves;
    ITroveManager1 public troveManager1;
    ITroveManager2 public troveManager2;
    ITroveManager3 public troveManager3;

    // --- Events ---

    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event TroveManager1AddressChanged(address _troveManager1Address);
    event TroveManager2AddressChanged(address _troveManager2Address);
    event TroveManager3AddressChanged(address _troveManager3Address);

    // --- Dependency setters ---

    function setAddresses(
        address _sortedTrovesAddress,
        address _troveManager1Address,
        address _troveManager2Address,
        address _troveManager3Address
    )
        external
        onlyOwner
    {
        checkContract(_sortedTrovesAddress);
        checkContract(_troveManager1Address);
        checkContract(_troveManager2Address);
        checkContract(_troveManager3Address);

        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        troveManager1 = ITroveManager1(_troveManager1Address);
        troveManager2 = ITroveManager2(_troveManager2Address);
        troveManager3 = ITroveManager3(_troveManager3Address);

        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit TroveManager3AddressChanged(_troveManager3Address);

        _renounceOwnership();
    }

    // --- Functions ---

    /* getRedemptionHints() - Helper function for finding the right hints to pass to redeemCollateral().
     *
     * It simulates a redemption of `_ZUSDamount` to figure out where the redemption sequence will start and what state the final Trove
     * of the sequence will end up in.
     *
     * Returns three hints:
     *  - `firstRedemptionHint` is the address of the first Trove with ICR >= MCR (i.e. the first Trove that will be redeemed).
     *  - `partialRedemptionHintNICR` is the final nominal ICR of the last Trove of the sequence after being hit by partial redemption,
     *     or zero in case of no partial redemption.
     *  - `truncatedZUSDamount` is the maximum amount that can be redeemed out of the the provided `_ZUSDamount`. This can be lower than
     *    `_ZUSDamount` when redeeming the full amount would leave the last Trove of the redemption sequence with less net debt than the
     *    minimum allowed value (i.e. MIN_NET_DEBT).
     *
     * The number of Troves to consider for redemption can be capped by passing a non-zero value as `_maxIterations`, while passing zero
     * will leave it uncapped.
     */

    function getRedemptionHints(
        uint _collId,
        uint _ZUSDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedZUSDamount
        )
    {
        ISortedTroves sortedTrovesCached = sortedTroves;

        uint remainingZUSD = _ZUSDamount;
        address currentTroveuser = sortedTrovesCached.getLast(_collId);

        while (currentTroveuser != address(0) && troveManager1.getCurrentICR(currentTroveuser, _price) < MCR) {
            currentTroveuser = sortedTrovesCached.getPrev(currentTroveuser, _collId);
        }

        firstRedemptionHint = currentTroveuser;

        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }

        while (currentTroveuser != address(0) && remainingZUSD > 0 && _maxIterations-- > 0) {
            uint netZUSDDebt = _getNetDebt(troveManager1.getTroveDebt(currentTroveuser))
                + (troveManager1.getPendingZUSDDebtReward(currentTroveuser));

            if (netZUSDDebt > remainingZUSD) {
                if (netZUSDDebt > MIN_NET_DEBT) {
                    uint maxRedeemableZUSD = LiquityMath._min(remainingZUSD, netZUSDDebt- MIN_NET_DEBT);

                    // uint[] memory rewardTokens =  troveManager1.getPendingTokenReward(currentTroveuser);

                    uint ETH = troveManager1.getTroveColl(currentTroveuser);

                    uint newColl = ETH - ((maxRedeemableZUSD * DECIMAL_PRECISION) / _price);
                    uint newDebt = netZUSDDebt - maxRedeemableZUSD;

                    uint compositeDebt = _getCompositeDebt(newDebt);
                    partialRedemptionHintNICR = LiquityMath._computeNominalCR(newColl, compositeDebt);

                    remainingZUSD = remainingZUSD - maxRedeemableZUSD;
                }
                break;
            } else {
                remainingZUSD = remainingZUSD - netZUSDDebt;
            }

            currentTroveuser = sortedTrovesCached.getPrev(currentTroveuser, _collId);
        }

        truncatedZUSDamount = _ZUSDamount - remainingZUSD;
    }

    /* getApproxHint() - return address of a Trove that is, on average, (length / numTrials) positions away in the 
    sortedTroves list from the correct insert position of the Trove to be inserted. 
    
    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function 
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:

    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will 
    be <= sqrt(length) positions away from the correct insert position.
    */
    function getApproxHint(uint _collId,uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed)
    {
        uint arrayLength = troveManager1.getTroveOwnersCount();

        if (arrayLength == 0) {
            return (address(0), 0, _inputRandomSeed);
        }

        hintAddress = sortedTroves.getLast(_collId);
        diff = LiquityMath._getAbsoluteDifference(_CR, troveManager1.getNominalICR(hintAddress));
        latestRandomSeed = _inputRandomSeed;

        uint i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint(keccak256(abi.encodePacked(latestRandomSeed)));

            uint arrayIndex = latestRandomSeed % arrayLength;
            address currentAddress = troveManager1.getTroveFromTroveOwnersArray(arrayIndex);
            uint currentNICR = troveManager1.getNominalICR(currentAddress);

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint currentDiff = LiquityMath._getAbsoluteDifference(currentNICR, _CR);

            if (currentDiff < diff) {
                diff = currentDiff;
                hintAddress = currentAddress;
            }
            i++;
        }
    }

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint) {
        return LiquityMath._computeNominalCR(_coll, _debt);
    }

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint) {
        return LiquityMath._computeCR(_coll, _debt, _price);
    }
}
