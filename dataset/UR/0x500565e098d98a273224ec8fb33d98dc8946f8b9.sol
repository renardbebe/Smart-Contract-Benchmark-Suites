 

pragma solidity ^0.4.24;

 

 
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

 

 

contract GameCellCoin is PausableToken
{
  using SafeMath for uint256;
  
   
  string public name="Game Cell Coin";
  string public symbol="GCC";
  string public standard="ERC20";
  
  uint8 public constant decimals = 18;  
  
  uint256 public constant INITIAL_SUPPLY = 25 *(10**8)*(10 ** uint256(decimals));
  
  event ReleaseTarget(address target);
    
  mapping(address => TimeLock[]) public allocations;
  
  struct TimeLock
  {
      uint time;
      uint256 balance;
  }

   
  constructor() public 
  {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) 
  {
      require(canSubAllocation(msg.sender, _value));
    
      subAllocation(msg.sender);
    
      return super.transfer(_to, _value); 
  }
  
  function canSubAllocation(address sender, uint256 sub_value) private constant returns (bool)
  {
      if (sub_value==0)
      {
          return false;
      }
      
      if (balances[sender] < sub_value)
      {
          return false;
      }
      
      uint256 alllock_sum = 0;
      for (uint j=0; j<allocations[sender].length; j++)
      {
          if (allocations[sender][j].time >= block.timestamp)
          {
              alllock_sum = alllock_sum.add(allocations[sender][j].balance);
          }
      }
      
      uint256 can_unlock = balances[sender].sub(alllock_sum);
      
      return can_unlock >= sub_value;
  }
  
  function subAllocation(address sender) private
  {
      for (uint j=0; j<allocations[sender].length; j++)
      {
          if (allocations[sender][j].time < block.timestamp)
          {
              allocations[sender][j].balance = 0;
          }
      }
  }
  
  function setAllocation(address _address, uint256 total_value, uint[] times, uint256[] balanceRequires) public onlyOwner returns (bool)
  {
      require(times.length == balanceRequires.length);
      uint256 sum = 0;
      for (uint x=0; x<balanceRequires.length; x++)
      {
          require(balanceRequires[x]>0);
          sum = sum.add(balanceRequires[x]);
      }
      
      require(total_value >= sum);
      
      require(balances[msg.sender]>=sum);

      for (uint i=0; i<times.length; i++)
      {
          bool find = false;
          
          for (uint j=0; j<allocations[_address].length; j++)
          {
              if (allocations[_address][j].time == times[i])
              {
                  allocations[_address][j].balance = allocations[_address][j].balance.add(balanceRequires[i]);
                  find = true;
                  break;
              }
          }
          
          if (!find)
          {
              allocations[_address].push(TimeLock(times[i], balanceRequires[i]));
          }
      }
      
      return super.transfer(_address, total_value); 
  }
  
  function releaseAllocation(address target)  public onlyOwner 
  {
      require(balances[target] > 0);
      
      for (uint j=0; j<allocations[target].length; j++)
      {
          allocations[target][j].balance = 0;
      }
      
      emit ReleaseTarget(target);
  }
}