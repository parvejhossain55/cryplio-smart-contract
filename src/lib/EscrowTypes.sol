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
        address indexed buyer,
        uint256 amount,
        uint256 timestamp
    );

    event EscrowRefunded(
        bytes32 indexed tradeId,
        address indexed seller,
        uint256 amount,
        uint256 timestamp
    );

    event FeeCollected(
        bytes32 indexed tradeId,
        address indexed token,
        address feeRecipient,
        uint256 feeAmount,
        uint256 timestamp
    );

    event EscrowForceReleased(
        bytes32 indexed tradeId,
        address indexed buyer,
        uint256 amount,
        address indexed releasedBy,
        uint256 timestamp
    );

    // Admin events
    event AuthorizedSignerAdded(address indexed signer, address indexed addedBy);
    event AuthorizedSignerRemoved(address indexed signer, address indexed removedBy);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event TokenSupportedAdded(address indexed token);
    event TokenSupportedRemoved(address indexed token);

    // Structs
    struct Escrow {
        bytes32 tradeId;
        address buyer;
        address seller;
        address token;
        uint256 amount;
        uint48 expiresAt;
        EscrowStatus status;
    }

    // ENUM
    enum EscrowStatus {
        Locked,
        Released,
        Refunded
    }
    
    // Constants
    uint256 public constant MIN_EXPIRY_TIME = 5 minutes; // Minimum 5 minutes
    uint256 public constant MAX_EXPIRY_TIME = 30 days; // Maximum 30 days
    
    // Errors
    error EscrowNotFound();
    error EscrowAlreadyExists();
    error InvalidTradeId();
    error InvalidAddresses();
    error BuyerCannotBeSeller();
    error InvalidAmount();
    error InvalidStatus();
    error Unauthorized();
    error UnsupportedToken();
    error CannotRefund();
    error NotAuthorizedSigner();
    error EscrowExpired();
    error InvalidSigner();
    error InvalidExpiryTime();
    error InvalidSignature();
    error NonceAlreadyUsed();

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
        if (buyer == seller) {
            revert BuyerCannotBeSeller();
        }
    }

    function validateAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert InvalidAmount();
        }
    }

    function validateExpiryTime(uint256 expiryTime) internal pure {
        if (expiryTime < MIN_EXPIRY_TIME || expiryTime > MAX_EXPIRY_TIME) {
            revert InvalidExpiryTime();
        }
    }

    function validateEscrowExists(bool exists) internal pure {
        if (exists) {
            revert EscrowAlreadyExists();
        }
    }

    function validateTokenSupported(bool supported) internal pure {
        if (!supported) {
            revert UnsupportedToken();
        }
    }

    function isExpired(uint256 expiresAt) internal view returns (bool) {
        return block.timestamp > expiresAt;
    }

    function canRefund(uint256 expiresAt) internal view returns (bool) {
        return isExpired(expiresAt);
    }
}