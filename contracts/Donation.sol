//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";

contract Donate {
  event LogDonation(address indexed, uint256);
  mapping(address => uint256) public donates;

  function donate(uint256 amount) external payable {
    require(msg.value >= amount, "not enought ETH sent");

    address sender = msg.sender;

    donates[sender] += amount;
    emit LogDonation(sender, msg.value);
  }

  function getBalance() external view returns (uint256) {
    return address(this).balance;
  }

  function getDonationsOfAUser() external view returns (uint256) {
    return donates[msg.sender];
  }

  fallback() external payable {
    console.log("Fallback() Called");
    emit LogDonation(msg.sender, msg.value);
  }

  receive() external payable {
    console.log("receive() called");
    emit LogDonation(msg.sender, msg.value);
  }
}
