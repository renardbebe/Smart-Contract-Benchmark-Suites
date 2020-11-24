 

pragma solidity ^0.4.18;

 

 
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

 

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

 
contract FKX is CappedToken(FKX.TOKEN_SUPPLY) {

  using SafeMath for uint256;

  string public constant name = "Knoxstertoken";
  string public constant symbol = "FKX";
  uint8 public constant decimals = 18;
  string public constant version = "1.0";
  uint256 public constant TOKEN_SUPPLY  = 150000000 * (10 ** uint256(decimals));  

}

 

 
contract FKXTokenTimeLock is Ownable {

   
  address[] public lockIndexes;

   
  struct TokenTimeLockVault {
       
      uint256 amount;

       
      uint256 releaseTime;

       
      uint256 arrayIndex;
  }

   
  FKX public token;

   
  mapping(address => TokenTimeLockVault) public tokenLocks;

  function FKXTokenTimeLock(FKX _token) public {
    token = _token;
  }

  function lockTokens(address _beneficiary, uint256 _releaseTime, uint256 _tokens) external onlyOwner  {
    require(_releaseTime > now);
    require(_tokens > 0);

    TokenTimeLockVault storage lock = tokenLocks[_beneficiary];
    lock.amount = _tokens;
    lock.releaseTime = _releaseTime;
    lock.arrayIndex = lockIndexes.length;
    lockIndexes.push(_beneficiary);

    LockEvent(_beneficiary, _tokens, _releaseTime);
  }

  function exists(address _beneficiary) external onlyOwner view returns (bool) {
    TokenTimeLockVault memory lock = tokenLocks[_beneficiary];
    return lock.amount > 0;
  }

   
  function release() public {
    TokenTimeLockVault memory lock = tokenLocks[msg.sender];

    require(now >= lock.releaseTime);

    require(lock.amount > 0);

    delete tokenLocks[msg.sender];

    lockIndexes[lock.arrayIndex] = 0x0;

    UnlockEvent(msg.sender);

    assert(token.transfer(msg.sender, lock.amount));   
  }

   
  function releaseAll(uint from, uint to) external onlyOwner returns (bool) {
    require(from >= 0);
    require(to <= lockIndexes.length);
    for (uint i = from; i < to; i++) {
      address beneficiary = lockIndexes[i];
      if (beneficiary == 0x0) {  
        continue;
      }
      
      TokenTimeLockVault memory lock = tokenLocks[beneficiary];
      
      if (!(now >= lock.releaseTime && lock.amount > 0)) {  
        continue;
      }

      delete tokenLocks[beneficiary];

      lockIndexes[lock.arrayIndex] = 0x0;
      
      UnlockEvent(beneficiary);

      assert(token.transfer(beneficiary, lock.amount));
    }
    return true;
  }

   
  event LockEvent(address indexed beneficiary, uint256 amount, uint256 releaseTime);

   
  event UnlockEvent(address indexed beneficiary);
  
}

 

 
contract FKXSale is Ownable {

  FKX public token;

  FKXTokenTimeLock public tokenLock;

  function FKXSale() public {

    token =  new FKX();

    tokenLock = new FKXTokenTimeLock(token);

  }

   
  function finalize() public onlyOwner {
     
    token.finishMinting();
  }

   
  function mintBaseLockedTokens(address beneficiary, uint256 baseTokens, uint256 bonusTokens, uint256 releaseTime) public onlyOwner {
    require(beneficiary != 0x0);
    require(baseTokens > 0);
    require(bonusTokens > 0);
    require(releaseTime > now);
    require(!tokenLock.exists(beneficiary));
    
     
    token.mint(beneficiary, baseTokens);

     
    token.mint(tokenLock, bonusTokens);

     
    tokenLock.lockTokens(beneficiary, releaseTime, bonusTokens);
  }

   
  function mintLockedTokens(address beneficiary, uint256 tokens, uint256 releaseTime) public onlyOwner {
    require(beneficiary != 0x0);
    require(tokens > 0);
    require(releaseTime > now);
    require(!tokenLock.exists(beneficiary));

     
    token.mint(tokenLock, tokens);

     
    tokenLock.lockTokens(beneficiary, releaseTime, tokens);
  }

   
  function mintTokens(address beneficiary, uint256 tokens) public onlyOwner {
    require(beneficiary != 0x0);
    require(tokens > 0);
    
     
    token.mint(beneficiary, tokens);
  }

   
  function releaseAll(uint from, uint to) public onlyOwner returns (bool) {
    tokenLock.releaseAll(from, to);

    return true;
  }


}