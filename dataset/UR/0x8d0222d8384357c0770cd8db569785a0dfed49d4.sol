 

pragma solidity ^0.4.13;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract BurnableToken is StandardToken {
 
   
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
 
  event Burn(address indexed burner, uint indexed value);
 
}

 
contract HamsterMarketplaceToken is BurnableToken, Pausable {

  string public constant name = 'Hamster Marketplace Token';                    
  string public constant symbol = 'HMT';                                        
  uint8 public constant decimals = 8;                                           
  uint256 constant INITIAL_SUPPLY = 10000000 * 10**uint256(decimals);           
  uint256 public sellPrice;
  mapping(address => uint256) bonuses;
  uint8 public freezingPercentage;
  uint32 public constant unfreezingTimestamp = 1550534400;                      

   
  function HamsterMarketplaceToken() {
    totalSupply = INITIAL_SUPPLY;                                               
    balances[msg.sender] = INITIAL_SUPPLY;                                      
    sellPrice = 0;
    freezingPercentage = 100;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return super.balanceOf(_owner) - bonuses[_owner] * freezingPercentage / 100;
  }

   
  function transfer(address _to, uint256 _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(balances[msg.sender] - bonuses[msg.sender] * freezingPercentage / 100 >= _value);
    return super.transfer(_to, _value);
  }

   
  function transferWithBonuses(address _to, uint256 _value, uint256 _bonus) onlyOwner returns (bool) {
    require(_to != address(0));
    require(balances[msg.sender] - bonuses[msg.sender] * freezingPercentage / 100 >= _value + _bonus);
    bonuses[_to] = bonuses[_to].add(_bonus);
    return super.transfer(_to, _value + _bonus);
  }

   
  function bonusesOf(address _owner) constant returns (uint256 balance) {
    return bonuses[_owner] * freezingPercentage / 100;
  }

   
  function setFreezingPercentage(uint8 _percentage) onlyOwner returns (bool) {
    require(_percentage < freezingPercentage);
    require(now < unfreezingTimestamp);
    freezingPercentage = _percentage;
    return true;
  }

   
  function unfreezeBonuses() returns (bool) {
    require(now >= unfreezingTimestamp);
    freezingPercentage = 0;
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool) {
    require(_to != address(0));
    require(balances[_from] - bonuses[_from] * freezingPercentage / 100 >= _value);
    return super.transferFrom(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  
  function getPrice() constant returns (uint256 _sellPrice) {
      return sellPrice;
  }

   
  function setPrice(uint256 newSellPrice) external onlyOwner returns (bool success) {
      require(newSellPrice > 0);
      sellPrice = newSellPrice;
      return true;
  }

   
  function sell(uint256 amount) external returns (uint256 revenue){
      require(balances[msg.sender] - bonuses[msg.sender] * freezingPercentage / 100 >= amount);            
      balances[this] = balances[this].add(amount);                                                         
      balances[msg.sender] = balances[msg.sender].sub(amount);                                             
      revenue = amount.mul(sellPrice);                                                                     
      msg.sender.transfer(revenue);                                                                        
      Transfer(msg.sender, this, amount);                                                                  
      return revenue;                                                                                      
  }

   
  function getTokens(uint256 amount) onlyOwner external returns (bool success) {
      require(balances[this] >= amount);
      balances[msg.sender] = balances[msg.sender].add(amount);
      balances[this] = balances[this].sub(amount);
      Transfer(this, msg.sender, amount);
      return true;
  }

   
  function sendEther() payable onlyOwner external returns (bool success) {
      return true;
  }

   
  function getEther(uint256 amount) onlyOwner external returns (bool success) {
      require(amount > 0);
      msg.sender.transfer(amount);
      return true;
  }
}