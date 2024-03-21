// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Sample {
    uint[] internal tokens;

    mapping(uint => uint) internal tokenBalance;

    address pool;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    function setPool(address _address) public {
        pool = _address;
    }

    function approvedTokens() public view returns(uint[] memory) {
        return tokens;
    }

    function addTokens(uint[] memory _tokenIds) external {
        uint256 length = _tokenIds.length;
        require(length > 0, "NO_TOKENS_TO_ADD");

        for (uint256 i = 0; i < length; i++) {
            tokens.push(_tokenIds[i]);
        }
    }

    function tok() external view returns(uint[] memory, uint) {
        return(tokens,tokens.length);
    }

    uint[] test = [0,0,0,0,0];

    function getTokenBalances() external view returns (uint[] memory) {
        
        uint[] memory balances;

        tokens.length == 0 ? balances = test : balances = new uint[](tokens.length);

        uint256 j;
        for (uint i = 0; i < balances.length; i++){
            balances[j] = tokenBalance[i];
            j++;
        }

        return balances;
    }

    function receiveCollToken(uint _collTokenId, uint _collAmount) external {
        tokenBalance[_collTokenId] = tokenBalance[_collTokenId] + _collAmount;
    }


    
        uint[] tokenIds = [0,10e18,0,0,0];
        
        uint[] liqTokens = [0,5e18,0,0,0];

    function getEntireSystemColl() public view returns (uint entireSystemColl, uint[] memory, uint[] memory) {
        uint activeETHColl = 0;
        uint liquidatedColl = 0;
        return (activeETHColl + liquidatedColl, tokenIds, liqTokens) ;
    }

    function getEntireCollPrice(uint _collId, uint _collAmount, bool _isCollIncrease, uint[] memory price) public view returns(uint, uint[] memory, uint[] memory) {
        (uint totalEth, uint[] memory activeTokens, uint[] memory liquidatedTokens) = getEntireSystemColl();

        if(_collAmount > 0) {
            if(_isCollIncrease) {
                (_collId == 0) ? (totalEth = totalEth + _collAmount) : (activeTokens[_collId] = activeTokens[_collId] + _collAmount);
            }
            else {
                (_collId == 0) ? (totalEth = totalEth - _collAmount) : (activeTokens[_collId] = activeTokens[_collId] - _collAmount);
            }
        }

        uint ethCollPrice = totalEth * price[0];

        uint[] memory activeTokenPrice = new uint[](activeTokens.length);        
        uint[] memory liquidatedTokenPrice = new uint[](liquidatedTokens.length);

        for(uint i = 0; i < price.length-1; i++){
            activeTokenPrice[i] = activeTokens[i] * price[i+1];
            liquidatedTokenPrice[i] = liquidatedTokens[i] * price[i+1];
        }
        
        uint _totalFunds;

        for (uint i = 0; i < price.length-1; i++){
            _totalFunds = _totalFunds + (activeTokenPrice[i] + liquidatedTokenPrice[i]);
        }

        _totalFunds = _totalFunds + ethCollPrice;

        return(_totalFunds, activeTokens, liquidatedTokens);
    }

    function _computeEntireCR(uint _debt, uint _price) public pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _price / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }


    function getPendingTokenReward() public view returns (uint[] memory) {
        uint[] memory dummy = new uint[](tokenIds.length);
        uint[] memory snapshotColl = new uint[](tokenIds.length);
        uint[] memory rewardPerUnitStaked = new uint[](tokenIds.length);

        uint[] memory rewardSnapshotsColl = liqTokens;

        (uint[] memory L_COLL) = tokenIds;

        for(uint i = 0; i < tokenIds.length; i++) {
            snapshotColl[i] = rewardSnapshotsColl[i];
            rewardPerUnitStaked[i] = L_COLL[i] - snapshotColl[i];
        }
        
        if (1 != 1) { return dummy; }

        uint stake = 5000000000000000000;

        uint[] memory pendingReward = new uint[](tokenIds.length);

        for(uint i = 0; i < tokenIds.length; i++) {
            pendingReward[i] = (stake * rewardPerUnitStaked[i]) / 1e18;
        }
        
        return pendingReward;
    }
    
    
    struct LocalVariables {
        address[] batchAddress;
        uint batchLength;
        // uint index;
    }

    mapping(address => uint) tokenId;

    function set(address user, uint token) public{
        tokenId[user] = token;
    }


    // input: 5 user address

    // LocalVariables 0 {
    // address[]: [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4]
    // length: 2
    // }

    // LocalVariables 1 {
    // address[]: [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4]
    // length: 1
    // }

    // LocalVariables 2 {
    // address[]: []
    // length: 0
    // }

    // LocalVariables 3 {
    // address[]: [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4]
    // length: 1
    // }

    // LocalVariables 4 {
    // address[]: [0x5B38Da6a701c568545dCfcB03FcB875f56beddC4]
    // length: 1
    // }

    struct Node {
        bool exists;
        address nextId;                  // Id of next node (smaller NICR) in the list
        address prevId;                  // Id of previous node (larger NICR) in the list
    }

    struct Data {
        address head;                        // Head of the list. Also the node in the list with the largest NICR
        address tail;                        // Tail of the list. Also the node in the list with the smallest NICR
        uint256 maxSize;                     // Maximum size of the list
        uint256 size;                        // Current size of the list
        mapping (address => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    Data[] public data;

    function _insert(address _id) public {

        data[4].nodes[_id].exists = true;

            data[4].head = _id;
            data[4].tail = _id;

            // Insert after `nextId` as the tail
            data[4].nodes[_id].prevId = data[4].tail;
            data[4].nodes[data[4].tail].nextId = _id;
            data[4].tail = _id;
        

        data[4].size = data[4].size + 1;
    }

    function set() public {
        for(uint i = 0; i < 5; i++) {
            data.push();
        }
    }

    function del(address h) public {
            data[3].head = data[4].head;
            data[3].tail = data[4].tail;
            data[3].size = data[4].size;
            data[3].nodes[h] = data[4].nodes[h];
            data.pop();
    }

    function dis(address h) public view returns(address, address, uint, Node memory){

        return(data[4].head,data[4].tail,data[4].size,data[4].nodes[h]);
    }

    function disp(address h) public view returns(address, address, uint, Node memory){

        return(data[3].head,data[3].tail,data[3].size,data[3].nodes[h]);
    }


    
}