pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./MipsBestPractices.sol";

contract MipsBestPracticesTest is DSTest {
    MipsBestPractices practices;

    function setUp() public {
        practices = new MipsBestPractices();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
