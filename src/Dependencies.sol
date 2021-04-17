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
        require(EndAbstract(chainlog.getAddress("MCD_VOW")).live() == 0, "Dependencies/system-shutdown");
        
        // Do something that depends on the system being live
    }

}
