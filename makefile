.PHONY: test deployA deployS

-include .env

test:
	 forge test


deployA:
	forge script script/DeployRaffle.s.sol:DeployRaffles --broadcast -vvvv

deployS:
	forge script script/DeployRaffle.s.sol:DeployRaffles --rpc-url $(SEPOLIA_URL) --private-key $(PRIVATE_KEY)  --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv


