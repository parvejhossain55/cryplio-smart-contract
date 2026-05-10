// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./EscrowAuth.sol";
import "../lib/EscrowTypes.sol";

/**
 * @title EscrowOperations
 * @dev Base contract containing core escrow operations
 */
abstract contract EscrowOperations is EscrowAuth, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Events (re-exported for convenience)
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
    

    // Constructor
    constructor(address[] memory _initialTokens) EscrowAuth(_initialTokens) {}
    
    /**
     * @dev Create a new escrow for a trade
     * @param tradeId Unique identifier for the trade
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param token Address of the ERC20 token (USDT/USDC/etc.)
     * @param amount Amount of tokens to lock
     */
    function createEscrow(
        bytes32 tradeId,
        address buyer,
        address seller,
        address token,
        uint256 amount
    ) external onlyAuthorized nonReentrant returns (bool) {
        // Validate inputs
        EscrowTypes.validateTradeId(tradeId);
        EscrowTypes.validateAddresses(buyer, seller);
        EscrowTypes.validateAmount(amount);
        
        // Validate token support
        if (!supportedTokens[token]) {
            revert EscrowTypes.UnsupportedToken();
        }
        
        // Check if escrow already exists
        if (_escrowExists(tradeId)) {
            revert EscrowTypes.EscrowAlreadyExists();
        }
        
        // Transfer tokens from buyer to this contract
        IERC20 tokenContract = IERC20(token);
        tokenContract.safeTransferFrom(buyer, address(this), amount);
        
        // Create escrow record
        _createEscrow(tradeId, buyer, seller, token, amount);
        
        emit EscrowCreated(tradeId, buyer, seller, token, amount, block.timestamp);
        return true;
    }
    
}