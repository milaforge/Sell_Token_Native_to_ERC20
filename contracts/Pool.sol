//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPool.sol";
import "./Whitelist.sol";

import "hardhat/console.sol";

contract Pool is IPool, Whitelist, AccessControl, Ownable {
  PoolModel private poolInformation; // pool information
  PoolDetailedInfo private poolDetailedInfo; // ido information (pool details)

  address[] private participantsAddress;
  mapping(address => ParticipantDetails) private participantsDetails;
  uint256 private _weiRaised;

  event LogPoolContractAddress(address _address);
  event LogPoolStatusChanged(uint256 currentStatus, uint256 newStatus);
  event Deposit(address indexed investor, uint256 amount);

  constructor(PoolModel memory _poolInfo) {
    _preValidatePoolCreation(_poolInfo);
    poolInformation = IPool.PoolModel({
      hardCap: _poolInfo.hardCap,
      softCap: _poolInfo.softCap,
      startDateTime: _poolInfo.startDateTime,
      endDateTime: _poolInfo.endDateTime,
      status: _poolInfo.status
    });

    emit LogPoolContractAddress(address(this));
    console.log("Pool Created", address(this));
  }

  function addPoolDetailedInfo(PoolDetailedInfo memory _detailedPoolInfo)
    external
    override
    onlyOwner
  {
    _prePoolDetailUpdate(_detailedPoolInfo);
    poolDetailedInfo.walletAddress = _detailedPoolInfo.walletAddress;
    poolDetailedInfo.projectTokenAddress = _detailedPoolInfo
      .projectTokenAddress;
    poolDetailedInfo.minAllocationPerUser = _detailedPoolInfo
      .minAllocationPerUser;
    poolDetailedInfo.maxAllocationPerUser = _detailedPoolInfo
      .maxAllocationPerUser;
    poolDetailedInfo.totalTokenProvided = _detailedPoolInfo.totalTokenProvided;
    poolDetailedInfo.exchangeRate = _detailedPoolInfo.exchangeRate;
    poolDetailedInfo.tokenPrice = _detailedPoolInfo.tokenPrice;
    poolDetailedInfo.totalTokenSold = _detailedPoolInfo.totalTokenSold;
  }

  // accidentally sent ETH's are reverted;
  receive() external payable pooIsOngoing(poolInformation) {
    revert("use deposit() method.");
  }

  function updatePoolStatus(uint256 _newStatus) external override onlyOwner {
    require(_newStatus < 5, "wrong Status;");
    uint256 currentStatus = uint256(poolInformation.status);
    poolInformation.status = PoolStatus(_newStatus);
    emit LogPoolStatusChanged(currentStatus, _newStatus);
  }

  function getCompletePoolDetails()
    external
    view
    override
    poolIsCreated(poolInformation)
    returns (CompletePoolDetails memory poolDetails)
  {
    poolDetails = CompletePoolDetails({
      participationDetails: getParticipantsInfo(),
      totalRaised: getTotalRaised(),
      poolInfo: poolInformation,
      poolDetails: poolDetailedInfo
    });
  }

  function getParticipantsInfo()
    public
    view
    override
    poolIsCreated(poolInformation)
    returns (Participations memory participants)
  {
    uint256 count = participantsAddress.length;
    ParticipantDetails[] memory parts = new ParticipantDetails[](count);

    for (uint256 i = 0; i < participantsAddress.length; i++) {
      address userAddress = participantsAddress[i];
      parts[i] = participantsDetails[userAddress];
    }
    participants.count = count;
    participants.investorsDetails = parts;
  }

  function deposit()
    external
    payable
    override
    onlyWhitelisted
    pooIsOngoing(poolInformation)
    hardCapNotPassed(poolInformation.hardCap, msg.value)
    returns (bool success)
  {
    _addToParticipants(_msgSender());
    uint256 _weiBeforeRaise = _weiRaised;
    _weiRaised += msg.value;
    success = _weiRaised > _weiBeforeRaise;
    require(success, "Deposit overflow?!");
    emit Deposit(_msgSender(), msg.value);
  }

  function getTotalRaised() internal view returns (uint256 amount) {
    amount = _weiRaised;
  }

  function _addToParticipants(address _address) private {
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
    require(_poolInfo.softCap < _poolInfo.hardCap, "softCap must be < hardCap");
    require(
      //solhint-disable-next-line not-rely-on-time
      _poolInfo.startDateTime > block.timestamp,
      "startDateTime must be > now"
    );
    require(
      //solhint-disable-next-line not-rely-on-time
      _poolInfo.endDateTime > block.timestamp,
      "endDate must be at future time"
    ); //TODO how much in the future?
  }

  function _prePoolDetailUpdate(PoolDetailedInfo memory _poolDetailedInfo)
    private
    pure
  {
    require(
      address(_poolDetailedInfo.walletAddress) != address(0),
      "walletAddress is a zero address!"
    );
    require(
      _poolDetailedInfo.minAllocationPerUser > 0,
      "minAllocation must be > 0!"
    );
    require(
      _poolDetailedInfo.minAllocationPerUser <
        _poolDetailedInfo.maxAllocationPerUser,
      "minAllocation must be < max!"
    );

    require(_poolDetailedInfo.exchangeRate > 0, "exchangeRate must be > 0!");
    require(_poolDetailedInfo.tokenPrice > 0, "token price must be > 0!");
  }

  modifier poolIsCreated(IPool.PoolModel storage _poolInfo) {
    require(_poolInfo.hardCap > 0, "Pool not created yet!");
    _;
  }

  modifier pooIsOngoing(IPool.PoolModel storage _poolInfo) {
    require(
      uint256(_poolInfo.status) == uint256(IPool.PoolStatus.Ongoing) &&
        // solhint-disable-next-line not-rely-on-time
        _poolInfo.startDateTime >= block.timestamp &&
        // solhint-disable-next-line not-rely-on-time
        _poolInfo.endDateTime <= block.timestamp,
      "Pool not open!"
    );
    _;
  }

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
