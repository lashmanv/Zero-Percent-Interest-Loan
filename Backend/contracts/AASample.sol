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


    
        uint[] actTokenColl = [0,0,0,0,0];
        
        uint[] liqTokens = [0,0,0,0,0];

    function getEntireSystemColl() public view returns (uint entireSystemColl, uint[] memory, uint[] memory) {
        uint activeETHColl = 0;
        uint liquidatedColl = 0;
        return (activeETHColl + liquidatedColl, actTokenColl, liqTokens) ;
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

    // function transfer(uint _collateralTokenId, uint _collateralAmount) external {
    //     IERC20 collateralAddress = tokens[_collateralTokenId];
    //     bool success = collateralAddress.transferFrom(msg.sender, pool, _collateralAmount);
    //     require(success, "BorrowerOps: Sending ETH to ActivePool failed");
    // }


    /*
    function (
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    */
    // function depositWith(uint _collateralTokenId,uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
    //     tokens[_collateralTokenId].(msg.sender, address(this), amount, deadline, v, r, s);
    //     tokens[_collateralTokenId].transferFrom(msg.sender, address(this), amount);
    // }
}


    
//27 0x92d2a8c519e4c74700ed72a12c0940851f7035753fc22c1d2dfbcd48802f695b 0x31ba6a6dacb80b147419929fd1b7fb6932680d2d39b3fed270104eab8e95a65c
