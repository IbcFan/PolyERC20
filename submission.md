# PolyERC20 - Fungible token transfer using IBC

## Team Members (PolyIbc)
- IbcFan
- eigenvibes

## Project Overview
PolyERC20 is a set of contracts that allow for the transfer of fungible tokens between different blockchains using the Inter-Blockchain Communication (IBC) protocol. 
It's built on top of xERC20 and regular ERC20 contracts.

## Run-book
A comprehensive run-book can be found in [Readme.md](./Readme.md)

## Resources Used
- **Solidity**: Solidity is a statically typed, contract programming language that is used for implementing smart contracts on various blockchain platforms. It is primarily used for developing smart contracts on an EVM blockchain.
- **IBC Explorer**: A web service that allows users to explore the IBC packets and channels.
- **Foundry**: A smart contract development toolchain.

## Challenges Faced
1. Testing and debugging the root causes for the failure of IBC packet transfers or channel handshakes.
2. Multichain support in Foundry is still in its early stages.
3. Compilation of the contracts with VIBC and xERC20 dependencies takes a loooong time.

## What We Learned
1. The importance of tooling and infrastructure for IBC development.

## Future Improvements
1. Adding extensive testing.
2. Building web and onchain services that leverage PolyErc20 and demonstrate its capabilities.

## Proof of testnet interaction
Contracts:
- [PolyERC20](https://optimism-sepolia.blockscout.com/address/0x0F9d1b9f042feeC6D2941e994CE93c81F1FBa24C) on Optimism
- [PolyERC20](https://base-sepolia.blockscout.com/address/0x0F9d1b9f042feeC6D2941e994CE93c81F1FBa24C) on Base
- [xERC20](https://optimism-sepolia.blockscout.com/address/0x69352D89876c36a719EdeB3f1b2D7B9137569930) on Optimism
- [xERC20](https://base-sepolia.blockscout.com/address/0x69352D89876c36a719EdeB3f1b2D7B9137569930) on Base
- [UC Bridge](https://optimism-sepolia.blockscout.com/address/0x64C18466822e7fc69a1d148f06660a18f4A5b1BE) on Optimism
- [UC Bridge](https://base-sepolia.blockscout.com/address/0x64C18466822e7fc69a1d148f06660a18f4A5b1BE) on Base
- [Custom Bridge](https://optimism-sepolia.blockscout.com/address/0xA4418D26F7020c62d9174f417f3E3CEeFc2f5e9C) on Optimism
- [Custom Bridge](https://base-sepolia.blockscout.com/address/0xA4418D26F7020c62d9174f417f3E3CEeFc2f5e9C) on Base

PolyERC20 transfer transactions:
- [Transfer](https://optimism-sepolia.blockscout.com/tx/0x5b08cc5ac901f128ba6db94f8eaf75b301b6207a84f85f5283fd9ffb8a12da05?tab=logs) from Optimism to Base
- [RecvPacket](https://base-sepolia.blockscout.com/tx/0xeb445a694cace8afe47c30e6e81c4a596337bfee8ea3a31d2f2969e419ac4592) on Base
- [Acknowledgement](https://optimism-sepolia.blockscout.com/tx/0x7a337d19ec4119fd8c281ceb4e324b2d215f6fbbf8f657f87b24a714358125d0) on optimism

xERC20 transfer transactions using an UC Bridge:
- [Bridge](https://optimism-sepolia.blockscout.com/tx/0xedd2e28aa0bfdc6f6d426a5ec11e4511b90163a4114fab97b1d4f48ef8781e9e) from Optimism to Base
- [RecvPacket](https://base-sepolia.blockscout.com/tx/0x72a551d8b674e41fb346dd8e73bb880f233fbf3db74ca064b010bedb8cc297a7) on Base
- [Acknowledgement](https://optimism-sepolia.blockscout.com/tx/0xedac1a33a54f2a2370bd09d5e2751ea4c60a7a117b9dc9f1638ebb0786c6c754) on optimism

xERC20 transfer transactions using a custom Bridge:
- [Bridge](https://optimism-sepolia.blockscout.com/tx/0xb33c6e8eaacbdf165fd83e55af2554ec5930dbd60841daf3182368c049367dfc) from Optimism to Base
- [RecvPacket](https://base-sepolia.blockscout.com/tx/0x7d8a9ad9876072a5912e254d1e75ba55be15c83ae9c7c6759e6a09511be03469) on Base
- [Acknowledgement](https://optimism-sepolia.blockscout.com/tx/0x93499fdd33d2a879704eab9a048fa3f5d3af632f10153c02d6abe359df5efa57) on optimism

