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
    function rely(address guy) external auth { wards[guy] = 1; emit Rely(guy); }
    function deny(address guy) external auth { wards[guy] = 0; emit Deny(guy); }
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
