# Technical MIPs Development Best Practices

This repository is a collection of best practices and code snippets to ensure your proposed MIP moves through the code review process as quickly as possible. It is intended as a living document which will evolve as the protocol does. Please check back here for continuing developments.

## Before Starting

Before starting your next great MIP you should be aware of how the Maker protocol works. We highly recommend you read over the [protocol documentation](https://docs.makerdao.com/) to get up to speed with the basics. This document is intended for those who are already familiar with how Maker works. We also recommend you engage in the [forum](https://forum.makerdao.com/) and [chat](https://chat.makerdao.com/) first to determine if governance is interested in your idea. It's possible someone else is already working on your idea, so best to coordinate first before wasting too much time. You can also review the [MIPs Portal](https://mips.makerdao.com/mips/list) to see if your idea is being worked on already.

## Getting Started

There are lots of tools to choose from in Ethereum ecosystem, and although it is not completely manditory to use the Maker toolset we highly recommend that you do. Similar to the rest of this guide, you can choose to stray from this best practices document, but you must have a very good reason for doing so.

### Maker Developer Ecosystem

 * [Solidity](https://soliditylang.org/) - Maker uses the Solidity programming language.
 * [dapp.tools](https://dapp.tools/) - Maker uses the dapp.tools development stack. This includes dapp, seth and hevm.

## MIP Development Topics

### Terminology

Maker is organized into (a core set of contracts)[https://github.com/makerdao/dss] as well as an ever-growing ecosystem of "edge contracts" which we call MIPs. For the purposes of this document we will be ignoring core contract development. The most common type of MIP is the addition of a new collateral type. Not every colleteral addition requires an associated MIP - most ERC20 tokens can just use the standard gem joins. A MIP is required if you are introducing new functionality. Here are some examples of collateral additions that require custom logic:

 * [MIP21: Real World Assets - Off-Chain Asset Backed Lender](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d43)
 * [MIP22: Centrifuge Direct Liquidation Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d44)
 * [MIP29: Peg Stability Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d4d)
 * [MIP30: Farmable cUSDC Adapter (CropJoin)](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d4f)
 * [MIP43: Term Lending Module (TLM)](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d84)
 * [MIP50: Direct Deposit Module](https://mips.makerdao.com/mips/details/606e444beb7b907fbc08f0f3)

Of course new collateral additions are not the only thing that can be added to the Maker ecosystem. Here are some examples of MIPs that interact with different parts of the Maker core contracts:

 * [MIP25: Flash Mint Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d47)
 * [MIP34: Keg Streaming Payments Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d53)

### Versioning

All contracts should target Solidity `0.6.12` specifically. We periodically bump this version number up so be sure to check back here when starting a new MIP. Use the exact version syntax `pragma solidity 0.6.12;` at the top of your files.

### Libraries

To keep things simple we recommend you only install the [dss-interfaces](https://github.com/makerdao/dss-interfaces) library when interfacing with the core contracts. This reduces any issues with versioning, code changes, etc. You can add this to your project via `dapp install makerdao/dss-interfaces`. If you absolutely need to pull in the [core contracts](https://github.com/makerdao/dss) library for say setting up a test environment then feel free to do so.


### Testing

We recommend MIP authors add exhaustive testing to accompany their code. The Maker Smart Contract Core Unit(s) will expect a large amount of both unit and integration tests. These tests should cover every facet of the code. Bonus points for fuzz and symbolic tests.

Integration tests should be run on a mainnet fork against the live code. Hevm provides this functionality via the `--rpc` argument.

### Dependency Management

The Maker core contracts will specify each of their dependencies in the constructor. This is okay for the core contracts, but it is not scalable for MIPs. We recommend you use the [chainlog](https://github.com/makerdao/dss-chain-log) as the source of truth to pull in any dependencies your MIP may have. The chainlog exists at the following addresses:

Mainnet: [0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F](https://etherscan.io/address/0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F)  
Kovan: [0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F](https://kovan.etherscan.io/address/0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F)  

For quick access to a list of live contracts on both Kovan and Mainnet you can visit the [releases page](https://changelog.makerdao.com/).

See [Dependencies.sol](https://github.com/BellwoodStudios/mips-best-practices/blob/master/src/Dependencies.sol) for examples of dependency management.
