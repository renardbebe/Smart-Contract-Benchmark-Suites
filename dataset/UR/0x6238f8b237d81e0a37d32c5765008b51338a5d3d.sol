 

pragma solidity ^0.4.11;

 

 
 
contract ERC20 {
  function transfer(address _to, uint _value);
  function balanceOf(address _owner) constant returns (uint balance);
}

 
contract MainSale {
  function createTokens(address recipient) payable;
}

contract Reseller {
   
  mapping (address => uint256) public pay_claimed;
   
  uint256 public total_pay_claimed;
  
   
  MainSale public sale = MainSale(0xd43D09Ec1bC5e57C8F3D0c64020d403b04c7f783);
   
  ERC20 public token = ERC20(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280);
   
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;

   
  function buy() payable {
     
    sale.createTokens.value(msg.value)(address(this));
  }
  
   
  function withdraw() {
     
    uint256 pay_to_withdraw = pay_claimed[msg.sender];
     
    pay_claimed[msg.sender] = 0;
     
    total_pay_claimed -= pay_to_withdraw;
     
    token.transfer(msg.sender, pay_to_withdraw);
  }
  
   
  function claim() payable {
     
    if(block.number < 3930000) throw;
     
    uint256 pay_per_eth = (block.number - 3930000) / 10;
     
    uint256 pay_to_claim = pay_per_eth * msg.value;
     
    uint256 contract_pay_balance = token.balanceOf(address(this));
     
    if((contract_pay_balance - total_pay_claimed) < pay_to_claim) throw;
     
    pay_claimed[msg.sender] += pay_to_claim;
     
    total_pay_claimed += pay_to_claim;
     
    developer.transfer(msg.value);
  }
  
   
  function () payable {
     
    if(msg.value == 0) {
      withdraw();
    }
     
    else {
      claim();
    }
  }
}