 

 

pragma solidity ^0.4.13;

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

 

contract NiceContract {

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   
  mapping (address => uint256) public balances;
  mapping (address => uint256) public balances_bonus;
   
  bool public bought_tokens = false;
   
  uint256 public contract_eth_value;
  uint256 public contract_eth_value_bonus;
   
  bool bonus_received;
   
  address public sale;
   
  ERC20 public token;
  address constant public owner = 0xEE06BdDafFA56a303718DE53A5bc347EfbE4C68f;
  
   
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
    require(!bought_tokens);
     
    uint256 eth_to_withdraw = balances[msg.sender];
     
    balances[msg.sender] = 0;
     
    balances_bonus[msg.sender] = 0;
     
    msg.sender.transfer(eth_to_withdraw);
  }
  
   
  function buy_the_tokens() onlyOwner {
    require(!bought_tokens);
    require(sale != 0x0);
     
    bought_tokens = true;
     
    contract_eth_value = this.balance;
    contract_eth_value_bonus = this.balance;
     
    sale.transfer(contract_eth_value);
  }
  
  function set_sale_address(address _sale) onlyOwner {
     
    require(!bought_tokens);
    require(sale == 0x0);
    require(_sale != 0x0);
    sale = _sale;
  }

  function set_token_address(address _token) onlyOwner {
    require(_token != 0x0);
    token = ERC20(_token);
  }

  function set_bonus_received() onlyOwner {
    bonus_received = true;
  }

   
  function () payable {
    require(!bought_tokens);
     
    balances[msg.sender] += msg.value;
    balances_bonus[msg.sender] += msg.value;
  }
}