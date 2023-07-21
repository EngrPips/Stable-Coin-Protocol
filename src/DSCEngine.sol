//SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^ 0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin-contracts/interfaces/IERC20.sol";
import {AggregatorV3Interface} from
    "@chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
 * @title DSCEngine
 * @author EngrPips
 * @notice This contract controls the stable coin contract of this protocol
 * This system is design to be as minimalistic as possible and it is design in such a way that 1 token is always equal 1$
 * This system stable coin has the below feature
 * - Relative Stability -> Pegged(USD)
 * - Stability Mechanism -> Algorithmic
 * - Collateral Type -> Exogenous(weth, wbtc)
 * @notice This system is highly collateralized (you can only mint half the value of whatever collateral you provide), This system is loosely based on the MakeDAO DSC (DAI)
 */
contract DSCEngine is ReentrancyGuard {
    // interfaces, libraries, contracts

    // errors
    error DSCEngine__AmountNeedsToBeMoreThanZero();
    error DSCEngine__LengthOfCollateralArrayAndPriceFeedArrayNeedToBeEqual();
    error DSCEngine__YouCanOnlyDepositCollateralForSupportedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__HealthFactorShouldAlwaysBeGreaterThanOne(uint256 _userHealthFactor);
    error DSCEngine__MintingFailed();

    // Type declarations

    // State variables
    uint256 private constant PRESICION_TO_RAISE_PRICE_DECIMAL = 1e10;
    uint256 private constant STANDARD_DECIMAL = 1e18;
    uint256 private constant PROTOCOL_THRESHOLD = 50;
    uint256 private constant PROTOCOL_PRECISION = 100;
    uint256 private constant MINIMUM_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_collateralTokenToPriceFeed;
    mapping(address user => mapping(address collateralToken => uint256 amountDeposited)) private
        s_userToAmountDepositedOnVariousCollateralToken;
    mapping(address user => uint256 amountOfDSCMinted) private s_userToTheAmountOfDSCMinted;
    address[] private s_protocolSupportedCollateralToken;

    DecentralizedStableCoin private immutable i_DSC;

    // Events
    event CollateralDeposited(
        address indexed _depositor, address indexed _collateralTokenAddress, uint256 indexed _amountDeposited
    );

    // Modifiers

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) revert DSCEngine__AmountNeedsToBeMoreThanZero();
        _;
    }

    modifier onlySupportedTokenAddress(address _collateralTokenAddress) {
        if (s_collateralTokenToPriceFeed[_collateralTokenAddress] == address(0)) {
            revert DSCEngine__YouCanOnlyDepositCollateralForSupportedToken();
        }
        _;
    }

    //////////////////
    // Functions   //
    /////////////////

    // constructor
    constructor(address[] memory _collateralTokenAddress, address[] memory _priceFeedAddress, address _DSC) {
        if (_collateralTokenAddress.length == _priceFeedAddress.length) {
            revert DSCEngine__LengthOfCollateralArrayAndPriceFeedArrayNeedToBeEqual();
        }
        for (uint256 i = 0; i < _collateralTokenAddress.length; i++) {
            s_collateralTokenToPriceFeed[_collateralTokenAddress[i]] = _priceFeedAddress[i];
            s_protocolSupportedCollateralToken.push(_collateralTokenAddress[i]);
        }

        i_DSC = DecentralizedStableCoin(_DSC);
    }

    // receive function (if exists)

    // fallback function (if exists)

    // external
    function depositCollateral(address _collateralTokenAddress, uint256 _depositAmount)
        external
        moreThanZero(_depositAmount)
        onlySupportedTokenAddress(_collateralTokenAddress)
        nonReentrant
    {
        s_userToAmountDepositedOnVariousCollateralToken[msg.sender][_collateralTokenAddress] += _depositAmount;
        emit CollateralDeposited(msg.sender, _collateralTokenAddress, _depositAmount);
        bool success = IERC20(_collateralTokenAddress).transferFrom(msg.sender, address(this), _depositAmount);
        if (!success) revert DSCEngine__TransferFailed();
    }

    /*
     * 
     * @param _amountOfDSCToMint -> The amount of DSC the user wants to mint, this function would actually have to be pre-processed by making sure some important criteria are met, the following below condition should be met
     * -> The user must not be able to mint the amount of DSC that would break their health factor, making sure of this involve the below procedures
     * 1) getting the equivalent price of the collateral the user is depositing in USD
     * 2) convert their deposited collateral to USD equivalent in the process before minting
     * 3) calculate their helath factor using the USD value of their deposited collateral and making sure their health factor is intact
     */
    function mintDSC(uint256 _amountOfDSCToMint) external moreThanZero(_amountOfDSCToMint) nonReentrant {
        s_userToTheAmountOfDSCMinted[msg.sender] += _amountOfDSCToMint;
        _revertIfhealthFactorIsBroken(msg.sender);
        bool minted = i_DSC.mint(msg.sender, _amountOfDSCToMint);
        if (!minted) revert DSCEngine__MintingFailed();
    }

    // public
    function getUSDValueOfCollateral(address _tokenAddress, uint256 _amount)
        public
        view
        returns (uint256 USDValueOfCollateral)
    {
        AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(s_collateralTokenToPriceFeed[_tokenAddress]);
        (, int256 price,,,) = tokenPriceFeed.latestRoundData();
        USDValueOfCollateral = (_amount * (uint256(price) * PRESICION_TO_RAISE_PRICE_DECIMAL)) / STANDARD_DECIMAL;

        return USDValueOfCollateral;
    }

    function getAUserTotalCollateralValueInUSD(address _user)
        public
        view
        returns (uint256 _totalCollateralValueInUSD)
    {
        for (uint256 i; i < s_protocolSupportedCollateralToken.length; i++) {
            address token = s_protocolSupportedCollateralToken[i];
            uint256 amount = s_userToAmountDepositedOnVariousCollateralToken[_user][token];
            _totalCollateralValueInUSD += getUSDValueOfCollateral(token, amount);
        }

        return _totalCollateralValueInUSD;
    }

    // internal

    // private
    function getUserInformation(address _user)
        public
        view
        returns (uint256 _totalDSCMinted, uint256 _totalUserCollateralValueInUSD)
    {
        _totalDSCMinted = s_userToTheAmountOfDSCMinted[_user];
        _totalUserCollateralValueInUSD = getAUserTotalCollateralValueInUSD(_user);
        return (_totalDSCMinted, _totalUserCollateralValueInUSD);
    }

    function _revertIfhealthFactorIsBroken(address _user) private view {
        (uint256 _totalDSCMinted, uint256 _totalUserCollateralValueInUSD) = getUserInformation(_user);
        (uint256 healthFactor) = calculateHealthFactor(_totalDSCMinted, _totalUserCollateralValueInUSD);
        if (healthFactor < MINIMUM_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorShouldAlwaysBeGreaterThanOne(healthFactor);
        }
    }

    function calculateHealthFactor(uint256 _amountOfDSCMinted, uint256 _collateralValueInUSD)
        public
        pure
        returns (uint256 healthFactor)
    {
        uint256 thresholdCollateralValueInUsd = (_collateralValueInUSD * PROTOCOL_THRESHOLD) / PROTOCOL_PRECISION;
        if (_amountOfDSCMinted == 0) return healthFactor = type(uint256).max;
        healthFactor = (thresholdCollateralValueInUsd * STANDARD_DECIMAL) / _amountOfDSCMinted;
        return healthFactor;
    }

    // view & pure functions
}
