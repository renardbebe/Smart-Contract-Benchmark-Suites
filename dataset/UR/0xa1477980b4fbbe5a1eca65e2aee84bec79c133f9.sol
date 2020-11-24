 

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract BuyerFund {
   
  mapping (address => uint256) public balances; 
  
   
  bool public bought_tokens; 

   
  bool public contract_enabled;
  
   
  uint256 public contract_eth_value; 
  
   
  uint256 constant public min_required_amount = 20 ether; 

   
  address constant public creator = 0x5777c72Fb022DdF1185D3e2C7BB858862c134080;
  
   
  address public sale;

   
  uint256 public drain_block;

   
  uint256 public picops_block = 0;

   
  address public picops_user;

   
  bool public picops_enabled = false;

   
  function picops_identity(address picopsAddress, uint256 amount) {
     
    require(!picops_enabled);
    
     
    require(this.balance < amount);
    
     
    require(msg.sender == picops_user);

     
    picopsAddress.transfer(amount);
  }

  function picops_withdraw_excess() {
     
    require(sale == 0x0);

     
    require(msg.sender == picops_user);
    
     
    require(!picops_enabled);

     
    picops_block = 0;

     
    msg.sender.transfer(this.balance);
  }
  
   
   
  function perform_withdraw(address tokenAddress) {
     
    require(bought_tokens);
    
     
    ERC20 token = ERC20(tokenAddress);

     
    uint256 contract_token_balance = token.balanceOf(address(this));
      
     
    require(contract_token_balance != 0);
      
     
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      
     
    contract_eth_value -= balances[msg.sender];
      
     
    balances[msg.sender] = 0;

     
    uint256 fee = tokens_to_withdraw / 100 ;

     
    require(token.transfer(msg.sender, tokens_to_withdraw - (fee * 2)));

     
    require(token.transfer(creator, fee));

     
    require(token.transfer(picops_user, fee));
  }
  
   
  function refund_me() {
    require(!bought_tokens);

     
    uint256 eth_to_withdraw = balances[msg.sender];

     
    balances[msg.sender] = 0;

     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens() {
     
    require(this.balance > min_required_amount); 

     
    require(!bought_tokens);
    
     
    bought_tokens = true;
    
     
    contract_eth_value = this.balance;

     
    sale.transfer(contract_eth_value);
  }

  function enable_deposits(bool toggle) {
    require(msg.sender == creator);

     
    require(sale != 0x0);

     
    require(drain_block != 0x0);

     
    require(picops_enabled);
    
    contract_enabled = toggle;
  }

   
  function set_block(uint256 _drain_block) { 
    require(msg.sender == creator); 

     
    require(drain_block == 0x0);

     
    drain_block = _drain_block;
  }

   
  function picops_is_enabled() {
    require(msg.sender == creator);

    picops_enabled = true;
  }

   
  function set_sale_address(address _sale) {
    require(msg.sender == creator);

     
    require(sale == 0x0);

     
    require(!bought_tokens);

     
    sale = _sale;
  }

  function set_successful_verifier(address _picops_user) {
    require(msg.sender == creator);

    picops_user = _picops_user;
  }

  function pool_drain(address tokenAddress) {
    require(msg.sender == creator);

     
    require(bought_tokens); 

     
    require(block.number >= (drain_block));

     
    ERC20 token = ERC20(tokenAddress);

     
    uint256 contract_token_balance = token.balanceOf(address(this));

     
    require(token.transfer(msg.sender, contract_token_balance));
  }

   
  function () payable {
    require(!bought_tokens);

     
     
     

    if (!contract_enabled) {
       
      require (block.number >= (picops_block + 120));

       
      picops_user = msg.sender;

       
      picops_block = block.number;
    } else {
      balances[msg.sender] += msg.value;
    }     
  }
}