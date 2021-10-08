//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "hardhat/console.sol";

contract VentIDO is Ownable, AccessControl, Pausable {
  using SafeERC20 for IERC20;

  // Define role
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant POOL_OWNER_ROLE = keccak256("POOL_OWNER_ROLE");
  bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

  enum PoolStatus {
    Upcoming,
    Cancelled,
    Paused,
    Finished,
    Ongoing
  }

  struct PoolInfo {
    uint256 hardCap; // how much project wants to raise
    uint256 softCap; //how much of the raise will be accepted as successful IDO
    string startDateTime; //TODO how to represent timestamp?
    string endDateTime;
    address walletAddress; // address where Ether is sent
    IERC20 projectTokenAddress; //the address of the token that project is offering in return
    uint16 minAllocationPerUser;
    uint256 maxAllocationPerUser;
    PoolStatus status; //: by default “Upcoming”
  }

  struct InvestorInfo {
    address userAddress;
    uint256 balance;
    mapping(address => uint256) rewardDebt; // Reward debt
  }

  PoolInfo[] public poolInfo;
  mapping(address => InvestorInfo) public investorInfo;

  event PoolCreated(address indexed poolOwner);
  event InvestInPool(address indexed investor, uint256 amount);
  event RetrieveTokensFromPool(address indexed investor, uint256 amount);
  event RetrieveFundsFromPool(address indexed poolOwner, uint256 amount);
  event LogDepositReceived(address indexed from, bytes data);

  constructor(address poolOwner) {
    _setupRole(ADMIN_ROLE, _msgSender());
    _setupRole(POOL_OWNER_ROLE, poolOwner);
  }

  function createPool(PoolInfo memory pool)
    external
    onlyRole(POOL_OWNER_ROLE)
    returns (bool)
  {
    poolInfo.push(
      PoolInfo({
        hardCap: pool.hardCap,
        softCap: pool.softCap,
        startDateTime: pool.startDateTime,
        endDateTime: pool.endDateTime,
        walletAddress: pool.walletAddress,
        projectTokenAddress: pool.projectTokenAddress,
        minAllocationPerUser: pool.minAllocationPerUser,
        maxAllocationPerUser: pool.maxAllocationPerUser,
        status: PoolStatus.Upcoming
      })
    );
    return true;
  }

  // When no other function matches, not even receive()
  fallback() external payable {
    require(_msgData().length == 0, "non-existent function called");
    emit LogDepositReceived(_msgSender(), _msgData());
  }

  receive() external payable {
    emit LogDepositReceived(_msgSender(), _msgData());
  }
}
