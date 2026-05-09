// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/EscrowTypes.sol"

/**
 * @title ICryplioEscrow
 * @dev Interface for core escrow functionality
 */

 interface ICryplioEscrow {
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

    // Core functions
    function createEscrow(
        bytes32 tradeId,
        address buyer,
        address seller,
        address token,
        uint256 amount
    ) external returns (bool);

    function releaseEscrow(bytes32 tradeId) external returns (bool);
    
    function refundEscrow(bytes32 tradeId) external returns (bool);

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
        EscrowTypes.EscrowStatus status,
    );

    function escrowExists(bytes32 tradeId) external view returns (bool);
    
    function getEscrowStatus(bytes32 tradeId) external view returns (EscrowTypes.EscrowStatus);
    
    function isEscrowExpired(bytes32 tradeId) external view returns (bool);

 }