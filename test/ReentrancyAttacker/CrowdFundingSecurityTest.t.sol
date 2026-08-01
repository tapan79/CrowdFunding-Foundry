// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/CrowdFunding.sol";
import "./ReentrancyAttacker.sol";

contract CrowdFundingSecurityTest is Test {

    CrowdFunding crowdFunding;
    ReentrancyAttacker attacker;

    address OWNER = makeAddr("OWNER");
    address ALICE = makeAddr("ALICE");

    uint256 target = 20 ether;
    uint256 deadline = 30 days;

    function setUp() public {
        vm.prank(OWNER);
        crowdFunding = new CrowdFunding(target, deadline);

        attacker = new ReentrancyAttacker(address(crowdFunding));
    }

    function test_ReentrancyAttack() public {

        // Fund honest contributor
        vm.deal(ALICE, 10 ether);

        vm.prank(ALICE);
        crowdFunding.contribution{value: 10 ether}();

        // Fund attacker
        vm.deal(address(attacker), 2 ether);

        // Launch attack
        attacker.contribute{value: 2 ether}();

        // Deadline passes
        vm.warp(block.timestamp + 31 days);

        attacker.attack();

        // Vulnerability check
        assertGt(address(attacker).balance, 2 ether);
    }
}