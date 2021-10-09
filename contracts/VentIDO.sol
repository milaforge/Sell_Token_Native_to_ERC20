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

import "./Whitelist.sol";

import "hardhat/console.sol";

contract VentIDO is Ownable, AccessControl, Pausable , Whitelist {

  using SafeERC20 for IERC20;


  // **** <Roles> ****
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant POOL_OWNER_ROLE = keccak256("POOL_OWNER_ROLE");
  bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
  // **** </Roles> ****


  // **** <Structs> ****
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
    PoolStatus status; //: by default “Upcoming”,

    uint256 totalTokenProvided; //TODO is it about allowance?
    uint exchangeRate;          //TODO how to?
    uint tokenPrice;            //TODO how to?
    uint256 totalTokenSold;//TODO after implementing Deposit and Withdrawal

  }

  struct InvestorInfo {
    address userAddress;
    uint256 allocation;
    mapping(address => uint256) rewardDebt; // Reward debt
  }
  // **** </Structs> ****



  // **** <State> ****
  PoolInfo[] public poolInfo;
  mapping(address => InvestorInfo) public investorInfo;
  // **** </State> ****



  // **** <Events> ****
  event PoolCreated(address indexed poolOwner);
  event InvestInPool(address indexed investor, uint256 amount);
  event RetrieveTokensFromPool(address indexed investor, uint256 amount);
  event RetrieveFundsFromPool(address indexed poolOwner, uint256 amount);
  event LogDepositReceived(address indexed from, bytes data);
  // **** </Events> ****



  constructor() {
    _setupRole(ADMIN_ROLE, _msgSender());
  }



  // **** <External> ****
  function getPoolDetails() external view returns (PoolInfo memory) {
      require(
        address(poolInfo[0].walletAddress) == address(0), "Pool not created yet");

        // Pool data that needs to be retrieved:
        //   - Investors and their allocations //TODO after implementing Deposit
        //   - Number of tokens sold           //TODO after implementing Deposit and Withdrawal
        //   - Token price                     //TODO 
        //   - Exchange rate                   //TODO
        //   - Funding Target / hard cap
        //   - Total tokens provided for the pool
        //   - Max allocation per user
        //   - Min allocation per user
        //   - IDO start timestamp
      // return {
      //   min: 1
      // };
      return poolInfo[0];
  }

  function deposit() external payable onlyWhitelisted returns (bool) {

    // check if pool is still open?
    require(isPoolOpen(poolInfo[0]), "Pool not open!");

    //TODO check if hard cap is reached
    
    // TODO keep record of user participation
  }

  // When no other function matches, not even receive()
  fallback() external payable {
    require(_msgData().length == 0, "non-existent function called");
    emit LogDepositReceived(_msgSender(), _msgData());
  }

  receive() external payable {
    emit LogDepositReceived(_msgSender(), _msgData());
  }
  // **** </External> ****



  // **** <External-Admin> ****
  function setPoolOwner(address poolOwnerAddress) external onlyOwner {
    grantRole(POOL_OWNER_ROLE, poolOwnerAddress);
  }
  // **** </External-Admin> ****


  
  // **** <External-PoolOwner> ****
  function createPool(PoolInfo memory pool) external onlyRole(POOL_OWNER_ROLE)
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
  function addWhitelistUsers(address[] whitelistedAddresses) external onlyRole(POOL_OWNER_ROLE) {
    addToWhitelist(whitelistedAddresses);
  }
  // **** </External-PoolOwner> ****



  // **** <Internal> ****
  function getInvestorsAndTheirAllocations() internal returns (InvestorInfo[]){
    return investorInfo; //TODO Iterate through it. needs Iterable.
  }  
  // **** </Internal> ****



  // **** <Private> ****
  function isPoolOpen(PoolInfo _poolInfo) private view returns(bool) {
    return (poolInfo[0].endDateTime < block.timestamp && poolInfo[0].status PoolStatus.Ongoing);
  } 
  // **** </Private> ****
}
