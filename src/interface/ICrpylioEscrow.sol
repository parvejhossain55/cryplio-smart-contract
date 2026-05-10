// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/EscrowTypes.sol";

/**
 * @title ICryplioEscrow
 * @dev Interface for core escrow functionality
 * @notice All events are inherited from EscrowTypes to avoid duplication
 */
interface ICryplioEscrow {
    // Core functions
    function createEscrow(
        bytes32 tradeId,
        address buyer,
        address seller,
        address token,
        uint256 amount,
        uint256 expiryTime
    ) external returns (bool);

    function releaseEscrow(bytes32 tradeId) external returns (bool);
    
    function refundEscrow(bytes32 tradeId) external returns (bool);

    function forceReleaseEscrow(bytes32 tradeId) external returns (bool);

    // Admin functions
    function addAuthorizedSigner(address signer) external;
    function removeAuthorizedSigner(address signer) external;
    function setFeeRecipient(address _feeRecipient) external;
    function addSupportedToken(address token) external;
    function removeSupportedToken(address token) external;

    // View functions
    function getEscrow(bytes32 tradeId) 
    external 
    view 
    returns (
        address buyer,
        address seller,
        address token,
        uint256 amount,
        uint256 expiresAt,
        EscrowTypes.EscrowStatus status
    );

    function escrowExists(bytes32 tradeId) external view returns (bool);
    
    function getEscrowStatus(bytes32 tradeId) external view returns (EscrowTypes.EscrowStatus);
    
    function isEscrowExpired(bytes32 tradeId) external view returns (bool);

    function isAuthorized(address caller) external view returns (bool);
    function isTokenSupported(address token) external view returns (bool);
}