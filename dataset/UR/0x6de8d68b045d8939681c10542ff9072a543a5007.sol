 

pragma solidity ^0.4.14;

 
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
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
   
  mapping(address => uint256) usedTokens;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if(1 <= usedTokens[msg.sender]) { 
        usedTokens[msg.sender] = usedTokens[msg.sender].sub(_value);
        usedTokens[_to] = usedTokens[_to].add(_value);
    }
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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
    usedTokens[_from] = usedTokens[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    usedTokens[_to] = usedTokens[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


contract XmasCoin is StandardToken {
  
  using SafeMath for uint;

  string public constant name = "XmasCoin";
  string public constant symbol = "XMAS";
  uint public constant decimals = 0;
  uint public constant totalSupply = 100;

  address public owner = msg.sender;
   
  uint public giftPool;
   
  uint public timeToOpenPresents;

  event GiftPoolContribution(address giver, uint amountContributed);
  event GiftClaimed(address claimant, uint amountClaimed, uint tokenAmountUsed);

  modifier onlyOwner {
      require(msg.sender == owner);
      _;
  }

  function XmasCoin() {
     
    balances[owner] = balances[owner].add(totalSupply);

     
    timeToOpenPresents = 1514160000;
  } 

  function claimXmasGift(address claimant)
    public
    returns (bool)
  {
    require(now > timeToOpenPresents);
    require(1 <= validTokenBalance(claimant));
    
    uint amount = giftBalance(claimant);
    uint tokenBalance = validTokenBalance(claimant);
    usedTokens[claimant] += tokenBalance;
    
    claimant.transfer(amount);
    GiftClaimed(claimant, amount, tokenBalance);
    
    return true;
  }

   
  function () 
    public
    payable
  {
    require(msg.value > 0);
    require(now < timeToOpenPresents);
    giftPool += msg.value;
    GiftPoolContribution(msg.sender, msg.value);
  } 
  
  function validTokenBalance (address _owner)
    public
    constant
    returns (uint256)
  {
      return balances[_owner].sub(usedTokens[_owner]);
  }
  
  function usedTokenBalance (address _owner)
    public
    constant
    returns (uint256)
  {
      return usedTokens[_owner];
  }
  
  function giftBalance(address claimant)
    public
    constant
    returns (uint)
  {
    return giftPool.div(totalSupply).mul(validTokenBalance(claimant));    
  }
  
  function selfDestruct()
    public
    onlyOwner
  {
     suicide(owner);
  }
  
}