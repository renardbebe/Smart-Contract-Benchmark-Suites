 

 

pragma solidity ^0.4.13;

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

 

contract SuperbContract {

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   
  uint256 FEE = 100;     
  uint256 FEE_DEV = 10;  
  address public owner;
  address constant public developer = 0xEE06BdDafFA56a303718DE53A5bc347EfbE4C68f;

   
  uint256 public max_amount = 0 ether;   
  uint256 public min_amount = 0 ether;

   
  mapping (address => uint256) public balances;
  mapping (address => uint256) public balances_bonus;
   
  bool public bought_tokens = false;
   
  uint256 public contract_eth_value;
  uint256 public contract_eth_value_bonus;
   
  bool bonus_received;
   
  address public sale = 0x98Ba698Fc04e79DCE066873106424252e6aabc31;
   
  ERC20 public token;
   
  uint256 fees;
   
  bool got_refunded;
  
  function SuperbContract() {
     
    owner = msg.sender;
  }

   

   
  function buy_the_tokens() onlyOwner {
    require(!bought_tokens);
     
    require(sale != 0x0);
     
    require(this.balance >= min_amount);
     
    bought_tokens = true;
     
    uint256 dev_fee = fees/FEE_DEV;
    owner.transfer(fees-dev_fee);
    developer.transfer(dev_fee);
     
    contract_eth_value = this.balance;
    contract_eth_value_bonus = this.balance;
     
    sale.transfer(contract_eth_value);
  }

  function set_token_address(address _token) onlyOwner {
    require(_token != 0x0);
    token = ERC20(_token);
  }

  function set_bonus_received() onlyOwner {
    bonus_received = true;
  }

  function set_got_refunded() onlyOwner {
     
    got_refunded = true;
  }

  function changeOwner(address new_owner) onlyOwner {
    require(new_owner != 0x0);
    owner = new_owner;
  }

   

   
  function withdraw() {
     
    require(bought_tokens);
    uint256 contract_token_balance = token.balanceOf(address(this));
     
    require(contract_token_balance != 0);
    uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
     
    contract_eth_value -= balances[msg.sender];
     
    balances[msg.sender] = 0;
     
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }

  function withdraw_bonus() {
   
    require(bought_tokens);
    require(bonus_received);
    uint256 contract_token_balance = token.balanceOf(address(this));
    require(contract_token_balance != 0);
    uint256 tokens_to_withdraw = (balances_bonus[msg.sender] * contract_token_balance) / contract_eth_value_bonus;
    contract_eth_value_bonus -= balances_bonus[msg.sender];
    balances_bonus[msg.sender] = 0;
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }
  
   
  function refund_me() {
    require(!bought_tokens || got_refunded);
     
    uint256 eth_to_withdraw = balances[msg.sender];
     
    balances[msg.sender] = 0;
     
    balances_bonus[msg.sender] = 0;
     
    msg.sender.transfer(eth_to_withdraw);
  }

   
  function () payable {
    require(!bought_tokens);
     
    require(max_amount == 0 || this.balance <= max_amount);
     
    uint256 fee = msg.value / FEE;
    fees += fee;
     
    balances[msg.sender] += (msg.value-fee);
    balances_bonus[msg.sender] += (msg.value-fee);
  }
}