// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ITroveManager1.sol";
import "./ISortedTroves.sol";
import "./IPriceFeed.sol";
import "./LiquityMath.sol";

/* Wrapper contract - used for calculating gas of read-only and internal functions. 
Not part of the Liquity application. */
contract FunctionCaller {

    ITroveManager1 troveManager;
    address public troveManagerAddress;

    ISortedTroves sortedTroves;
    address public sortedTrovesAddress;

    IPriceFeed priceFeed;
    address public priceFeedAddress;

    // --- Dependency setters ---

    function setTroveManagerAddress(address _troveManagerAddress) external {
        troveManagerAddress = _troveManagerAddress;
        troveManager = ITroveManager1(_troveManagerAddress);
    }
    
    function setSortedTrovesAddress(address _sortedTrovesAddress) external {
        troveManagerAddress = _sortedTrovesAddress;
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
    }

     function setPriceFeedAddress(address _priceFeedAddress) external {
        priceFeedAddress = _priceFeedAddress;
        priceFeed = IPriceFeed(_priceFeedAddress);
    }

    // --- Non-view wrapper functions used for calculating gas ---
    
    function troveManager_getCurrentICR(address _address, uint _price) external view returns (uint) {
        return troveManager.getCurrentICR(_address, _price);  
    }

    function sortedTroves_findInsertPosition(uint _collId, uint _NICR, address _prevId, address _nextId) external view returns (address, address) {
        return sortedTroves.findInsertPosition(_collId, _NICR, _prevId, _nextId);
    }
}
