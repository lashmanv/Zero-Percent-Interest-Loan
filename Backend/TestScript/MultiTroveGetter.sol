// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./TroveManager1.sol";
import "./SortedTroves.sol";

/*  Helper contract for grabbing Trove data for the front end. Not part of the core Liquity system. */
contract MultiTroveGetter {
    struct CombinedTroveData {
        address owner;

        uint debt;
        uint collId;
        uint coll;
        uint stake;

        uint snapshotETH;
        uint snapshotZUSDDebt;
    }

    TroveManager1 public troveManager; // XXX Troves missing from ITroveManager?
    ISortedTroves public sortedTroves;

    constructor(TroveManager1 _troveManager, ISortedTroves _sortedTroves) {
        troveManager = _troveManager;
        sortedTroves = _sortedTroves;
    }

    function getMultipleSortedTroves(int _startIdx, uint _collId, uint _count)
        external view returns (CombinedTroveData[] memory _troves)
    {
        uint startIdx;
        bool descend;

        if (_startIdx >= 0) {
            startIdx = uint(_startIdx);
            descend = true;
        } else {
            startIdx = uint(-(_startIdx + 1));
            descend = false;
        }

        uint sortedTrovesSize = sortedTroves.getSize(_collId);

        if (startIdx >= sortedTrovesSize) {
            _troves = new CombinedTroveData[](0);
        } else {
            uint maxCount = sortedTrovesSize - startIdx;

            if (_count > maxCount) {
                _count = maxCount;
            }

            if (descend) {
                _troves = _getMultipleSortedTrovesFromHead(startIdx, _collId, _count);
            } else {
                _troves = _getMultipleSortedTrovesFromTail(startIdx, _collId, _count);
            }
        }
    }

    function _getMultipleSortedTrovesFromHead(uint _startIdx, uint _collId, uint _count)
        internal view returns (CombinedTroveData[] memory _troves)
    {
        address currentTroveowner = sortedTroves.getFirst(_collId);

        for (uint idx = 0; idx < _startIdx; ++idx) {
            currentTroveowner = sortedTroves.getNext(currentTroveowner, _collId);
        }

        _troves = new CombinedTroveData[](_count);

        for (uint idx = 0; idx < _count; ++idx) {
            _troves[idx].owner = currentTroveowner;
            (
                _troves[idx].debt,
                _troves[idx].collId,
                _troves[idx].coll,
                _troves[idx].stake,
                /* status */,
                /* arrayIndex */,
                ,
            ) = troveManager.Troves(currentTroveowner);
            (
                _troves[idx].snapshotETH,
                _troves[idx].snapshotZUSDDebt
            ) = troveManager.getRewardSnapshots(currentTroveowner);

            currentTroveowner = sortedTroves.getNext(currentTroveowner, _collId);
        }
    }

    function _getMultipleSortedTrovesFromTail(uint _startIdx, uint _collId,uint _count)
        internal view returns (CombinedTroveData[] memory _troves)
    {
        address currentTroveowner = sortedTroves.getLast(_collId);

        for (uint idx = 0; idx < _startIdx; ++idx) {
            currentTroveowner = sortedTroves.getPrev(currentTroveowner, _collId);
        }

        _troves = new CombinedTroveData[](_count);

        for (uint idx = 0; idx < _count; ++idx) {
            _troves[idx].owner = currentTroveowner;
            (
                _troves[idx].debt,
                _troves[idx].collId,
                _troves[idx].coll,
                _troves[idx].stake,
                /* status */,
                /* arrayIndex */,
                ,
            ) = troveManager.Troves(currentTroveowner);
            (
                _troves[idx].snapshotETH,
                _troves[idx].snapshotZUSDDebt
            ) = troveManager.getRewardSnapshots(currentTroveowner);

            currentTroveowner = sortedTroves.getPrev(currentTroveowner, _collId);
        }
    }
}
