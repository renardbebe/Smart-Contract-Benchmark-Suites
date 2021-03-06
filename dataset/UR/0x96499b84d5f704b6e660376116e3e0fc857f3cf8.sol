 

pragma solidity ^0.4.11;
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
      
     
    require (now >= 1512835200);  
    
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
    
     
    require (now >= 1512835200);  
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

 
contract UpgradeAgent {
   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }
  function upgradeFrom(address _from, uint256 _value) public;
}

contract PSIToken is StandardToken {
    address public owner;
    string public constant name = "Protostarr";  
    string public constant symbol = "PSR";  
    uint256 public constant decimals = 4;
    
     
    address public constant founders_addr = 0xEa16ebd8Cdf5A51fa0a80bFA5665146b2AB82210;
    
    UpgradeAgent public upgradeAgent;
    uint256 public totalUpgraded;
    
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);
    
    event UpgradeAgentSet(address agent);
    function setUpgradeAgent(address agent) external {
        if (agent == 0x0) revert();
         
        if (msg.sender != owner) revert();
        upgradeAgent = UpgradeAgent(agent);
        
         
        if(!upgradeAgent.isUpgradeAgent()) revert();
        UpgradeAgentSet(upgradeAgent);
    }
    function upgrade(uint256 value) public {
        
        if(address(upgradeAgent) == 0x00) revert();
         
        if (value <= 0) revert();
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        
         
        totalSupply = totalSupply.sub(value);
        totalUpgraded = totalUpgraded.add(value);
        
         
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

     
    function PSIToken() {
         
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
     
    function () payable {
        createTokens(msg.sender);
    }
     
    function createTokens(address recipient) payable {
        if(msg.value<=uint256(1 ether).div(600)) {
            revert();
        }
    
        uint multiplier = 10 ** decimals;
    
         
        uint tokens = ((msg.value.mul(getPrice())).mul(multiplier)).div(1 ether);
        totalSupply = totalSupply.add(tokens);
        balances[recipient] = balances[recipient].add(tokens);      
        
         
         
        
         
        uint ftokens = tokens.div(10);
        totalSupply = totalSupply.add(ftokens);
        balances[founders_addr] = balances[founders_addr].add(ftokens);
    
         
        if(!founders_addr.send(msg.value)) {
            revert();
        }
    
    }
  
     
     
     
     
     
     
     
     
     
    function getPrice() constant returns (uint result) {
        if (now < 1502640000) {  
            revert();  
        } else {
            if (now < 1502645400) {  
                return 170;
            } else {
                if (now < 1503244800) {  
                    return 150;
                } else {
                    if (now < 1503849600) {  
                        return 130;
                    } else {
                        if (now < 1504454400) {  
                            return 110;
                        } else {
                            if (now < 1505059200) {  
                                return 100;
                            } else {
                                revert();  
                            }
                        }
                    }
                }
            }
        }
    }
  
}