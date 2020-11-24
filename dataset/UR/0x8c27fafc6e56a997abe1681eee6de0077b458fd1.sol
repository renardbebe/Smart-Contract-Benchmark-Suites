 

pragma solidity ^0.4.13;

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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract GigaToken is StandardToken, Contactable {

  string public constant name = "Giga";
  string public constant symbol = "GIGA";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 10000000 * (10 ** uint256(decimals)); 
 
  event IncreaseSupply(uint256 increaseByAmount, uint256 oldAmount, uint256 newAmount);  
  

   
  function GigaToken() public {
    
 
    totalSupply = INITIAL_SUPPLY; 
    balances[msg.sender] = INITIAL_SUPPLY; 
  }

  function increaseSupply(uint256 _increaseByAmount) external onlyOwner {
    require(_increaseByAmount > 0);
    uint256 oldSupply = totalSupply;
    totalSupply = totalSupply.add(_increaseByAmount);
    balances[owner] = balances[owner].add(_increaseByAmount);
    IncreaseSupply(_increaseByAmount, oldSupply, totalSupply);

  }

}

contract GigaCrowdsale is  Contactable {
  using SafeMath for uint256;

   
  GigaToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;
  uint256 public tokensPurchased;


   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  
  event SetRate(uint256 oldRate, uint256 newRate);
  event SetEndTime(uint256 oldEndTime, uint256 newEndTime);

  function GigaCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet,string _contactInformation) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    
    contactInformation = _contactInformation;
    token = createTokenContract();
    token.setContactInformation(_contactInformation);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    
   
  }

   
  function createTokenContract() internal returns (GigaToken) {
    return new GigaToken();
  }


   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);
    
     
    weiRaised = weiRaised.add(weiAmount);
    tokensPurchased = tokensPurchased.add(tokens);

    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function transferTokens (address _beneficiary, uint256 _tokens) onlyOwner external {
      token.transfer(_beneficiary, _tokens);
  }

  function transferTokenContractOwnership(address _newOwner) onlyOwner external {
     token.transferOwnership(_newOwner);
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  function  setEndTime(uint256 _endTime) external onlyOwner {
    require(_endTime >= startTime);
    SetEndTime(endTime, _endTime);
    endTime = _endTime;

  }

  function setRate(uint256 _rate) external onlyOwner {
    require(_rate > 0);
    SetRate(rate, _rate);
    rate = _rate;

  }

  function increaseSupply(uint256 _increaseByAmount) external onlyOwner {
    require(_increaseByAmount > 0);
      
    token.increaseSupply(_increaseByAmount);
   
  }

  function setTokenContactInformation(string _info) external onlyOwner {
    token.setContactInformation(_info);
  }
  
}