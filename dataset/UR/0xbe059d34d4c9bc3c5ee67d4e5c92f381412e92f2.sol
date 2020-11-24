 

pragma solidity ^0.4.23;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}






 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}




 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}







 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}






contract Arbitrator is Ownable {

  mapping(address => bool) private aribitratorWhitelist;
  address private primaryArbitrator;

  event ArbitratorAdded(address indexed newArbitrator);
  event ArbitratorRemoved(address indexed newArbitrator);
  event ChangePrimaryArbitratorWallet(address indexed newPrimaryWallet);

  constructor() public {
    primaryArbitrator = msg.sender;
  }

  modifier onlyArbitrator() {
    require(aribitratorWhitelist[msg.sender] == true || msg.sender == primaryArbitrator);
    _;
  }

  function changePrimaryArbitrator(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    emit ChangePrimaryArbitratorWallet(walletAddress);
    primaryArbitrator = walletAddress;
  }

  function addArbitrator(address newArbitrator) public onlyOwner {
    require(newArbitrator != address(0));
    emit ArbitratorAdded(newArbitrator);
    aribitratorWhitelist[newArbitrator] = true;
  }

  function deleteArbitrator(address arbitrator) public onlyOwner {
    require(arbitrator != address(0));
    require(arbitrator != msg.sender);  
    emit ArbitratorRemoved(arbitrator);
    delete aribitratorWhitelist[arbitrator];
  }

   
  function isArbitrator(address arbitratorCheck) external view returns(bool) {
    return (aribitratorWhitelist[arbitratorCheck] || arbitratorCheck == primaryArbitrator);
  }
}







contract ApprovedWithdrawer is Ownable {

  mapping(address => bool) private withdrawerWhitelist;
  address private primaryWallet;

  event WalletApproved(address indexed newAddress);
  event WalletRemoved(address indexed removedAddress);
  event ChangePrimaryApprovedWallet(address indexed newPrimaryWallet);

  constructor() public {
    primaryWallet = msg.sender;
  }

  modifier onlyApprovedWallet(address _to) {
    require(withdrawerWhitelist[_to] == true || primaryWallet == _to);
    _;
  }

  function changePrimaryApprovedWallet(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    emit ChangePrimaryApprovedWallet(walletAddress);
    primaryWallet = walletAddress;
  }

  function addApprovedWalletAddress(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    emit WalletApproved(walletAddress);
    withdrawerWhitelist[walletAddress] = true;
  }

  function deleteApprovedWalletAddress(address walletAddress) public onlyOwner {
    require(walletAddress != address(0));
    require(walletAddress != msg.sender);  
    emit WalletRemoved(walletAddress);
    delete withdrawerWhitelist[walletAddress];
  }

   
  function isApprovedWallet(address walletCheck) external view returns(bool) {
    return (withdrawerWhitelist[walletCheck] || walletCheck == primaryWallet);
  }
}


 


