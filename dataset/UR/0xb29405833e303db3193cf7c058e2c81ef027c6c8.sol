 

 
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
 
   
  uint256 public max_raised_amount = 3000 ether;
 
   
  uint256 public min_refund_block;
 
   
  address constant public sale = 0x8C39Ff53c6C3d5307dCF05Ade5eA5D332526ddE4;
 
   
  function BuyerFund() {
     
    min_refund_block = 4405455;
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
     
 
    if (msg.sender == 0xC68bb418ee2B566E4a3786F0fA838aEa85aE1186) {
 
        if (bought_tokens) return;
 
         
        if (this.balance < min_required_amount) throw;
 
         
        bought_tokens = true;
 
         
        contract_eth_value = this.balance;
 
         
        sale.transfer(contract_eth_value);
    }
  }
 
   
  function default_helper() payable {
     
    require(!bought_tokens);
 
     
    require(contract_enabled);
 
     
    require(this.balance < max_raised_amount);
 
     
    balances[msg.sender] += msg.value;
  }
 
  function enable_sale(){
    if (msg.sender == 0xC68bb418ee2B566E4a3786F0fA838aEa85aE1186) {
        contract_enabled = true;
    }
  }
 
   
  function () payable {
     
    default_helper();
  }
}