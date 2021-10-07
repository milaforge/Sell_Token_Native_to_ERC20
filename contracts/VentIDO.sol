// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

contract VentIDO {
    
  event LogDepositReceived(address);
  bytes32 private a = keccak256('test');

  constructor(uint256 age) {
    console.log("Initialized with", age);
  }

  fallback() external payable {
    require(msg.data.length == 0, "not good");
    emit LogDepositReceived(msg.sender);
  }
}
