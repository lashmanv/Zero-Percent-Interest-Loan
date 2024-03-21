// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ISortedTroves.sol";
import "./ITroveManager1.sol";
import "./ITroveManager2.sol";
import "./ITroveManager3.sol";
import "./IBorrowerOperations.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./console.sol";

/*
* A sorted doubly linked list with nodes sorted in descending order.
*
* Nodes map to active Troves in the system - the ID property is the address of a Trove owner.
* Nodes are ordered according to their current nominal individual collateral ratio (NICR),
* which is like the ICR but without the price, i.e., just collateral / debt.
*
* The list optionally accepts insert position hints.
*
* NICRs are computed dynamically at runtime, and not stored on the Node. This is because NICRs of active Troves
* change dynamically as liquidation events occur.
*
* The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NICRs of all active Troves,
* but maintains their order. A node inserted based on current NICR will maintain the correct position,
* relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
* Thus, Nodes remain sorted by current NICR.
*
* Nodes need only be re-inserted upon a Trove operation - when the owner adds or removes collateral or debt
* to their position.
*
* The list is a modification of the following audited SortedDoublyLinkedList:
* https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
*
*
* Changes made in the Liquity implementation:
*
* - Keys have been removed from nodes
*
* - Ordering checks for insertion are performed by comparing an NICR argument to the current NICR, calculated at runtime.
*   The list relies on the property that ordering by ICR is maintained as the ETH:USD price varies.
*
* - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
*/
contract SortedTroves is Ownable, CheckContract, ISortedTroves {

    string constant public NAME = "SortedTroves";

    address[] internal collateralTokens;

    address public borrowerOperationsAddress;

    ITroveManager1 public troveManager1;
    ITroveManager2 public troveManager2;
    ITroveManager3 public troveManager3;

    Data[] public data;

    uint internal size = 100;

    // --- Dependency setters ---

    function setParams(uint256 _size, address _troveManager1Address, address _troveManager2Address,  address _troveManager3Address,  address _borrowerOperationsAddress) external override onlyOwner {
        require(_size > 0, "SortedTroves: Size cant be zero");
        checkContract(_troveManager1Address);
        checkContract(_troveManager2Address);
        checkContract(_troveManager3Address);
        checkContract(_borrowerOperationsAddress);
        
        data.push();
        data[0].maxSize = _size;

        collateralTokens.push(address(0));

        troveManager1 = ITroveManager1(_troveManager1Address);
        troveManager2 = ITroveManager2(_troveManager2Address);
        troveManager3 = ITroveManager3(_troveManager3Address);
        borrowerOperationsAddress = _borrowerOperationsAddress;

        emit TroveManager1AddressChanged(_troveManager1Address);
        emit TroveManager2AddressChanged(_troveManager2Address);
        emit TroveManager3AddressChanged(_troveManager3Address);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);

        _renounceOwnership();
    }

    function setCollTokenAddress(address _collToken) external override {
        _requireCallerIsBO();
        collateralTokens.push(_collToken);
        data.push();
        data[collateralTokens.length-1].maxSize = size;
    }

    /*
     * @dev Add a node to the list
     * @param _id Node's id
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */

    function insert (address _id, uint _collId, uint256 _NICR, address _prevId, address _nextId) external override {
        ITroveManager1 troveManager1Cached = troveManager1;
        ITroveManager2 troveManager2Cached = troveManager2;
        ITroveManager3 troveManager3Cached = troveManager3;

        _requireCallerIsBOorTroveM(troveManager1Cached,troveManager2Cached,troveManager3Cached);
        _insert(troveManager1Cached, _id, _collId, _NICR, _prevId, _nextId);
    }

    function _insert(ITroveManager1 _troveManager, address _id, uint _collId, uint256 _NICR, address _prevId, address _nextId) internal {
        // List must not be full
        require(!isFull(_collId), "SortedTroves: List is full");
        // List must not already contain node
        require(!contains(_id, _collId), "SortedTroves: List already contains the node");
        // Node id must not be null
        require(_id != address(0), "SortedTroves: Id cannot be zero");
        // NICR must be non-zero
        require(_NICR > 0, "SortedTroves: NICR must be positive");

        address prevId = _prevId;
        address nextId = _nextId;

        if (!_validInsertPosition(_troveManager, _collId, _NICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_troveManager, _collId, _NICR, prevId, nextId);
        }

        data[_collId].nodes[_id].exists = true;

        if (prevId == address(0) && nextId == address(0)) {
            // Insert as head and tail
            data[_collId].head = _id;
            data[_collId].tail = _id;
        } else if (prevId == address(0)) {
            // Insert before `prevId` as the head
            data[_collId].nodes[_id].nextId = data[_collId].head;
            data[_collId].nodes[data[_collId].head].prevId = _id;
            data[_collId].head = _id;
        } else if (nextId == address(0)) {
            // Insert after `nextId` as the tail
            data[_collId].nodes[_id].prevId = data[_collId].tail;
            data[_collId].nodes[data[_collId].tail].nextId = _id;
            data[_collId].tail = _id;
        } else {
            // Insert at insert position between `prevId` and `nextId`
            data[_collId].nodes[_id].nextId = nextId;
            data[_collId].nodes[_id].prevId = prevId;
            data[_collId].nodes[prevId].nextId = _id;
            data[_collId].nodes[nextId].prevId = _id;
        }

        data[_collId].size = data[_collId].size + 1;
        emit NodeAdded(_id, _NICR);
    }

    function remove(address _id, uint _collId) external override {
        _requireCallerIsTroveManager();
        _remove(_id, _collId);
    }

    /*
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function _remove(address _id, uint _collId) internal {
        // List must contain the node
        require(contains(_id, _collId), "SortedTroves: List does not contain the id");

        if (data[_collId].size > 1) {
            // List contains more than a single node
            if (_id == data[_collId].head) {
                // The removed node is the head
                // Set head to next node
                data[_collId].head = data[_collId].nodes[_id].nextId;
                // Set prev pointer of new head to null
                data[_collId].nodes[data[_collId].head].prevId = address(0);
            } else if (_id == data[_collId].tail) {
                // The removed node is the tail
                // Set tail to previous node
                data[_collId].tail = data[_collId].nodes[_id].prevId;
                // Set next pointer of new tail to null
                data[_collId].nodes[data[_collId].tail].nextId = address(0);
            } else {
                // The removed node is neither the head nor the tail
                // Set next pointer of previous node to the next node
                data[_collId].nodes[data[_collId].nodes[_id].prevId].nextId = data[_collId].nodes[_id].nextId;
                // Set prev pointer of next node to the previous node
                data[_collId].nodes[data[_collId].nodes[_id].nextId].prevId = data[_collId].nodes[_id].prevId;
            }
        } else {
            // List contains a single node
            // Set the head and tail to null
            data[_collId].head = address(0);
            data[_collId].tail = address(0);
        }

        delete data[_collId].nodes[_id];
        data[_collId].size = data[_collId].size - 1;
        emit NodeRemoved(_id);
    }

    /*
     * @dev Re-insert the node at a new position, based on its new NICR
     * @param _id Node's id
     * @param _newNICR Node's new NICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(address _id, uint _collId, uint256 _newNICR, address _prevId, address _nextId) external override {
        ITroveManager1 troveManager1Cached = troveManager1;
        ITroveManager2 troveManager2Cached = troveManager2;
        ITroveManager3 troveManager3Cached = troveManager3;

        _requireCallerIsBOorTroveM(troveManager1Cached, troveManager2Cached, troveManager3Cached);
        // List must contain the node
        require(contains(_id, _collId), "SortedTroves: List does not contain the id");
        // NICR must be non-zero
        require(_newNICR > 0, "SortedTroves: NICR must be positive");

        // Remove node from the list
        _remove(_id, _collId);

        _insert(troveManager1Cached, _id, _collId, _newNICR, _prevId, _nextId);
    }

    /*
     * @dev Checks if the list contains a node
     */
    function contains(address _id, uint _collId) public view override returns (bool) {
        return data[_collId].nodes[_id].exists;
    }

    /*
     * @dev Checks if the list is full
     */
    function isFull(uint _collId) public view override returns (bool) {
        return data[_collId].size == data[_collId].maxSize;
    }

    /*
     * @dev Checks if the list is empty
     */
    function isEmpty(uint _collId) public view override returns (bool) {
        return data[_collId].size == 0;
    }

    /*
     * @dev Returns the current size of the list
     */
    function getSize(uint _collId) external view override returns (uint256) {
        return data[_collId].size;
    }

    /*
     * @dev Returns the maximum size of the list
     */
    function getMaxSize(uint _collId) external view override returns (uint256) {
        return data[_collId].maxSize;
    }

    /*
     * @dev Returns the first node in the list (node with the largest NICR)
     */
    function getFirst(uint _collId) external view override returns (address) {
        return data[_collId].head;
    }

    /*
     * @dev Returns the last node in the list (node with the smallest NICR)
     */
    function getLast(uint _collId) external view override returns (address) {
        return data[_collId].tail;
    }

    /*
     * @dev Returns the next node (with a smaller NICR) in the list for a given node
     * @param _id Node's id
     */
    function getNext(address _id, uint _collId) external view override returns (address) {
        return data[_collId].nodes[_id].nextId;
    }

    /*
     * @dev Returns the previous node (with a larger NICR) in the list for a given node
     * @param _id Node's id
     */
    function getPrev(address _id, uint _collId) external view override returns (address) {
        return data[_collId].nodes[_id].prevId;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function validInsertPosition(uint _collId, uint256 _NICR, address _prevId, address _nextId) external view override returns (bool) {
        return _validInsertPosition(troveManager1, _collId, _NICR, _prevId, _nextId);
    }

    function _validInsertPosition(ITroveManager1 _troveManager, uint _collId, uint256 _NICR, address _prevId, address _nextId) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty(_collId);
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data[_collId].head == _nextId && _NICR >= _troveManager.getNominalICR(_nextId);
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data[_collId].tail == _prevId && _NICR <= _troveManager.getNominalICR(_prevId);
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
            return data[_collId].nodes[_prevId].nextId == _nextId &&
                   _troveManager.getNominalICR(_prevId) >= _NICR &&
                   _NICR >= _troveManager.getNominalICR(_nextId);
        }
    }

    /*
     * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
     * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(ITroveManager1 _troveManager, uint _collId, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data[_collId].head == _startId && _NICR >= _troveManager.getNominalICR(_startId)) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data[_collId].nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_troveManager, _collId, _NICR, prevId, nextId)) {
            prevId = data[_collId].nodes[prevId].nextId;
            nextId = data[_collId].nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
     * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(ITroveManager1 _troveManager, uint _collId, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data[_collId].tail == _startId && _NICR <= _troveManager.getNominalICR(_startId)) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data[_collId].nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_troveManager, _collId, _NICR, prevId, nextId)) {
            nextId = data[_collId].nodes[nextId].prevId;
            prevId = data[_collId].nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Find the insert position for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(uint _collId, uint256 _NICR, address _prevId, address _nextId) external view override returns (address, address) {
        return _findInsertPosition(troveManager1, _collId, _NICR, _prevId, _nextId);
    }

    function _findInsertPosition(ITroveManager1 _troveManager, uint _collId, uint256 _NICR, address _prevId, address _nextId) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId,_collId) || _NICR > _troveManager.getNominalICR(prevId)) {
                // `prevId` does not exist anymore or now has a smaller NICR than the given NICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId,_collId) || _NICR < _troveManager.getNominalICR(nextId)) {
                // `nextId` does not exist anymore or now has a larger NICR than the given NICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_troveManager, _collId, _NICR, data[_collId].head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_troveManager, _collId, _NICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_troveManager, _collId, _NICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_troveManager,_collId, _NICR, prevId);
        }
    }

    // --- 'require' functions ---

    function _requireCallerIsTroveManager() internal view {
        require( msg.sender == address(troveManager1) || 
        msg.sender == address(troveManager2) ||
        msg.sender == address(troveManager3), "SortedTroves: Caller is not the TroveManager");
    }

    function _requireCallerIsBO() internal view {
        require(msg.sender == borrowerOperationsAddress, "SortedTroves: Caller is not the BO");
    }

    function _requireCallerIsBOorTroveM(ITroveManager1 _troveManager1, ITroveManager2 _troveManager2, ITroveManager3 _troveManager3) internal view {
        require (msg.sender == borrowerOperationsAddress || 
        msg.sender == address(_troveManager1) || 
        msg.sender == address(_troveManager2) ||
        msg.sender == address(_troveManager3), "SortedTroves: Caller is neither BO nor TroveM");
    }
}