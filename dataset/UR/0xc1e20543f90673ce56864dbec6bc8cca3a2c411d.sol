 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
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
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
     
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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








contract Token  is StandardToken, PausableToken , BurnableToken, MintableToken {
  mapping(address => bool) blacklist;
  uint256 public dayTimeStamp = 89280;

  event RefreshLockUp(address addr, uint256 date, uint256 amount);
  event AddLock(address indexed to, uint256 time, uint256 amount);


	struct LockAccount {
	  uint256 unlockDate;
		uint256 amount;
    bool div;
    uint day;
    uint256 unlockAmount;
	}
  

 struct LockState {
    uint256 latestReleaseTime;
    LockAccount[] locks; 
  }

	mapping (address => LockAccount) public lockAccounts;
  mapping (address => LockState) public multiLockAccounts;



  bool public noLocked = false;
  string public  name; 
  string public  symbol; 
  uint8 public decimals;


    constructor( uint256 _initialSupply, string _name, string _symbol, uint8 _decimals,address admin) public {
        owner = msg.sender;
        totalSupply_ = _initialSupply;
        balances[admin] = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused canTransfer(msg.sender, _value) returns (bool) {
      refreshLockUp(msg.sender);
      require(noLocked || (balanceOf(msg.sender).sub(lockAccounts[msg.sender].amount)) >= _value);
      if (_to == address(0)) {
        require(msg.sender == owner);
        totalSupply_ = totalSupply_.sub(_value);
      }

      super.transfer(_to, _value);
    }

  function addLock(address _addr, uint256 _value, uint256 _release_time) onlyOwner public {
    require(_value > 0);
    require(_release_time > now);

    LockState storage lockState = multiLockAccounts[_addr];
    if (_release_time > lockState.latestReleaseTime) {
      lockState.latestReleaseTime = _release_time;
    }
    lockState.locks.push(LockAccount(_release_time, _value,false,0,0));

    emit AddLock(_addr, _release_time, _value);
  }

  function clearLock(address _addr) onlyOwner {
    uint256 i;
    LockState storage lockState = multiLockAccounts[_addr];
    for (i=0; i<lockState.locks.length; i++) {
      lockState.locks[i].amount = 0;
      lockState.locks[i].unlockDate = 0;
    }
  }

  function getLockAmount(address _addr) view public returns (uint256 locked) {
    uint256 i;
    uint256 amt;
    uint256 time;
    uint256 lock = 0;

    LockState storage lockState = multiLockAccounts[_addr];
    if (lockState.latestReleaseTime < now) {
      return 0;
    }

    for (i=0; i<lockState.locks.length; i++) {
      amt = lockState.locks[i].amount;
      time = lockState.locks[i].unlockDate;

      if (time > now) {
        lock = lock.add(amt);
      }
    }

    return lock;
  }



  function lock(address addr) public onlyOwner returns (bool) {
    require(blacklist[addr] == false);
    blacklist[addr] = true;  
    return true;
  }

  function unlock(address addr) public onlyOwner returns (bool) {
    require(blacklist[addr] == true);
    blacklist[addr] = false; 
    return true;
  }

  function showlock(address addr) public view returns (bool) {
    return blacklist[addr];
  }

  
  function Now() public view returns (uint256){
    return now;
  }

  function () public payable {
    revert();
  }

  function unlockAllTokens() public onlyOwner {
    noLocked = true;
  }

    function relockAllTokens() public onlyOwner {
    noLocked = false;
  }

  function showTimeLockValue(address _user)
  public view returns (uint256 ,uint256, bool, uint256, uint256)
  {
    return (lockAccounts[_user].amount, lockAccounts[_user].unlockDate, lockAccounts[_user].div, lockAccounts[_user].day, lockAccounts[_user].unlockAmount);
  }



  function addTimeLockAddress(address _owner, uint256 _amount, uint256 _unlockDate, bool _div,
  uint _day, uint256 _unlockAmount)
        public
        onlyOwner
        returns(bool)
    {
        require(balanceOf(_owner) >= _amount);
        require(_unlockDate >= now);

        lockAccounts[_owner].amount = _amount;
        lockAccounts[_owner].unlockDate = _unlockDate;
        lockAccounts[_owner].div = _div;
        lockAccounts[_owner].day = _day;
        lockAccounts[_owner].unlockAmount = _unlockAmount;

        return true;
    }

  modifier canTransfer(address _sender, uint256 _value) {
    require(blacklist[_sender] == false);
    require(noLocked || lockAccounts[_sender].unlockDate < now || (balanceOf(msg.sender).sub(lockAccounts[msg.sender].amount)) >= _value);
    require(balanceOf(msg.sender).sub(getLockAmount(msg.sender)) >= _value);
    _;
  }

  function refreshLockUp(address _sender) {
    if (lockAccounts[_sender].div && lockAccounts[_sender].amount > 0) {
      uint current = now;
      if ( current >= lockAccounts[_sender].unlockDate) {
          uint date = current.sub(lockAccounts[_sender].unlockDate);
          lockAccounts[_sender].amount = lockAccounts[_sender].amount.sub(lockAccounts[_sender].unlockAmount);
          if ( date.div(lockAccounts[_sender].day.mul(dayTimeStamp)) >= 1 && lockAccounts[_sender].amount > 0 ) {
            if (lockAccounts[_sender].unlockAmount.mul(date.div(lockAccounts[_sender].day.mul(dayTimeStamp))) <= lockAccounts[_sender].amount) {
            lockAccounts[_sender].amount = lockAccounts[_sender].amount.sub(lockAccounts[_sender].unlockAmount.mul(date.div(lockAccounts[_sender].day.mul(dayTimeStamp))));
            } else {
              lockAccounts[_sender].amount = 0;
            }
          }
          if ( lockAccounts[_sender].amount > 0 ) {
            lockAccounts[_sender].unlockDate = current.add(dayTimeStamp.mul(lockAccounts[_sender].day)).sub(date % dayTimeStamp.mul(lockAccounts[_sender].day));
          } else {
            lockAccounts[_sender].div = false;
            lockAccounts[_sender].unlockDate = 0;
          }    
      }
      emit RefreshLockUp(_sender, lockAccounts[_sender].unlockDate, lockAccounts[_sender].amount);

    }
  }
  
  


  function totalBurn() public view returns(uint256) {
		return balanceOf(address(0));
	}



}