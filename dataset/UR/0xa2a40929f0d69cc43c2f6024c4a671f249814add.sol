 

pragma solidity 0.5.1;

 
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

contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

 
contract BasicToken is ERC20Basic, ReentrancyGuard {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  uint256 public totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public nonReentrant returns (bool) {
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

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    nonReentrant
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

   
  function approve(address _spender, uint256 _value) public nonReentrant returns (bool) {
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
    nonReentrant
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
    nonReentrant
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

contract Freeze is Ownable, ReentrancyGuard {
  
  using SafeMath for uint256;

  struct Group {
    address[] holders;
    uint until;
  }
  
	 
  uint public groups;
  
	 
  mapping (uint => Group) public lockup;
  
	 
  modifier lockupEnded (address _holder) {
    bool freezed;
    uint groupId;
    (freezed, groupId) = isFreezed(_holder);
    
    if (freezed) {
      if (lockup[groupId-1].until < block.timestamp)
        _;
      else 
        revert("Your holdings are freezed, wait until transfers become allowed");
    }
    else 
      _;
  }
  
	 
  function isFreezed (address _holder) public view returns(bool, uint) {
    bool freezed = false;
    uint i = 0;
    while (i < groups) {
      uint index  = indexOf(_holder, lockup[i].holders);

      if (index == 0) {
        if (checkZeroIndex(_holder, i)) {
          freezed = true;
          i++;
          continue;
        }  
        else {
          i++;
          continue;
        }
      }
      
      if (index != 0) {
        freezed = true;
        i++;
        continue;
      }
      i++;
    }
    if (!freezed) i = 0;
    
    return (freezed, i);
  }
  
	 
  function indexOf (address element, address[] memory at) internal pure returns (uint) {
    for (uint i=0; i < at.length; i++) {
      if (at[i] == element) return i;
    }
    return 0;
  }
  
	 
  function checkZeroIndex (address _holder, uint lockGroup) internal view returns (bool) {
    if (lockup[lockGroup].holders[0] == _holder)
      return true;
        
    else 
      return false;
  }
  
	 
  function setGroup (address[] memory _holders, uint _until) public onlyOwner returns (bool) {
    lockup[groups].holders = _holders;
    lockup[groups].until   = _until;
    
    groups++;
    return true;
  }
}

 
contract PausableToken is StandardToken, Freeze {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    lockupEnded(msg.sender)
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
    lockupEnded(msg.sender)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    lockupEnded(msg.sender)
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    lockupEnded(msg.sender)
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    lockupEnded(msg.sender)
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract SingleToken is PausableToken {

  string  public constant name      = "Gofind XR"; 

  string  public constant symbol    = "XR";

  uint32  public constant decimals  = 8;

  uint256 public constant maxSupply = 13E16;
  
  constructor() public {
    totalSupply_ = totalSupply_.add(maxSupply);
    balances[msg.sender] = balances[msg.sender].add(maxSupply);
  }
}