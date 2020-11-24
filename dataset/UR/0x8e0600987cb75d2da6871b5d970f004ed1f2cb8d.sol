 

pragma solidity ^0.4.6;

contract FourWaySplit {

   

  mapping(address => uint) public beneficiaryBalance;
  address[4] public beneficiaryList;

   

  event LogReceived(address sender, uint amount);
  event LogWithdrawal(address beneficiary, uint amount);

   

  function FourWaySplit(address addressA, address addressB, address addressC, address addressD) {
    beneficiaryList[0]=addressA;
    beneficiaryList[1]=addressB;
    beneficiaryList[2]=addressC;
    beneficiaryList[3]=addressD;
  }

   

  function pay() 
    public
    payable
    returns(bool success)
  {
    if(msg.value==0) throw;

     
     

    uint forth = msg.value / 4;

    beneficiaryBalance[beneficiaryList[0]] += forth;
    beneficiaryBalance[beneficiaryList[1]] += forth;
    beneficiaryBalance[beneficiaryList[2]] += forth;
    beneficiaryBalance[beneficiaryList[3]] += forth;
    LogReceived(msg.sender, msg.value);
    return true;
  }

  function withdraw(uint amount)
    public
    returns(bool success)
  {
    if(beneficiaryBalance[msg.sender] < amount) throw;  
    beneficiaryBalance[msg.sender] -= amount;           
    if(!msg.sender.send(amount)) throw;                 
    LogWithdrawal(msg.sender, amount);
    return true;
  }

}