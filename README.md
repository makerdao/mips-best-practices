# Technical MIPs Development Best Practices

This repository is a collection of best practices and code snippets to ensure your proposed MIP moves through the code review process as quickly as possible. It is intended as a living document which will evolve as the protocol does. Please check back here for continuing developments.

## Before Starting

Before starting your next great MIP you should be aware of how the Maker protocol works. We highly recommend you read over the [protocol documentation](https://docs.makerdao.com/) to get up to speed with the basics. This document is intended for those who are already familiar with how Maker works. We also recommend you engage in the [forum](https://forum.makerdao.com/) and [chat](https://chat.makerdao.com/) first to determine if governance is interested in your idea. It's possible someone else is already working on your idea, so best to coordinate first before wasting too much time. You can also review the [MIPs Portal](https://mips.makerdao.com/mips/list) to see if your idea is being worked on already.

## Getting Started

There are lots of tools to choose from in Ethereum ecosystem, and although it is not completely mandatory to use the Maker toolset we highly recommend that you do. Similar to the rest of this guide, you can choose to stray from this best practices document, but you must have a very good reason for doing so.

### Maker Developer Ecosystem

 * [Solidity](https://soliditylang.org/) - Maker uses the Solidity programming language.
 * [dapp.tools](https://dapp.tools/) - Maker uses the dapp.tools development stack. This includes dapp, seth and hevm.

## MIP Development Topics

### Terminology

Maker is organized into [a core set of contracts](https://github.com/makerdao/dss) as well as an ever-growing ecosystem of "edge contracts". For the purposes of this document we will be ignoring core contract development. The most common type of MIP is the addition of a new collateral type. Not every colleteral addition requires an associated MIP - most ERC20 tokens can just use the standard gem joins. A MIP is required if you are introducing new functionality. Here are some examples of collateral additions that require custom logic:

 * [MIP21: Real World Assets - Off-Chain Asset Backed Lender](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d43)
 * [MIP22: Centrifuge Direct Liquidation Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d44)
 * [MIP29: Peg Stability Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d4d)
 * [MIP30: Farmable cUSDC Adapter (CropJoin)](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d4f)
 * [MIP43: Term Lending Module (TLM)](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d84)
 * [MIP50: Direct Deposit Module](https://mips.makerdao.com/mips/details/606e444beb7b907fbc08f0f3)

Of course new collateral additions are not the only thing that can be added to the Maker ecosystem. Here are some examples of MIPs that interact with different parts of the Maker core contracts:

 * [MIP25: Flash Mint Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d47)
 * [MIP34: Keg Streaming Payments Module](https://mips.makerdao.com/mips/details/60626de7e65b747f996b3d53)

### Design and Specification

The intent of all new modules needs to be clearly specified in natural language and/or mathematics--code alone is not considered sufficient. Err on the side of being too detailed--vague or non-existent specifications have led to bugs in the past. Make an effort to identify high-level properties (e.g. "users cannot withdraw more than their stake" or "the sum of all balances should equal the total supply"). These should later be used to create property-based tests.

### Versioning

All contracts should target Solidity `0.6.12` specifically. We periodically bump this version number up so be sure to check back here when starting a new MIP. Use the exact version syntax `pragma solidity 0.6.12;` at the top of your files.

### Libraries

We recommend you build MIPs with no external dependencies. If you really need to pull in some libraries for testing that is fine, but we recommend you keep this to a minimum.

### Testing

We recommend MIP authors add exhaustive testing to accompany their code. The Maker Smart Contract Core Unit(s) will expect a large amount of both unit and integration tests. These tests should cover every facet of the code. Bonus points for fuzz and symbolic tests. In particular, an effort should be made to test high-level properties and complete user experience flows, not just the behavior of individual functions (although the latter is still necessary).

Integration tests should be run on a mainnet fork against the live code. Hevm provides this functionality via the `--rpc` argument.

### Flat Code

The Maker team recommends flat code. Inheritance can be nice for code-reusability, but it comes at the cost of readability if used too much. Having to jump between multiple files with `virtual` methods can make code harder to audit. In general "less is more" - we are looking for succinct code that does exactly what it needs to and nothing more.

### Variable Naming

Maker recommends using abstract variable names where ever possible. You can see lots of examples of this in [the core contracts](https://github.com/makerdao/dss). For example in the `Vat`, debt ceilings are not called `debtCeiling` - they are called `line`. Often a 3 to 4 letter single word is used instead of a long descriptive name. You can see this not only in the variable naming, but also the contract names themselves - `vat`, `vow`, `end`, `dog`, etc.

### Upgradability

Upgradable contracts are generally discouraged except in cases where there is an extermely strong justification for their use. This is in contrast to the wider eco-system which uses things like Transparent Proxies frequently. This is not to say that Maker disallows upgrading code, but it should be done through redeployment as opposed to updating the interface on a fixed address.

### Arbitrary Contract Calls

Do not make external calls to unknown code unless absolutely necessary. Arbitrary code execution is an anti-pattern, and we try to stay away from it as much as possible. This is things such as the new `transferAndCall()` extention to ERC20. These methods may provide conveniance, but re-entrancy is a notoriously hard thing to reason about. Notable exceptions are if the external call is necessary for the module's core functionality. For example, Flash Loans / Mints require calling external code such as in the [clipper](https://github.com/makerdao/dss/blob/master/src/clip.sol#L395) and [MIP25](https://github.com/hexonaut/dss-flash/blob/master/src/flash.sol#L128). If this has to be done we recommend put re-entrancy guards on all the contract functions that provoke storage changes.

### Common Code Patterns

Below are some common patterns you can copy + paste into your project:

#### Auth

Common auth modifier used to give administrative access to the contract:

```
event Rely(address indexed usr);
event Deny(address indexed usr);

// --- Auth ---
function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
mapping (address => uint256) public wards;
modifier auth {
    require(wards[msg.sender] == 1, "MODULE/not-authorized");
    _;
}
```

and remember to initialize in the constructor:

```
constructor(...) public {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
}
```

#### File

Administrative parameters change:

```
event File(bytes32 indexed what, uint256 data);
event File(bytes32 indexed what, address data);
event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
event File(bytes32 indexed ilk, bytes32 indexed what, address data);

// --- Administration ---
function file(bytes32 what, uint256 data) external auth {
    if (what == "value") value = data;
    else revert("MODULE/file-unrecognized-param");
    emit File(what, data);
}
function file(bytes32 what, address data) external auth {
    if (what == "addr") addr = data;
    else revert("MODULE/file-unrecognized-param");
    emit File(what, data);
}
function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
    if (what == "value") ilks[ilk].value = data;
    else revert("MODULE/file-unrecognized-param");
    emit File(ilk, what, data);
}
function file(bytes32 ilk, bytes32 what, address data) external auth {
    if (what == "addr") ilks[ilk].addr = data;
    else revert("MODULE/file-unrecognized-param");
    emit File(ilk, what, data);
}
```

#### Math

A bunch of common math functions:

```
// --- Math ---
uint256 constant WAD = 10 ** 18;
uint256 constant RAY = 10 ** 27;
uint256 constant RAD = 10 ** 45;
function add(uint256 x, uint256 y) public pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}
function sub(uint256 x, uint256 y) public pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}
function mul(uint256 x, uint256 y) public pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}
function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x != 0 ? ((x - 1) / y) + 1 : 0;
}
function wmul(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = mul(x, y) / WAD;
}
function wmulup(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = divup(mul(x, y), WAD);
}
function wdiv(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = mul(x, WAD) / y;
}
function wdivup(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = divup(mul(x, WAD), y);
}
function rmul(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = mul(x, y) / RAY;
}
function rmulup(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = divup(mul(x, y), RAY);
}
function rdiv(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = mul(x, RAY) / y;
}
function rdivup(uint256 x, uint256 y) public pure returns (uint256 z) {
    z = divup(mul(x, RAY), y);
}
```

### Dependency Management

The Maker core contracts will specify each of their dependencies in the constructor. This is okay for the core contracts, but it is not scalable for MIPs. We recommend you use the [chainlog](https://github.com/makerdao/dss-chain-log) as the source of truth to pull in any dependencies your MIP may have. The chainlog exists at the following addresses:

Mainnet: [0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F](https://etherscan.io/address/0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F)  
Kovan: [0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F](https://kovan.etherscan.io/address/0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F)  

For quick access to a list of live contracts on both Kovan and Mainnet you can visit the [releases page](https://changelog.makerdao.com/).

To keep things simple we recommend you define interfaces inside the same file as the contract that is using them. The standard pattern is to define them as `FooLike`. Where `Foo` is the name of the contract dependency. You can see examples of this below.

See [FullExample.sol](https://github.com/makerdao/mips-best-practices/blob/master/src/FullExample.sol).

```
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

// Define interface dependencies in-line instead of importing them
// Use the FooLike {} syntax specific to just what functions you are using

interface ChainlogLike {
    function getAddress(bytes32) external view returns (address);
}

interface DaiLike {
    function approve(address, uint256) external returns (bool);
}

interface DaiJoinLike {
    function join(address, uint256) external;
}

interface EndLike {
    function live() external returns (uint256);
}

contract FullExample {

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);

    // --- Auth ---
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    mapping (address => uint256) public wards;
    modifier auth {
        require(wards[msg.sender] == 1, "MODULE/not-authorized");
        _;
    }

    // Use the immutable keyword on permanent contracts to save gas
    ChainlogLike immutable public chainlog;

    // Dai / DaiJoin can be set as immutable because they are "permanent contracts"
    DaiLike immutable public dai;
    DaiJoinLike immutable public daiJoin;

    // The end is not a "permanent contract" so we need to allow it to be updated
    EndLike public end;

    constructor(ChainlogLike _chainlog) public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        
        chainlog = _chainlog;
        dai = DaiLike(_chainlog.getAddress("MCD_DAI"));
        daiJoin = DaiJoinLike(_chainlog.getAddress("MCD_JOIN_DAI"));
        end = EndLike(_chainlog.getAddress("MCD_END"));
    }

    // --- Administration ---
    function file(bytes32 what, address data) external auth {
        // The end has specific interface, so we need to have governance forcefully update the end
        // when a new end is deployed
        if (what == "end") end = EndLike(data);
        else revert("MODULE/file-unrecognized-param");
        emit File(what, data);
    }

    function doSomething() public {
        // ... My MIP Custom Logic ...

        // I need to send revenue into the vow.
        // Since there is no interface dependency, I want to load the vow
        // on the fly so I can always get the most recent version.
        // 
        // Please note there is need to worry about vow updates as the argument
        // is a generic address and no specific interface is required
        dai.approve(address(daiJoin), 123 ether);
        daiJoin.join(chainlog.getAddress("MCD_VOW"), 123 ether);
    }

    function doSomethingElse() public {
        // We require the end contract here with a specific function call
        require(end.live() == 0, "MODULE/system-shutdown");
        
        // Do something that depends on the system being live
    }

}
```

You may ask which are the "permanent contracts". In general you should assume every contract is **not** permanent and will be replaced at some point. There are 3 exceptions to this rule:

 * vat
 * dai
 * daiJoin

For the remaining core contract dependencies we recommend you set them in the constructor and use the `file(XXX, YYY)` pattern to allow governance to update them at a later time. There is one notable exception with the `vow`. A very common operation is to either send profit to the surplus buffer (`vow`) or suck dai from it. Both of these operations use the `vat` with a generic address, so we recommend you load the `vow` from the changelog right as you need it as in the example above.

### Rounding

Due to limited precision, sometimes we need to round a result. In the case you are building a collateral adapter or something that interacts with a user you always want to round "against" the user. This ensures that the collateral adapter will always have enough collateral to pay out previous depositors. You can see an example of this in the [CropJoin adapter](https://github.com/hexonaut/crop/blob/main/src/crop.sol#L127) where `rmulup()` is used to round "against" the user and require them to get at most what they are owed and no more.

### Overflow

Maker core contracts use a lot of high precision numbers which are called RADs (10^45 decimals). For example, `vat` DAI is measured in RADs and whenever you are dealing with internal accounting with DAI you are usually dealing with RADs. It is important to keep track of the range of your numbers especially in intermediate calculations. In particular whenever you are dealing with multiplications of `RAD * RAY` you will want to be sure of the maximum size of these numbers as that multiplication only allows the product of those two terms to be ~100,000 in natural units. This could show up with something as innocuous as `rdiv(vat.dai(address(this)), x)`. If you find yourself in this situation you can usually get around it by flipping the order of division and multiplication, but this needs to be accounted for on a per-instance basis. If you do reduce the precision of any number remember to account for any rounding concerns outlined in the section above.

### Bad Debt

New collateral adapters need ways to liquidate themselves when the collateralization ratio drops below the critical threshold. With a normal ERC20 we can just use the standard liquidation mechanism. In cases where the standard collateralization cannot be used, careful attention needs to be paid to how long this process is likely to take. For example in [MIP21](https://github.com/makerdao/MIP21-RWA-Example/blob/master/src/RwaLiquidationOracle.sol#L122) `cull()` is used to enforce bad debt invocation after a deadline elapses. Simiarly in [MIP50: Direct Deposit Module](https://github.com/makerdao/dss-direct-deposit/blob/master/src/DssDirectDepositAaveDai.sol#L303) `cull()` will force the debt into the `vow` for potential debt auctions to recapitalize the system. As a general rule of thumb, there should always be a timer to which debt is forced to be written off as uncollectable. Further it should not require governance intervention to write-off this bad debt. Governance may be unwilling to trigger debt auctions which risks system stability.

### System Shutdown

One of the primary gaurantees that ensures Dai's stability is the shutdown module which allows Dai holders to redeem their Dai for the underlying collateral. It is important that MIP creators take this into account when designing their MIPs. It is one of the most overlooked pieces, but it is very important for system stability. While there are no exact rules on how to deal with this, we can provide some general rules of thumb that can get you started.

#### Access to Collateral

In order to comply with system shutdown, anyone should be ideally be able to redeem `vat.gems` for the underlying collateral. It is because of this constraint you see things like [AuthGemJoin](https://github.com/makerdao/dss-gem-joins/blob/master/src/join-auth.sol#L70) not requiring `auth` on the `exit()` function. This is intentionally omitted in order to allow anyone to pull the collateral out even though an authorized party was the one that put it in.

#### Graceful Shutdown

If you are able to gracefully close out your module then we recommend you do so. An example of this is in [MIP50: Direct Deposit Module](https://github.com/makerdao/dss-direct-deposit/blob/master/src/DssDirectDepositAaveDai.sol#L287). You can see the permissionless `cage()` function which can be executed when `vat.live() == 0`. Upon execution, the system will begin gracefully closing itself out.

### Gas Saving Tips

Below are some random tips for saving gas that we have collected along the way:

#### Use full-width types

Intuitively you may think that by using two `uint128`s in storage right next to each other you are saving gas. This is not necessarily the case and in fact this pattern may slightly increase gas usage. Unless you are using both variables in the same transaction you may be wasting gas on bitwise operations.

It's somewhat common to have a flag variable to indicate if a contract is in some state. It is intuitive to use `bool` to define this varaible, but in fact it is usually more gas efficient to use `uint256` like in [this case](https://github.com/makerdao/dss/blob/master/src/vat.sol#L65) in the `vat`.
