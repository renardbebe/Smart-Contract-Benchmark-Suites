 

pragma solidity ^0.4.19;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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

 

 

pragma solidity ^0.4.12;



contract Recoverable is Ownable {

   
  function Recoverable() public {
  }

   
   
  function recoverTokens(ERC20Basic token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

   
   
   
  function tokensToBeReturned(ERC20Basic token) public returns (uint) {
    return token.balanceOf(this);
  }
}

 

 

pragma solidity ^0.4.14;




 
contract StandardTokenExt is Recoverable, StandardToken {

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }
}

 

 

pragma solidity ^0.4.8;



 
contract ReleasableToken is StandardTokenExt {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            throw;
        }
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        throw;
    }
    _;
  }

   
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        throw;
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
     
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

 

contract WhitelistableToken is ReleasableToken {
   
  struct WhitelistedInvestor {
    uint idx;
    bool whitelisted;
  }

  mapping(address => WhitelistedInvestor) whitelist;

  mapping(uint => address) indexedWhitelist;
  uint whitelistTotal;
  address public whitelistAgent;  


  modifier isWhitelisted(address _destination) {
    if(!released) {
      if(!whitelist[_destination].whitelisted) {
        revert();
      }
    }
    _;
  }

  modifier onlyWhitelistAgent(address _sender) {
    if(_sender != whitelistAgent) {
      revert();
    }

    _;
  }

  function isOnWhitelist(address _investor) public view returns (bool whitelisted) {
    return whitelist[_investor].whitelisted;
  }

  function addToWhitelist(address _investor) public onlyWhitelistAgent(msg.sender) {
    if (!whitelist[_investor].whitelisted) {  
      whitelist[_investor].whitelisted = true;
      whitelist[_investor].idx = whitelistTotal;
      indexedWhitelist[whitelistTotal] = _investor;
      whitelistTotal += 1;
    }
  }

  function removeFromWhitelist(address _investor) public onlyWhitelistAgent(msg.sender) {
    if (!whitelist[_investor].whitelisted) {
      revert();
    }
    whitelist[_investor].whitelisted = false;
    uint idx = whitelist[_investor].idx;
    indexedWhitelist[idx] = address(0);
  }

  function setWhitelistAgent(address agent) public onlyOwner {
    whitelistAgent = agent;
  }

   
  function getWhitelistTotal() public view returns (uint total) {
    return whitelistTotal;
  }

  function getWhitelistAt(uint idx) public view returns (address investor) {
    return indexedWhitelist[idx];
  }

  function transfer(address _to, uint _value) isWhitelisted(_to) public returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) isWhitelisted(_from) isWhitelisted(_to) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

 

 
 
contract SDAToken is WhitelistableToken {
   

  string public constant name = "Safe Digital Advertising";   
  string public constant symbol = "SDA";   
  uint8 public constant decimals = 8;   

  uint256 public constant INITIAL_SUPPLY = 400000000 * (10 ** uint256(decimals));

  function SDAToken() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
}