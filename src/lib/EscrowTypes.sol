// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Cryplio EscrowTypes
 * @dev Library containing types, constants, events and error for escrow contracts
 */

library EscrowTypes {
    // Events
    event EscrowCreated(
        bytes32 indexed tradeId,
        address indexed buyer,
        address indexed seller,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    event EscrowReleased(
        bytes32 indexed tradeId,
        address indexed seller,
        uint256 amount,
        uint256 timestamp
    );

    event EscrowRefunded(
        bytes32 indexed tradeId,
        address indexed buyer,
        uint256 amount,
        uint256 timestamp
    );

    // Structs
    struct Escrow {
        bytes32 tradeId;
        address buyer;
        address seller;
        address token;
        uint256 amount;
        uint256 expiresAt;
        EscrowStatus status;
    }

    // ENUM
    enum EscrowStatus {
        Locked,
        Released,
        Refunded
    }
    
    // Constants
    uint256 public constant ESCROW_EXPIRY_TIME = 1 hours; // 1 hours for payment
    
    // Errors
    error EscrowNotFound();
    error EscrowAlreadyExists();
    error InvalidTradeId();
    error InvalidAddresses();
    error InvalidAmount();
    error InvalidStatus();
    error Unauthorized();
    error UnsupportedToken();
    error CannotRefund();
    error NotAuthorizedSigner();
    error EscrowExpired();

    // Validation functions
    function validateTradeId(bytes32 tradeId) internal pure {
        if (tradeId == bytes32(0)) {
            revert InvalidTradeId();
        }
    }

    function validateAddresses(address buyer, address seller) internal pure {
        if (buyer == address(0) || seller == address(0)) {
            revert InvalidAddresses();
        }
    }

    function validateAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert InvalidAmount();
        }
    }

    function isExpired(uint256 expiresAt) internal view returns (bool) {
        return block.timestamp > expiresAt;
    }

    function canRefund(uint256 expiresAt) internal view returns (bool) {
        return isExpired(expiresAt);
    }
}