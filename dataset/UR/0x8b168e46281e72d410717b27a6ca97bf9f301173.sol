 

pragma solidity ^0.4.13;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract LINKFund {
   
  mapping (address => uint256) public balances;
  
   
  bool public bought_tokens;
  
   
  uint256 public contract_eth_value;
  
   
   
  uint256 constant public min_required_amount = 1 ether;
  
   
   
   
  uint256 constant public max_raised_amount = 700 ether;
  
   
  uint256 public min_buy_block;
  
   
  uint256 public min_refund_block;
  
   
  address constant public sale = 0x7093128612a02e32F1C1aa44cCD7411d84EE09Ac;
  
   
  address constant public creator = 0x0b11C7acb647eCa11d510eEc4fb0c17Bfccd6498;
  
   
  function LINKFund() {
     
    min_buy_block = block.number + 3456;
    
     
    min_refund_block = block.number + 864000;
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
    if (!bought_tokens) {
       
      if (block.number < min_refund_block) throw;
    }
    
     
    uint256 eth_to_withdraw = balances[msg.sender];
      
     
    balances[msg.sender] = 0;
      
     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens() {
     
	if (msg.sender != creator) throw;
	
     
    if (bought_tokens) return;
    
     
    if (this.balance < min_required_amount) throw;
    
     
    if (block.number < min_buy_block) throw;
    
     
    bought_tokens = true;
    
     
    contract_eth_value = this.balance;

     
    creator.transfer(contract_eth_value);
  }
  
   
  function default_helper() payable {
     
    if (this.balance > max_raised_amount) throw;
    
     
     
    if (!bought_tokens) {
      balances[msg.sender] += msg.value;
    }
  }
  
   
  function () payable {
     
    default_helper();
  }
}