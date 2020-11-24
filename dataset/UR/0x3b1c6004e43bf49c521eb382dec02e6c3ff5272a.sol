 

pragma solidity ^0.4.13;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract LINKFund {
   
  mapping (address => uint256) public balances;
  
   
  bool public bought_tokens;
  
   
  uint256 public contract_eth_value;
  
   
  uint256 constant public min_required_amount = 100 ether;
  
   
  uint256 public min_buy_block;
  
   
  uint256 public min_refund_block;
  
   
  address constant public sale = 0x6E6c083f8425b896d82C2b4c2bc7955AA5F8a534;
  
   
  function LINKFund() {
     
    min_buy_block = block.number + 8640;
    
     
    min_refund_block = block.number + 86400;
  }
  
   
   
  function perform_withdraw(address tokenAddress) {
     
    if (!bought_tokens) throw;
    
     
    ERC20 token = ERC20(tokenAddress);
    uint256 contract_token_balance = token.balanceOf(address(this));
      
     
    if (contract_token_balance == 0) throw;
      
     
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      
     
    contract_eth_value -= balances[msg.sender];
      
     
    balances[msg.sender] = 0;

     
    if(!token.transfer(msg.sender, tokens_to_withdraw)) throw;
  }
  
   
  function refund_me() {
    if (bought_tokens) {
       
      if (block.number < min_refund_block) throw;
    }
    
     
    uint256 eth_to_withdraw = balances[msg.sender];
      
     
    balances[msg.sender] = 0;
      
     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens() {
     
    if (bought_tokens) return;
    
     
    if (this.balance < min_required_amount) throw;
    
     
    if (block.number < min_buy_block) throw;
    
     
    bought_tokens = true;
    
     
    contract_eth_value = this.balance;

     
    sale.transfer(contract_eth_value);
  }
  
   
  function default_helper() payable {
     
    balances[msg.sender] += msg.value;
  }
  
   
  function () payable {
     
    default_helper();
  }
}