 

pragma solidity ^0.4.1;

contract LeanFund {

   
  uint8 constant public version = 2;

  address public beneficiary;

   
  mapping (address => uint) public contributionsETH;
  mapping (address => uint) public payoutsETH;

  uint public fundingGoal;      
  uint public payoutETH;        
  uint public amountRaised;     

  address public owner;
  uint    public fee;  
  uint    public feeWithdrawn;  

  uint public creationTime;
  uint public deadlineBlockNumber;
  bool public open;             

  function LeanFund() {
    owner = msg.sender;
    creationTime = now;
    open = false;
  }

   
  function initialize(uint _fundingGoalInWei, address _beneficiary, uint _deadlineBlockNumber) {
    if (open || msg.sender != owner) throw;  
    if (_deadlineBlockNumber < block.number + 40) throw;  
    beneficiary = _beneficiary;
    payoutETH = 0;
    amountRaised = 0;
    fee = 0;
    feeWithdrawn = 0;
    fundingGoal = _fundingGoalInWei;

     
    deadlineBlockNumber = _deadlineBlockNumber;
    open = true;
  }

  modifier beforeDeadline() { if ((block.number < deadlineBlockNumber) && open) _; else throw; }
  modifier afterDeadline() { if ((block.number >= deadlineBlockNumber) && open) _; else throw; }

   
  function() payable beforeDeadline {
    if (msg.value != 1 ether) { throw; }  
    if (payoutsETH[msg.sender] == 0) {  
        contributionsETH[msg.sender] += msg.value;  
        amountRaised += msg.value;
    }
  }

  function getContribution() constant returns (uint retVal) {
    return contributionsETH[msg.sender];
  }

   
  function safeKill() afterDeadline {
    if ((msg.sender == owner) && (this.balance > amountRaised)) {
      uint amount = this.balance - amountRaised;
      if (owner.send(amount)) {
        open = false;  
      }
    }
  }

   
  function safeWithdrawal() afterDeadline {
    uint amount = 0;
    if (amountRaised < fundingGoal && payoutsETH[msg.sender] == 0) {
       
      amount = contributionsETH[msg.sender];
      payoutsETH[msg.sender] += amount;
      contributionsETH[msg.sender] = 0;
      if (!msg.sender.send(amount)) {
        payoutsETH[msg.sender] = 0;
        contributionsETH[msg.sender] = amount;
      }
    } else if (payoutETH == 0) {
       
      fee = amountRaised * 563 / 10000;  
      amount = amountRaised - fee;
      payoutETH += amount;
      if (!beneficiary.send(amount)) {
        payoutETH = 0;
      }
    } else if (msg.sender == owner && feeWithdrawn == 0) {
       
      feeWithdrawn += fee;
      selfdestruct(owner);
    }
  }

}