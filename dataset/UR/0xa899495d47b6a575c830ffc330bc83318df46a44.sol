 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
pragma solidity ^0.4.11;

contract StakeTreeMVP {
  using SafeMath for uint256;

  uint public version = 1;

  struct Funder {
    bool exists;
    uint balance;
    uint withdrawalEntry;
  }
  mapping(address => Funder) public funders;

  bool public live = true;  
  uint public totalCurrentFunders = 0;  
  uint public withdrawalCounter = 0;  
  uint public sunsetWithdrawDate;
 
  address public beneficiary;  
  uint public sunsetWithdrawalPeriod;  
  uint public withdrawalPeriod;  
  uint public minimumFundingAmount;  
  uint public lastWithdrawal;  
  uint public nextWithdrawal;  

  uint public contractStartTime;  

  function StakeTreeMVP(
    address beneficiaryAddress, 
    uint withdrawalPeriodInit, 
    uint withdrawalStart, 
    uint sunsetWithdrawPeriodInit,
    uint minimumFundingAmountInit) {

    beneficiary = beneficiaryAddress;
    withdrawalPeriod = withdrawalPeriodInit;
    sunsetWithdrawalPeriod = sunsetWithdrawPeriodInit;

    lastWithdrawal = withdrawalStart; 
    nextWithdrawal = lastWithdrawal + withdrawalPeriod;

    minimumFundingAmount = minimumFundingAmountInit;

    contractStartTime = now;
  }

   
  modifier onlyByBeneficiary() {
    require(msg.sender == beneficiary);
    _;
  }

  modifier onlyByFunder() {
    require(isFunder(msg.sender));
    _;
  }

  modifier onlyAfterNextWithdrawalDate() {
    require(now >= nextWithdrawal);
    _;
  }

  modifier onlyWhenLive() {
    require(live);
    _;
  }

  modifier onlyWhenSunset() {
    require(!live);
    _;
  }

   
  function () payable {
    fund();
  }

   

  function fund() public payable onlyWhenLive {
    require(msg.value >= minimumFundingAmount);

     
    if(!isFunder(msg.sender)) {
      totalCurrentFunders = totalCurrentFunders.add(1);  

      funders[msg.sender] = Funder({
        exists: true,
        balance: msg.value,
        withdrawalEntry: withdrawalCounter  
      });
    }
    else {
       
       
      funders[msg.sender].balance = getRefundAmountForFunder(msg.sender).add(msg.value);
       
      funders[msg.sender].withdrawalEntry = withdrawalCounter;
    }
  }

   

   
  function calculateWithdrawalAmount(uint startAmount) public returns (uint){
    return startAmount.mul(10).div(100);  
  }

   
  function calculateRefundAmount(uint amount, uint withdrawalTimes) public returns (uint) {    
    for(uint i=0; i<withdrawalTimes; i++){
      amount = amount.mul(9).div(10);
    }
    return amount;
  }

   

   

  function getRefundAmountForFunder(address addr) public constant returns (uint) {
    uint amount = funders[addr].balance;
    uint withdrawalTimes = getHowManyWithdrawalsForFunder(addr);
    return calculateRefundAmount(amount, withdrawalTimes);
  }

  function getBeneficiary() public constant returns (address) {
    return beneficiary;
  }

  function getCurrentTotalFunders() public constant returns (uint) {
    return totalCurrentFunders;
  }

  function getWithdrawalCounter() public constant returns (uint) {
    return withdrawalCounter;
  }

  function getWithdrawalEntryForFunder(address addr) public constant returns (uint) {
    return funders[addr].withdrawalEntry;
  }

  function getContractBalance() public constant returns (uint256 balance) {
    balance = this.balance;
  }

  function getFunderBalance(address funder) public constant returns (uint256) {
    return getRefundAmountForFunder(funder);
  }

  function isFunder(address addr) public constant returns (bool) {
    return funders[addr].exists;
  }

  function getHowManyWithdrawalsForFunder(address addr) private constant returns (uint) {
    return withdrawalCounter.sub(getWithdrawalEntryForFunder(addr));
  }

   
  function setMinimumFundingAmount(uint amount) external onlyByBeneficiary {
    require(amount > 0);
    minimumFundingAmount = amount;
  }

  function withdraw() external onlyByBeneficiary onlyAfterNextWithdrawalDate onlyWhenLive  {
     
    uint amount = calculateWithdrawalAmount(this.balance);

     
    withdrawalCounter = withdrawalCounter.add(1);
    lastWithdrawal = now;  
    nextWithdrawal = nextWithdrawal + withdrawalPeriod;  

     
    beneficiary.transfer(amount);
  }

   
   
   
   
  function refund() external onlyByFunder {
     
    uint walletBalance = this.balance;
    uint amount = getRefundAmountForFunder(msg.sender);
    require(amount > 0);

     
    removeFunder();

     
    msg.sender.transfer(amount);

     
    assert(this.balance == walletBalance-amount);
  }

   
   
  function removeFunder() public onlyByFunder {
    delete funders[msg.sender];
    totalCurrentFunders = totalCurrentFunders.sub(1);
  }

   

  function sunset() external onlyByBeneficiary onlyWhenLive {
    sunsetWithdrawDate = now.add(sunsetWithdrawalPeriod);
    live = false;
  }

  function swipe(address recipient) external onlyWhenSunset onlyByBeneficiary {
    require(now >= sunsetWithdrawDate);

    recipient.transfer(this.balance);
  }
}