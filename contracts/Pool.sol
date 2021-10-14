//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPool.sol";
import "./IWhitelist.sol";
import "./Validations.sol";
import "hardhat/console.sol";

contract Pool is IPool, Ownable {
  PoolModel private poolInformation; // pool information
  PoolDetailedInfo private poolDetailedInfo; // ido information (pool details)
  IWhitelist private whitelist;

  address[] private participantsAddress;
  mapping(address => uint256) private participations;
  uint256 private _weiRaised = 0;

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

  function addPoolDetailedInfo(PoolDetailedInfo memory _pdi)
    external
    override
    onlyOwner
  {
    _prePoolDetailUpdate(_pdi);

    whitelist = IWhitelist(_pdi.whitelistContractAddress); // Whitelist address

    poolDetailedInfo.walletAddress = _pdi.walletAddress;
    poolDetailedInfo.projectTokenAddress = _pdi.projectTokenAddress;
    poolDetailedInfo.minAllocationPerUser = _pdi.minAllocationPerUser;
    poolDetailedInfo.maxAllocationPerUser = _pdi.maxAllocationPerUser;
    poolDetailedInfo.totalTokenProvided = _pdi.totalTokenProvided;
    poolDetailedInfo.exchangeRate = _pdi.exchangeRate;
    poolDetailedInfo.tokenPrice = _pdi.tokenPrice;
    poolDetailedInfo.totalTokenSold = _pdi.totalTokenSold;
  }

  receive() external payable {
    revert("Call deposit()");
  }

  function deposit(address _sender)
    external
    payable
    override
    onlyOwner
    pooIsOngoing(poolInformation)
    hardCapNotPassed(poolInformation.hardCap, msg.value)
    isWhitelisted(_sender)
  {
    uint256 _amount = msg.value;
    increaseRaisedWEI(_amount);
    _addToParticipants(_sender);
    emit Deposit(_sender, _amount);

    console.log("Pool Balance", address(this).balance); //TODO debug
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
    private
    view
    returns (Participations memory participants)
  {
    uint256 count = participantsAddress.length;

    ParticipantDetails[] memory parts = new ParticipantDetails[](count);

    for (uint256 i = 0; i < count; i++) {
      address userAddress = participantsAddress[i];
      parts[i] = ParticipantDetails(userAddress, participations[userAddress]);
    }
    participants.count = count;
    participants.investorsDetails = parts;
  }

  function getTotalRaised() private view returns (uint256 amount) {
    amount = _weiRaised;
  }

  function increaseRaisedWEI(uint256 _amount) private {
    require(_amount > 0, "No WEI found!");

    uint256 _weiBeforeRaise = getTotalRaised();
    _weiRaised += msg.value;

    assert(_weiRaised > _weiBeforeRaise); //TODO requires more research
  }

  function _addToParticipants(address _address) private {
    if (didAlreadyParticipated(_address)) addToListOfParticipants(_address);
    keepRecordOfWEIRaised(_address);
  }

  function didAlreadyParticipated(address _address)
    private
    view
    returns (bool isIt)
  {
    isIt = participations[_address] > 0; //TODO is it safe?
  }

  function addToListOfParticipants(address _address) private {
    participantsAddress.push(_address);
  }

  function keepRecordOfWEIRaised(address _address)
    private
  {
    participations[_address] += msg.value;
    console.log(_address, "Participated", msg.value);
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

  modifier pooIsOngoing(IPool.PoolModel storage _poolInfo) {
    require(
      _poolInfo.status == IPool.PoolStatus.Ongoing &&
        // solhint-disable-next-line not-rely-on-time
        _poolInfo.startDateTime >= block.timestamp &&
        // solhint-disable-next-line not-rely-on-time
        _poolInfo.endDateTime >= block.timestamp,
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

  modifier isWhitelisted(address _address) {
    console.log(msg.sender, _address);
    require(whitelist.isWhitelisted(_address), "Not whitelisted");
    _;
  }
}
