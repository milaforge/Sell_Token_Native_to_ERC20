//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPool.sol";
import "./Whitelist.sol";
import "./Pool.sol";
import "./Validations.sol";

contract IDO is Pausable, AccessControl, Ownable, Whitelist {
  mapping(address => bool) private _didRefund; // keep track of users who did refund project token.
  bytes32 private constant POOL_OWNER_ROLE = keccak256("POOL_OWNER_ROLE");
  IPool private pool;
  IERC20 private projectToken;

  event LogPoolOwnerRoleGranted(address indexed owner);
  event LogPoolOwnerRoleRevoked(address indexed owner);
  event LogPoolCreated(address indexed poolOwner);
  event LogPoolStatusChanged(address indexed poolOwner, uint256 newStatus);
  event LogWithdraw(address indexed participant, uint256 amount);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  // Admin grants PoolOwner role to some address;
  function grantPoolOwnerRole(address _address)
    external
    onlyOwner
    _nonZeroAddress(_address)
    returns (bool success)
  {
    grantRole(POOL_OWNER_ROLE, _address);
    success = true;
  }

  // Admin revokes PoolOwner role feom an address;
  function revokePoolOwnerRole(address _address)
    external
    onlyOwner
    _nonZeroAddress(_address)
  {
    revokeRole(POOL_OWNER_ROLE, _address);
  }

  function createPool(
    uint256 _hardCap,
    uint256 _softCap,
    uint256 _startDateTime,
    uint256 _endDateTime,
    uint256 _status
  )
    external
    payable
    onlyRole(POOL_OWNER_ROLE)
    _createPoolOnlyOnce
    returns (bool success)
  {
    IPool.PoolModel memory model = IPool.PoolModel({
      hardCap: _hardCap,
      softCap: _softCap,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      status: IPool.PoolStatus(_status)
    });

    pool = new Pool(model);
    emit LogPoolCreated(_msgSender());
    success = true;
  }

  function addIDOInfo(
    address _walletAddress,
    address _projectTokenAddress,
    uint16 _minAllocationPerUser,
    uint256 _maxAllocationPerUser,
    uint256 _totalTokenProvided,
    uint256 _exchangeRate,
    uint256 _tokenPrice,
    uint256 _totalTokenSold
  ) external onlyRole(POOL_OWNER_ROLE) {
    projectToken = IERC20(_projectTokenAddress);
    pool.addIDOInfo(
      IPool.IDOInfo({
        walletAddress: _walletAddress,
        projectTokenAddress: _projectTokenAddress,
        minAllocationPerUser: _minAllocationPerUser,
        maxAllocationPerUser: _maxAllocationPerUser,
        totalTokenProvided: _totalTokenProvided,
        exchangeRate: _exchangeRate,
        tokenPrice: _tokenPrice,
        totalTokenSold: _totalTokenSold
      })
    );
  }

  function updatePoolStatus(uint256 newStatus)
    external
    onlyRole(POOL_OWNER_ROLE)
    returns (bool success)
  {
    pool.updatePoolStatus(newStatus);
    emit LogPoolStatusChanged(_msgSender(), newStatus);
    success = true;
  }

  function addAddressesToWhitelist(address[] calldata whitelistedAddresses)
    external
    onlyRole(POOL_OWNER_ROLE)
  {
    addToWhitelist(whitelistedAddresses);
  }

  function getCompletePoolDetails()
    external
    view
    _poolIsCreated
    returns (IPool.CompletePoolDetails memory poolDetails)
  {
    poolDetails = pool.getCompletePoolDetails();
  }

  // Whitelisted accounts can invest in the Pool by just sending ETH to IDO contract;
  receive() external payable _onlyWhitelisted(msg.sender) {
    pool.deposit{value: msg.value}(msg.sender);
  }

  function refund()
    external
    _onlyWhitelisted(msg.sender)
    _refundOnlyOnce(msg.sender)
  {
    address _receiver = msg.sender;
    _didRefund[_receiver] = true;

    uint256 _amount = pool.unclaimedTokens(_receiver);
    require(_amount > 0, "no participations found!");

    _beforeTransferChecks();

    bool successTokenTransfer = projectToken.transfer(_receiver, _amount);
    require(successTokenTransfer, "Token transfer failed!");

    _afterTransferAsserts();

    emit LogWithdraw(_receiver, _amount);
  }

  function poolAddress()
    external
    view
    onlyRole(POOL_OWNER_ROLE)
    returns (address _pool)
  {
    _pool = address(pool);
  }

  modifier _onlyWhitelisted(address _address) {
    require(isWhitelisted(_address), "Not Whitelisted!");
    _;
  }

  modifier _refundOnlyOnce(address _participant) {
    require(!_didRefund[_participant], "Already claimed!");
    _;
  }

  modifier _createPoolOnlyOnce() {
    require(address(pool) == address(0), "Pool already created!");
    _;
  }

  modifier _poolIsCreated() {
    require(address(pool) != address(0), "Pool not created yet!");
    _;
  }

  function _beforeTransferChecks() private {
    //Some business logic, before transfering tokens to recipient
  }

  function _afterTransferAsserts() private {
    //Some business logic, after project token transfer is possible
  }
}
