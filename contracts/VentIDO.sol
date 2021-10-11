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
  IPool private pool;

  event LogPoolOwnerRoleGranted(address indexed owner);
  event LogPoolOwnerRoleRevoked(address indexed owner);
  event LogPoolCreated(address indexed poolOwner);
  event LogPoolStatusChanged(address indexed poolOwner, uint256 newStatus);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  // Admin grants PoolOwner role to some address;
  function grantPoolOwnerRole(address _address)
    external
    onlyOwner
    nonZeroAddress(_address)
    returns (bool success)
  {
    grantRole(POOL_OWNER_ROLE, _address);
    success = true;
  }

  // Admin revokes PoolOwner role feom an address;
  function revokePoolOwnerRole(address _address)
    external
    onlyOwner
    nonZeroAddress(_address)
  {
    revokeRole(POOL_OWNER_ROLE, _address);
  }

  function createPool(
    uint256 _hardCap,
    uint256 _softCap,
    uint256 _startDateTime,
    uint256 _endDateTime,
    address _walletAddress
  ) external payable onlyRole(POOL_OWNER_ROLE) returns (IPool) {
    IPool.PoolModel memory model = IPool.PoolModel({
      hardCap: _hardCap,
      softCap: _softCap,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      walletAddress: _walletAddress,
      projectTokenAddress: _walletAddress, //TODO update this address when adding Token and withdrawal()
      minAllocationPerUser: 1,
      maxAllocationPerUser: 1000,
      status: IPool.PoolStatus.Upcoming,
      totalTokenProvided: 0,
      exchangeRate: 1,
      tokenPrice: 1,
      totalTokenSold: 0
    });

    pool = new Pool(model);
    emit LogPoolCreated(_msgSender());
    return pool;
  }

  function getPoolDetails()
    external
    view
    returns (IPool.PoolDetails memory poolDetails)
  {
    poolDetails = pool.getPoolDetails();
  }

  function updatePoolStatus(uint256 newStatus)
    external
    onlyRole(POOL_OWNER_ROLE)
  {
    pool.updatePoolStatus(newStatus);
    emit LogPoolStatusChanged(_msgSender(), newStatus);
  }

  function addAddressesToWhitelist(address[] calldata whitelistedAddresses)
    external
    onlyRole(POOL_OWNER_ROLE)
  {
    addToWhitelist(whitelistedAddresses);
  }

  function investInPool() external payable {
    bool success = pool.deposit();
    require(success, "Investing failed!");
  }
}
