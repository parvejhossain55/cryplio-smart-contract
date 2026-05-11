.PHONY: build test clean anvil deploy deploy-usdt help

# Load .env file
ifneq ("$(wildcard .env)","")
    include .env
    export
endif

# Defaults
RPC_URL ?= http://localhost:8545

help: ## Show all available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Compile contracts
	forge build

test: ## Run tests
	forge test

clean: ## Remove build artifacts
	forge clean

anvil: ## Start local Anvil test node
	anvil

deploy: ## Deploy CryplioEscrow (uses .env variables)
	forge script script/Deploy.s.sol:DeployCryplioEscrow --rpc-url $(RPC_URL) --broadcast --private-key $(PRIVATE_KEY)

deploy-usdt: ## Deploy Mock USDT for local testing
	forge script script/DeployMockUSDT.s.sol:DeployMockUSDT --rpc-url $(RPC_URL) --broadcast --private-key $(PRIVATE_KEY)

deploy-sepolia: ## Deploy to Sepolia and verify
	forge script script/Deploy.s.sol:DeployCryplioEscrow --rpc-url $(SEPOLIA_RPC_URL) --broadcast --verify --private-key $(PRIVATE_KEY)

fmt: ## Format code
	forge fmt

snapshot: ## Create gas snapshot
	forge snapshot

coverage: ## Run test coverage
	forge coverage

balance: ## Check ETH balance of the deployer
	@cast balance $(shell cast wallet address --private-key $(PRIVATE_KEY)) --rpc-url $(RPC_URL) --ether
