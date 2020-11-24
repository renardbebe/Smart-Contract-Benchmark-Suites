 

 

pragma solidity ^0.4.18;

 
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) public returns (bool success);
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

 

contract Moongang {

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier minAmountReached {
     
    require(this.balance >= SafeMath.div(SafeMath.mul(min_amount, 100), 99));
    _;
  }

  modifier underMaxAmount {
    require(max_amount == 0 || this.balance <= max_amount);
    _;
  }

   
  uint256 constant FEE = 100;     
   
  uint256 constant FEE_DEV = 6;  
  uint256 constant FEE_AUDIT = 12;  
  address public owner;
  address constant public developer = 0xEE06BdDafFA56a303718DE53A5bc347EfbE4C68f;
  address constant public auditor = 0x63F7547Ac277ea0B52A0B060Be6af8C5904953aa;
  uint256 public individual_cap;

   
  uint256 public max_amount;   
  uint256 public min_amount;

   
  mapping (address => uint256) public balances;
  mapping (address => uint256) public balances_bonus;
   
  mapping (address => bool) public whitelist;
   
  bool public bought_tokens;
   
  uint256 public contract_eth_value;
  uint256 public contract_eth_value_bonus;
   
  bool public bonus_received;
   
  address public sale;
   
  ERC20 public token;
   
  uint256 fees;
   
  bool public allow_refunds;
   
  uint256 public percent_reduction;
   
  bool public whitelist_enabled;

   
  function Moongang(uint256 max, uint256 min, uint256 cap) {
     
    owner = msg.sender;
    max_amount = SafeMath.div(SafeMath.mul(max, 100), 99);
    min_amount = min;
    individual_cap = cap;
     
    whitelist_enabled = false;
    whitelist[msg.sender] = true;
  }

   

   
  function buy_the_tokens() onlyOwner minAmountReached underMaxAmount {
     
    require(!bought_tokens && sale != 0x0);
     
    bought_tokens = true;
     
    uint256 dev_fee = SafeMath.div(fees, FEE_DEV);
    uint256 audit_fee = SafeMath.div(fees, FEE_AUDIT);
    owner.transfer(SafeMath.sub(SafeMath.sub(fees, dev_fee), audit_fee));
    developer.transfer(dev_fee);
    auditor.transfer(audit_fee);
     
    contract_eth_value = this.balance;
    contract_eth_value_bonus = this.balance;
     
    sale.transfer(contract_eth_value);
  }

  function force_refund(address _to_refund) onlyOwner {
    require(!bought_tokens);
    uint256 eth_to_withdraw = SafeMath.div(SafeMath.mul(balances[_to_refund], 100), 99);
    balances[_to_refund] = 0;
    balances_bonus[_to_refund] = 0;
    fees = SafeMath.sub(fees, SafeMath.div(eth_to_withdraw, FEE));
    _to_refund.transfer(eth_to_withdraw);
  }

  function force_partial_refund(address _to_refund) onlyOwner {
    require(percent_reduction > 0);
     
     
    uint256 basic_amount = SafeMath.div(SafeMath.mul(balances[_to_refund], percent_reduction), 100);
    uint256 eth_to_withdraw = basic_amount;
    if (!bought_tokens) {
       
      eth_to_withdraw = SafeMath.div(SafeMath.mul(basic_amount, 100), 99);
      fees = SafeMath.sub(fees, SafeMath.div(eth_to_withdraw, FEE));
    }
    balances[_to_refund] = SafeMath.sub(balances[_to_refund], eth_to_withdraw);
    balances_bonus[_to_refund] = balances[_to_refund];
    _to_refund.transfer(eth_to_withdraw);
  }

  function whitelist_addys(address[] _addys) onlyOwner {
    for (uint256 i = 0; i < _addys.length; i++) {
      whitelist[_addys[i]] = true;
    }
  }

  function blacklist_addys(address[] _addys) onlyOwner {
    for (uint256 i = 0; i < _addys.length; i++) {
      whitelist[_addys[i]] = false;
    }
  }

  function set_sale_address(address _sale) onlyOwner {
     
    require(_sale != 0x0);
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
    require(_reduction <= 100);
    percent_reduction = _reduction;
  }

  function set_whitelist_enabled(bool _boolean) onlyOwner {
    whitelist_enabled = _boolean;
  }

  function change_individual_cap(uint256 _cap) onlyOwner {
    individual_cap = _cap;
  }

  function change_owner(address new_owner) onlyOwner {
    require(new_owner != 0x0);
    owner = new_owner;
  }

  function change_max_amount(uint256 _amount) onlyOwner {
       
       
      max_amount = SafeMath.div(SafeMath.mul(_amount, 100), 99);
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
    require(!bought_tokens && allow_refunds && percent_reduction == 0);
     
     
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
    if (whitelist_enabled) {
      require(whitelist[msg.sender]);
    }
     
    uint256 fee = SafeMath.div(msg.value, FEE);
    fees = SafeMath.add(fees, fee);
     
    balances[msg.sender] = SafeMath.add(balances[msg.sender], SafeMath.sub(msg.value, fee));
     
     
    require(individual_cap == 0 || balances[msg.sender] <= individual_cap);
    balances_bonus[msg.sender] = balances[msg.sender];
  }
}