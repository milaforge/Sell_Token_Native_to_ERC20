//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Validations.sol";

contract Whitelist {
  mapping(address => bool) private whitelistedAddressesMap;
  address[] private whitelistedAddressesArray;

  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed accout);

  constructor() {}

  function addToWhitelist(address[] calldata _addresses)
    internal
    returns (bool success)
  {
    require(_addresses.length > 0, "an array of address is expected");

    for (uint256 i = 0; i < _addresses.length; i++) {
      address userAddress = _addresses[i];

      Validations.revertOnZeroAddress(userAddress);

      if (!isAddressWhitelisted(userAddress))
        addAddressToWhitelist(userAddress);
    }
    success = true;
  }

  function isWhitelisted(address _address)
    internal
    view
    _nonZeroAddress(_address)
    returns (bool isIt)
  {
    isIt = whitelistedAddressesMap[_address];
  }

  function getWhitelistedUsers() internal view returns (address[] memory) {
    uint256 count = whitelistedAddressesArray.length;

    address[] memory _whitelistedAddresses = new address[](count);

    for (uint256 i = 0; i < count; i++) {
      _whitelistedAddresses[i] = whitelistedAddressesArray[i];
    }
    return _whitelistedAddresses;
  }

  modifier _nonZeroAddress(address _address) {
    Validations.revertOnZeroAddress(_address);
    _;
  }

  function isAddressWhitelisted(address _address)
    private
    view
    returns (bool isIt)
  {
    isIt = whitelistedAddressesMap[_address];
  }

  function addAddressToWhitelist(address _address) private {
    whitelistedAddressesMap[_address] = true;
    whitelistedAddressesArray.push(_address);
    emit AddedToWhitelist(_address);
  }
}
