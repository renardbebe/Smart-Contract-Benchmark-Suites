 

pragma solidity ^0.4.23;

interface ERC20 {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}



contract KGTcomplementaryAirdrop{

uint amount = 1000000000;
uint public active = 1;
uint public price = 0;

mapping(address => uint) public used;

function () public payable {
  require(active>0);
  require(used[msg.sender]!=active);
  require(msg.value>=price);
  
  address addr=0xfe417d8eef16948ba0301c05f5cba87e2c1c51c8;

  ERC20 token = ERC20(addr);
  uint256 contract_token_balance = token.balanceOf(address(this));
  require(contract_token_balance != 0);
   
  require(token.transfer(msg.sender, amount));
  used[msg.sender]=active;
}

function withdrawAdmin() public returns (bool success) {
    require(msg.sender==0x67Dc443AEcEcE8353FE158E5F562873808F12c11);
  address addr=0xfe417d8eef16948ba0301c05f5cba87e2c1c51c8;

  ERC20 token = ERC20(addr);
  uint256 contract_token_balance = token.balanceOf(address(this));
  require(contract_token_balance != 0);
   
  if(msg.sender==0x67Dc443AEcEcE8353FE158E5F562873808F12c11)require(token.transfer(msg.sender, contract_token_balance));
  if(address(this).balance>0)msg.sender.transfer(address(this).balance);
  success=true;
  return success;
}

function contractbalance() public view returns (uint) {
  
  address addr=0xfe417d8eef16948ba0301c05f5cba87e2c1c51c8;

  ERC20 token = ERC20(addr);
  uint256 contract_token_balance = token.balanceOf(address(this));
  
  return contract_token_balance;
}

function settings(uint _amount, uint _active) public returns (bool success) {
     require(msg.sender==0x67Dc443AEcEcE8353FE158E5F562873808F12c11);
     if(msg.sender==0x67Dc443AEcEcE8353FE158E5F562873808F12c11){
         if(_amount>0)amount=_amount;
         active=_active;
         success=true;
     return success;
     }

}

function price(uint _price) public returns (bool success) {
     require(msg.sender==0x67Dc443AEcEcE8353FE158E5F562873808F12c11);
     if(msg.sender==0x67Dc443AEcEcE8353FE158E5F562873808F12c11){
         price=_price;
         success=true;
     return success;
     }

}

}