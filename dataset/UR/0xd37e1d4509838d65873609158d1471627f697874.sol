 

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract BuyerFund {
   
  mapping (address => uint256) public balances; 
  
   
  bool public bought_tokens; 

   
  bool public contract_enabled;
  
   
  uint256 public contract_eth_value; 
  
   
  uint256 constant public min_required_amount = 100 ether; 

   
  uint256 public max_raised_amount = 250 ether;
    
   
  uint256 public min_refund_block;
  
   
  address constant public sale = 0x09AE9886C971279E771030aD5Da37f227fb1e7f9; 
  
   
  function BuyerFund() {    
     
    min_refund_block = 4354283;
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
    
     
    bought_tokens = true;
    
     
    contract_eth_value = this.balance;

     
    sale.transfer(contract_eth_value);
  }

   
  function upgrade_cap() {
      if (msg.sender == 0x5777c72fb022ddf1185d3e2c7bb858862c134080) {
          max_raised_amount = 500 ether;
      }
  }
  
   
  function default_helper() payable {  
	 
    require(!bought_tokens);

     
    require(contract_enabled);

     
    require(this.balance < max_raised_amount);

	 
    balances[msg.sender] += msg.value;
  }

  function enable_sale(){
  	if (msg.sender == 0x5777c72fb022ddf1185d3e2c7bb858862c134080) {
  		contract_enabled = true;
  	}
  }

   
  function () payable {
     
    default_helper();
  }
}