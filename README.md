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

### Flat Code

The Maker team recommends flat code. Inheritance can be nice for code-reusability, but it comes at the cost of readability if used too much. Having to jump between multiple files with `virtual` methods can make things trickier to audit.

### Variable Naming

Maker recommends using abstract variable names where ever possible. You can see lots of examples of this in [the core contracts](https://github.com/makerdao/dss). For example in the `Vat`, debt ceilings are not called `debtCeiling` - they are called `line`. Often a 3 to 4 letter single word is used instead of a long descriptive name. You can see this not only in the variable naming, but also the contract names themselves - `vat`, `vow`, `end`, `dog`, etc.

### Upgradability

Maker has a strict policy of no upgradable contracts. This is in contrast to the wider eco-system which uses things like Transparent Proxies frequently. This is not to say that Maker disallows upgrading code, but it must be done through redeployment as opposed to updating the interface on a fixed address.

### Arbitrary Contract Calls

Do not make external calls to unknown code unless absolutely necessary. Arbitrary code execution is an anti-pattern, and we try to stay away from it as much as possible. This is things such as the new `transferAndCall()` extention to ERC20. These methods may provide conveniance, but re-entrancy is a notoriously hard thing to reason about. Notable exceptions are if the external call is necessary for the module's core functionality. For example, Flash Loans / Mints require calling external code such as in the [clipper](https://github.com/makerdao/dss/blob/master/src/clip.sol#L395) and [MIP25](https://github.com/hexonaut/dss-flash/blob/master/src/flash.sol#L128). If this has to be done we recommend put re-entrancy guards on the calling function.

### Common Code Patterns

Below are some common patterns you can copy + paste into your project:

#### Auth

Common auth modifier used to give administrative access to the contract:

```
// --- Auth ---
function rely(address guy) external auth { wards[guy] = 1; emit Rely(guy); }
function deny(address guy) external auth { wards[guy] = 0; emit Deny(guy); }
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
// --- Administration ---
function file(bytes32 what, uint256 data) external auth {
    if (what == "param") param = data;
    else revert("MODULE/file-unrecognized-param");
    emit File(what, data);
}
function file(bytes32 what, address data) external auth {
    if (what == "addr") addr = data;
    else revert("MODULE/file-unrecognized-param");
    emit File(what, data);
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
    z = add(x, sub(y, 1)) / y;
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

See [Dependencies.sol](https://github.com/BellwoodStudios/mips-best-practices/blob/master/src/Dependencies.sol) for examples of dependency management.

```
pragma solidity 0.6.12;

import "dss-interfaces/dss/ChainlogAbstract.sol";
import "dss-interfaces/dss/DaiAbstract.sol";
import "dss-interfaces/dss/DaiJoinAbstract.sol";
import "dss-interfaces/dss/EndAbstract.sol";

contract Dependencies {

    // Use the immutable keyword on permanent contracts to save gas
    ChainlogAbstract immutable public chainlog;

    // Dai / DaiJoin can be set as immutable because they are "permanent contracts"
    DaiAbstract immutable public dai;
    DaiJoinAbstract immutable public daiJoin;

    // We need to cache the vow because it is on a hot path
    address public vow;

    constructor(ChainlogAbstract _chainlog) public {
        chainlog = _chainlog;
        dai = DaiAbstract(_chainlog.getAddress("MCD_DAI"));
        daiJoin = DaiJoinAbstract(_chainlog.getAddress("MCD_JOIN_DAI"));

        vow = _chainlog.getAddress("MCD_VOW");
    }

    // Permissionless refresh to cached contracts
    function rdeps() public {
        vow = chainlog.getAddress("MCD_VOW");
    }

    function doSomething() public {
        // ... My MIP Custom Logic ...

        // I need to send revenue into the vow
        // We normally recommend performing this lookup as-needed instead of caching the address locally, but
        // in this case we need every bit of gas savings we can get
        dai.approve(address(daiJoin), 123 ether);
        daiJoin.join(vow, 123 ether);
    }

    function doSomethingElse() public {
        // We require the end contract here, look it up as-needed
        require(EndAbstract(chainlog.getAddress("MCD_END")).live() == 0, "Dependencies/system-shutdown");
        
        // Do something that depends on the system being live
    }

}
```

You may ask which are the "permanent contracts". In general you should assume every contract is **not** permanent and will be replaced at some point. There are 3 exceptions to this rule:

 * vat
 * dai
 * daiJoin

We recommend looking up mcd core contracts as-needed to ensure that when they are upgraded nothing needs to be done to keep your MIP running smoothly. If you absolutely need to cache contracts locally we recommend providing a way for these addresses to be permissionlessly refreshed called `rdeps()`.

### Rounding

Due to limited precision, sometimes we need to round a result. In the case you are building a collateral adapter or something that interacts with a user you always want to round "against" the user. This ensures that the collateral adapter will always have enough collateral to pay out previous depositors. You can see an example of this in the [CropJoin adapter](https://github.com/hexonaut/crop/blob/main/src/crop.sol#L127) where `rmulup()` is used to round "against" the user and require them to get at most what they are owed and no more.

### Bad Debt

New collateral adapters need ways to liquidate themselves when the collateralization ratio drops below the critical threshold. With a normal ERC20 we can just use the standard liquidation mechanism. In cases where the standard collateralization cannot be used, careful attention needs to be paid to how long this process is likely to take. For example in [MIP21](https://github.com/makerdao/MIP21-RWA-Example/blob/master/src/RwaLiquidationOracle.sol#L122) `cull()` is used to enforce bad debt invocation after a deadline elapses. Simiarly in [MIP50: Direct Deposit Module](https://github.com/BellwoodStudios/dss-direct-deposit/blob/master/src/DssDirectDepositAaveDai.sol#L303) `cull()` will force the debt into the `vow` for potential debt auctions to recapitalize the system. As a general rule of thumb, there should always be a timer to which debt is forced to be written off as uncollectable. Further it should not require governance intervention to write-off this bad debt. Governance may be unwilling to trigger debt auctions which risks system stability.

### System Shutdown

One of the primary gaurantees that ensures Dai's stability is the shutdown module which allows Dai holders to redeem their Dai for the underlying collateral. It is important that MIP creators take this into account when designing their MIPs. It is one of the most overlooked pieces, but it is very important for system stability. While there are no exact rules on how to deal with this, we can provide some general rules of thumb that can get you started.

#### Access to Collateral

In order to comply with system shutdown, anyone should be ideally be able to redeem `vat.gems` for the underlying collateral. It is because of this constraint you see things like [AuthGemJoin](https://github.com/makerdao/dss-gem-joins/blob/master/src/join-auth.sol#L70) not requiring `auth` on the `exit()` function. This is intentionally omitted in order to allow anyone to pull the collateral out even though an authorized party was the one that put it in.

#### Graceful Shutdown

If you are able to gracefully close out your module then we recommend you do so. An example of this is in [MIP50: Direct Deposit Module](https://github.com/BellwoodStudios/dss-direct-deposit/blob/master/src/DssDirectDepositAaveDai.sol#L287). You can see the permissionless `cage()` function which can be executed when `vat.live() == 0`. Upon execution, the system will begin gracefully closing itself out.
