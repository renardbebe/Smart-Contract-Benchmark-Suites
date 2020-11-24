 

pragma solidity ^0.4.11;


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {    uint256 c = a * b;    assert(a == 0 || c / a == b);    return c;  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


contract Stars is StandardToken {

  string public name = "Stars";
  string public symbol = "STR";
  uint public decimals = 8;
  uint public INITIAL_SUPPLY = 60000000 * 10**8;   

   
  function Stars() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}


contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


contract StarsICO is Pausable {
  using SafeMath for uint256;

  uint256 public constant MAX_GAS_PRICE = 50000000000 wei;     

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet_address;

   
  address public token_address;

   
  uint256 public rate;

   
  uint256 public capTokens;

   
  uint256 public weiRaised;
  uint256 public tokensSold;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  modifier validGasPrice() {
    require(tx.gasprice <= MAX_GAS_PRICE);
    _;
  }

  function StarsICO(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet_address, address _token_address, uint256 _cap) {
     
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet_address != 0x0);
    require(_token_address != 0x0);
    require(_cap > 0);

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet_address = _wallet_address;
    token_address = _token_address;
    capTokens = _cap;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) whenNotPaused validGasPrice private {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 tokens = convertWeiToTokens(weiAmount);

    wallet_address.transfer(msg.value);
    Stars tok = Stars(token_address);
    if (tok.transferFrom(wallet_address, beneficiary, tokens)) {
       
      weiRaised = weiRaised.add(weiAmount);
      tokensSold = tokensSold.add(tokens);
      TokenPurchase(beneficiary, beneficiary, weiAmount, tokens);
    }
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool withinCap = tokensSold.add(convertWeiToTokens(msg.value)) <= capTokens;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

  function convertWeiToTokens(uint256 weiAmount) constant returns (uint256) {
     
    uint256 tokens = weiAmount.div(10 ** 10);
    tokens = tokens.mul(rate);
    return tokens;
  }
}