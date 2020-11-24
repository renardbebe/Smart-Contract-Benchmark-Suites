 

pragma solidity ^0.4.22;

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
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

 
contract ERC20Token {
  using SafeMath for uint256;

  uint256 public totalSupply;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   
  function transfer(address _to, uint256 _value) public returns (bool) {
     
    require(_to != address(0));
     
    require(_value <= balanceOf[msg.sender]);

     
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     
    require(_to != address(0));
     
    require(_value <= balanceOf[_from]);
     
    require(_value <= allowance[_from][msg.sender]);

     
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

     
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    emit Transfer(_from, _to, _value);

    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
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
}

 
contract ApproveAndCallFallBack {
  function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) public;
}

contract BCBToken is ERC20Token, Ownable {
  uint256 constant public BCB_UNIT = 10 ** 18;

  string public constant name = "BCBToken";
  string public constant symbol = "BCB";
  uint32 public constant decimals = 18;

  uint256 public totalSupply = 120000000 * BCB_UNIT;
  uint256 public lockedAllocation = 53500000 * BCB_UNIT;
  uint256 public totalAllocated = 0;
  address public allocationAddress;

  uint256 public lockEndTime;

  constructor(address _allocationAddress) public {
     
    balanceOf[owner] = totalSupply - lockedAllocation;
    allocationAddress = _allocationAddress;

     
    lockEndTime = now + 12 * 30 days;
  }

   
  function releaseLockedTokens() public onlyOwner {
    require(now > lockEndTime);
    require(totalAllocated < lockedAllocation);

    totalAllocated = lockedAllocation;
    balanceOf[allocationAddress] = balanceOf[allocationAddress].add(lockedAllocation);

    emit Transfer(0x0, allocationAddress, lockedAllocation);
  }

   
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
    if (approve(_spender, _value)) {
      ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, address(this), _extraData);
      return true;
    }
  }
}