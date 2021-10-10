//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

//TODO the following imports will be needed for future use-cases;
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/security/PullPayment.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IPool.sol";
import "./Pool.sol";
import "./Whitelist.sol";

import "hardhat/console.sol"; //TODO debug

contract VentIDO is Pausable, AccessControl, Whitelist, Ownable {
  bytes32 private constant POOL_OWNER_ROLE = keccak256("POOL_OWNER_ROLE");
  Pool private pool;

  event LogPoolOwnerRoleGranted(address indexed owner);
  event LogPoolOwnerRoleRevoked(address indexed owner);
  event LogPoolCreated(address indexed poolOwner);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function createPool(IPool.PoolModel calldata _poolInfo)
    external
    payable
    onlyRole(POOL_OWNER_ROLE)
  {
    pool = new Pool(_poolInfo);
    emit LogPoolCreated(_msgSender());
    //TODO check if pool is created
  }

  function investInPool() external payable {
    bool success = pool.deposit();
    require(success, "Investing failed!");
  }

  function addAddressesToWhitelist(address[] calldata whitelistedAddresses)
    external
    onlyRole(POOL_OWNER_ROLE)
  {
    addToWhitelist(whitelistedAddresses);
  }
}
