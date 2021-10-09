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

  function addToWhitelist(address _address) internal {
    require(_address != address(0), "No correct address");
    whitelist[_address] = true;
    emit AddedToWhitelist(_address);
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
