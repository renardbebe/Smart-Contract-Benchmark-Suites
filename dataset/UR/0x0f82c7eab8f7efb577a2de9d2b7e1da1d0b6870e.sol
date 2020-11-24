 

pragma solidity ^0.4.13;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract DistrictBuyer {
   
  mapping (address => uint256) public balances;
   
  uint256 public bounty;
   
  bool public bought_tokens;
   
  uint256 public time_bought;
   
  uint256 public contract_eth_value;
   
  bool public kill_switch;
  
   
  bytes32 password_hash = 0x1b266c9bad3a46ed40bf43471d89b83712ed06c2250887c457f5f21f17b2eb97;
   
  uint256 earliest_buy_time = 1500390000;
   
  address developer = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
   
  address public sale = 0xF8094e15c897518B5Ac5287d7070cA5850eFc6ff;
   
  ERC20 public token = ERC20(0x0AbdAce70D3790235af448C88547603b945604ea);
  
   
  function activate_kill_switch(string password) {
     
    if (msg.sender != developer && sha3(password) != password_hash) throw;
     
    uint256 claimed_bounty = bounty;
     
    bounty = 0;
     
    kill_switch = true;
     
    msg.sender.transfer(claimed_bounty);
  }
  
   
   
  function withdraw(address user, bool has_fee) internal {
     
    if (!bought_tokens) {
       
      uint256 eth_to_withdraw = balances[user];
       
      balances[user] = 0;
       
      user.transfer(eth_to_withdraw);
    }
     
    else {
       
      uint256 contract_token_balance = token.balanceOf(address(this));
       
      if (contract_token_balance == 0) throw;
       
      uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
       
      contract_eth_value -= balances[user];
       
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
     
    if (now < earliest_buy_time) return;
     
    if (kill_switch) return;
     
    bought_tokens = true;
     
    time_bought = now;
     
    uint256 claimed_bounty = bounty;
     
    bounty = 0;
     
    contract_eth_value = this.balance - claimed_bounty;
     
     
     
    if(!sale.call.value(contract_eth_value)()) throw;
     
    msg.sender.transfer(claimed_bounty);
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
     
    if (msg.sender == address(sale)) throw;
     
    default_helper();
  }
}