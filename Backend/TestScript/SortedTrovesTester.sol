// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ISortedTroves.sol";


contract SortedTrovesTester {
    ISortedTroves sortedTroves;

    function setSortedTroves(address _sortedTrovesAddress) external {
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
    }

    function insert(address _id, uint _collId, uint256 _NICR, address _prevId, address _nextId) external {
        sortedTroves.insert(_id, _collId, _NICR, _prevId, _nextId);
    }

    function remove(address _id, uint _collId) external {
        sortedTroves.remove(_id, _collId);
    }

    function reInsert(address _id, uint _collId, uint256 _newNICR, address _prevId, address _nextId) external {
        sortedTroves.reInsert(_id, _collId, _newNICR, _prevId, _nextId);
    }

    function getNominalICR(address) external pure returns (uint) {
        return 1;
    }

    function getCurrentICR(address, uint) external pure returns (uint) {
        return 1;
    }
}
