 

pragma solidity ^0.4.17;
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 
contract SafeBasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size + 4);
     _;
  }
   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
    require(_to != address(0));
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract SafeStandardToken is ERC20, SafeBasicToken {
  mapping (address => mapping (address => uint256)) allowed;
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
     
     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
contract LendConnect is SafeStandardToken{
  string public constant name = "LendConnect Token";
  string public constant symbol = "LCT";
  uint256 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 6500000 * (10 ** uint256(decimals));
  function LendConnect(address _ownerAddress) public {
    totalSupply = INITIAL_SUPPLY;
    balances[_ownerAddress] = INITIAL_SUPPLY;
  }
}
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  LendConnect public token;
   
  
  uint256 public start_time = 1511377200; 
  uint256 public phase_1_Time = 1511809200; 
  uint256 public phase_2_Time = 1512241200; 
  uint256 public phase_3_Time = 1512673200; 
  uint256 public phase_4_Time = 1513105200; 
  uint256 public end_Time = 1513278000; 
  uint256 public phase_1_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_2_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_3_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_4_remaining_tokens  = 1000000 * (10 ** uint256(18));
  uint256 public phase_5_remaining_tokens  = 1000000 * (10 ** uint256(18));
  mapping(address => uint256) phase_1_balances;
  mapping(address => uint256) phase_2_balances;
  mapping(address => uint256) phase_3_balances;
  mapping(address => uint256) phase_4_balances;
  mapping(address => uint256) phase_5_balances;
  
  
   
  address public wallet;
   
  uint256 public rate = 730;
   
  uint256 public weiRaised;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  event RateChanged(address indexed owner, uint256 old_rate, uint256 new_rate);
  
   
  function Crowdsale(address tokenContractAddress, address _walletAddress) public{
    wallet = _walletAddress;
    token = LendConnect(tokenContractAddress);
  }
   
  function () payable public{
    buyTokens(msg.sender);
  }
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
     
    uint256 tokens = weiAmount.mul(rate);
     
    require(isTokenAvailable(tokens));
     
    weiRaised = weiRaised.add(weiAmount);
    token.transfer(beneficiary, tokens);
     
    updatePhaseSupplyAndBalance(tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
   
  function isTokenAvailable(uint256 _tokens) internal constant returns (bool){
    uint256 current_time = now;
    uint256 total_expected_tokens = 0;
    if(current_time > start_time && current_time < phase_1_Time){
      total_expected_tokens = _tokens + phase_1_balances[msg.sender];
      return total_expected_tokens <= 10000 * (10 ** uint256(18)) &&
        _tokens <= phase_1_remaining_tokens;
    }
    else if(current_time > phase_1_Time && current_time < phase_2_Time){
      total_expected_tokens = _tokens + phase_2_balances[msg.sender];
      return total_expected_tokens <= 2000 * (10 ** uint256(18)) &&
        _tokens <= phase_2_remaining_tokens;
    }
    else if(current_time > phase_2_Time && current_time < phase_3_Time){
      total_expected_tokens = _tokens + phase_3_balances[msg.sender];
      return total_expected_tokens <= 2000 * (10 ** uint256(18)) &&
        _tokens <= phase_3_remaining_tokens;
    }
    else if(current_time > phase_3_Time && current_time < phase_4_Time){
      total_expected_tokens = _tokens + phase_4_balances[msg.sender];
      return total_expected_tokens <= 3500 * (10 ** uint256(18)) &&
        _tokens <= phase_4_remaining_tokens;
    }
    else{
      total_expected_tokens = _tokens + phase_5_balances[msg.sender];
      return total_expected_tokens <= 3500 * (10 ** uint256(18)) &&
        _tokens <= phase_5_remaining_tokens;
    }
  }
   
  function updatePhaseSupplyAndBalance(uint256 _tokens) internal {
    uint256 current_time = now;
    if(current_time > start_time && current_time < phase_1_Time){
      phase_1_balances[msg.sender] = phase_1_balances[msg.sender].add(_tokens);
      phase_1_remaining_tokens = phase_1_remaining_tokens - _tokens;
    }
    else if(current_time > phase_1_Time && current_time < phase_2_Time){
      phase_2_balances[msg.sender] = phase_2_balances[msg.sender].add(_tokens);
      phase_2_remaining_tokens = phase_2_remaining_tokens - _tokens;
    }
    else if(current_time > phase_2_Time && current_time < phase_3_Time){
      phase_3_balances[msg.sender] = phase_3_balances[msg.sender].add(_tokens);
      phase_3_remaining_tokens = phase_3_remaining_tokens - _tokens;
    }
    else if(current_time > phase_3_Time && current_time < phase_4_Time){
      phase_4_balances[msg.sender] = phase_4_balances[msg.sender].add(_tokens);
      phase_4_remaining_tokens = phase_4_remaining_tokens - _tokens;
    }
    else{
      phase_5_balances[msg.sender] = phase_5_balances[msg.sender].add(_tokens);
      phase_5_remaining_tokens = phase_5_remaining_tokens - _tokens;
    }
  }
   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= start_time && now <= end_Time;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  function hasEnded() public constant returns (bool) {
    return now > end_Time;
  }
   
  function transferBack(uint256 tokens) onlyOwner public returns (bool){
    token.transfer(owner, tokens);
    return true;
  }
   
  function changeRate(uint256 _rate) onlyOwner public returns (bool){
    RateChanged(msg.sender, rate, _rate);
    rate = _rate;
    return true;
  }
  function tokenBalance() constant public returns (uint256){
    return token.balanceOf(this);
  }
}