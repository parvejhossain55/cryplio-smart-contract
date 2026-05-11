// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/CryplioEscrow.sol";

contract DeployCryplioEscrow is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address feeRecipient = vm.envAddress("FEE_RECIPIENT");
        
        // Initial supported tokens (e.g. USDT, USDC on local/testnet)
        // For production, these should be set in .env or passed as args
        address[] memory initialTokens = new address[](1);
        initialTokens[0] = vm.envAddress("INITIAL_TOKEN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        CryplioEscrow escrow = new CryplioEscrow(initialTokens);
        escrow.setFeeRecipient(feeRecipient);
        
        // Add an initial authorized signer if provided
        address initialSigner = vm.envAddress("INITIAL_SIGNER");
        if (initialSigner != address(0)) {
            escrow.addAuthorizedSigner(initialSigner);
        }

        vm.stopBroadcast();
        
        console.log("CryplioEscrow deployed at:", address(escrow));
    }
}
