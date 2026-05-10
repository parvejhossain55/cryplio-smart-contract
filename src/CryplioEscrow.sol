// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./base/EscrowOperations.sol";
import "./base/EscrowViews.sol";

/**
 * @title CryplioEscrow
 * @dev Main escrow contract combining operations and views
 */
contract CryplioEscrow is EscrowOperations, EscrowViews {
    // Events are inherited from EscrowOperations

    constructor(address[] memory _initialTokens)
        EscrowOperations(_initialTokens)
    {}
}