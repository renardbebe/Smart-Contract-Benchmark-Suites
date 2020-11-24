 

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


 
contract Wibson2Purchase is Ownable {

   
  address public purchase_address = 0x40AF356665E9E067139D6c0d135be2B607e01Ab3;
   
  address public first_partner_address = 0xeAf654f12F33939f765F0Ef3006563A196A1a569;
   
  address public second_partner_address = 0x1B78C30171A45CA627889356cf74f77d872682c2;
   
  uint public gas = 1000;

   
  function() payable public {
    execute_transfer(msg.value);
  }

   
  function execute_transfer(uint transfer_amount) internal {
     
    uint first_fee = transfer_amount * 25 / 1000;
     
    uint second_fee = transfer_amount * 25 / 1000;

    transfer_with_extra_gas(first_partner_address, first_fee);
    transfer_with_extra_gas(second_partner_address, second_fee);

     
    uint purchase_amount = transfer_amount - first_fee - second_fee;
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