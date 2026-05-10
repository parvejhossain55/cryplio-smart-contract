// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EscrowState.sol";
import "../lib/EscrowTypes.sol";

/**
 * @title EscrowAuth
 * @dev Base contract containing authorization modifiers and logic
 */
abstract contract EscrowAuth is EscrowState, Ownable {
      // Modifiers
    modifier onlyAuthorized() {
        if (!_isAuthorized(msg.sender)) {
            revert EscrowTypes.Unauthorized();
        }
        _;
    }
    
    modifier validEscrow(bytes32 tradeId) {
        if (!_escrowExists(tradeId)) {
            revert EscrowTypes.EscrowNotFound();
        }
        _;
    }
    
    modifier onlyBuyer(bytes32 tradeId) {
        EscrowTypes.Escrow storage escrow = _getEscrow(tradeId);
        if (escrow.buyer != msg.sender) {
            revert EscrowTypes.Unauthorized();
        }
        _;
    }
    
    modifier onlySeller(bytes32 tradeId) {
        EscrowTypes.Escrow storage escrow = _getEscrow(tradeId);
        if (escrow.seller != msg.sender) {
            revert EscrowTypes.Unauthorized();
        }
        _;
    }
    
    modifier validStatus(bytes32 tradeId, EscrowTypes.EscrowStatus requiredStatus) {
        EscrowTypes.Escrow storage escrow = _getEscrow(tradeId);
        if (escrow.status != requiredStatus) {
            revert EscrowTypes.InvalidStatus();
        }
        _;
    }
    
    modifier notExpired(bytes32 tradeId) {
        EscrowTypes.Escrow storage escrow = _getEscrow(tradeId);
        if (EscrowTypes.isExpired(escrow.expiresAt)) {
            revert EscrowTypes.EscrowExpired();
        }
        _;
    }
    
    modifier canRefund(bytes32 tradeId) {
        EscrowTypes.Escrow storage escrow = _getEscrow(tradeId);
        if (!EscrowTypes.canRefund(escrow.expiresAt)) {
            revert EscrowTypes.CannotRefund();
        }
        _;
    }

    // Constructor
    constructor(address[] memory _initialTokens) EscrowState(_initialTokens) Ownable(msg.sender) {}
    
    // Authorization management functions (only owner)
    function addAuthorizedSigner(address signer) external onlyOwner {
        _addAuthorizedSigner(signer);
    }
    
    function removeAuthorizedSigner(address signer) external onlyOwner {
        _removeAuthorizedSigner(signer);
    }
    // View functions for authorization
    function isAuthorized(address caller) external view returns (bool) {
        return _isAuthorized(caller);
    }
}