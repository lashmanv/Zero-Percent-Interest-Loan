// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./../Interfaces/IZQTYToken.sol";
import "./../Interfaces/ICommunityIssuance.sol";
import "./../Dependencies/BaseMath.sol";
import "./../Dependencies/LiquityMath.sol";
import "./../Dependencies/Ownable.sol";
import "./../Dependencies/CheckContract.sol";


contract CommunityIssuance is ICommunityIssuance, Ownable, CheckContract, BaseMath {

    // --- Data ---

    string constant public NAME = "CommunityIssuance";

    uint constant public SECONDS_IN_ONE_MINUTE = 60;

   /* The issuance factor F determines the curvature of the issuance curve.
    *
    * Minutes in one year: 60*24*365 = 525600
    *
    * For 50% of remaining tokens issued each year, with minutes as time units, we have:
    * 
    * F ** 525600 = 0.5
    * 
    * Re-arranging:
    * 
    * 525600 * ln(F) = ln(0.5)
    * F = 0.5 ** (1/525600)
    * F = 0.999998681227695000 
    */
    uint constant public ISSUANCE_FACTOR = 999998681227695000;

    /* 
    * The community ZQTY supply cap is the starting balance of the Community Issuance contract.
    * It should be minted to this contract by ZQTYToken, when the token is deployed.
    * 
    * Set to 32M (slightly less than 1/3) of total ZQTY supply.
    */
    uint constant public ZQTYSupplyCap = 32e24; // 32 million

    IZQTYToken public zqtyToken;

    address public stabilityPoolAddress;

    uint public totalZQTYIssued;
    uint public immutable deploymentTime;

    // --- Functions ---

    constructor() {
        deploymentTime = block.timestamp;
    }

    function setAddresses
    (
        address _zqtyTokenAddress, 
        address _stabilityPoolAddress
    ) 
        external 
        onlyOwner 
        override 
    {
        checkContract(_zqtyTokenAddress);
        checkContract(_stabilityPoolAddress);

        zqtyToken = IZQTYToken(_zqtyTokenAddress);
        stabilityPoolAddress = _stabilityPoolAddress;

        // When ZQTYToken deployed, it should have transferred CommunityIssuance's ZQTY entitlement
        uint ZQTYBalance = zqtyToken.balanceOf(address(this));
        assert(ZQTYBalance >= ZQTYSupplyCap);

        emit ZQTYTokenAddressSet(_zqtyTokenAddress);
        emit StabilityPoolAddressSet(_stabilityPoolAddress);

        _renounceOwnership();
    }

    function issueZQTY() external override returns (uint) {
        _requireCallerIsStabilityPool();

        uint latestTotalZQTYIssued = ZQTYSupplyCap * (_getCumulativeIssuanceFraction()) / (DECIMAL_PRECISION);
        uint issuance = latestTotalZQTYIssued - (totalZQTYIssued);

        totalZQTYIssued = latestTotalZQTYIssued;
        emit TotalZQTYIssuedUpdated(latestTotalZQTYIssued);
        
        return issuance;
    }

    /* Gets 1-f^t    where: f < 1

    f: issuance factor that determines the shape of the curve
    t:  time passed since last ZQTY issuance event  */
    function _getCumulativeIssuanceFraction() internal view returns (uint) {
        // Get the time passed since deployment
        uint timePassedInMinutes = block.timestamp - (deploymentTime) / (SECONDS_IN_ONE_MINUTE);

        // f^t
        uint power = LiquityMath._decPow(ISSUANCE_FACTOR, timePassedInMinutes);

        //  (1 - f^t)
        uint cumulativeIssuanceFraction = (uint(DECIMAL_PRECISION) - (power));
        assert(cumulativeIssuanceFraction <= DECIMAL_PRECISION); // must be in range [0,1]

        return cumulativeIssuanceFraction;
    }

    function sendZQTY(address _account, uint _ZQTYamount) external override {
        _requireCallerIsStabilityPool();

        zqtyToken.transfer(_account, _ZQTYamount);
    }

    // --- 'require' functions ---

    function _requireCallerIsStabilityPool() internal view {
        require(msg.sender == stabilityPoolAddress, "CommunityIssuance: caller is not SP");
    }
}
