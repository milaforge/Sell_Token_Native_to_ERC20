//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
  mapping(address => bool) internal whitelist;

  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed accout);

  modifier onlyWhitelisted() {
    require(isWhitelisted(_msgSender()), "Not Whitelisted");
    _;
  }

  function addToWhitelist(address[] memory _address) internal {
    require(_address.length > 0, "an array is expected!");

    for (uint256 i = 0; i < _address.length; i++) {
      address userAddress = _address[i];

      require(userAddress != address(0), "zero address is not accepted!");

      whitelist[userAddress] = true;

      emit AddedToWhitelist(userAddress);
    }
  }

  function removeFromWhitelist(address _address) internal {
    require(_address != address(0), "No correct address");
    whitelist[_address] = false;
    emit RemovedFromWhitelist(_address);
  }

  function isWhitelisted(address _address) internal view returns (bool) {
    require(_address != address(0), "No correct address");
    return whitelist[_address];
  }
}
