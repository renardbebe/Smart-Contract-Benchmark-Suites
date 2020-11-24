 

pragma solidity ^0.4.18;
 
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure  returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
 
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
 
     
     
 
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
 
   
  function approve(address _spender, uint256 _value) public returns (bool) {
 
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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
 
 
 
contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();
 
  bool public mintingFinished = false;
 
  address public saleAgent;
  
   modifier canMint() {
   require(!mintingFinished);
    _;
  }
  
   modifier onlySaleAgent() {
   require(msg.sender == saleAgent);
    _;
  }

  function setSaleAgent(address newSaleAgent) public onlyOwner {
   saleAgent = newSaleAgent;
  }

   
  function mint(address _to, uint256 _amount) public onlySaleAgent canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
 
   
  function finishMinting() public onlySaleAgent returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}
 
contract AgroTechFarmToken is MintableToken {
    
    string public constant name = "Agro Tech Farm";
    
    string public constant symbol = "ATF";
    
    uint32 public constant decimals = 18;
}

contract preSale2 is Ownable {    
    using SafeMath for uint;        
    AgroTechFarmToken public token;
    bool public preSale2Finished = false;          
    address public multisig;  
    uint public rate;
    uint public tokenCap;
    uint public start;
    uint public period;
    uint public hardcap;
    address public restricted;
	uint public restrictedPercent;

    function preSale2() public {        
	    token = AgroTechFarmToken(0xa55ffAeA5c8cf32B550F663bf17d4F7b739534ff); 
		multisig = 0x227917ac3C1F192874d43031cF4D40fd40Ae6127;
		rate = 83333333333000000000; 
		tokenCap =  25000000000000000000000; 
		start = 1518739200; 
		period = 8; 
	    hardcap = 500000000000000000000;
	    restricted = 0xbcCd749ecCCee5B4898d0E38D2a536fa84Ea9Ef6;   
	    restrictedPercent = 35;
          
    }
 
    modifier saleIsOn() {
    	require(now > start && now < start + period * 1 days);
    	_;
    }
	
    modifier isUnderHardCap() {
      require(this.balance <= hardcap);
        _;
    } 


  function balancePreSale2() public constant returns (uint) {
     return this.balance;
    }


  function finishPreSale2() public onlyOwner returns (bool)  {
        if(now > start + period * 1 days || this.balance >= hardcap) {                     
         multisig.transfer(this.balance);
         preSale2Finished = true;
         return true;
         } else return false;     
      }
 
   function createTokens() public isUnderHardCap saleIsOn payable {
        uint tokens = rate.mul(msg.value).div(1 ether);      
        uint bonusTokens = 0;        
        uint totalSupply = token.totalSupply();
       
        if (totalSupply <= tokenCap) {
            bonusTokens = tokens.div(2); 
        } else bonusTokens = tokens.mul(40).div(100); 

        
        tokens += bonusTokens;     
        token.mint(msg.sender, tokens);
       
	    uint restrictedTokens = tokens.mul(restrictedPercent).div(100); 
        token.mint(restricted, restrictedTokens);        
        
    }
 

    function() external payable {
        createTokens();
    } 
}