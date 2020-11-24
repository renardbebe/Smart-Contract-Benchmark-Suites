 

pragma solidity ^0.4.15;

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Equio {
   
  mapping (address => uint256) public balances;
   
  bool public bought_tokens;
   
  uint256 public time_bought;
   
  uint256 public contract_eth_value;
   
  bool public kill_switch;
   
  address public creator;
   
  string name;
   
  address public sale;  
   
  ERC20 public token;  
   
  bytes32 password_hash;  
   
  uint256 earliest_buy_block;  
   
  uint256 earliest_buy_time;  

  function Equio(
    string _name,
    address _sale,
    address _token,
    bytes32 _password_hash,
    uint256 _earliest_buy_block,
    uint256 _earliest_buy_time
  ) payable {
      creator = msg.sender;
      name = _name;
      sale = _sale;
      token = ERC20(_token);
      password_hash = _password_hash;
      earliest_buy_block = _earliest_buy_block;
      earliest_buy_time = _earliest_buy_time;
  }

   
   
  function withdraw(address user) internal {
     
    if (!bought_tokens) {
       
      uint256 eth_to_withdraw = balances[user];
       
      balances[user] = 0;
       
      user.transfer(eth_to_withdraw);
    } else {  
       
      uint256 contract_token_balance = token.balanceOf(address(this));
       
      require(contract_token_balance > 0);
       
      uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
       
      contract_eth_value -= balances[user];
       
      balances[user] = 0;
       
       
      require(token.transfer(user, tokens_to_withdraw));
    }
  }

   
   
  function auto_withdraw(address user){
     
     
    require (bought_tokens && now > time_bought + 1 hours);
     
    withdraw(user);
  }

   
  function buy_sale(){
     
    require(bought_tokens);
     
    require(block.number < earliest_buy_block);
    require(now < earliest_buy_time);
     
    require(!kill_switch);
     
    bought_tokens = true;
     
    time_bought = now;
     
    contract_eth_value = this.balance;
     
     
     
     
     
    require(sale.call.value(contract_eth_value)());
  }

   
  function activate_kill_switch(string password) {
     
    require(sha3(password) == password_hash);
     
    kill_switch = true;
  }

   
  function default_helper() payable {
     
    if (msg.value <= 1 finney) {
      withdraw(msg.sender);
    } else {  
       
      require (!kill_switch);
       
       
      require (!bought_tokens);
       
      balances[msg.sender] += msg.value;
    }
  }

   
  function () payable {
     
     
    require(msg.sender != address(sale));
     
    default_helper();
  }
}

contract EquioGenesis {

   
   
   
  function generate (
    string _name,
    address _sale,
    address _token,
    bytes32 _password_hash,
    uint256 _earliest_buy_block,
    uint256 _earliest_buy_time
  ) returns (Equio equioAddess) {
    return new Equio(
      _name,
      _sale,
      _token,
      _password_hash,
      _earliest_buy_block,
      _earliest_buy_time
    );
  }
}