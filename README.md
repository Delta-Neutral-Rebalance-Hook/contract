# ReHook - Uniswap v4 Liquidity Provider Reward Hook

A Uniswap v4 hook that implements a time-weighted reward system for liquidity providers. This hook collects bonus fees from swaps and redistributes them to liquidity providers based on their contribution time and amount.

## Overview

ReHook enhances Uniswap v4 pools by:

1. Collecting bonus fees from every swap (1% of the input amount)
2. Tracking liquidity provider contributions with time-weighted accounting
3. Distributing accumulated fees to LPs when they add or remove liquidity
4. Ensuring fair distribution based on contribution size and duration

## Features

- **Time-Weighted Rewards**: LPs earn more rewards the longer they provide liquidity
- **Dual Token Rewards**: Rewards are distributed in both pool tokens
- **Secure Signature-Based Authentication**: Uses message signing to verify LP transactions
- **Compatible with Uniswap v4 Architecture**: Implements standard hook interfaces

## Implementation Details

The hook leverages Uniswap v4's hook system with the following callbacks:

- `beforeSwap`: Collects a small fee from swap transactions
- `afterAddLiquidity`: Records LP positions and distributes accumulated rewards
- `afterRemoveLiquidity`: Updates LP positions and distributes accumulated rewards when liquidity is withdrawn

## Usage

Deployed on the [Base network](https://base.org/).

## Requirements

- [Foundry](https://getfoundry.sh/)
- Uniswap v4 dependencies

## Development

```bash
# Clone the repository
git clone https://github.com/Hook-up-to-AMM/contract.git
cd ./contract

# Install dependencies
forge install

# Build
forge build

# Test
forge test -vvv
```

## Testing

The project includes comprehensive test cases that demonstrate:

- Collecting fees from swap operations
- Tracking LP positions over time
- Distributing rewards based on time-weighted contributions
- Handling various liquidity addition and removal scenarios

## License

UNLICENSED

## Credits

Built with [Foundry](https://getfoundry.sh/) and [Uniswap v4 Core](https://github.com/Uniswap/v4-core).

## Our Hackathon Journey

This is the very first hackathon for all 5 members of our team. We were divided into 2 subgroups: 3 people responsible for smart contracts and 2 people handling frontend and backend.

We thought it would go well, but that proved to be a naive assumption. Our journey can be separated into 3 stages:

### Stage 1: Rebalancing Hook (20+ hours)
Initially, we aimed to write a hook contract featuring rebalancing with a short position on perpetual DEX. We also worked on a backend database and complex frontend interfaces with wallet connectivity, which we actually completed. However, we struggled to understand what delta is. After consulting with a mentor, we discovered it was impossible to transfer tokens from poolManager to Hook to execute our planned logic. This attempt ultimately failed after more than 20 hours of work (4/4 14:00 - 4/6 10:00).

Then, we took a much-needed break (4/6 10:00 - 4/6 14:00).

### Stage 2: Rebalancing AMM (4 hours) 
After failing with the rebalancing hook, we quickly pivoted to research on rebalancing AMM. The frontend and backend subgroup continued their development, creating a good-looking webpage that could connect to wallets and sign transactions.

However, we soon realized it would be impossible to develop an entire AMM on our own before the deadline! This stage took roughly 4 hours (4/6 14:00 - 4/6 18:00).

### Stage 3: Time-Weighted Incentive Hook (ongoing, 9.5+ hours)
Finally, we pivoted to a time-weighted incentive Hook. The frontend and backend were no longer needed, so the team members helped with mathematics before heading home. Thankfully, this approach was successful. We spent about 3 hours on the mathematical work, followed by 5 hours writing the hook contract. Then we created documentation and submitted our project.

Everyone was exhausted, but we all acknowledge this is a lifetime cherished memory!
