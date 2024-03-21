// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

// import "./IPriceFeed.sol";
// import "./ITellorCaller.sol";
// import "./SafeMath.sol";
import "./Ownable.sol";
import "./CheckContract.sol";
// import "./BaseMath.sol";
// import "./LiquityMath.sol";
// import "./console.sol";

contract PriceOracle is Ownable, CheckContract{
    // using SafeMath for uint256;

    string constant public NAME = "PriceOracle";

    AggregatorInterface[] priceFeed;
     // Core Liquity contracts
    address borrowerOperationsAddress;
    address troveManagerAddress;


   // DAI/USD: 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9
   // AAVE/USD: 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9
   // WETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
   // WBTC/USD: 0x230E0321Cf38F09e247e50Afc7801EA2351fe56F
   // ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
   // STETH/USD: 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8
    address[] priceFeeds = [0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9,  0x547a514d5e3769680Ce22B2361c10Ea13619e8a9, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, 0x230E0321Cf38F09e247e50Afc7801EA2351fe56F, 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8];

    function setAddresses() external onlyOwner {
        // Get an initial price from Chainlink to serve as first reference for lastGoodPrice
        for(uint i = 0; i < priceFeeds.length; i++) {
            checkContract(priceFeeds[i]);

            priceFeed.push(AggregatorInterface(priceFeeds[i]));

        }
    }

    function getPrice(uint256 _tokenId) public view returns (int256){
        return priceFeed[_tokenId].latestAnswer();
    }

    function getEntirePrice() public view returns(int256[] memory){
        int256[] memory prices = new int256[](priceFeed.length);

        for(uint i=0; i< prices.length; i++){
            prices[i] = priceFeed[i].latestAnswer();
        }

        return prices;
    }

}