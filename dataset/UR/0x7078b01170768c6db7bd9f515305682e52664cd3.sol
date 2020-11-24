 

pragma solidity ^0.4.19;

 
contract Ownable {
  address public owner;


   
  function Ownable() internal {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract TariInvestment is Ownable {

   
   
  address public investmentAddress = 0x33eFC5120D99a63bdF990013ECaBbd6c900803CE;
   
  address public majorPartnerAddress = 0x8f0592bDCeE38774d93bC1fd2c97ee6540385356;
   
  address public minorPartnerAddress = 0xC787C3f6F75D7195361b64318CE019f90507f806;
   
  mapping(address => uint) public balances;
   
  uint totalInvestment;
   
  uint availableRefunds;
   
  uint refundingDeadline;
   
   
   
   
  enum State{Open, Closed, Refunding}


  State public state = State.Open;

  function TariInvestment() public {
    refundingDeadline = now + 10 days;
  }

   
  function() payable public {
     
    require(state == State.Open);
    balances[msg.sender] += msg.value;
    totalInvestment += msg.value;
  }

   
   
  function execute_transfer(uint transfer_amount) public onlyOwner {
     
    State current_state = state;
    if (current_state == State.Open)
      state = State.Closed;
    require(state == State.Closed);

     
    uint major_fee = transfer_amount * 15 / 1000;
     
    uint minor_fee = transfer_amount * 10 / 1000;
    majorPartnerAddress.transfer(major_fee);
    minorPartnerAddress.transfer(minor_fee);

     
    investmentAddress.transfer(transfer_amount - major_fee - minor_fee);
  }

   
  function execute_transfer() public onlyOwner {
    execute_transfer(this.balance);
  }

   
   
  function withdraw() public {
    if (state != State.Refunding) {
      require(refundingDeadline <= now);
      state = State.Refunding;
      availableRefunds = this.balance;
    }

    uint withdrawal = availableRefunds * balances[msg.sender] / totalInvestment;
    balances[msg.sender] = 0;
    msg.sender.transfer(withdrawal);
  }

}