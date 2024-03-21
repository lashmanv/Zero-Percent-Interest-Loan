// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC2612.sol";

interface IZUSDToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event TroveManager1AddressChanged(address _troveManager1Address);
    event TroveManager2AddressChanged(address _troveManager2Address);
    event TroveManager3AddressChanged(address _troveManager3Address);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event ZUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}
