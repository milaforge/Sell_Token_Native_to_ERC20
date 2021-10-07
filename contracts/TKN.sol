//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

// Pausable, PullPayment, AccessControl

contract TKN is ERC20 {
  constructor(string memory name, string memory symbol)
    public
    ERC20(name, symbol)
  {
      console.log("Minting ...");
    _mint(msg.sender, 10000 * 10**decimals());
  }
}
