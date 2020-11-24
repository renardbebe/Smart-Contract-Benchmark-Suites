 

pragma solidity ^0.4.18;

 
library SafeMath {

  function mul(uint a, uint b) internal constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal constant returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

}

 
contract Roles {
  
   
  address public owner;

   
  address public globalOperator;

   
  address public crowdsale;
  
  function Roles() public {
    owner = msg.sender;
     
    globalOperator = address(0); 
     
    crowdsale = address(0); 
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyGlobalOperator() {
    require(msg.sender == globalOperator);
    _;
  }

   
  modifier anyRole() {
    require(msg.sender == owner || msg.sender == globalOperator || msg.sender == crowdsale);
    _;
  }

   
   
  function changeOwner(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnerChanged(owner, newOwner);
    owner = newOwner;
  }

   
   
  function changeGlobalOperator(address newGlobalOperator) onlyOwner public {
    require(newGlobalOperator != address(0));
    GlobalOperatorChanged(globalOperator, newGlobalOperator);
    globalOperator = newGlobalOperator;
  }

   
   
  function changeCrowdsale(address newCrowdsale) onlyOwner public {
    require(newCrowdsale != address(0));
    CrowdsaleChanged(crowdsale, newCrowdsale);
    crowdsale = newCrowdsale;
  }

   
  event OwnerChanged(address indexed _previousOwner, address indexed _newOwner);
  event GlobalOperatorChanged(address indexed _previousGlobalOperator, address indexed _newGlobalOperator);
  event CrowdsaleChanged(address indexed _previousCrowdsale, address indexed _newCrowdsale);

}

 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract ExtendedToken is ERC20, Roles {
  using SafeMath for uint;

   
  uint256 public constant MINT_CAP = 6 * 10**27;

   
  uint256 public constant MINIMUM_LOCK_AMOUNT = 100000 * 10**18;

   
  struct Locked {
       
      uint256 lockedAmount; 
       
      uint256 lastUpdated; 
       
      uint256 lastClaimed; 
  }
  
   
  bool public transferPaused = false;

   
  mapping (address => uint) public balances;
   
  mapping (address => Locked) public locked;
   
  mapping (address => mapping (address => uint)) internal allowed;

   
  function pause() public onlyOwner {
      transferPaused = true;
      Pause();
  }

   
  function unpause() public onlyOwner {
      transferPaused = false;
      Unpause();
  }

   
   
   
   
  function mint(address _to, uint _amount) public anyRole returns (bool) {
      _mint(_to, _amount);
      Mint(_to, _amount);
      return true;
  }
  
   
  function _mint(address _to, uint _amount) internal returns (bool) {
      require(_to != address(0));
	    require(totalSupply.add(_amount) <= MINT_CAP);
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      return true;
  }

   
   
   
  function burn(uint _amount) public onlyGlobalOperator returns (bool) {
	    require(balances[msg.sender] >= _amount);
	    uint256 newBalance = balances[msg.sender].sub(_amount);      
      balances[msg.sender] = newBalance;
      totalSupply = totalSupply.sub(_amount);
      Burn(msg.sender, _amount);
      return true;
  }

   
   
   
  function lockedAmount(address _from) public constant returns (uint256) {
      return locked[_from].lockedAmount;
  }

   
   
   
   
  function lock(uint _amount) public returns (bool) {
      require(_amount >= MINIMUM_LOCK_AMOUNT);
      uint newLockedAmount = locked[msg.sender].lockedAmount.add(_amount);
      require(balances[msg.sender] >= newLockedAmount);
      _checkLock(msg.sender);
      locked[msg.sender].lockedAmount = newLockedAmount;
      locked[msg.sender].lastUpdated = now;
      Lock(msg.sender, _amount);
      return true;
  }

   
  function _checkLock(address _from) internal returns (bool) {
    if (locked[_from].lockedAmount >= MINIMUM_LOCK_AMOUNT) {
      return _mintBonus(_from, locked[_from].lockedAmount);
    }
    return false;
  }

   
  function _mintBonus(address _from, uint256 _amount) internal returns (bool) {
      uint referentTime = max(locked[_from].lastUpdated, locked[_from].lastClaimed);
      uint timeDifference = now.sub(referentTime);
      uint amountTemp = (_amount.mul(timeDifference)).div(30 days); 
      uint mintableAmount = amountTemp.div(100);

      locked[_from].lastClaimed = now;
      _mint(_from, mintableAmount);
      LockClaimed(_from, mintableAmount);
      return true;
  }

   
   
  function claimBonus() public returns (bool) {
      require(msg.sender != address(0));
      return _checkLock(msg.sender);
  }

   
   
   
  function unlock(uint _amount) public returns (bool) {
      require(msg.sender != address(0));
      require(locked[msg.sender].lockedAmount >= _amount);
      uint newLockedAmount = locked[msg.sender].lockedAmount.sub(_amount);
      if (newLockedAmount < MINIMUM_LOCK_AMOUNT) {
        Unlock(msg.sender, locked[msg.sender].lockedAmount);
        _checkLock(msg.sender);
        locked[msg.sender].lockedAmount = 0;
      } else {
        locked[msg.sender].lockedAmount = newLockedAmount;
        Unlock(msg.sender, _amount);
        _mintBonus(msg.sender, _amount);
      }
      return true;
  }

   
  function _transfer(address _from, address _to, uint _value) internal {
    require(!transferPaused);
    require(_to != address(0));
    require(balances[_from] >= _value.add(locked[_from].lockedAmount));
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
  
   
   
   
   
  function transfer(address _to, uint _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }
  
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

   
   
   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
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

   
   
   
   
  function max(uint a, uint b) pure internal returns(uint) {
    return (a > b) ? a : b;
  }

   
  function () public payable {
    revert();
  }

   
   
  function claimTokens(address _token) public onlyOwner {
    if (_token == address(0)) {
         owner.transfer(this.balance);
         return;
    }

    ERC20 token = ERC20(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

   
  event Mint(address _to, uint _amount);
  event Burn(address _from, uint _amount);
  event Lock(address _from, uint _amount);
  event LockClaimed(address _from, uint _amount);
  event Unlock(address _from, uint _amount);
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event Pause();
  event Unpause();

}

 
contract WizzleInfinityToken is ExtendedToken {
    string public constant name = "Wizzle Infinity Token";
    string public constant symbol = "WZI";
    uint8 public constant decimals = 18;
    string public constant version = "v1";

    function WizzleInfinityToken() public { 
      totalSupply = 0;
    }

}