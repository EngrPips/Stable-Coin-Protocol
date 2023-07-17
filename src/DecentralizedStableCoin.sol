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

import {ERC20Burnable, ERC20} from "@openzeppelin-contracts/token/ERC20/extensions/ERC20Burnable.sol";


/**
 * @title DecentralizedStableCoin
 * @author EngrPips
 * @notice This stable is minted with deposited collateral in weth or wbtc
 * @notice This contract is the implementation of our Protocol stable coin which will be govern by DSCEngine contract.
 * Collateral: Exognenous
 * Stability Mechanism: Algorithmic 
 * Relative Stability: Peggged(USD)
 * 
 */
contract DecentralizedStableCoin {

}