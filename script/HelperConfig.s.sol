//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.18;

import {Script} from "forge-std/Script.sol";
import {AggregatorV3Mock} from "../test/mocks/AggregatorV3Mock.sol";
import {ERC20Mock} from "@openzeppelin-contracts/mocks/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address wethPriceFeedAddress;
        address wbtcPriceFeedAddress;
        address wethAddress;
        address wbtcAddress;
        uint256 deployerKey;
    }

    uint8 public constant DECIMALS = 8;
    int256 public constant WETH_PRICEFEED_INITIAL_ANSWER = 2000e8;
    int256 public constant WBTC_PRICEFEED_INITIAL_ANSWER = 4000e8;

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = createOrGetAnvilConfig();
        }
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            wethPriceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wbtcPriceFeedAddress: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            wethAddress: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wbtcAddress: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });

        return sepoliaNetworkConfig;
    }

    function createOrGetAnvilConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        if (activeNetworkConfig.wethPriceFeedAddress != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        AggregatorV3Mock wethPriceFeed = new AggregatorV3Mock(DECIMALS, WETH_PRICEFEED_INITIAL_ANSWER);
        AggregatorV3Mock wbtcPriceFeed = new AggregatorV3Mock(DECIMALS, WBTC_PRICEFEED_INITIAL_ANSWER);
        ERC20Mock wethMock = new ERC20Mock();
        ERC20Mock wbtcMock = new ERC20Mock();
        vm.stopBroadcast();

        anvilNetworkConfig = NetworkConfig({
            wethPriceFeedAddress: address(wethPriceFeed),
            wbtcPriceFeedAddress: address(wbtcPriceFeed),
            wethAddress: address(wethMock),
            wbtcAddress: address(wbtcMock),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });

        return anvilNetworkConfig;
    }
}
