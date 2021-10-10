//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPool.sol";
import "./Whitelist.sol";

import "hardhat/console.sol";

contract Pool is IPool, Whitelist, AccessControl, Ownable {
  PoolModel private poolInformation;
  address[] private participantsAddress;
  mapping(address => ParticipantDetails) private participantsDetails;
  uint256 private _weiRaised;

  event Deposit(address indexed investor, uint256 amount);

  constructor(PoolModel memory _poolInfo) {
    _preValidatePoolCreation(_poolInfo);

    poolInformation = IPool.PoolModel({
      hardCap: _poolInfo.hardCap,
      softCap: _poolInfo.softCap,
      startDateTime: _poolInfo.startDateTime,
      endDateTime: _poolInfo.endDateTime,
      walletAddress: _poolInfo.walletAddress,
      projectTokenAddress: _poolInfo.projectTokenAddress,
      minAllocationPerUser: _poolInfo.minAllocationPerUser,
      maxAllocationPerUser: _poolInfo.maxAllocationPerUser,
      status: IPool.PoolStatus.Ongoing,
      totalTokenProvided: _poolInfo.totalTokenProvided,
      exchangeRate: _poolInfo.exchangeRate,
      tokenPrice: _poolInfo.tokenPrice,
      totalTokenSold: _poolInfo.totalTokenSold
    });
  }

  // accidentally sent ETH's are reverted;
  receive() external payable pooIsOngoing(poolInformation) {
    revert("use deposit() method.");
  }

  function getPoolDetails()
    external
    view
    override
    poolIsCreated(poolInformation)
    returns (PoolDetails memory poolDetails)
  {
    uint256 count = participantsAddress.length - 1;

    ParticipantDetails[] memory investorsInfo = new ParticipantDetails[](count);

    for (uint256 i = 0; i < participantsAddress.length; i++) {
      address userAddress = participantsAddress[i];

      investorsInfo[i] = ParticipantDetails({
        addressOfParticipant: userAddress,
        totalRaisedInWei: participantsDetails[userAddress].totalRaisedInWei
      });
    }

    poolDetails = PoolDetails({
      investorsAndAllocations: investorsInfo,
      countOfInvestors: investorsInfo.length,
      totalRaised: getTotalRaised(),
      hardCap: poolInformation.hardCap,
      softCap: poolInformation.softCap,
      minAllocationPerUser: poolInformation.minAllocationPerUser,
      maxAllocationPerUser: poolInformation.maxAllocationPerUser,
      startDateTime: poolInformation.startDateTime
    });
  }

  function deposit()
    public
    payable
    override
    onlyWhitelisted
    pooIsOngoing(poolInformation)
    hardCapNotPassed(poolInformation.hardCap, msg.value)
    returns (bool success)
  {
    addToParticipants(_msgSender());
    uint256 _weiBeforeRaise = _weiRaised;
    _weiRaised += msg.value;
    success = _weiRaised > _weiBeforeRaise;
    require(success, "Deposit failed!");
    emit Deposit(_msgSender(), msg.value);
  }

  function getTotalRaised() internal view returns (uint256 amount) {
    amount = _weiRaised;
  }

  function addToParticipants(address _address) private {
    if (participantsDetails[_address].totalRaisedInWei < 1) {
      participantsAddress.push(_address);
    }
    participantsDetails[_address].addressOfParticipant = _address;
    participantsDetails[_address].totalRaisedInWei += msg.value;
  }

  function _preValidatePoolCreation(IPool.PoolModel memory _poolInfo)
    private
    view
  {
    require(_poolInfo.hardCap > 0, "hardCap must be > 0");
    require(_poolInfo.softCap > 0, "softCap must be > 0");
    require(_poolInfo.softCap > _poolInfo.hardCap, "softCap must be < hardCap");

    //solhint-disable-next-line not-rely-on-time
    require(
      _poolInfo.startDateTime > block.timestamp,
      "startDateTime must be > now"
    );
    require(
      //solhint-disable-next-line not-rely-on-time
      _poolInfo.endDateTime > block.timestamp,
      "endDate must be at future time"
    ); //TODO how much in the future?
    require(
      address(_poolInfo.walletAddress) != address(0),
      "walletAddress is a zero address!"
    );
    require(
      address(_poolInfo.projectTokenAddress) != address(0),
      "TokenAddress is a zero address!"
    );
    require(_poolInfo.minAllocationPerUser > 0, "minAllocation must be > 0!");
    require(
      _poolInfo.minAllocationPerUser < _poolInfo.maxAllocationPerUser,
      "minAllocation must be < max!"
    );
    require(
      _poolInfo.status == IPool.PoolStatus.Ongoing,
      "Pool status must be ongoing!"
    );
    require(
      _poolInfo.totalTokenProvided > 0,
      "totalTokenProvided must be > 0!"
    );
    require(_poolInfo.exchangeRate > 0, "exchangeRate must be > 0!");
    require(_poolInfo.tokenPrice > 0, "token price must be > 0!");
    require(_poolInfo.totalTokenSold == 0, "total tokens sold must be = 0!");
  }

  function _preDepositValidation(uint256 _amount) internal view {
    //TODO
  }

  modifier poolIsCreated(IPool.PoolModel storage _poolInfo) {
    require(_poolInfo.hardCap > 0, "Pool not created yet!");
    _;
  }

  modifier pooIsOngoing(IPool.PoolModel storage _poolInfo) {
    require(
      _poolInfo.status == IPool.PoolStatus.Ongoing &&
        // solhint-disable-next-line not-rely-on-time
        _poolInfo.startDateTime >= block.timestamp &&
        // solhint-disable-next-line not-rely-on-time
        _poolInfo.endDateTime <= block.timestamp,
      "Pool not open!"
    );
    _;
  }

  // make sure hardCap not passed
  modifier hardCapNotPassed(uint256 _hardCap, uint256 _depositAmount) {
    require(
      address(this).balance + // TODO can I access pool balance from here?
        _depositAmount <=
        _hardCap,
      "hardCap reached!"
    );
    _;
  }
}
