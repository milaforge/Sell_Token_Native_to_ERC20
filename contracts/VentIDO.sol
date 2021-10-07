// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

contract VentIDO {
  event LogDepositReceived(address indexed, uint256);
  uint256 private age;

  constructor(uint256 _age) {
    age = _age;
  }

  function getAge() external view returns (uint256) {
    return age;
  }

  // When no other function matches, not even receive
  fallback() external payable {
    require(msg.data.length == 0, "not good");
    emit LogDepositReceived(msg.sender, msg.value);
  }

  receive() external payable {
    emit LogDepositReceived(msg.sender, msg.value);
  }
}
