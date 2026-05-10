// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import "../lib/EscrowTypes.sol";

/**
 * @title EscrowState
 * @dev Base contract containing all state variables and storage 
 * for escrow functionality
 */
abstract contract EscrowState {
    using EscrowTypes for EscrowTypes.Escrow;

    // State Variable
    mapping (bytes32 => EscrowTypes.Escrow) escrows;
    mapping (address => bool) authorizedSigner;

    // Token management
    mapping(address => bool) public supportedTokens;

    // Constructor
    constructor(address[] memory _initialTokens) {
        require(_initialTokens.length > 0, "Initial tokens required");
        for (uint256 i = 0; i < _initialTokens.length; i++) {
            address token = _initialTokens[i];
            require(token != address(0), "Invalid token address");
            if (!supportedTokens[token]) {
                supportedTokens[token] = true;
            }
        }
    }

    // Authorized signer management
    function _addAuthorizedSigner(address signer) internal {
        authorizedSigner[signer] = true;
    }

    function _removeAuthorizedSigner(address signer) internal {
        authorizedSigner[signer] = false;
    }

    function _isAuthorized(address signer) internal view returns (bool) {
        return authorizedSigner[signer];
    }

    // Internal state management functions
    function _createEscrow(
        bytes32 tradeId,
        address buyer,
        address seller,
        address token,
        uint256 amount
    ) internal {
        escrows[tradeId] = EscrowTypes.Escrow({
            tradeId: tradeId,
            buyer: buyer,
            seller: seller,
            token: token,
            amount: amount,
            expiresAt: block.timestamp + EscrowTypes.ESCROW_EXPIRY_TIME,
            status: EscrowTypes.EscrowStatus.Locked
        });
    }

    function _updateEscrowStatus(bytes32 tradeId, EscrowTypes.EscrowStatus newStatus) internal {
        escrows[tradeId].status = newStatus;
    }

    function _getEscrow(bytes32 tradeId) internal view returns (EscrowTypes.Escrow storage) {
        if (escrows[tradeId].buyer == address(0)) {
            revert EscrowTypes.EscrowNotFound();
        }
        return escrows[tradeId];
    }

    function _escrowExists(bytes32 tradeId) internal view returns (bool) {
        return escrows[tradeId].buyer != address(0);
    }
}