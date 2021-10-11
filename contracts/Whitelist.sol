//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";

contract Whitelist is Context {
  mapping(address => bool) internal _whitelistedUsers;

  uint256 internal countOfUsersWhitelisted = 0;

  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed accout);

  function addToWhitelist(address[] memory _addresses)
    internal
    returns (bool success)
  {
    require(_addresses.length > 0, "an array of address is expected!");

    for (uint256 i = 0; i < _addresses.length; i++) {
      address userAddress = _addresses[i];

      require(addressNotZero(userAddress), "zero address is not accepted!");

      bool whitelisted = _whitelistedUsers[userAddress];
      if (!whitelisted) {
        _whitelistedUsers[userAddress] == true;
        countOfUsersWhitelisted++;
        emit AddedToWhitelist(userAddress);
      }
    }
    success = true;
  }

  function _removeFromWhitelist(address _address)
    internal
    nonZeroAddress(_address)
    removeOnlyOnce(_address)
  {
    _whitelistedUsers[_address] = false;
    countOfUsersWhitelisted--;
    emit RemovedFromWhitelist(_address);
  }

  function _isWhitelisted(address _address)
    internal
    view
    nonZeroAddress(_address)
    returns (bool isWhiteListed)
  {
    isWhiteListed = _whitelistedUsers[_address];
  }

  function addressNotZero(address _address) private pure returns (bool isZero) {
    isZero = (address(0) != address(_address));
  }

  modifier nonZeroAddress(address _address) {
    require(addressNotZero(_address), "zero address not accepted!");
    _;
  }

  modifier onlyWhitelisted() {
    require(_isWhitelisted(_msgSender()), "Not Whitelisted");
    _;
  }

  modifier removeOnlyOnce(address _address) {
    require(_whitelistedUsers[_address], "removing non existent address!");
    _;
  }
}
