//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

// Pausable, PullPayment, AccessControl

contract RewardToken is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply
  )  ERC20(name, symbol) {
    _mint(msg.sender, initialSupply * 10**18);
  }
}
