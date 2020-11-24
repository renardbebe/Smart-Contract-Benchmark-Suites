 

pragma solidity ^0.4.21;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public  returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 bal) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Token is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
     
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
     
     
     
     
    assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract LavevelToken is Token {
  string public constant NAME = "Googlier Token";
  string public constant SYMBOL = "GOOGLIER";
  uint256 public constant DECIMALS = 18;

  uint256 public constant INITIAL_SUPPLY = 500000000 * 10**18;

   
  function LavevelToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

 

 
contract LavevelICO is Ownable {
  using SafeMath for uint256;
  Token token;

  uint256 public constant RATE = 3000;  
  uint256 public constant CAP = 5350;  
  uint256 public constant START = 1519862400;  
  uint256 public constant DAYS = 45;  
  
  uint256 public constant initialTokens = 6000000 * 10**18;  
  bool public initialized = false;
  uint256 public raisedAmount = 0;
  
   
  event BoughtTokens(address indexed to, uint256 value);

   
  modifier whenSaleIsActive() {
     
    assert(isActive());
    _;
  }
  
   
  function LavevelICO(address _tokenAddr) public {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr);
  }
  
   
  function initialize() public onlyOwner {
      require(initialized == true);  
      require(tokensAvailable() == initialTokens);  
      initialized = true;
  }

   
  function isActive() public view returns (bool) {
    return (
        initialized == true &&
        now >= START &&  
        now <= START.add(DAYS * 1 days) &&  
        goalReached() == false  
    );
  }

   
  function goalReached() public view returns (bool) {
    return (raisedAmount >= CAP * 1 ether);
  }

   
  function () public payable {
    buyTokens();
  }

   
  function buyTokens() public payable whenSaleIsActive {
    uint256 weiAmount = msg.value;  
    uint256 tokens = weiAmount.mul(RATE);
    
    emit BoughtTokens(msg.sender, tokens);  
    raisedAmount = raisedAmount.add(msg.value);  
    token.transfer(msg.sender, tokens);  
    
    owner.transfer(msg.value); 
  }

   
  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }

   
  function destroy() onlyOwner public {
     
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);
     
    selfdestruct(owner);
  }
}