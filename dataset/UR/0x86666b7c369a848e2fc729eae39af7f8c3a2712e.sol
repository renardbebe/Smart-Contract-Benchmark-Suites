 

 

pragma solidity ^0.4.18;

 
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

 

contract Moongang {

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier minAmountReached {
     
    uint256 correct_amount = SafeMath.div(SafeMath.mul(min_amount, 100), 99);
    require(this.balance >= correct_amount);
    _;
  }

  modifier underMaxAmount {
    uint256 correct_amount = SafeMath.div(SafeMath.mul(min_amount, 100), 99);
    require(max_amount == 0 || this.balance <= correct_amount);
    _;
  }

   
  uint256 constant FEE = 100;     
  uint256 constant FEE_DEV = SafeMath.div(20, 3);  
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
   
  address public sale;
   
  ERC20 public token;
   
  uint256 fees;
   
  bool allow_refunds;
   
  uint256 percent_reduction;
  
  function Moongang(uint256 max, uint256 min) {
     
    owner = msg.sender;
    max_amount = max;
    min_amount = min;
  }

   

   
  function buy_the_tokens() onlyOwner minAmountReached underMaxAmount {
    require(!bought_tokens);
     
    require(sale != 0x0);
     
    bought_tokens = true;
     
    uint256 dev_fee = SafeMath.div(fees, FEE_DEV);
    owner.transfer(SafeMath.sub(fees, dev_fee));
    developer.transfer(dev_fee);
     
    contract_eth_value = this.balance;
    contract_eth_value_bonus = this.balance;
     
    sale.transfer(contract_eth_value);
  }
  
  function set_sale_address(address _sale) onlyOwner {
     
    require(_sale != 0x0 && sale == 0x0);
    sale = _sale;
  }

  function set_token_address(address _token) onlyOwner {
    require(_token != 0x0);
    token = ERC20(_token);
  }

  function set_bonus_received(bool _boolean) onlyOwner {
    bonus_received = _boolean;
  }

  function set_allow_refunds(bool _boolean) onlyOwner {
     
    allow_refunds = _boolean;
  }

  function set_percent_reduction(uint256 _reduction) onlyOwner {
      percent_reduction = _reduction;
  }

  function change_owner(address new_owner) onlyOwner {
    require(new_owner != 0x0);
    owner = new_owner;
  }

  function change_max_amount(uint256 _amount) onlyOwner {
       
       
      max_amount = _amount;
  }

  function change_min_amount(uint256 _amount) onlyOwner {
       
       
      min_amount = _amount;
  }

   

   
  function withdraw() {
     
    require(bought_tokens);
    uint256 contract_token_balance = token.balanceOf(address(this));
     
    require(contract_token_balance != 0);
    uint256 tokens_to_withdraw = SafeMath.div(SafeMath.mul(balances[msg.sender], contract_token_balance), contract_eth_value);
     
    contract_eth_value = SafeMath.sub(contract_eth_value, balances[msg.sender]);
     
    balances[msg.sender] = 0;
     
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }

  function withdraw_bonus() {
   
    require(bought_tokens && bonus_received);
    uint256 contract_token_balance = token.balanceOf(address(this));
    require(contract_token_balance != 0);
    uint256 tokens_to_withdraw = SafeMath.div(SafeMath.mul(balances_bonus[msg.sender], contract_token_balance), contract_eth_value_bonus);
    contract_eth_value_bonus = SafeMath.sub(contract_eth_value_bonus, balances_bonus[msg.sender]);
    balances_bonus[msg.sender] = 0;
    require(token.transfer(msg.sender, tokens_to_withdraw));
  }
  
   
  function refund() {
    require(allow_refunds && percent_reduction == 0);
     
     
    uint256 eth_to_withdraw = SafeMath.div(SafeMath.mul(balances[msg.sender], 100), 99);
     
    balances[msg.sender] = 0;
     
    balances_bonus[msg.sender] = 0;
     
    fees = SafeMath.sub(fees, SafeMath.div(eth_to_withdraw, FEE));
     
    msg.sender.transfer(eth_to_withdraw);
  }

   
   
  function partial_refund() {
    require(allow_refunds && percent_reduction > 0);
     
     
    uint256 basic_amount = SafeMath.div(SafeMath.mul(balances[msg.sender], percent_reduction), 100);
    uint256 eth_to_withdraw = basic_amount;
    if (!bought_tokens) {
       
      eth_to_withdraw = SafeMath.div(SafeMath.mul(basic_amount, 100), 99);
      fees = SafeMath.sub(fees, SafeMath.div(eth_to_withdraw, FEE));
    }
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], eth_to_withdraw);
    balances_bonus[msg.sender] = balances[msg.sender];
    msg.sender.transfer(eth_to_withdraw);
  }

   
  function () payable underMaxAmount {
    require(!bought_tokens);
     
    uint256 fee = SafeMath.div(msg.value, FEE);
    fees = SafeMath.add(fees, fee);
     
    balances[msg.sender] = SafeMath.add(balances[msg.sender], SafeMath.sub(msg.value, fee));
    balances_bonus[msg.sender] = balances[msg.sender];
  }
}