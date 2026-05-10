// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./EscrowState.sol";
import "../lib/EscrowTypes.sol";

/**
 * @title EscrowAuth
 * @dev Base contract containing authorization modifiers and management functions
 * @notice Handles all access control for the escrow system
 * @custom:security Owner controls authorized signers and fee recipient
 */
abstract contract EscrowAuth is EscrowState, Ownable {
      // Modifiers
    /// @notice Restricts access to authorized admin signers only
    /// @dev Used for refund and force release functions
    modifier onlyAuthorized() {
        if (!_isAuthorized(msg.sender)) {
            revert EscrowTypes.NotAuthorizedSigner();
        }
        _;
    }
    
    /// @notice Validates that escrow exists before proceeding
    /// @param tradeId Trade identifier to check
    modifier validEscrow(bytes32 tradeId) {
        if (!_escrowExists(tradeId)) {
            revert EscrowTypes.EscrowNotFound();
        }
        _;
    }
    
    /// @notice Restricts access to escrow seller only
    /// @dev SECURITY: Prevents unauthorized release of funds
    /// @param tradeId Trade identifier
    modifier onlySeller(bytes32 tradeId) {
        EscrowTypes.Escrow storage escrow = _getEscrow(tradeId);
        if (escrow.seller != msg.sender) {
            revert EscrowTypes.Unauthorized();
        }
        _;
    }
    
    /// @notice Validates escrow can be refunded
    /// @dev SECURITY: Only allows refunds after expiry or dispute resolution
    /// @param tradeId Trade identifier
    modifier canRefund(bytes32 tradeId) {
        EscrowTypes.Escrow storage escrow = _getEscrow(tradeId);
        if (!EscrowTypes.canRefund(escrow.expiresAt)) {
            revert EscrowTypes.CannotRefund();
        }
        _;
    }

    /// @param _initialTokens Array of supported ERC20 token addresses
    constructor(address[] memory _initialTokens) EscrowState(_initialTokens) Ownable(msg.sender) {}

    // Authorization management functions (only owner)
    /// @notice Add an address to authorized signers list
    /// @dev ACCESS: Only owner can call. Grants admin privileges for refund/force release.
    /// @param signer Address to authorize as admin
    function addAuthorizedSigner(address signer) external onlyOwner {
        _addAuthorizedSigner(signer);
    }
    
    /// @notice Remove an address from authorized signers list
    /// @dev ACCESS: Only owner can call. Revokes admin privileges.
    /// @param signer Address to remove authorization from
    function removeAuthorizedSigner(address signer) external onlyOwner {
        _removeAuthorizedSigner(signer);
    }

    // Fee recipient management
    /// @notice Emitted when fee recipient (treasury wallet) is updated
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    /// @notice Set the fee recipient address (treasury wallet)
    /// @dev FINANCIAL: All platform fees will be sent to this address
    ///      ACCESS: Only owner can call
    ///      SECURITY: Cannot be set to zero address
    /// @param _feeRecipient New fee recipient address
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    /// @notice Check if an address is authorized as admin
    /// @dev Used by frontend to check admin status
    /// @param caller Address to check
    /// @return bool True if authorized, false otherwise
    function isAuthorized(address caller) external view returns (bool) {
        return _isAuthorized(caller);
    }
}