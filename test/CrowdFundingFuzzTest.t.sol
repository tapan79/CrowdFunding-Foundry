// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/CrowdFunding.sol";

contract CrowdFundingFuzzTest is Test {

    CrowdFunding crowdFunding;

    address internal OWNER = makeAddr("OWNER");
    address internal ALICE = makeAddr("ALICE");
    address internal BOB = makeAddr("BOB");

    uint target = 10 ether;
    uint deadline = 30 days;

    function setUp() public {
        vm.prank(OWNER);
        crowdFunding = new CrowdFunding(target, deadline);
    }

    // Verifies for contribution of minimum amount
    function testFuzzContribution(uint256 amount) public {
    // Consider only valid contributions
    vm.assume(amount >= 100 wei);
    vm.assume(amount <= 100 ether);

    // Give ALICE enough ETH
    vm.deal(ALICE, amount);

    // ALICE contributes
    vm.prank(ALICE);
    crowdFunding.contribution{value: amount}();

    // Verify contribution
    assertEq(crowdFunding.contributors(ALICE), amount);

    // Verify raised amount
    assertEq(crowdFunding.raisedamount(), amount);
    }

    // Multiple Contributions by the Same User
    function testFuzzMultipleContribution(uint96 amount1, uint96 amount2) public {
    vm.assume(amount1 >= 100 wei);
    vm.assume(amount2 >= 100 wei);

    vm.deal(ALICE, uint256(amount1) + uint256(amount2));

    vm.startPrank(ALICE);

    crowdFunding.contribution{value: amount1}();
    crowdFunding.contribution{value: amount2}();

    vm.stopPrank();

    assertEq(
        crowdFunding.contributors(ALICE),
        uint256(amount1) + uint256(amount2)
    );

    assertEq(
        crowdFunding.raisedamount(),
        uint256(amount1) + uint256(amount2)
    );
    }

    // Multiple Contributors
    function testFuzzMultipleContributors(uint96 aliceAmount, uint96 bobAmount) public {
    vm.assume(aliceAmount >= 100 wei);
    vm.assume(bobAmount >= 100 wei);

    vm.deal(ALICE, aliceAmount);
    vm.deal(BOB, bobAmount);

    vm.prank(ALICE);
    crowdFunding.contribution{value: aliceAmount}();

    vm.prank(BOB);
    crowdFunding.contribution{value: bobAmount}();

    assertEq(
        crowdFunding.contributors(ALICE),
        aliceAmount
    );

    assertEq(
        crowdFunding.contributors(BOB),
        bobAmount
    );

    assertEq(
        crowdFunding.raisedamount(),
        uint256(aliceAmount) + uint256(bobAmount)
    );
    }

    // Contribution After Deadline Should Revert
    function testFuzzContributionAfterDeadline(uint96 amount) public {
    vm.assume(amount >= 100 wei);

    vm.deal(ALICE, amount);

    // Move time beyond the campaign deadline
    vm.warp(deadline + 1);

    vm.prank(ALICE);

    vm.expectRevert();

    crowdFunding.contribution{value: amount}();
    }

    // Create Request with Random Values
    function testFuzzCreateRequest(uint96 value) public {
    vm.assume(value > 0);
    vm.assume(value <= 100 ether);

    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Laptop",
        payable(BOB),
        value
    );

    (
        string memory description,
        address recipient,
        uint256 requestValue,
        bool completed,
        uint256 noOfVoters
    ) = crowdFunding.getRequest(0);

    assertEq(description, "Buy Laptop");
    assertEq(recipient, BOB);
    assertEq(requestValue, value);
    assertFalse(completed);
    assertEq(noOfVoters, 0);
    }

    // Vote Request (Random Contributors and Voting) - valid contributor can successfully vote
    function testFuzz_VoteRequest(address contributor, uint96 amount) public {
    vm.assume(contributor != address(0));
    vm.assume(contributor != OWNER);

    amount = uint96(bound(amount, crowdFunding.minimumcontribution(), 10 ether));

    vm.deal(contributor, amount);

    vm.prank(contributor);
    crowdFunding.contribution{value: amount}();

    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Buy Equipment",
        payable(BOB),
        1 ether
    );

    vm.prank(contributor);
    crowdFunding.voterequest(0);

    (
        ,
        ,
        ,
        ,
        uint256 noOfVoters
    ) = crowdFunding.getRequest(0);

    assertEq(noOfVoters, 1);
    }

    // Make Payment (Random Payment Values and State Verification)
    function testFuzz_MakePayment(uint96 paymentAmount) public {
    paymentAmount = uint96(bound(paymentAmount, 1 wei, 5 ether));

    vm.deal(ALICE, 10 ether);

    vm.prank(ALICE);
    crowdFunding.contribution{value: 10 ether}();

    vm.prank(OWNER);
    crowdFunding.createrequest(
        "Vendor Payment",
        payable(BOB),
        paymentAmount
    );

    vm.prank(ALICE);
    crowdFunding.voterequest(0);

    uint256 balanceBefore = BOB.balance;

    vm.prank(OWNER);
    crowdFunding.makepayment(0);

    uint256 balanceAfter = BOB.balance;

    assertEq(balanceAfter - balanceBefore, paymentAmount);

    (
        ,
        ,
        ,
        bool completed,
        uint256 noOfVoters
    ) = crowdFunding.getRequest(0);

    assertTrue(completed);
    assertEq(noOfVoters, 1);
    }
}