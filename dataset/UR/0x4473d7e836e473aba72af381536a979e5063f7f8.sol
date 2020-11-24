 

pragma solidity ^0.4.13;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract CobinhoodBuyer {
   
  mapping (address => uint256) public balances;
   
  bool public received_tokens;
   
  bool public purchased_tokens;
   
  uint256 public contract_eth_value;
   
  bool public kill_switch;

   
  bytes32 password_hash = 0xe3ce8892378c33f21165c3fa9b1c106524b2352e16ea561d943008f11f0ecce0;
   
  uint256 public latest_buy_time = 1505109600;
   
  uint256 public eth_cap = 299 ether;
   
  uint256 public eth_min = 149 ether;
   
  address public developer = 0x0575C223f5b87Be4812926037912D45B31270d3B;
   
  address public fee_claimer = 0x9793661F48b61D0b8B6D39D53CAe694b101ff028;
   
  address public sale = 0x0bb9fc3ba7bcf6e5d6f6fc15123ff8d5f96cee00;
   
  ERC20 public token;

   
  function set_address(address _token) {
     
    require(msg.sender == developer);
     
    token = ERC20(_token);
  }

   
  function force_received() {
      require(msg.sender == developer);
      received_tokens = true;
  }

   
  function received_tokens() {
      if( token.balanceOf(address(this)) > 0){
          received_tokens = true;
      }
  }

   
  function activate_kill_switch(string password) {
     
    require(msg.sender == developer || sha3(password) == password_hash);

     
    kill_switch = true;
  }

   
  function withdraw(address user){
     
    require(received_tokens || now > latest_buy_time);
     
    if (balances[user] == 0) return;
     
    if (!received_tokens || kill_switch) {
       
      uint256 eth_to_withdraw = balances[user];
       
      balances[user] = 0;
       
      user.transfer(eth_to_withdraw);
    }
     
    else {
       
      uint256 contract_token_balance = token.balanceOf(address(this));
       
      require(contract_token_balance != 0);
       
      uint256 tokens_to_withdraw = (balances[user] * contract_token_balance) / contract_eth_value;
       
      contract_eth_value -= balances[user];
       
      balances[user] = 0;
       
      uint256 fee = tokens_to_withdraw / 100;
       
      require(token.transfer(fee_claimer, fee));
       
      require(token.transfer(user, tokens_to_withdraw - fee));
    }
  }

   
  function purchase(){
     
    if (purchased_tokens) return;
     
    if (now > latest_buy_time) return;
     
    if (kill_switch) return;
     
    if (this.balance < eth_min) return;
     
    purchased_tokens = true;
     
     
     
    require(sale.call.value(this.balance)());
  }

   
  function () payable {
     
    require(!kill_switch);
     
    require(!purchased_tokens);
     
    require(this.balance < eth_cap);
     
    balances[msg.sender] += msg.value;
  }
}