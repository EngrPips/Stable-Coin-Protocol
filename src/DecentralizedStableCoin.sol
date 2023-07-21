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
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";

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
contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__AmountToBurnMustBeGreaterThanZero();
    error DecentralizedStableCoin__AmountToMintMustBeGreaterThanZero();
    error DecentralizedStableCoin__YouCantBurnMoreThanYouHave();
    error DecentralizedStableCoin__YouCantMintToAddressZero();

    constructor() ERC20("DecentralizedStableCoin", "DSC") {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);

        if (_amount < 0) {
            revert DecentralizedStableCoin__AmountToBurnMustBeGreaterThanZero();
        }
        if (_amount > balance) {
            revert DecentralizedStableCoin__YouCantBurnMoreThanYouHave();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__YouCantMintToAddressZero();
        }
        if (_amount == 0) {
            revert DecentralizedStableCoin__AmountToMintMustBeGreaterThanZero();
        }

        _mint(_to, _amount);

        return true;
    }
}
