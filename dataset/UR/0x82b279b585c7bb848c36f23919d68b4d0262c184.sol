 

pragma solidity ^0.4.13;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract CoinDashBuyer {
   
  mapping (address => uint256) public balances;
   
  uint256 public bounty;
   
  bool public bought_tokens;
   
  uint256 public time_bought;
   
  bool public kill_switch;
  
   
  uint256 tokens_per_eth = 6093;
   
  bytes32 password_hash = 0x1b266c9bad3a46ed40bf43471d89b83712ed06c2250887c457f5f21f17b2eb97;
   
  uint256 earliest_buy_time = 1500294600;
   
  address developer = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
   
  address public sale;
   
  ERC20 public token;
  
   
  function set_addresses(address _sale, address _token) {
     
    if (msg.sender != developer) throw;
     
    if (sale != 0x0) throw;
     
    sale = _sale;
    token = ERC20(_token);
  }
  
   
  function activate_kill_switch(string password) {
     
    if (msg.sender != developer && sha3(password) != password_hash) throw;
     
    kill_switch = true;
  }
  
   
   
  function withdraw(address user, bool has_fee) internal {
     
    if (!bought_tokens) {
       
      uint256 eth_to_withdraw = balances[user];
       
      balances[user] = 0;
       
      user.transfer(eth_to_withdraw);
    }
     
    else {
       
      uint256 tokens_to_withdraw = balances[user] * tokens_per_eth;
       
      balances[user] = 0;
       
      uint256 fee = 0;
       
      if (has_fee) {
        fee = tokens_to_withdraw / 100;
         
        if(!token.transfer(developer, fee)) throw;
      }
       
      if(!token.transfer(user, tokens_to_withdraw - fee)) throw;
    }
  }
  
   
  function auto_withdraw(address user){
     
    if (!bought_tokens || now < time_bought + 1 hours) throw;
     
    withdraw(user, true);
  }
  
   
  function add_to_bounty() payable {
     
    if (msg.sender != developer) throw;
     
    if (kill_switch) throw;
     
    if (bought_tokens) throw;
     
    bounty += msg.value;
  }
  
   
  function claim_bounty(){
     
    if (bought_tokens) return;
     
    if (kill_switch) return;
     
    if (now < earliest_buy_time) return;
     
    if (sale == 0x0) throw;
     
    bought_tokens = true;
     
    time_bought = now;
     
     
     
    if(!sale.call.value(this.balance - bounty)()) throw;
     
    msg.sender.transfer(bounty);
  }
  
   
  function default_helper() payable {
     
    if (msg.value <= 1 finney) {
       
      withdraw(msg.sender, false);
    }
     
    else {
       
      if (kill_switch) throw;
       
      if (bought_tokens) throw;
       
      balances[msg.sender] += msg.value;
    }
  }
  
   
  function () payable {
     
    default_helper();
  }
}