//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPool.sol";
import "./Validations.sol";

contract Pool is IPool, Ownable {
  PoolModel private poolInformation;
  IDOInfo private idoInfo;

  address[] private participantsAddress;
  mapping(address => uint256) private collaborations;
  uint256 private _weiRaised = 0;

  event LogPoolContractAddress(address);
  event LogPoolStatusChanged(uint256 currentStatus, uint256 newStatus);
  event LogDeposit(address indexed participant, uint256 amount);

  constructor(PoolModel memory _pool) {
    _preValidatePoolCreation(_pool);
    poolInformation = IPool.PoolModel({
      hardCap: _pool.hardCap,
      softCap: _pool.softCap,
      startDateTime: _pool.startDateTime,
      endDateTime: _pool.endDateTime,
      status: _pool.status
    });

    emit LogPoolContractAddress(address(this));
  }

  modifier _addIDOInfoOnlyOnce() {
    require(
      address(idoInfo.walletAddress) == address(0),
      "already added IDO info"
    );
    _;
  }

  function addIDOInfo(IDOInfo memory _pdi)
    external
    override
    onlyOwner
    _addIDOInfoOnlyOnce
  {
    _preIDOInfoUpdate(_pdi);

    idoInfo.walletAddress = _pdi.walletAddress;
    idoInfo.projectTokenAddress = _pdi.projectTokenAddress;
    idoInfo.minAllocationPerUser = _pdi.minAllocationPerUser;
    idoInfo.maxAllocationPerUser = _pdi.maxAllocationPerUser;
    idoInfo.totalTokenProvided = _pdi.totalTokenProvided;
    idoInfo.exchangeRate = _pdi.exchangeRate;
    idoInfo.tokenPrice = _pdi.tokenPrice;
    idoInfo.totalTokenSold = _pdi.totalTokenSold;
  }

  receive() external payable {
    revert("Call deposit()");
  }

  function deposit(address _sender)
    external
    payable
    override
    onlyOwner
    _pooIsOngoing(poolInformation)
    _hardCapNotPassed(poolInformation.hardCap)
  {
    uint256 _amount = msg.value;

    _increaseRaisedWEI(_amount);
    _addToParticipants(_sender);
    emit LogDeposit(_sender, _amount);
  }

  function unclaimedTokens(address _participant)
    external
    view
    override
    onlyOwner
    _isPoolFinished(poolInformation)
    returns (uint256 _tokensAmount)
  {
    uint256 amountParticipated = collaborations[_participant];
    _tokensAmount = amountParticipated / _getTotalRaised(); //TODO do the calculation here
  }

  function updatePoolStatus(uint256 _newStatus) external override onlyOwner {
    require(_newStatus < 5 && _newStatus >= 0, "wrong Status;");
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
      participationDetails: _getParticipantsInfo(),
      totalRaised: _getTotalRaised(),
      pool: poolInformation,
      poolDetails: idoInfo
    });
  }

  function _getParticipantsInfo()
    private
    view
    returns (Participations memory participants)
  {
    uint256 count = participantsAddress.length;

    ParticipantDetails[] memory parts = new ParticipantDetails[](count);

    for (uint256 i = 0; i < count; i++) {
      address userAddress = participantsAddress[i];
      parts[i] = ParticipantDetails(userAddress, collaborations[userAddress]);
    }
    participants.count = count;
    participants.investorsDetails = parts;
  }

  function _getTotalRaised() private view returns (uint256 amount) {
    amount = _weiRaised;
  }

  function _increaseRaisedWEI(uint256 _amount) private {
    require(_amount > 0, "No WEI found!");

    uint256 _weiBeforeRaise = _getTotalRaised();
    _weiRaised += msg.value;

    assert(_weiRaised > _weiBeforeRaise); //TODO requires more research
  }

  function _addToParticipants(address _address) private {
    if (!_didAlreadyParticipated(_address)) _addToListOfParticipants(_address);
    _keepRecordOfWEIRaised(_address);
  }

  function _didAlreadyParticipated(address _address)
    private
    view
    returns (bool isIt)
  {
    isIt = collaborations[_address] > 0;
  }

  function _addToListOfParticipants(address _address) private {
    participantsAddress.push(_address);
  }

  function _keepRecordOfWEIRaised(address _address) private {
    collaborations[_address] += msg.value;
  }

  function _preValidatePoolCreation(IPool.PoolModel memory _pool) private view {
    require(_pool.hardCap > 0, "hardCap must be > 0");
    require(_pool.softCap > 0, "softCap must be > 0");
    require(_pool.softCap < _pool.hardCap, "softCap must be < hardCap");
    require(
      //solhint-disable-next-line not-rely-on-time
      _pool.startDateTime > block.timestamp,
      "startDateTime must be > now"
    );
    require(
      //solhint-disable-next-line not-rely-on-time
      _pool.endDateTime > block.timestamp,
      "endDate must be at future time"
    ); //TODO how much in the future?
  }

  function _preIDOInfoUpdate(IDOInfo memory _idoInfo) private pure {
    require(
      address(_idoInfo.walletAddress) != address(0),
      "walletAddress is a zero address!"
    );
    require(_idoInfo.minAllocationPerUser > 0, "minAllocation must be > 0!");
    require(
      _idoInfo.minAllocationPerUser < _idoInfo.maxAllocationPerUser,
      "minAllocation must be < max!"
    );

    require(_idoInfo.exchangeRate > 0, "exchangeRate must be > 0!");
    require(_idoInfo.tokenPrice > 0, "token price must be > 0!");
  }

  modifier _pooIsOngoing(IPool.PoolModel storage _pool) {
    require(_pool.status == IPool.PoolStatus.Ongoing, "Pool not open!");
    // solhint-disable-next-line not-rely-on-time
    require(_pool.startDateTime >= block.timestamp, "Pool not started yet!");
    // solhint-disable-next-line not-rely-on-time
    require(_pool.endDateTime >= block.timestamp, "pool endDate passed!");

    _;
  }

  modifier _isPoolFinished(IPool.PoolModel storage _pool) {
    require(
      _pool.status == IPool.PoolStatus.Finished,
      "Pool status not Finished!"
    );
    _;
  }

  modifier _hardCapNotPassed(uint256 _hardCap) {
    uint256 _beforeBalance = _getTotalRaised();

    uint256 sum = _getTotalRaised() + msg.value;
    require(sum <= _hardCap, "hardCap reached!");
    assert(sum > _beforeBalance);
    _;
  }
}
