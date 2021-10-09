//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./Whitelist.sol";

import "hardhat/console.sol";

contract VentIDO is Ownable, AccessControl, Pausable, Whitelist {
  using SafeERC20 for IERC20;

  // **** <Roles> ****
  bytes32 private constant POOL_OWNER_ROLE = keccak256("POOL_OWNER_ROLE");
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
    uint256 startDateTime; //TODO how to represent timestamp?
    uint256 endDateTime;
    address walletAddress; // address where Ether is sent
    IERC20 projectTokenAddress; //the address of the token that project is offering in return
    uint16 minAllocationPerUser;
    uint256 maxAllocationPerUser;
    PoolStatus status; //: by default “Upcoming”,
    uint256 totalTokenProvided; //TODO is it about allowance?
    uint256 exchangeRate; //TODO how to?
    uint256 tokenPrice; //TODO how to?
    uint256 totalTokenSold; //TODO after implementing Deposit and Withdrawal
  }

  struct InvestorInfo {
    address userAddress;
    uint256 allocation;
  }
  // **** </Structs> ****

  // **** <State> ****
  PoolInfo[] private poolInfo;

  // mapping(address => uint256) public investorsParticipation; // users participation amount
  // **** </State> ****

  // **** <Events> ****
  event PoolCreated(address indexed poolOwner);
  event InvestInPool(address indexed investor, uint256 amount);
  event RetrieveTokensFromPool(address indexed investor, uint256 amount);
  event RetrieveFundsFromPool(address indexed poolOwner, uint256 amount);
  event LogDepositReceived(address indexed from, bytes data);

  // **** </Events> ****

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  // **** <External> ****
  function getPoolDetails() external view {
    // returns (PoolInfo memory)
    require(
      address(poolInfo[0].walletAddress) == address(0),
      "Pool not created yet"
    );

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
    // return poolInfo[0];
  }

  function deposit()
    external
    payable
    onlyWhitelisted
    pooIsOngoing
    returns (bool)
  {
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

  // **** <External-Owner> ****
  function grantPoolOwnerRole(address _ownerAddress) external onlyOwner {
    grantRole(POOL_OWNER_ROLE, _ownerAddress);
    console.log("new Pool owner", _ownerAddress);
  }

  function revokePoolOwnerRole(address _ownerAddress) external onlyOwner {
    revokeRole(POOL_OWNER_ROLE, _ownerAddress);
    console.log("pool has no owner", _ownerAddress);
  }

  // **** </External-Owner> ****

  // **** <External-PoolOwner> ****
  function createPool()
    external
    view
    /*PoolInfo memory pool*/
    onlyRole(POOL_OWNER_ROLE)
    returns (bool)
  {
    console.log("Creating a new pool");
    // poolInfo.push(
    //   PoolInfo({
    //     hardCap: pool.hardCap,
    //     softCap: pool.softCap,
    //     startDateTime: pool.startDateTime,
    //     endDateTime: pool.endDateTime,
    //     walletAddress: pool.walletAddress,
    //     projectTokenAddress: pool.projectTokenAddress,
    //     minAllocationPerUser: pool.minAllocationPerUser,
    //     maxAllocationPerUser: pool.maxAllocationPerUser,
    //     status: PoolStatus.Upcoming
    //   })
    // );

    return true;
  }

  function addWhitelistUsers(address[] calldata whitelistedAddresses)
    external
    onlyRole(POOL_OWNER_ROLE)
  {
    addToWhitelist(whitelistedAddresses);
  }

  // **** </External-PoolOwner> ****

  // **** <Internal> ****
  function getArrayOfInvestorsAllocation() internal {
    // returns (InvestorInfo[] storage s)
    // // I think it is cost effectice to return count of investors and
    // // webapp could use Promise.all(getInvestorInfo(index)); to fetch all invesors info concurrently.
    // InvestorInfo[] storage investors;
    // InvestorInfo[] storage investorsInfo = new InvestorInfo[](
    //   countOfUsersWhitelisted
    // );
    // // the count of whitelisted users is kept in Whitelist.sol
    // for (uint256 i = 0; i < countOfUsersWhitelisted; i++) {}
    // return investorInfo; //TODO Iterate through it. needs Iterable.
  }

  // **** </Internal> ****

  // **** <Private> ****
  // **** </Private> ****

  // **** <Modifier> ****
  modifier pooIsOngoing() {
    require(
      poolInfo[0].status == PoolStatus.Ongoing &&
        poolInfo[0].startDateTime >= block.timestamp &&
        poolInfo[0].endDateTime <= block.timestamp
    );
    _;
  }

  // **** </Modifier> ****
}
