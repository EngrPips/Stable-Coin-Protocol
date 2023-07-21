//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin-contracts/mocks/ERC20Mock.sol";


contract DSCEngineTest is Test {
    HelperConfig public config;
    DecentralizedStableCoin public DSC;
    DSCEngine public DSCE;

    address wethPriceFeedAddress;
    address wbtcPriceFeedAddress;
    address wethAddress;
    address wbtcAddress;
    uint256 deployerKey;

    address[] testCollateralTokenAddresses;
    address[] testPriceFeedAddresses;

    address user = makeAddr("USER");
    uint256 private constant COLLATERAL_AMOUNT = 1 ether;
    uint256 private constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (DSC, DSCE, config) = deployer.run();
        (wethPriceFeedAddress,,wethAddress,,) = config.activeNetworkConfig();

        ERC20Mock(wethAddress).mint(user, STARTING_BALANCE);
    }

    //////////////////////////
    /// CONSTRUCTOR TEST     ///
    //////////////////////////

    function testItRevertIfTheLengthOfPriceFeedArrayAndCollateralTokenArrayAreNotEqual() public {
        testCollateralTokenAddresses = [wethAddress, wbtcAddress];
        testPriceFeedAddresses = [wethPriceFeedAddress];

        vm.expectRevert(DSCEngine.DSCEngine__LengthOfCollateralArrayAndPriceFeedArrayNeedToBeEqual.selector);
        new DSCEngine(testCollateralTokenAddresses, testPriceFeedAddresses, address(DSC));
    }
}