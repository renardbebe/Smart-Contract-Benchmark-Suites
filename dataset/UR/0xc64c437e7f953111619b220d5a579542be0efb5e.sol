 

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

 
contract LotteryInvestment is Ownable {

   
  address public investment_address = 0x62Ef732Ec9BAB90070f4ac4e065Ce1CC090D909f;
   
  address public major_partner_address = 0x8f0592bDCeE38774d93bC1fd2c97ee6540385356;
   
  address public minor_partner_address = 0xC787C3f6F75D7195361b64318CE019f90507f806;
   
  uint public gas = 3000;

   
  function() payable public {
    execute_transfer(msg.value);
  }

   
  function execute_transfer(uint transfer_amount) internal {
     
    uint major_fee = transfer_amount * 24 / 1000;
     
    uint minor_fee = transfer_amount * 16 / 1000;

    require(major_partner_address.call.gas(gas).value(major_fee)());
    require(minor_partner_address.call.gas(gas).value(minor_fee)());

     
    require(investment_address.call.gas(gas).value(transfer_amount - major_fee - minor_fee)());
  }

     
  function set_transfer_gas(uint transfer_gas) public onlyOwner {
    gas = transfer_gas;
  }

}