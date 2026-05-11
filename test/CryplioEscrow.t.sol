// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/CryplioEscrow.sol";
import "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract CryplioEscrowTest is Test {
    CryplioEscrow public escrow;
    ERC20Mock public token;
    
    address public owner = address(1);
    address public buyer = address(2);
    address public seller = address(3);
    address public feeRecipient = address(4);
    address public authorizedSigner = address(5);
    
    bytes32 public constant TRADE_ID = keccak256("trade1");
    uint256 public constant AMOUNT = 1000 * 10**18;
    uint256 public constant EXPIRY_TIME = 1 hours;
    
    function setUp() public {
        vm.startPrank(owner);
        token = new ERC20Mock();
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        
        escrow = new CryplioEscrow(tokens);
        escrow.setFeeRecipient(feeRecipient);
        escrow.addAuthorizedSigner(authorizedSigner);
        vm.stopPrank();
        
        token.mint(seller, AMOUNT);
    }
    
    function test_CreateEscrow() public {
        vm.startPrank(seller);
        token.approve(address(escrow), AMOUNT);
        escrow.createEscrow(TRADE_ID, buyer, seller, address(token), AMOUNT, EXPIRY_TIME);
        vm.stopPrank();
        
        (address b, address s, address t, uint256 a, uint256 e, EscrowTypes.EscrowStatus status) = escrow.getEscrow(TRADE_ID);
        
        assertEq(b, buyer);
        assertEq(s, seller);
        assertEq(t, address(token));
        assertEq(a, AMOUNT);
        assertEq(uint(status), uint(EscrowTypes.EscrowStatus.Locked));
    }
    
    function test_ReleaseEscrow() public {
        test_CreateEscrow();
        
        vm.prank(seller);
        escrow.releaseEscrow(TRADE_ID);
        
        uint256 fee = (AMOUNT * escrow.FEE_BPS()) / 10000;
        uint256 netAmount = AMOUNT - fee;
        
        assertEq(token.balanceOf(buyer), netAmount);
        assertEq(token.balanceOf(feeRecipient), fee);
        assertEq(uint(escrow.getEscrowStatus(TRADE_ID)), uint(EscrowTypes.EscrowStatus.Released));
    }
    
    function test_RefundEscrow() public {
        test_CreateEscrow();
        
        vm.warp(block.timestamp + EXPIRY_TIME + 1);
        
        vm.prank(authorizedSigner);
        escrow.refundEscrow(TRADE_ID);
        
        uint256 fee = (AMOUNT * escrow.REFUND_FEE_BPS()) / 10000;
        uint256 netAmount = AMOUNT - fee;
        
        assertEq(token.balanceOf(seller), netAmount);
        assertEq(token.balanceOf(feeRecipient), fee);
        assertEq(uint(escrow.getEscrowStatus(TRADE_ID)), uint(EscrowTypes.EscrowStatus.Refunded));
    }

    function test_ForceReleaseEscrow() public {
        test_CreateEscrow();
        
        vm.prank(authorizedSigner);
        escrow.forceReleaseEscrow(TRADE_ID);
        
        uint256 fee = (AMOUNT * escrow.FEE_BPS()) / 10000;
        uint256 netAmount = AMOUNT - fee;
        
        assertEq(token.balanceOf(buyer), netAmount);
        assertEq(token.balanceOf(feeRecipient), fee);
        assertEq(uint(escrow.getEscrowStatus(TRADE_ID)), uint(EscrowTypes.EscrowStatus.Released));
    }

    function test_Pause_RevertsCreate() public {
        vm.prank(owner);
        escrow.pause();
        
        vm.startPrank(seller);
        token.approve(address(escrow), AMOUNT);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        escrow.createEscrow(TRADE_ID, buyer, seller, address(token), AMOUNT, EXPIRY_TIME);
        vm.stopPrank();
    }
    
    function test_CreateEscrow_InvalidToken_Reverts() public {
        ERC20Mock otherToken = new ERC20Mock();
        otherToken.mint(seller, AMOUNT);
        
        vm.startPrank(seller);
        otherToken.approve(address(escrow), AMOUNT);
        vm.expectRevert(EscrowTypes.UnsupportedToken.selector);
        escrow.createEscrow(TRADE_ID, buyer, seller, address(otherToken), AMOUNT, EXPIRY_TIME);
        vm.stopPrank();
    }
    
    function test_ReleaseEscrow_Unauthorized_Reverts() public {
        test_CreateEscrow();
        
        vm.prank(buyer);
        vm.expectRevert(EscrowTypes.Unauthorized.selector);
        escrow.releaseEscrow(TRADE_ID);
    }
    
    function test_RefundEscrow_BeforeExpiry_Reverts() public {
        test_CreateEscrow();
        
        vm.prank(authorizedSigner);
        vm.expectRevert(EscrowTypes.CannotRefund.selector);
        escrow.refundEscrow(TRADE_ID);
    }

    function test_CreateEscrowMeta() public {
        uint256 sellerPrivKey = 0x1234;
        address sellerAddr = vm.addr(sellerPrivKey);
        token.mint(sellerAddr, AMOUNT);
        
        vm.prank(sellerAddr);
        token.approve(address(escrow), AMOUNT);
        
        uint256 nonce = 0;
        bytes memory signature;
        
        {
            // Type hash from EscrowOperations
            bytes32 CREATE_ESCROW_TYPEHASH = keccak256(
                "CreateEscrow(bytes32 tradeId,address buyer,address seller,address token,uint256 amount,uint256 expiryTime,uint256 nonce)"
            );
            
            // EIP-712 Domain Separator
            bytes32 domainSeparator = keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes("CryplioEscrow")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(escrow)
                )
            );
            
            // Struct hash
            bytes32 structHash = keccak256(
                abi.encode(
                    CREATE_ESCROW_TYPEHASH,
                    TRADE_ID,
                    buyer,
                    sellerAddr,
                    address(token),
                    AMOUNT,
                    EXPIRY_TIME,
                    nonce
                )
            );
            
            // Final hash
            bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
            
            // Sign
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPrivKey, hash);
            signature = abi.encodePacked(r, s, v);
        }
        
        // Execute meta-tx
        escrow.createEscrowMeta(TRADE_ID, buyer, sellerAddr, address(token), AMOUNT, EXPIRY_TIME, nonce, signature);
        
        (address b, address s_recovered,,,, ) = escrow.getEscrow(TRADE_ID);
        assertEq(b, buyer);
        assertEq(s_recovered, sellerAddr);
        assertTrue(escrow.usedNonces(sellerAddr, nonce));
    }
}
