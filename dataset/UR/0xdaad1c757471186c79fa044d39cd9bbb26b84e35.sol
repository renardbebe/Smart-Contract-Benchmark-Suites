 

pragma solidity ^0.4.13;

 
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
  
  uint256 totalBonus = 0;
  
  uint256 maxBonus = 2000000;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  function addBonus(uint256 _bonus) onlyOwner {
      totalBonus += _bonus;
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

contract SimpleTokenCoin is MintableToken {
    
    string public constant name = "Global Business System";
    
    string public constant symbol = "GBT";
    
    uint32 public constant decimals = 18;
    
}

contract GlobalBusinessSystem is Ownable {
    
    using SafeMath for uint;

    SimpleTokenCoin public token = new SimpleTokenCoin();
    
    uint start;
    uint period;
    uint period1;
    uint period2;
    uint period3;
    address multisig;
    uint hardcap;
    uint rate;
    uint restrictedPercent;
    uint minValue;
    uint maxValue;
    address restricted;

    function GlobalBusinessSystem(){
        multisig = 0x1a74Fa96a1BaC3C2AF3F31058F02b0471BFe71f4;
	    hardcap = 1000;
	    rate = 10000000000000000000000;
	    start = 1503448000;
	    period = 30;
	    period1 = 7;
	     
	    maxValue = 200;
    }
    
    modifier saleIsOn(){
        require(now < start + period * 1 days);
        _;
    }
    
    modifier isUnderHardCap() {
        require(multisig.balance <= hardcap);
        _;
    }
    
    modifier isMinMax() {
        require(msg.value*100>=1 && msg.value<=maxValue);
        _;
    }
    
    function createTokens() isUnderHardCap saleIsOn payable {
        multisig.transfer(msg.value);
        uint tokens = rate.mul(msg.value).div(1 ether);
        uint bonusTokens = 0;
        if(now < start + (period1 * 1 days)) {
          bonusTokens = tokens.div(5);  
          token.addBonus(bonusTokens);
        }
        tokens += bonusTokens;
        token.mint(msg.sender, tokens);
    }
    
    function finishMinting() public onlyOwner {
        token.finishMinting();
    }

    function() external payable {
        createTokens();
    }
}