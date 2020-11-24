 

 

pragma solidity ^0.4.13;

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract DeveryFUND {
   
  mapping (address => uint256) public balances;
   
  bool public bought_tokens = false;
   
  uint256 public contract_eth_value;
   
  uint256 constant public min_amount = 10 ether;
  uint256 constant public max_amount = 1100 ether;
  bytes32 hash_pwd = 0x6ad8492244e563b8fdd6a63472f9122236592c392bab2c8bd24dc77064d5d6ac;
   
  address public sale;
   
  ERC20 public token;
  address constant public creator = 0xEE06BdDafFA56a303718DE53A5bc347EfbE4C68f;
  uint256 public buy_block;
  bool public emergency_used = false;
  
   
  function withdraw() {
     
    require(bought_tokens);
    require(!emergency_used);
    uint256 contract_token_balance = token.balanceOf(address(this));
     
    require(contract_token_balance != 0);
     
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
     
    contract_eth_value -= balances[msg.sender];
     
    balances[msg.sender] = 0;
    uint256 fee = tokens_to_withdraw / 100;
     
    require(token.transfer(creator, fee));
     
    require(token.transfer(msg.sender, tokens_to_withdraw - fee));
  }
  
   
  function refund_me() {
    require(!bought_tokens);
     
    uint256 eth_to_withdraw = balances[msg.sender];
     
    balances[msg.sender] = 0;
     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens(string _password) {
    require(this.balance > min_amount);
    require(!bought_tokens);
    require(sale != 0x0);
    require(msg.sender == creator || hash_pwd == keccak256(_password));
     
    buy_block = block.number;
     
    bought_tokens = true;
     
    contract_eth_value = this.balance;
     
    sale.transfer(contract_eth_value);
  }
  
  function set_sale_address(address _sale, string _password) {
     
    require(msg.sender == creator || hash_pwd == keccak256(_password));
    require(sale == 0x0);
    require(!bought_tokens);
    sale = _sale;
  }

  function set_token_address(address _token, string _password) {
    require(msg.sender == creator || hash_pwd == keccak256(_password));
    token = ERC20(_token);
  }

  function emergy_withdraw(address _token) {
     
     
     
    require(block.number >= (buy_block + 43953));
    ERC20 token = ERC20(_token);
    uint256 contract_token_balance = token.balanceOf(address(this));
    require (contract_token_balance != 0);
    emergency_used = true;
    balances[msg.sender] = 0;
     
    require(token.transfer(msg.sender, contract_token_balance));
  }

   
  function () payable {
    require(!bought_tokens);
    require(this.balance <= max_amount);
    balances[msg.sender] += msg.value;
  }
}