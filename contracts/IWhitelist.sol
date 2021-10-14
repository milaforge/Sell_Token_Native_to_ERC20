//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IWhitelist {
  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed accout);

  function addToWhitelist(address[] calldata _addresses)
    external
    returns (bool success);

  function isWhitelisted(address _address)
    external
    view
    returns (bool isWhiteListed);

  function getWhitelistedUsers()
    external
    view
    returns (address[] memory);
}
