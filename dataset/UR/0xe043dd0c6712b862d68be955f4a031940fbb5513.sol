 

pragma solidity 0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
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

 

 
interface IRegistry {
  function owner()
    external
    returns(address);

  function updateContractAddress(
    string _name,
    address _address
  )
    external
    returns (address);

  function getContractAddress(
    string _name
  )
    external
    view
    returns (address);
}

 

 
interface IBrickblockToken {
  function transfer(
    address _to,
    uint256 _value
  )
    external
    returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (bool);

  function balanceOf(
    address _address
  )
    external
    view
    returns (uint256);

  function approve(
    address _spender,
    uint256 _value
  )
    external
    returns (bool);
}

 

 

 

contract AccessToken is PausableToken {
  uint8 public constant version = 1;

   
  IRegistry internal registry;
  string public constant name = "AccessToken";
  string public constant symbol = "ACT";
  uint8 public constant decimals = 18;

   
  uint256 internal totalMintedActPerLockedBbkToken;

   
  uint256 public totalLockedBBK;

   
  mapping(address => uint256) internal lockedBbkPerUser;

   
  mapping(address => uint256) internal mintedActPerUser;

   
  mapping(address => uint256) internal mintedActFromCurrentLockPeriodPerUser;

   
  mapping(address => uint256) internal mintedActFromPastLockPeriodsPerUser;

   
  mapping(address => uint256) internal balances;

   
  mapping(address => uint256) public receivedAct;

   
  mapping(address => uint256) public spentAct;


  event Mint(uint256 amount);
  event Burn(address indexed burner, uint256 value);
  event BbkLocked(
    address indexed locker,
    uint256 lockedAmount,
    uint256 totalLockedAmount
  );
  event BbkUnlocked(
    address indexed locker,
    uint256 unlockedAmount,
    uint256 totalLockedAmount
  );

  modifier onlyContract(string _contractName)
  {
    require(
      msg.sender == registry.getContractAddress(_contractName)
    );
    _;
  }

  constructor (
    address _registryAddress
  )
    public
  {
    require(_registryAddress != address(0));
    registry = IRegistry(_registryAddress);
  }

   
   
  function lockedBbkOf(
    address _address
  )
    external
    view
    returns (uint256)
  {
    return lockedBbkPerUser[_address];
  }

   
  function lockBBK(
    uint256 _amount
  )
    external
    returns (bool)
  {
    require(_amount > 0);
    IBrickblockToken _bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );

    require(settleCurrentLockPeriod(msg.sender));
    lockedBbkPerUser[msg.sender] = lockedBbkPerUser[msg.sender].add(_amount);
    totalLockedBBK = totalLockedBBK.add(_amount);
    require(_bbk.transferFrom(msg.sender, this, _amount));
    emit BbkLocked(msg.sender, _amount, totalLockedBBK);
    return true;
  }

   
  function unlockBBK(
    uint256 _amount
  )
    external
    returns (bool)
  {
    require(_amount > 0);
    IBrickblockToken _bbk = IBrickblockToken(
      registry.getContractAddress("BrickblockToken")
    );
    require(_amount <= lockedBbkPerUser[msg.sender]);
    require(settleCurrentLockPeriod(msg.sender));
    lockedBbkPerUser[msg.sender] = lockedBbkPerUser[msg.sender].sub(_amount);
    totalLockedBBK = totalLockedBBK.sub(_amount);
    require(_bbk.transfer(msg.sender, _amount));
    emit BbkUnlocked(msg.sender, _amount, totalLockedBBK);
    return true;
  }

   
  function distribute(
    uint256 _amount
  )
    external
    onlyContract("FeeManager")
    returns (bool)
  {
    totalMintedActPerLockedBbkToken = totalMintedActPerLockedBbkToken
      .add(
        _amount
          .mul(1e18)
          .div(totalLockedBBK)
      );

    uint256 _delta = (_amount.mul(1e18) % totalLockedBBK).div(1e18);
    mintedActFromPastLockPeriodsPerUser[owner] = mintedActFromPastLockPeriodsPerUser[owner].add(_delta);
    totalSupply_ = totalSupply_.add(_amount);
    emit Mint(_amount);
    return true;
  }

   
  function getMintedActFromCurrentLockPeriod(
    address _address
  )
    private
    view
    returns (uint256)
  {
    return lockedBbkPerUser[_address]
      .mul(totalMintedActPerLockedBbkToken.sub(mintedActPerUser[_address]))
      .div(1e18);
  }

   
  function settleCurrentLockPeriod(
    address _address
  )
    private
    returns (bool)
  {
    mintedActFromCurrentLockPeriodPerUser[_address] = getMintedActFromCurrentLockPeriod(_address);
    mintedActFromPastLockPeriodsPerUser[_address] = mintedActFromPastLockPeriodsPerUser[_address]
      .add(mintedActFromCurrentLockPeriodPerUser[_address]);
    mintedActPerUser[_address] = totalMintedActPerLockedBbkToken;

    return true;
  }

   

   
  function balanceOf(
    address _address
  )
    public
    view
    returns (uint256)
  {
    mintedActFromCurrentLockPeriodPerUser[_address] = getMintedActFromCurrentLockPeriod(_address);

    return totalMintedActPerLockedBbkToken == 0
      ? 0
      : mintedActFromCurrentLockPeriodPerUser[_address]
      .add(mintedActFromPastLockPeriodsPerUser[_address])
      .add(receivedAct[_address])
      .sub(spentAct[_address]);
  }

   
  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));
    spentAct[msg.sender] = spentAct[msg.sender].add(_value);
    receivedAct[_to] = receivedAct[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
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
    require(_to != address(0));
    require(_value <= balanceOf(_from));
    require(_value <= allowed[_from][msg.sender]);
    spentAct[_from] = spentAct[_from].add(_value);
    receivedAct[_to] = receivedAct[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   

   
  function burn(
    address _address,
    uint256 _value
  )
    external
    onlyContract("FeeManager")
    returns (bool)
  {
    require(_value <= balanceOf(_address));
    spentAct[_address] = spentAct[_address].add(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_address, _value);
    return true;
  }
}