.PHONY: build test clean anvil deploy help

# Config (override with: make deploy SCRIPT=path/to/Script.s.sol PRIVATE_KEY=0x...)
RPC_URL ?= http://localhost:8545
SCRIPT ?= script/Counter.s.sol
PRIVATE_KEY ?= 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

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

deploy: ## Deploy script (requires anvil running). Usage: make deploy [SCRIPT=path] [PRIVATE_KEY=0x...] [RPC_URL=http://...]
	forge script $(SCRIPT) --rpc-url $(RPC_URL) --broadcast --private-key $(PRIVATE_KEY)

fmt: ## Format code
	forge fmt

snapshot: ## Create gas snapshot
	forge snapshot

coverage: ## Run test coverage
	forge coverage
