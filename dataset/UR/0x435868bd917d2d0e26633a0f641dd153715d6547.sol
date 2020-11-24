 

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract BuyerFund {
   
  mapping (address => uint256) public balances; 
  
   
  mapping (address => uint256) public picops_balances; 
  
   
  bool public bought_tokens; 

   
  bool public contract_enabled = true;
  
   
  uint256 public contract_eth_value; 
  
   
  uint256 constant public min_required_amount = 20 ether; 

   
  address constant public creator = 0x2E2E356b67d82D6f4F5D54FFCBcfFf4351D2e56c;
  
   
  address public sale = 0xf58546F5CDE2a7ff5C91AFc63B43380F0C198BE8;

   
  address public picops_user;

   
  bool public is_verified = false;

   
  bytes32 public h_pwd = 0x30f5931696381f3826a0a496cf17fecdf9c83e15089c9a3bbd804a3319a1384e; 

   
  bytes32 public s_pwd = 0x8d9b2b8f1327f8bad773f0f3af0cb4f3fbd8abfad8797a28d1d01e354982c7de; 

   
  uint256 public creator_fee; 

   
  uint256 public claim_block = 5350521;

   
  uint256 public change_block = 4722681;

   
   
  function perform_withdraw(address tokenAddress) {
     
    require(bought_tokens);
    
     
    ERC20 token = ERC20(tokenAddress);

     
    uint256 contract_token_balance = token.balanceOf(address(this));
      
     
    require(contract_token_balance != 0);
      
     
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      
     
    contract_eth_value -= balances[msg.sender];
      
     
    balances[msg.sender] = 0;

     
    uint256 fee = tokens_to_withdraw / 100;

     
    require(token.transfer(msg.sender, tokens_to_withdraw - fee));

     
    require(token.transfer(picops_user, fee));
  }
  
   
  function refund_me() {
    require(this.balance > 0);

     
    uint256 eth_to_withdraw = balances[msg.sender];

     
    balances[msg.sender] = 0;

     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens(bytes32 _pwd) {
     
    require(this.balance > min_required_amount); 

     
    require(!bought_tokens);
    
     
    require(msg.sender == creator || h_pwd == keccak256(_pwd));

     
    bought_tokens = true;

     
    creator_fee = this.balance / 100; 
    
     
    contract_eth_value = this.balance - creator_fee;

     
    creator.transfer(creator_fee);

     
    sale.transfer(contract_eth_value);
  }

   
  function enable_deposits(bool toggle) {
    require(msg.sender == creator);
    
     
    contract_enabled = toggle;
  }

   
  function verify_fund() payable { 
    if (!is_verified) {
        picops_balances[msg.sender] += msg.value;
    }   
  }
  
  function verify_send(address _picops, uint256 amount) {
     
    require(picops_balances[msg.sender] > 0);

     
    require(picops_balances[msg.sender] >= amount);

     
    uint256 eth_to_withdraw = picops_balances[msg.sender];

     
    picops_balances[msg.sender] = picops_balances[msg.sender] - amount;

     
    _picops.transfer(amount);
  }
  
  function verify_withdraw() { 
     
    uint256 eth_to_withdraw = picops_balances[msg.sender];
        
     
    picops_balances[msg.sender] = 0;
        
     
    msg.sender.transfer(eth_to_withdraw);
  }
   

   
  function picops_is_verified(bool toggle) {
    require(msg.sender == creator);

    is_verified = toggle;
  }

   
  function set_sale_address(address _sale, bytes32 _pwd) {
    require(keccak256(_pwd) == s_pwd || msg.sender == creator);

     
    require (block.number > change_block);
    
     
    sale = _sale;
  }

  function set_successful_verifier(address _picops_user) {
    require(msg.sender == creator);

    picops_user = _picops_user;
  }

   
  function delay_pool_drain_block(uint256 _block) {
    require(_block > claim_block);

    claim_block = _block;
  }

   
  function delay_pool_change_block(uint256 _block) {
    require(_block > change_block);

    change_block = _block;
  }

   
  function pool_drain(address tokenAddress) {
    require(msg.sender == creator);

     
     
     
    require(block.number >= claim_block);

     
    if (this.balance > 0) {
      creator.transfer(this.balance);
    }

     
    ERC20 token = ERC20(tokenAddress);

     
    uint256 contract_token_balance = token.balanceOf(address(this));

     
    require(token.transfer(msg.sender, contract_token_balance));
  }

   
  function () payable {
     
    require(!bought_tokens);

     
    require(contract_enabled);
    
     
    balances[msg.sender] += msg.value;
  }
}