contract CoinSparrow  is Ownable, Arbitrator, ApprovedWithdrawer, Pausable {

   
  using SafeMath for uint256;

   

   
  uint8 constant private STATUS_JOB_NOT_EXIST = 1;  
  uint8 constant private STATUS_JOB_CREATED = 2;  
  uint8 constant private STATUS_JOB_STARTED = 3;  
  uint8 constant private STATUS_HIRER_REQUEST_CANCEL = 4;  
                                                   
  uint8 constant private STATUS_JOB_COMPLETED = 5;  
  uint8 constant private STATUS_JOB_IN_DISPUTE = 6;  
  uint8 constant private STATUS_HIRER_CANCELLED = 7;  
  uint8 constant private STATUS_CONTRACTOR_CANCELLED = 8;  
  uint8 constant private STATUS_FINISHED_FUNDS_RELEASED = 9;  
  uint8 constant private STATUS_FINISHED_FUNDS_RELEASED_BY_CONTRACTOR = 10;  
  uint8 constant private STATUS_CONTRACTOR_REQUEST_CANCEL = 11;  
                                                         
  uint8 constant private STATUS_MUTUAL_CANCELLATION_PROCESSED = 12;  

   
   
   
  uint8 constant private COINSPARROW_CONTRACT_VERSION = 1;

   

  event JobCreated(bytes32 _jobHash, address _who, uint256 _value);
  event ContractorStartedJob(bytes32 _jobHash, address _who);
  event ContractorCompletedJob(bytes32 _jobHash, address _who);
  event HirerRequestedCancel(bytes32 _jobHash, address _who);
  event ContractorRequestedCancel(bytes32 _jobHash, address _who);
  event CancelledByHirer(bytes32 _jobHash, address _who);
  event CancelledByContractor(bytes32 _jobHash, address _who);
  event MutuallyAgreedCancellation(
    bytes32 _jobHash,
    address _who,
    uint256 _hirerAmount,
    uint256 _contractorAmount
  );
  event DisputeRequested(bytes32 _jobHash, address _who);
  event DisputeResolved(
    bytes32 _jobHash,
    address _who,
    uint256 _hirerAmount,
    uint256 _contractorAmount
  );
  event HirerReleased(bytes32 _jobHash, address _hirer, address _contractor, uint256 _value);
  event AddFeesToCoinSparrowPool(bytes32 _jobHash, uint256 _value);
  event ContractorReleased(bytes32 _jobHash, address _hirer, address _contractor, uint256 _value);
  event HirerLastResortRefund(bytes32 _jobHash, address _hirer, address _contractor, uint256 _value);
  event WithdrawFeesFromCoinSparrowPool(address _whoCalled, address _to, uint256 _amount);
  event LogFallbackFunctionCalled(address _from, uint256 _amount);


   

   
  struct JobEscrow {
     
    bool exists;
     
     
     
    uint32 hirerCanCancelAfter;
     
    uint8 status;
     
    uint32 jobCompleteDate;
     
    uint32 secondsToComplete;
     
    uint32 agreedCompletionDate;
  }

   


   
  uint256 private totalInEscrow;
   
  uint256 private feesAvailableForWithdraw;

   
  uint256 private MAX_SEND;

   
  mapping(bytes32 => JobEscrow) private jobEscrows;

   
  mapping(address => mapping(bytes32 => uint256)) private hirerEscrowMap;

   

   

  modifier onlyHirer(address _hirer) {
    require(msg.sender == _hirer);
    _;
  }

   

  modifier onlyContractor(address _contractor) {
    require(msg.sender == _contractor);
    _;
  }

   

  modifier onlyHirerOrContractor(address _hirer, address _contractor) {
    require(msg.sender == _hirer || msg.sender == _contractor);
    _;
  }

   

   

  constructor(uint256 _maxSend) public {
    require(_maxSend > 0);
     
    MAX_SEND = _maxSend;
  }

   

  function() payable {
     
    emit LogFallbackFunctionCalled(msg.sender, msg.value);
  }

   
  function createJobEscrow(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee,
    uint32 _jobStartedWindowInSeconds,
    uint32 _secondsToComplete
  ) payable external whenNotPaused onlyHirer(_hirer)
  {

     
    require(msg.value == _value && msg.value > 0);

     
    require(_fee < _value);

     
    require(msg.value <= MAX_SEND);

     
    require(_jobStartedWindowInSeconds > 0);

     
    require(_secondsToComplete > 0);

     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(!jobEscrows[jobHash].exists);

     
    jobEscrows[jobHash] = JobEscrow(
      true,
      uint32(block.timestamp) + _jobStartedWindowInSeconds,
      STATUS_JOB_CREATED,
      0,
      _secondsToComplete,
      0);

     
    totalInEscrow = totalInEscrow.add(msg.value);

     
    hirerEscrowMap[msg.sender][jobHash] = msg.value;

     
    emit JobCreated(jobHash, msg.sender, msg.value);
  }

   

   
  function hirerReleaseFunds(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirer(_hirer)
  {

    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);

     
    require(hirerEscrowMap[msg.sender][jobHash] > 0);

     
    uint256 jobValue = hirerEscrowMap[msg.sender][jobHash];

     
    require(jobValue > 0 && jobValue == _value);

     
    require(jobValue >= jobValue.sub(_fee));

     
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

      
    emit HirerReleased(
      jobHash,
      msg.sender,
      _contractor,
      jobValue);

      
    emit AddFeesToCoinSparrowPool(jobHash, _fee);

     
    delete jobEscrows[jobHash];
     
    delete hirerEscrowMap[msg.sender][jobHash];

     
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);

     
    totalInEscrow = totalInEscrow.sub(jobValue);

     
    _contractor.transfer(jobValue.sub(_fee));

  }

   
  function contractorReleaseFunds(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {

    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);

     
    require(jobEscrows[jobHash].status == STATUS_JOB_COMPLETED);
     
    require(block.timestamp > jobEscrows[jobHash].jobCompleteDate + 4 weeks);

     
    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

     
    require(jobValue > 0 && jobValue == _value);

     
    require(jobValue >= jobValue.sub(_fee));

     
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    emit ContractorReleased(
      jobHash,
      _hirer,
      _contractor,
      jobValue);  
    emit AddFeesToCoinSparrowPool(jobHash, _fee);

    delete jobEscrows[jobHash];  
    delete  hirerEscrowMap[_hirer][jobHash];  

     
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);

     
    totalInEscrow = totalInEscrow.sub(jobValue);

     
    _contractor.transfer(jobValue.sub(_fee));

  }

   
  function hirerLastResortRefund(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirer(_hirer)
  {
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);
    
     
    require(jobEscrows[jobHash].status == STATUS_JOB_STARTED);
     
    require(block.timestamp > jobEscrows[jobHash].agreedCompletionDate + 4 weeks);

     
    uint256 jobValue = hirerEscrowMap[msg.sender][jobHash];

     
    require(jobValue > 0 && jobValue == _value);

     
    require(jobValue >= jobValue.sub(_fee));

     
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    emit HirerLastResortRefund(
      jobHash,
      _hirer,
      _contractor,
      jobValue);  

    delete jobEscrows[jobHash];  
    delete  hirerEscrowMap[_hirer][jobHash];  

     
    totalInEscrow = totalInEscrow.sub(jobValue);

     
    _hirer.transfer(jobValue);
  }

   

   
  function jobStarted(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);
     
    require(jobEscrows[jobHash].status == STATUS_JOB_CREATED);
    jobEscrows[jobHash].status = STATUS_JOB_STARTED;  
    jobEscrows[jobHash].hirerCanCancelAfter = 0;
    jobEscrows[jobHash].agreedCompletionDate = uint32(block.timestamp) + jobEscrows[jobHash].secondsToComplete;
    emit ContractorStartedJob(jobHash, msg.sender);
  }

   
  function jobCompleted(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    require(jobEscrows[jobHash].exists);  
    require(jobEscrows[jobHash].status == STATUS_JOB_STARTED);  
    jobEscrows[jobHash].status = STATUS_JOB_COMPLETED;
    jobEscrows[jobHash].jobCompleteDate = uint32(block.timestamp);
    emit ContractorCompletedJob(jobHash, msg.sender);
  }

   

   
  function contractorCancel(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyContractor(_contractor)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

     
    require(jobEscrows[jobHash].exists);

     
    require(jobValue > 0 && jobValue == _value);

     
    require(jobValue >= jobValue.sub(_fee));

     
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[_hirer][jobHash];
    emit CancelledByContractor(jobHash, msg.sender);

    totalInEscrow = totalInEscrow.sub(jobValue);

    _hirer.transfer(jobValue);
  }

   
  function hirerCancel(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirer(_hirer)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);

    require(jobEscrows[jobHash].hirerCanCancelAfter > 0);
    require(jobEscrows[jobHash].status == STATUS_JOB_CREATED);
    require(jobEscrows[jobHash].hirerCanCancelAfter < block.timestamp);

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

     
    require(jobValue > 0 && jobValue == _value);

     
    require(jobValue >= jobValue.sub(_fee));

     
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[msg.sender][jobHash];
    emit CancelledByHirer(jobHash, msg.sender);

    totalInEscrow = totalInEscrow.sub(jobValue);

    _hirer.transfer(jobValue);
  }

   
  function requestMutualJobCancellation(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirerOrContractor(_hirer, _contractor)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);
    require(jobEscrows[jobHash].status == STATUS_JOB_STARTED);

    if (msg.sender == _hirer) {
      jobEscrows[jobHash].status = STATUS_HIRER_REQUEST_CANCEL;
      emit HirerRequestedCancel(jobHash, msg.sender);
    }
    if (msg.sender == _contractor) {
      jobEscrows[jobHash].status = STATUS_CONTRACTOR_REQUEST_CANCEL;
      emit ContractorRequestedCancel(jobHash, msg.sender);
    }
  }

   
  function processMutuallyAgreedJobCancellation(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee,
    uint8 _contractorPercent,
    bytes _hirerMsgSig,
    bytes _contractorMsgSig
  ) external
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);

    require(msg.sender == _hirer || msg.sender == _contractor);
    require(_contractorPercent <= 100 && _contractorPercent >= 0);

     
     
    require(
      checkRefundSignature(_contractorPercent,_hirerMsgSig,_hirer)&&
      checkRefundSignature(_contractorPercent,_contractorMsgSig,_contractor));

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

     
    require(jobValue > 0 && jobValue == _value);

     
    require(jobValue >= jobValue.sub(_fee));

     
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    totalInEscrow = totalInEscrow.sub(jobValue);
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[_hirer][jobHash];

    uint256 contractorAmount = jobValue.sub(_fee).mul(_contractorPercent).div(100);
    uint256 hirerAmount = jobValue.sub(_fee).mul(100 - _contractorPercent).div(100);

    emit MutuallyAgreedCancellation(
      jobHash,
      msg.sender,
      hirerAmount,
      contractorAmount);

    emit AddFeesToCoinSparrowPool(jobHash, _fee);

    if (contractorAmount > 0) {
      _contractor.transfer(contractorAmount);
    }
    if (hirerAmount > 0) {
      _hirer.transfer(hirerAmount);
    }
  }

   

   
  function requestDispute(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  ) external onlyHirerOrContractor(_hirer, _contractor)
  {

     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);
    require(
      jobEscrows[jobHash].status == STATUS_JOB_STARTED||
      jobEscrows[jobHash].status == STATUS_JOB_COMPLETED||
      jobEscrows[jobHash].status == STATUS_HIRER_REQUEST_CANCEL||
      jobEscrows[jobHash].status == STATUS_CONTRACTOR_REQUEST_CANCEL);

    jobEscrows[jobHash].status = STATUS_JOB_IN_DISPUTE;

    emit DisputeRequested(jobHash, msg.sender);
  }

   

  function resolveDispute(

    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee,
    uint8 _contractorPercent
  ) external onlyArbitrator
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

     
    require(jobEscrows[jobHash].exists);

    require(jobEscrows[jobHash].status == STATUS_JOB_IN_DISPUTE);
    require(_contractorPercent <= 100);

    uint256 jobValue = hirerEscrowMap[_hirer][jobHash];

     
    require(jobValue > 0 && jobValue == _value);

     
    require(jobValue >= jobValue.sub(_fee));

     
    require(totalInEscrow >= jobValue && totalInEscrow > 0);

    totalInEscrow = totalInEscrow.sub(jobValue);
    feesAvailableForWithdraw = feesAvailableForWithdraw.add(_fee);
     

    delete jobEscrows[jobHash];
    delete  hirerEscrowMap[_hirer][jobHash];

    uint256 contractorAmount = jobValue.sub(_fee).mul(_contractorPercent).div(100);
    uint256 hirerAmount = jobValue.sub(_fee).mul(100 - _contractorPercent).div(100);
    emit DisputeResolved(
      jobHash,
      msg.sender,
      hirerAmount,
      contractorAmount);

    emit AddFeesToCoinSparrowPool(jobHash, _fee);

    _contractor.transfer(contractorAmount);
    _hirer.transfer(hirerAmount);

  }

   

   
  function withdrawFees(address _to, uint256 _amount) onlyOwner onlyApprovedWallet(_to) external {
     
    require(_amount > 0);
    require(_amount <= feesAvailableForWithdraw && feesAvailableForWithdraw > 0);

    feesAvailableForWithdraw = feesAvailableForWithdraw.sub(_amount);

    emit WithdrawFeesFromCoinSparrowPool(msg.sender,_to, _amount);

    _to.transfer(_amount);
  }

   

  function howManyFees() external view returns (uint256) {
    return feesAvailableForWithdraw;
  }

   

  function howMuchInEscrow() external view returns (uint256) {
    return totalInEscrow;
  }

   

  function setMaxSend(uint256 _maxSend) onlyOwner external {
    require(_maxSend > 0);
    MAX_SEND = _maxSend;
  }

   

  function getMaxSend() external view returns (uint256) {
    return MAX_SEND;
  }

   

  function getContractVersion() external pure returns(uint8) {
    return COINSPARROW_CONTRACT_VERSION;
  }

   

   

  function getJobStatus(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint8)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint8 status = STATUS_JOB_NOT_EXIST;

    if (jobEscrows[jobHash].exists) {
      status = jobEscrows[jobHash].status;
    }
    return status;
  }

   

  function getJobCanCancelAfter(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 hirerCanCancelAfter = 0;

    if (jobEscrows[jobHash].exists) {
      hirerCanCancelAfter = jobEscrows[jobHash].hirerCanCancelAfter;
    }
    return hirerCanCancelAfter;
  }

   

  function getSecondsToComplete(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 secondsToComplete = 0;

    if (jobEscrows[jobHash].exists) {
      secondsToComplete = jobEscrows[jobHash].secondsToComplete;
    }
    return secondsToComplete;
  }

   

  function getAgreedCompletionDate(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 agreedCompletionDate = 0;

    if (jobEscrows[jobHash].exists) {
      agreedCompletionDate = jobEscrows[jobHash].agreedCompletionDate;
    }
    return agreedCompletionDate;
  }

   

  function getActualCompletionDate(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns (uint32)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint32 jobCompleteDate = 0;

    if (jobEscrows[jobHash].exists) {
      jobCompleteDate = jobEscrows[jobHash].jobCompleteDate;
    }
    return jobCompleteDate;
  }

   

  function getJobValue(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee) external view returns(uint256)
  {
     
    bytes32 jobHash = getJobHash(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee);

    uint256 amount = 0;
    if (jobEscrows[jobHash].exists) {
      amount = hirerEscrowMap[_hirer][jobHash];
    }
    return amount;
  }

   
  function validateRefundSignature(
    uint8 _contractorPercent,
    bytes _sigMsg,
    address _signer) external pure returns(bool)
  {

    return checkRefundSignature(_contractorPercent,_sigMsg,_signer);

  }

   
  function checkRefundSignature(
    uint8 _contractorPercent,
    bytes _sigMsg,
    address _signer) private pure returns(bool)
  {
    bytes32 percHash = keccak256(abi.encodePacked(_contractorPercent));
    bytes32 msgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",percHash));

    address addr = ECRecovery.recover(msgHash,_sigMsg);
    return addr == _signer;
  }

   
  function getJobHash(
    bytes16 _jobId,
    address _hirer,
    address _contractor,
    uint256 _value,
    uint256 _fee
  )  private pure returns(bytes32)
  {
    return keccak256(abi.encodePacked(
      _jobId,
      _hirer,
      _contractor,
      _value,
      _fee));
  }

}