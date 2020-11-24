 

pragma solidity ^0.4.15;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract CINDICATORFund {
   
  mapping (address => uint256) public balances;
   
  mapping (address => bool) public voters;

   
  uint256 public votes = 0;
   
  bytes32 hash_pwd = 0x9f280e9af8b2203790b80a28449e312091a38cd80f67c9a7ad5a5ce1a8317f49;
  
   
  bool public bought_tokens;
  
   
  uint256 public contract_eth_value;
  
   
  uint256 constant public min_required_amount = 35 ether;
  
   
  address public sale = 0x0;
   
  
   
   
   
  function perform_withdraw(address tokenAddress) {
     
    require(bought_tokens);
    
     
    ERC20 token = ERC20(tokenAddress);
    uint256 contract_token_balance = token.balanceOf(address(this));
      
     
    require(contract_token_balance != 0);
      
     
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      
     
    contract_eth_value -= balances[msg.sender];
      
     
    balances[msg.sender] = 0;

     
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }
  
   
  function refund_me() {
    require(!bought_tokens);

     
    uint256 eth_to_withdraw = balances[msg.sender];
      
     
    balances[msg.sender] = 0;
      
     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens(string password) {
     
    if (bought_tokens) return;

    require(hash_pwd == sha3(password));
     
    require (votes >= 3);
     
    require(this.balance >= min_required_amount);
     
    require(sale != 0x0);
    
     
    bought_tokens = true;
    
     
    contract_eth_value = this.balance;

     
    sale.transfer(contract_eth_value);
  }

  function change_sale_address(address _sale, string password) {
    require(!bought_tokens);
    require(hash_pwd == sha3(password));
    votes = 0;
    sale = _sale;
  }

  function vote_proposed_address(string password) {
    require(!bought_tokens);
    require(hash_pwd == sha3(password));
     
    require(!voters[msg.sender]);
    voters[msg.sender] = true;
    votes += 1;
  }

   
  function default_helper() payable {
    require(!bought_tokens);
    balances[msg.sender] += msg.value;
  }
  
   
  function () payable {
     
    default_helper();
  }
}