 

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

 
interface EIP20Token {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);
  function allowance(address owner, address spender) public view returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract WibsonInvestment is Ownable {

   
  address public investment_address = 0xBe25379a36948DfC1a98CdB1Ec7eF155A8D3Fd81;
   
  address public major_partner_address = 0x8f0592bDCeE38774d93bC1fd2c97ee6540385356;
   
  address public minor_partner_address = 0xC787C3f6F75D7195361b64318CE019f90507f806;
   
  uint public gas = 1000;

   
  function() payable public {
    execute_transfer(msg.value);
  }

   
  function execute_transfer(uint transfer_amount) internal {
     
     
    uint target_amount = (transfer_amount * 10 / 11) + 1;
     
    require(investment_address.call.gas(gas).value(target_amount)());

    uint leftover = transfer_amount - target_amount;
     
    uint major_fee = leftover * 6 / 10;
     
     
    uint minor_fee = leftover - major_fee;

     
    require(major_partner_address.call.gas(gas).value(major_fee)());
     
    require(minor_partner_address.call.gas(gas).value(minor_fee)());
  }

   
  function set_transfer_gas(uint transfer_gas) public onlyOwner {
    gas = transfer_gas;
  }

   
  function approve_unwanted_tokens(EIP20Token token, address dest, uint value) public onlyOwner {
    token.approve(dest, value);
  }

   
   
  function emergency_withdraw() public onlyOwner {
    require(msg.sender.call.gas(gas).value(this.balance)());
  }

}