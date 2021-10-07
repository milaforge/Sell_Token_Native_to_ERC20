// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

contract Pool {

    event LogDepositReceived(address);
    bytes32 private a = keccak256('test');

    constructor(uint age) public {
        console.log("Initialized with", age);

    }

    fallback() external payable {
        require(msg.data.length == 0, "not good");
        emit LogDepositReceived(msg.sender);
    }

}
