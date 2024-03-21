// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId;                  // Id of next node (smaller NICR) in the list
        address prevId;                  // Id of previous node (larger NICR) in the list
    }

    // Information for the list
    struct Data {
        address head;                        // Head of the list. Also the node in the list with the largest NICR
        address tail;                        // Tail of the list. Also the node in the list with the smallest NICR
        uint256 maxSize;                     // Maximum size of the list
        uint256 size;                        // Current size of the list
        mapping (address => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    // --- Events ---    
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);
    event TroveManager1AddressChanged(address _troveManager1Address);
    event TroveManager2AddressChanged(address _troveManager2Address);
    event TroveManager3AddressChanged(address _troveManager3Address);
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);


    // --- Functions ---
    
    function setParams(uint256 _size, address _troveManager1Address, address _troveManager2Address, address _troveManager3Address, address _borrowerOperationsAddress) external;

    function setCollTokenAddress(address _collToken) external;

    function insert(address _id, uint _collId, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id, uint _collId) external;

    function reInsert(address _id, uint _collId, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id, uint _collId) external view returns (bool);

    function isFull(uint _collId) external view returns (bool);

    function isEmpty(uint _collId) external view returns (bool);

    function getSize(uint _collId) external view returns (uint256);

    function getMaxSize(uint _collId) external view returns (uint256);

    function getFirst(uint _collId) external view returns (address);

    function getLast(uint _collId) external view returns (address);

    function getNext(address _id, uint _collId) external view returns (address);

    function getPrev(address _id, uint _collId) external view returns (address);

    function validInsertPosition(uint _collId, uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint _collId, uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}
