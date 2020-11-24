 

 

 

pragma solidity ^0.5.0;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
  
  function ceil(uint256 a, uint256 m) internal pure returns (uint256 ) {
        return ((a + m - 1) / m) * m;
  }
}

 
contract Ownable {
  address public owner;

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
    require(_value <= balances[msg.sender] && balances[_to] + _value >= balances[_to]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
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
    require(_value <= balances[_from] && balances[_to] + _value >= balances[_to]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
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

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

 

contract DOG is StandardBurnableToken, Ownable {

  string public constant name = "COINDOGS";  
  string public constant symbol = "DOG";  
  address payable public constant tokenOwner = 0xB30E79F1808FC364432fa4c73b7E0a5bA8c8fb02;
  uint256 public constant INITIAL_SUPPLY = 25000000;
  uint256 public price;
  uint256 public collectedTokens;
  uint256 public collectedEthers;

  using SafeMath for uint256;
  uint256 public startTime;
  uint256 public weiRaised;
  uint256 public tokensSold;
    
  bool public isFinished = false;

    modifier onlyAfter(uint256 time) {
        assert(now >= time);
        _;
    }

    modifier onlyBefore(uint256 time) {
        assert(now <= time);
        _;
    }
    
    modifier checkAmount(uint256 amount) {
        uint256 tokens = amount.div(price);
        assert(totalSupply_.sub(tokensSold.add(tokens)) >= 0);
        _;
    }
    
    modifier notNull(uint256 amount) {
        assert(amount >= price);
        _;
    }
    
        
    modifier checkFinished() {
        assert(!isFinished);
        _;
    }

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[tokenOwner] = INITIAL_SUPPLY;
    emit Transfer(0x0000000000000000000000000000000000000000, tokenOwner, INITIAL_SUPPLY);
    
    price = 0.0035 ether;    
    startTime = 1561975200;
  }
    
    function () external payable onlyAfter(startTime) checkFinished() checkAmount(msg.value) notNull(msg.value) {
        doPurchase(msg.value, msg.sender);
    }
    
    function doPurchase(uint256 amount, address sender) private {
        
        uint256 tokens = amount.div(price);
        
        balances[tokenOwner] = balances[tokenOwner].sub(tokens);
        balances[sender] = balances[sender].add(tokens);
        
        collectedTokens = collectedTokens.add(tokens);
        collectedEthers = collectedEthers.add(amount);
        
        weiRaised = weiRaised.add(amount);
        tokensSold = tokensSold.add(tokens);
        
        emit Transfer(tokenOwner, sender, tokens);
    }
    
    function withdraw() onlyOwner public returns (bool) {
        if (!tokenOwner.send(collectedEthers)) {
            return false;
        }
        collectedEthers = 0;
        return true;
    }
    
    function stop() onlyOwner public returns (bool) {
        isFinished = true;
        return true;
    }
    
    function changePrice(uint256 amount) onlyOwner public {
        price = amount;
    }
}