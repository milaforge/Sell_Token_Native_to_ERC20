//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Validations.sol";

contract Whitelist is Ownable, Validations {
  mapping(address => bool) internal whitelistedUsers;
  uint256 internal countOfUsersWhitelisted = 0;

  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed accout);

  modifier onlyWhitelisted() {
    require(isWhitelisted(_msgSender()), "Not Whitelisted");
    _;
  }

  function addToWhitelist(address[] memory _addresses)
    internal
    onlyOwner
    returns (bool)
  {
    require(_addresses.length > 0, "an array of address is expected!");

    for (uint256 i = 0; i < _addresses.length; i++) {
      address userAddress = _addresses[i];
      require(userAddress != address(0), "zero address is not accepted!");

      whitelistedUsers[userAddress] = true;

      countOfUsersWhitelisted++;

      emit AddedToWhitelist(userAddress);
    }

    return true;
  }

  function removeFromWhitelist(address _address)
    internal
    nonZeroAddress(_address)
    onlyOwner
  {
    whitelistedUsers[_address] = false;
    countOfUsersWhitelisted--;
    emit RemovedFromWhitelist(_address);
  }

  function isWhitelisted(address _address)
    internal
    view
    nonZeroAddress(_address)
    returns (bool)
  {
    return whitelistedUsers[_address];
  }
}
