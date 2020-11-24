 

pragma solidity ^0.4.21;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
library SafeMath {

   
  function mul(uint a, uint b) internal pure returns (uint c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint a, uint b) internal pure returns (uint) {
     
     
     
    return a / b;
  }

   
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  uint totalSupply_;

   
  function totalSupply() public view returns (uint) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint) {
    return balances[_owner];
  }

}

 
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint)) internal allowed;


   
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract RobotarTestToken is MintableToken {
    
   
   
  
    string public constant name = "Robotar token";
    
    string public constant symbol = "TTAR";
    
    uint32 public constant decimals = 18;
    
     
    
    bool public frozen = true;
    
    
  address public ico;
  modifier icoOnly { require(msg.sender == ico); _; }
  
  
   
   
  
  function RobotarTestToken(address _ico) public {
    ico = _ico;
  }
  
    function defrost() external icoOnly {
    frozen = false;
  }
    
      
   

  function transfer(address _to, uint _value)  public returns (bool) {
    require(!frozen);
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    require(!frozen);
    return super.transferFrom(_from, _to, _value);
  }


  function approve(address _spender, uint _value) public returns (bool) {
    require(!frozen);
    return super.approve(_spender, _value);
  }
    
  
  
  function supplyBezNolei() public view returns(uint) {
  return totalSupply().div(1 ether);
  }
    
}


contract TestRobotarCrowdsale is Ownable {
    
    using SafeMath for uint;
    
    address multisig;

   RobotarTestToken public token = new RobotarTestToken(this);

 

    
  uint rate = 1000;
       
	uint PresaleStart = 0;
	uint CrowdsaleStart = 0;
	uint PresalePeriod = 1 days;
	uint CrowdsalePeriod = 1 days;
	uint public threshold = 1000000000000000;	
	
	uint bountyPercent = 10;
	uint foundationPercent = 50;
	uint teamPercent = 40;
	
	address bounty;
	address foundation;
	address team;
	
  
 
    function TestRobotarCrowdsale() public {
        
	multisig = owner;	
			
	      }
	      	      
	      function setPresaleStart(uint _presaleStart) onlyOwner public returns (bool) {
	      PresaleStart = _presaleStart;
	  
	      return true;
	      }
	      
	       function setCrowdsaleStart(uint _crowdsaleStart)  onlyOwner public returns (bool) {
	       CrowdsaleStart = _crowdsaleStart;
	  
	       return true;
	       }
      
    
    

   function createTokens() public payable  {
       uint tokens = 0;
       uint bonusTokens = 0;
       
         if (now > PresaleStart && now < PresaleStart + PresalePeriod) {
       tokens = rate.mul(msg.value);
        bonusTokens = tokens.div(4);
        } 
        else if (now > CrowdsaleStart && now <  CrowdsaleStart + CrowdsalePeriod){
        tokens = rate.mul(msg.value);
        
        if(now < CrowdsaleStart + CrowdsalePeriod/4) {bonusTokens = tokens.mul(15).div(100);}
        else if(now >= CrowdsaleStart + CrowdsalePeriod/4 && now < CrowdsaleStart + CrowdsalePeriod/2) {bonusTokens = tokens.div(10);} 
        else if(now >= CrowdsaleStart + CrowdsalePeriod/2 && now < CrowdsaleStart + CrowdsalePeriod*3/4) {bonusTokens = tokens.div(20);}
        
        }      
                 
        tokens += bonusTokens;
       if (tokens>0) {token.mint(msg.sender, tokens);}
    }        
       

   function() external payable {
   if (msg.value >= threshold) createTokens();   
   
        }
   
       
    
   
    
    function finishICO(address _team, address _foundation, address _bounty) external onlyOwner {
	uint issuedTokenSupply = token.totalSupply();
	uint bountyTokens = issuedTokenSupply.mul(bountyPercent).div(100);
	uint foundationTokens = issuedTokenSupply.mul(foundationPercent).div(100);
	uint teamTokens = issuedTokenSupply.mul(teamPercent).div(100);
	bounty = _bounty;
	foundation = _foundation;
	team = _team;
	
	token.mint(bounty, bountyTokens);
	token.mint(foundation, foundationTokens);
	token.mint(team, teamTokens);
	
        token.finishMinting();
      
            }

function defrost() external onlyOwner {
token.defrost();
}
  
  function withdrawEther(uint _value) external onlyOwner {
    multisig.transfer(_value);
  }
  
  
}