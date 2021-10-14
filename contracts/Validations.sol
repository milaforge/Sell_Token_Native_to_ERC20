//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library Validations {
  function revertOnZeroAddress(address _address) internal pure {
    require(address(0) != address(_address), "zero address not accepted!");
  }
}
