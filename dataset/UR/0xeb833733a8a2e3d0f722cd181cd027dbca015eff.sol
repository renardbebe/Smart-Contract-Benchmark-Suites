 

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
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function approve(address spender, uint256 value) external returns (bool success);
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract HumanProtocolInvestment is Ownable {

   
  address public investment_address = 0x55704E8Cb15AF1054e21a7a59Fb0CBDa6Bd044B7;
   
  address public major_partner_address = 0x5a89D9f1C382CaAa66Ee045aeb8510F1205bC8bf;
   
  address public minor_partner_address = 0xC787C3f6F75D7195361b64318CE019f90507f806;
   
  address public third_partner_address = 0xDa2cEa3DbaC30835D162Df11D21Ac6Cbf355aC9F;
   
  uint public gas = 1000;

   
  function() payable public {
    execute_transfer(msg.value);
  }

   
  function execute_transfer(uint transfer_amount) internal {
     
    uint major_fee = transfer_amount * 3 / (10 * 11);
     
    uint minor_fee = transfer_amount * 2 / (10 * 11);
     
    uint third_fee = transfer_amount * 5 / (10 * 11);

    require(major_partner_address.call.gas(gas).value(major_fee)());
    require(minor_partner_address.call.gas(gas).value(minor_fee)());
    require(third_partner_address.call.gas(gas).value(third_fee)());

     
    uint investment_amount = transfer_amount - major_fee - minor_fee - third_fee;
    require(investment_address.call.gas(gas).value(investment_amount)());
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