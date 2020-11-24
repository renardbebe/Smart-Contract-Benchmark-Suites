 

pragma solidity ^0.4.21;

contract Ownable {
  address public owner;


   
  constructor() internal {
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
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function approve(address spender, uint256 value) external returns (bool success);
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract ChilliZTokenPurchase is Ownable {

   
  address public purchase_address = 0xd64671135E7e01A1e3AB384691374FdDA0641Ed6;
   
  address public major_partner_address = 0x212286e36Ae998FAd27b627EB326107B3aF1FeD4;
   
  address public minor_partner_address = 0x515962688858eD980EB2Db2b6fA2802D9f620C6d;
   
  uint public gas = 1000;

   
  function() payable public {
    execute_transfer(msg.value);
  }

   
  function execute_transfer(uint transfer_amount) internal {
     
    uint major_fee = transfer_amount * 25 / 1050;
     
    uint minor_fee = transfer_amount * 25 / 1050;

    transfer_with_extra_gas(major_partner_address, major_fee);
    transfer_with_extra_gas(minor_partner_address, minor_fee);

     
    uint purchase_amount = transfer_amount - major_fee - minor_fee;
    transfer_with_extra_gas(purchase_address, purchase_amount);
  }

   
  function transfer_with_extra_gas(address destination, uint transfer_amount) internal {
    require(destination.call.gas(gas).value(transfer_amount)());
  }

   
   
   
  function set_transfer_gas(uint transfer_gas) public onlyOwner {
    gas = transfer_gas;
  }

   
  function approve_unwanted_tokens(EIP20Token token, address dest, uint value) public onlyOwner {
    token.approve(dest, value);
  }

   
   
  function emergency_withdraw() public onlyOwner {
    transfer_with_extra_gas(msg.sender, address(this).balance);
  }

}