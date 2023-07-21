//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.18;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";


contract DeployDSC is Script {
    // address wethPriceFeedAddress;
    // address wbtcPriceFeedAddress;
    // address wethAddress;
    // address wbtcAddress;
    // uint256 deployerKey;

    address[] public collateralTokenAdresses;
    address[] public priceFeedAddressesForCollateralToken;

    address user = makeAddr("USER");

    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (address wethPriceFeedAddress, address wbtcPriceFeedAddress, address wethAddress,address wbtcAddress, uint256 deployerKey) = config.activeNetworkConfig();

        collateralTokenAdresses = [wethAddress, wbtcAddress];

        priceFeedAddressesForCollateralToken = [wethPriceFeedAddress, wbtcPriceFeedAddress];

        vm.startBroadcast(user);
        DecentralizedStableCoin DSC = new DecentralizedStableCoin();
        DSCEngine DSCE = new DSCEngine(collateralTokenAdresses, priceFeedAddressesForCollateralToken, address(DSC));
        DSC.transferOwnership(address(DSCE));
        vm.stopBroadcast();

        return (DSC, DSCE, config);
    }
}
