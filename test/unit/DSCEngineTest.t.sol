//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin-contracts/mocks/ERC20Mock.sol";

import {MockCollateralTokenFailTransferFrom} from "../mocks/MockCollateralTokenFailTransferFrom.sol";

import {MockCollateralTokenFailMint} from "../mocks/MockCollateralTokenFailMint.sol";

contract DSCEngineTest is Test {
    HelperConfig public config;
    DecentralizedStableCoin public DSC;
    DSCEngine public DSCE;
    MockCollateralTokenFailTransferFrom public MCTD;
    MockCollateralTokenFailMint public MCTM;

    address wethPriceFeedAddress;
    address wbtcPriceFeedAddress;
    address wethAddress;
    address wbtcAddress;
    uint256 deployerKey;

    address[] testCollateralTokenAddresses;
    address[] testPriceFeedAddresses;

    address[] mocktestCollateralTokenAddresses;

    address user = makeAddr("USER");
    address unSupportedCollateralToken = 0xAA289f64F48529eE6078860Da0fF4800c6ECEdA8;

    uint256 private constant COLLATERAL_AMOUNT = 1 ether;
    uint256 private constant STARTING_BALANCE = 10 ether;
    uint256 private constant APPROPRIATE_DSC_MINT = 0.1 ether;
    uint256 private constant APPROPRIATE_DSC_BURN = 0.1 ether;
    uint256 private constant PART_OF_TOTAL_COLLATERAL = 0.5 ether;

    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (DSC, DSCE, config) = deployer.run();
        (wethPriceFeedAddress, wbtcPriceFeedAddress, wethAddress, wbtcAddress,) = config.activeNetworkConfig();

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

    function testThatThePriceFeedsPassedInToTheConstructorArePushedToOurStateVariable() public {
        testPriceFeedAddresses = [wethAddress, wbtcAddress];
        console.log(wethAddress);
        console.log(wbtcAddress);
        assertEq(
            keccak256(abi.encodePacked(testPriceFeedAddresses)),
            keccak256(abi.encodePacked(DSCE.getTokensSupportedAsCollateralOnThisProtocol()))
        );
    }

    //////////////////////////
    /// DEPOSIT TEST       ///
    //////////////////////////

    modifier depositZeroCollateral() {
        vm.startPrank(user);
        ERC20Mock(wethAddress).approve(address(DSCE), COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine__AmountNeedsToBeMoreThanZero.selector);
        DSCE.depositCollateral(wethAddress, 0);
        _;
    }

    modifier depositCollateral() {
        vm.startPrank(user);
        ERC20Mock(wethAddress).approve(address(DSCE), COLLATERAL_AMOUNT);
        DSCE.depositCollateral(wethAddress, COLLATERAL_AMOUNT);
        _;
    }

    modifier depositSetUpForExceptionalCase() {
        MCTD = new MockCollateralTokenFailTransferFrom();
        mocktestCollateralTokenAddresses = [address(MCTD), wbtcAddress];
        testPriceFeedAddresses = [wethPriceFeedAddress, wbtcPriceFeedAddress];
        DSCEngine mockDSCE = new DSCEngine(mocktestCollateralTokenAddresses, testPriceFeedAddresses, address(MCTD));

        MCTD.mint(user, STARTING_BALANCE);
        vm.prank(user);
        MCTD.approve(address(mockDSCE), COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine__TransferFailed.selector);
        vm.prank(user);
        mockDSCE.depositCollateral(address(MCTD), COLLATERAL_AMOUNT);
        _;
    }

    modifier mintSetUpForExceptionalCase() {
        MCTM = new MockCollateralTokenFailMint();
        mocktestCollateralTokenAddresses = [address(MCTM), wbtcAddress];
        testPriceFeedAddresses = [wethPriceFeedAddress, wbtcPriceFeedAddress];
        DSCEngine mockDSCE = new DSCEngine(mocktestCollateralTokenAddresses, testPriceFeedAddresses, address(MCTM));

        MCTM.mint(user, STARTING_BALANCE);
        vm.prank(user);
        MCTM.approve(address(mockDSCE), COLLATERAL_AMOUNT);

        MCTM.transferOwnership(address(mockDSCE));

        vm.prank(user);
        mockDSCE.depositCollateral(address(MCTM), COLLATERAL_AMOUNT);

        vm.expectRevert(DSCEngine.DSCEngine__MintingFailed.selector);

        vm.prank(user);
        mockDSCE.mintDSC(0.25 ether);
        _;
    }

    function testThatUserCannotDepositZeroCollateral() public depositZeroCollateral {}

    function testThatTransactionRevertIfUserTryToDepositUnsupportedCollateral() public {
        vm.startPrank(user);
        ERC20Mock(wethAddress).approve(address(DSCE), COLLATERAL_AMOUNT);
        vm.expectRevert(DSCEngine.DSCEngine__YouCanOnlyDepositCollateralForSupportedToken.selector);
        DSCE.depositCollateral(unSupportedCollateralToken, COLLATERAL_AMOUNT);
        vm.stopPrank();
    }

    function testUserCanSuccessfullyDepositCollateral() public depositCollateral {}

    function testUserSuccessfullyDepositAndTheirCollateralBalanceUpdated() public depositCollateral {
        uint256 expectedUserCollateralBalance = 1 ether;
        uint256 actualUserCollateralBalance =
            DSCE.getTotalCollateralDepositedByAUserOnAParticularCollateralToken(address(user), wethAddress);
        assertEq(expectedUserCollateralBalance, actualUserCollateralBalance);
    }

    function testProtocolProperlyUpdateOverallBalanceOfUserAfterDeposit() public depositCollateral {
        uint256 expectedUserTotalCollateralBalance = 1 ether;
        uint256 actualUserTotalCollateralBalance = DSCE.getTotalCollateralDepositedByAUser(user);
        assertEq(expectedUserTotalCollateralBalance, actualUserTotalCollateralBalance);
    }

    function testRevertIfTransferFailsDuringDepositing() public depositSetUpForExceptionalCase {}

    //////////////////////////
    /// MINT TEST          ///
    //////////////////////////

    function testCantMintZeroDSC() public depositCollateral {
        vm.expectRevert(DSCEngine.DSCEngine__AmountNeedsToBeMoreThanZero.selector);
        DSCE.mintDSC(0);
    }

    function testUserDebtIsProperlyUpdatedOnSuccessfulMint() public depositCollateral {
        DSCE.mintDSC(0.1 ether);
        uint256 expectedUserDebt = 0.1 ether;
        uint256 actualUserDebt = DSCE.getAmountOfDebtMintedByAUser(user);

        assertEq(expectedUserDebt, actualUserDebt);
    }

    function testRevertWhenMintingFails() public mintSetUpForExceptionalCase {}

    ///////////////////////////////////
    ///DEPOSIT AND MINT TEST          ///
    ///////////////////////////////////

    modifier DepositAndMintDSC() {
        vm.startPrank(user);
        ERC20Mock(wethAddress).approve(address(DSCE), COLLATERAL_AMOUNT);
        DSCE.depositCollateralAndMintDSC(COLLATERAL_AMOUNT, wethAddress, APPROPRIATE_DSC_MINT);
        vm.stopPrank();
        _;
    }

    function testSuccessfullyDepositAndMintDSC() public DepositAndMintDSC {
        assertEq(DSCE.getAmountOfDebtMintedByAUser(user), APPROPRIATE_DSC_MINT);
    }

    //////////////////////////
    /// BURN TEST          ///
    //////////////////////////

    function testCanNotBurnZeroDSC() public DepositAndMintDSC {
        vm.expectRevert(DSCEngine.DSCEngine__AmountNeedsToBeMoreThanZero.selector);
        DSCE.burnDSC(0);
    }

    function testCanBurnDSC() public DepositAndMintDSC {
        vm.startPrank(user);
        (DSC).approve(address(DSCE), APPROPRIATE_DSC_BURN);
        DSCE.burnDSC(APPROPRIATE_DSC_BURN);
        assertEq(DSCE.getAmountOfDebtMintedByAUser(user), 0);
    }

    //////////////////////////
    /// REDEEM TEST        ///
    //////////////////////////

    function testCanRedeemCollateralWithoutMintingDebt() public depositCollateral {
        vm.startPrank(user);
        ERC20Mock(wethAddress).approve(address(DSCE), COLLATERAL_AMOUNT);
        DSCE.redeemCollateral(wethAddress, COLLATERAL_AMOUNT);
        uint256 userCollateralBalance =
            DSCE.getTotalCollateralDepositedByAUserOnAParticularCollateralToken(user, wethAddress);
        assertEq(userCollateralBalance, 0);
    }

    function testCanRedeemSomeAmountOfYourCollateral() public depositCollateral {
        vm.startPrank(user);
        // ERC20Mock(wethAddress).approve(address(DSCE), PART_OF_TOTAL_COLLATERAL);
        DSCE.redeemCollateral(wethAddress, PART_OF_TOTAL_COLLATERAL);
        uint256 userCollateralBalance =
            DSCE.getTotalCollateralDepositedByAUserOnAParticularCollateralToken(user, wethAddress);
        assertEq(userCollateralBalance, 0.5 ether);
    }

    function testCannotRedeemZeroAmountOfCollateral() public depositCollateral {
        vm.expectRevert(DSCEngine.DSCEngine__AmountNeedsToBeMoreThanZero.selector);
        DSCE.redeemCollateral(wethAddress, 0);
    }

    function testCanReedemCollateralForDSC() public DepositAndMintDSC {
        vm.startPrank(user);
        DSC.approve(address(DSCE), APPROPRIATE_DSC_MINT);
        DSCE.redeemCollateralForDSC(wethAddress, APPROPRIATE_DSC_MINT);
        uint256 userDebtAmount = DSCE.getAmountOfDebtMintedByAUser(user);
        assertEq(userDebtAmount, 0);
    }

    //////////////////////////
    /// LIQUIDATION TEST   ///
    //////////////////////////
}
