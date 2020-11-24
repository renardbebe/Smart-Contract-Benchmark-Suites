 

pragma solidity ^0.4.11;

 

 
contract DaoCasinoToken {
  uint256 public CAP;
  uint256 public totalEthers;
  function proxyPayment(address participant) payable;
  function transfer(address _to, uint _amount) returns (bool success);
}

contract BetBuyer {
   
  mapping (address => uint256) public balances;
   
  mapping (address => bool) public checked_in;
   
  uint256 public bounty;
   
  bool public bought_tokens;
   
  uint256 public time_bought;
   
  bool public kill_switch;
  
   
  uint256 bet_per_eth = 2000;
  
   
  DaoCasinoToken public token = DaoCasinoToken(0xFd08655DFcaD0d42B57Dc8f1dc8CC39eD8b6B071);
   
  address developer = 0x000Fb8369677b3065dE5821a86Bc9551d5e5EAb9;
  
   
  function activate_kill_switch() {
     
    if (msg.sender != developer) throw;
     
    kill_switch = true;
  }
  
   
  function withdraw(){
     
    if (!bought_tokens) {
       
      uint256 eth_amount = balances[msg.sender];
       
      balances[msg.sender] = 0;
       
      msg.sender.transfer(eth_amount);
    }
     
    else {
       
      uint256 bet_amount = balances[msg.sender] * bet_per_eth;
       
      balances[msg.sender] = 0;
       
      uint256 fee = 0;
       
      if (!checked_in[msg.sender]) {
        fee = bet_amount / 100;
         
        if(!token.transfer(developer, fee)) throw;
      }
       
      if(!token.transfer(msg.sender, bet_amount - fee)) throw;
    }
  }
  
   
  function add_to_bounty() payable {
     
    if (msg.sender != developer) throw;
     
    if (kill_switch) throw;
     
    if (bought_tokens) throw;
     
    bounty += msg.value;
  }
  
   
  function claim_bounty(){
     
    if (bought_tokens) return;
     
    if (kill_switch) throw;
     
    bought_tokens = true;
     
    time_bought = now;
     
     
     
    token.proxyPayment.value(this.balance - bounty)(address(this));
     
    msg.sender.transfer(bounty);
  }
  
   
  function default_helper() payable {
     
    if (msg.value <= 1 finney) {
       
      if (bought_tokens && token.totalEthers() < token.CAP()) {
         
        checked_in[msg.sender] = true;
      }
       
      else {
        withdraw();
      }
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