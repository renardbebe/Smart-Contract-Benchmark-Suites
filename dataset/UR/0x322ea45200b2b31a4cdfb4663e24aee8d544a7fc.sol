 

pragma solidity ^0.4.23;
 
 
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
    require(newOwner != address(0));      
    owner = newOwner;
  }
 
}
 
 
 
contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();
 
  bool public mintingFinished = false;
 
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
 
   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
 
   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}
 
contract RWTSToken is MintableToken {
    
    string public constant name = "RWTStart";
    
    string public constant symbol = "RWTS";
    
    uint32 public constant decimals = 18;
}

contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address public multisig;
 
    uint public restrictedPercent;
 
    address public restricted;
 
    RWTSToken public token = new RWTSToken();
 
    uint public startdate;
    
    uint public enddate;
    
    uint public rate;
 
    uint public hardcap;
    
    uint public softcap;
    
    mapping(address => uint) public balances;
 
    function Crowdsale() {
      multisig = 0xFf9ce13Da1064bb0469f2046c9824BF521e4aB79;
      restricted = 0x24abb04877ed5586dA6fe3D8F76E61Fd5EdBb1eA;
      startdate = 1530489599;
      enddate = 1533945599;
      rate = 330000000000000;
      softcap = 360000000000000000000;
      hardcap = 3100000000000000000000;
      restrictedPercent = 5;
    }
 
    modifier saleIsOn() {
      require(now > startdate && now < enddate);
      _;
    }
	
    modifier isUnderHardCap() {
      require(this.balance < hardcap);
      _;
    }
 
    function refund() external {  
      require(this.balance < softcap && now > enddate);
      uint value = balances[msg.sender]; 
      balances[msg.sender] = 0; 
      msg.sender.transfer(value); 
    }
 
    function finishMinting() public onlyOwner {
      if(this.balance >= softcap) {
        multisig.transfer(this.balance);
        uint issuedToken = token.totalSupply();
        uint restrictedTokens = issuedToken.mul(restrictedPercent).div(100);
        token.mint(restricted, restrictedTokens);
        token.finishMinting();
      }
    }
 
   function createTokens() isUnderHardCap saleIsOn payable {
      uint tokens = msg.value.div(rate).mul(1 ether);
      uint bonusTokens = 0;
     if(now < 1531439999) {
        bonusTokens = tokens.mul(35).div(100);
     }
      tokens += bonusTokens;
      token.mint(msg.sender, tokens);
      balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
 
    function() external payable {
        require(msg.value >= 33000000000000000);
        createTokens();
    }
    
}