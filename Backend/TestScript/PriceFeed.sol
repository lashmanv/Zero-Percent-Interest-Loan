// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPriceFeed.sol";
import "./ITellorCaller.sol";
import "./AggregatorV3Interface.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
import "./BaseMath.sol";
import "./LiquityMath.sol";
import "./console.sol";

/*
* PriceFeed for mainnet deployment, to be connected to Chainlink's live ETH:USD aggregator reference 
* contract, and a wrapper contract TellorCaller, which connects to TellorMaster contract.
*
* The PriceFeed uses Chainlink as primary oracle, and Tellor as fallback. It contains logic for
* switching oracles based on oracle failures, timeouts, and conditions for returning to the primary
* Chainlink oracle.
*/
contract PriceFeed is Ownable, CheckContract, BaseMath, IPriceFeed {

    string constant public NAME = "PriceFeed";

    AggregatorV3Interface[] public priceFeed;

    /**
     * Network: Mainnet
     * ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     * WETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     * STETH/USD: 0xcfe54b5cd566ab89272946f602d76ea879cab4a8
     * AAVE/USD: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9
     * DAI/USD: 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9
     * BTC/USD: 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c
     * WBTC/BTC: 0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23
     */

    /**
     * Network: Goerli
     * ETH/USD: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     * WETH/USD: 
     * BTC/USD: 0xA39434A63A52E749F02807ae27335515BA4b07F7
     * WBTC/BTC: 
     */ 

    // Core Liquity contracts
    address borrowerOperationsAddress;
    address troveManagerAddress;

    // Use to convert a price answer to an 18-digit precision uint
    uint constant public TARGET_DIGITS = 18;  

    // Maximum time period allowed since Chainlink's latest round data timestamp, beyond which Chainlink is considered frozen.
    uint constant public TIMEOUT = 444400;  // 4 hours: 60 * 60 * 4
    
    // Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    uint constant public MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND =  5e17; // 50%

    // The last good price seen from an oracle by Liquity
    uint[] public lastGoodPrice;

    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    enum Status {
        chainlinkWorking,
        chainlinkFrozen,
        chainlinkBroken
    }

    // The current status of the PricFeed, which determines the conditions for the next price fetch attempt
    Status[] public status;

    event PriceFeedStatusChanged(Status newStatus);

    constructor() {
        for(uint i = 0; i < 7; i++) {
            if(i < 6){lastGoodPrice.push(0);}
        }
    }

    // --- Dependency setters ---
    // ["0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419","0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419","0xcfe54b5cd566ab89272946f602d76ea879cab4a8","0x547a514d5e3769680Ce22B2361c10Ea13619e8a9","0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9","0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c","0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23"]
    function setAddresses(address[] memory priceFeeds) external onlyOwner {
        // Get an initial price from Chainlink to serve as first reference for lastGoodPrice
        for(uint i = 0; i < priceFeeds.length; i++) {
            checkContract(priceFeeds[i]);

            priceFeed.push(AggregatorV3Interface(priceFeeds[i]));

            ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse(i);
            ChainlinkResponse memory prevChainlinkResponse = _getPrevChainlinkResponse(i, chainlinkResponse.roundId, chainlinkResponse.decimals);
            
            require(!_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse) && !_chainlinkIsFrozen(chainlinkResponse), 
                "PriceFeed: Chainlink must be working and current");

            status.push(Status.chainlinkWorking);
        }
    }

    // --- Functions ---  
    /**
     * Returns the latest price
     */
    function getPrice(uint _tokenId) internal view returns (int p) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            p,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed[_tokenId].latestRoundData();
        return p;
    }

    function fetchWrappedTokenPrice(uint _priceId, uint _pegToBaseId, uint _assestToPedId) internal returns (uint) {
        int256 pegToBasePrice = getPrice(_pegToBaseId);
        int256 assetToPegPrice = getPrice(_assestToPedId);
    
        if (assetToPegPrice <= 0 || pegToBasePrice <= 0) {
            return 0;
        }

        int price = ((assetToPegPrice * pegToBasePrice * int256(10 ** 2)));

        _storePrice(_priceId,uint(price));

        return uint(price);
    }

    /*
    * fetchPrice():
    * Returns the latest price obtained from the Oracle. Called by Liquity functions that require a current price.
    *
    * Also callable by anyone externally.
    *
    * Non-view function - it stores the last good price seen by Liquity.
    *
    * Uses a main oracle Chainlink. If fail, 
    * it uses the last good price seen by Liquity.
    *
    */
    function fetchEntirePrice() external returns (uint256[] memory) {
        // Fire an event just like the mainnet version would.
        // This lets the subgraph rely on events to get the latest price even when developing locally.
        //emit LastGoodPriceUpdated(_price);
        uint[] memory _price = new uint[] (priceFeed.length-1);

        // _price[0] = fetchPrice(0);
        // _price[1] = fetchPrice(1);
        // _price[2] = fetchPrice(2);
        // _price[3] = fetchPrice(3);
        // _price[4] = fetchPrice(4);
        // _price[5] = fetchWrappedTokenPrice(5,5,6);

        for(uint i = 0; i < _price.length; i++) {
            if((i+1) == _price.length){
                _price[i] = fetchWrappedTokenPrice(i,i,i+1);
            }
            else{
                _price[i] = fetchPrice(i);
            }
        }

        return _price;
    }

    function fetchPrice(uint _collId) internal returns (uint last) {

        // Get current and previous price data from Chainlink, and current price data from Tellor
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse(_collId);
        ChainlinkResponse memory prevChainlinkResponse = _getPrevChainlinkResponse(_collId, chainlinkResponse.roundId, chainlinkResponse.decimals);

        // --- CASE 1: System fetched last price from Chainlink  ---
        if (status[_collId] == Status.chainlinkWorking) {
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {                
                // If Chainlink is broken, return 0
                _changeStatus(_collId, Status.chainlinkBroken);
                return 0;
            }

            // If Chainlink price has changed by > 50% between two consecutive rounds
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                _changeStatus(_collId, Status.chainlinkFrozen);
                return lastGoodPrice[_collId];
            }

            // If Chainlink is working, return Chainlink current price (no status change)
            return _storeChainlinkPrice(chainlinkResponse, _collId);
        }

        // --- CASE 2: untrusted at the last price fetch ---
        if (status[_collId] == Status.chainlinkFrozen) {
           // If Chainlink breaks, now both oracles are untrusted
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                _changeStatus(_collId, Status.chainlinkBroken);
                return lastGoodPrice[_collId];
            }

            // If Chainlink is frozen, return last good price (no status change)
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                return lastGoodPrice[_collId];
            }

            // If Chainlink is working, return Chainlink current price (no status change)
            return _storeChainlinkPrice(chainlinkResponse, _collId);
        }


        // --- CASE 3: untrusted at the last price fetch ---
         if (status[_collId] == Status.chainlinkBroken) {
            // If Chainlink breaks, now both oracles are untrusted
            if (_chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)) {
                _changeStatus(_collId, Status.chainlinkBroken);
                return lastGoodPrice[_collId];
            }

            // If Chainlink is frozen, return last good price (no status change)
            if (_chainlinkIsFrozen(chainlinkResponse)) {
                return lastGoodPrice[_collId];
            }

            // If Chainlink is live but deviated >50% from it's previous price and Tellor is still untrusted, switch 
            // to chainlinkBroken and return last good price
            if (_chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse)) {
                _changeStatus(_collId, Status.chainlinkBroken);
                return lastGoodPrice[_collId];
            }

            // Otherwise if Chainlink is live and deviated <50% from it's previous price and Tellor is still untrusted, 
            // return Chainlink price (no status change)
            return _storeChainlinkPrice(chainlinkResponse, _collId);
        }
    }

    function fetchCollPrice(uint _collId) external returns (uint last) {
        require(_collId < priceFeed.length-2,"");

        if(_collId == priceFeed.length-1) {
            fetchWrappedTokenPrice(5,5,6);
        }
        
        last = fetchPrice(_collId);
    }

    // --- Helper functions ---

    /* Chainlink is considered broken if its current or previous round data is in any way bad. We check the previous round
    * for two reasons:
    *
    * 1) It is necessary data for the price deviation check in case 1,
    * and
    * 2) Chainlink is the PriceFeed's preferred primary oracle - having two consecutive valid round responses adds
    * peace of mind when using or returning to Chainlink.
    */
    function _chainlinkIsBroken(ChainlinkResponse memory _currentResponse, ChainlinkResponse memory _prevResponse) internal view returns (bool) {
        return (_badChainlinkResponse(_currentResponse) || _badChainlinkResponse(_prevResponse));
    }

    function _badChainlinkResponse(ChainlinkResponse memory _response) internal view returns (bool) {
        // Check for response call reverted
        if (!_response.success) {return true;}
        // Check for an invalid roundId that is 0
        if (_response.roundId == 0) {return true;}
        // Check for an invalid timeStamp that is 0, or in the future
        if (_response.timestamp == 0 || _response.timestamp > block.timestamp) {return true;}
        // Check for non-positive price
        if (_response.answer <= 0) {return true;}

        return false;
    }

    function _chainlinkIsFrozen(ChainlinkResponse memory _response) internal view returns (bool) {
        // return false;
        return ((block.timestamp - _response.timestamp) > TIMEOUT);
    }

    function _chainlinkPriceChangeAboveMax(ChainlinkResponse memory _currentResponse, ChainlinkResponse memory _prevResponse) internal pure returns (bool) {
        uint currentScaledPrice = _scaleChainlinkPriceByDigits(uint256(_currentResponse.answer), _currentResponse.decimals);
        uint prevScaledPrice = _scaleChainlinkPriceByDigits(uint256(_prevResponse.answer), _prevResponse.decimals);

        uint minPrice = LiquityMath._min(currentScaledPrice, prevScaledPrice);
        uint maxPrice = LiquityMath._max(currentScaledPrice, prevScaledPrice);

        /*
        * Use the larger price as the denominator:
        * - If price decreased, the percentage deviation is in relation to the the previous price.
        * - If price increased, the percentage deviation is in relation to the current price.
        */
        uint percentDeviation = ((maxPrice - minPrice) * DECIMAL_PRECISION) / maxPrice;

        // Return true if price has more than doubled, or more than halved.
        return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
    }
    
    function _scaleChainlinkPriceByDigits(uint _price, uint _answerDigits) internal pure returns (uint) {
        /*
        * Convert the price returned by the Chainlink oracle to an 18-digit decimal for use by Liquity.
        * At date of Liquity launch, Chainlink uses an 8-digit price, but we also handle the possibility of
        * future changes.
        *
        */
        uint price;
        if (_answerDigits >= TARGET_DIGITS) {
            // Scale the returned price value down to Liquity's target precision
            price = _price / (10 ** (_answerDigits - TARGET_DIGITS));
        }
        else if (_answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Liquity's target precision
            price = _price * (10 ** (TARGET_DIGITS - _answerDigits));
        }
        return price;
    }

    function _changeStatus(uint _collId, Status _status) internal {
        status[_collId] = _status;
        emit PriceFeedStatusChanged(_status);
    }

    // function _storeChainlinkResponse(ChainlinkResponse memory _chainlinkResponse, uint _collId) internal returns (uint) {
    //     uint scaledChainlinkPrice = _scaleChainlinkPriceByDigits(uint256(_chainlinkResponse.answer), _chainlinkResponse.decimals);
    //     _storeResponse(_collId, scaledChainlinkPrice);

    //     return scaledChainlinkPrice;
    // }

    // function _storeResponse(uint _collId, uint _currentPrice) internal {
    //     response[_collId] = _currentPrice;
    //     emit LastGoodPriceUpdated(_currentPrice);
    // }

    function _storePrice(uint _collId, uint _currentPrice) internal {
        lastGoodPrice[_collId] = _currentPrice;
        emit LastGoodPriceUpdated(_currentPrice);
    }

    function _storeChainlinkPrice(ChainlinkResponse memory _chainlinkResponse, uint _collId) internal returns (uint) {
        uint scaledChainlinkPrice = _scaleChainlinkPriceByDigits(uint256(_chainlinkResponse.answer), _chainlinkResponse.decimals);
        _storePrice(_collId, scaledChainlinkPrice);

        return scaledChainlinkPrice;
    }

    // --- Oracle response wrapper functions ---

    function _getCurrentChainlinkResponse(uint _collId) internal view returns (ChainlinkResponse memory chainlinkResponse) {
        // First, try to get current decimal precision:
        try priceFeed[_collId].decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponse.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // Secondly, try to get latest price data:
        try priceFeed[_collId].latestRoundData() returns
        (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = answer;
            chainlinkResponse.timestamp = timestamp;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }
    }

    function _getPrevChainlinkResponse(uint _collId, uint80 _currentRoundId, uint8 _currentDecimals) internal view returns (ChainlinkResponse memory prevChainlinkResponse) {
        /*
        * NOTE: Chainlink only offers a current decimals() value - there is no way to obtain the decimal precision used in a 
        * previous round.  We assume the decimals used in the previous round are the same as the current round.
        */

        // Try to get the price data from the previous round:
        try priceFeed[_collId].getRoundData(_currentRoundId - 1) returns 
        (
            uint80 roundId,
            int256 answer,
            uint256 /* startedAt */,
            uint256 timestamp,
            uint80 /* answeredInRound */
        )
        {
            // If call to Chainlink succeeds, return the response and success = true
            prevChainlinkResponse.roundId = roundId;
            prevChainlinkResponse.answer = answer;
            prevChainlinkResponse.timestamp = timestamp;
            prevChainlinkResponse.decimals = _currentDecimals;
            prevChainlinkResponse.success = true;
            return prevChainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return prevChainlinkResponse;
        }
    }

    function collPriceDecimals() public view returns(uint[] memory) {
        uint[] memory decimals = new uint[] (priceFeed.length);
        for(uint i = 0; i < priceFeed.length; i++) {
            decimals[i] = priceFeed[i].decimals();
        }
        return(decimals);
    }
}
