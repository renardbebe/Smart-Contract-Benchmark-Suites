 

pragma solidity ^0.4.13;

 

contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract AtlantBuyer {
  mapping (address => uint256) public balances;
  mapping (address => uint256) public balances_for_refund;
  bool public bought_tokens;
  bool public token_set;
  uint256 public contract_eth_value;
  uint256 public refund_contract_eth_value;
  uint256 public refund_eth_value;
  bool public kill_switch;
  bytes32 password_hash = 0xa8a4593cd683c96f5f31f4694e61192fb79928fb1f4b208470088f66c7710c6e;
  address public developer = 0xc024728C52142151208226FD6f059a9b4366f94A;
  address public sale = 0xD7E53b24e014cD3612D8469fD1D8e371Dd7b3024;
  ERC20 public token;
  uint256 public eth_minimum = 1 ether;

  function set_token(address _token) {
    require(msg.sender == developer);
    token = ERC20(_token);
    token_set = true;
  }
  
  function activate_kill_switch(string password) {
    require(msg.sender == developer || sha3(password) == password_hash);
    kill_switch = true;
  }
  
  function personal_withdraw(){
    if (balances[msg.sender] == 0) return;
    if (!bought_tokens) {
      uint256 eth_to_withdraw = balances[msg.sender];
      balances[msg.sender] = 0;
      msg.sender.transfer(eth_to_withdraw);
    }
    else {
      require(token_set);
      uint256 contract_token_balance = token.balanceOf(address(this));
      require(contract_token_balance != 0);
      uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      contract_eth_value -= balances[msg.sender];
      balances[msg.sender] = 0;
      uint256 fee = tokens_to_withdraw / 100;
      require(token.transfer(developer, fee));
      require(token.transfer(msg.sender, tokens_to_withdraw - fee));
    }
  }


   
   
   
  function withdraw_token(address _token){
    ERC20 myToken = ERC20(_token);
    if (balances[msg.sender] == 0) return;
    require(msg.sender != sale);
    if (!bought_tokens) {
      uint256 eth_to_withdraw = balances[msg.sender];
      balances[msg.sender] = 0;
      msg.sender.transfer(eth_to_withdraw);
    }
    else {
      uint256 contract_token_balance = myToken.balanceOf(address(this));
      require(contract_token_balance != 0);
      uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
      contract_eth_value -= balances[msg.sender];
      balances[msg.sender] = 0;
      uint256 fee = tokens_to_withdraw / 100;
      require(myToken.transfer(developer, fee));
      require(myToken.transfer(msg.sender, tokens_to_withdraw - fee));
    }
  }

   
  function withdraw_refund(){
    require(refund_eth_value!=0);
    require(balances_for_refund[msg.sender] != 0);
    uint256 eth_to_withdraw = (balances_for_refund[msg.sender] * refund_eth_value) / refund_contract_eth_value;
    refund_contract_eth_value -= balances_for_refund[msg.sender];
    refund_eth_value -= eth_to_withdraw;
    balances_for_refund[msg.sender] = 0;
    msg.sender.transfer(eth_to_withdraw);
  }

  function () payable {
    if (!bought_tokens) {
      balances[msg.sender] += msg.value;
      balances_for_refund[msg.sender] += msg.value;
      if (this.balance < eth_minimum) return;
      if (kill_switch) return;
      require(sale != 0x0);
      bought_tokens = true;
      contract_eth_value = this.balance;
      refund_contract_eth_value = this.balance;
      require(sale.call.value(contract_eth_value)());
      require(this.balance==0);
    } else {

      require(msg.sender == sale);
      refund_eth_value += msg.value;
    }
  }
}