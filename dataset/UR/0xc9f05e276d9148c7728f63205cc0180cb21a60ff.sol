 

pragma solidity ^0.4.18;

 

 
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

 

 
contract Lockable is Ownable {
  event Lock();
  event Unlock();

  bool public locked = false;

   
  modifier whenNotLocked() {
    require(!locked);
    _;
  }

   
  modifier whenLocked() {
    require(locked);
    _;
  }

   
  function lock() onlyOwner whenNotLocked public {
    locked = true;
    Lock();
  }

   
  function unlock() onlyOwner whenLocked public {
    locked = false;
    Unlock();
  }
}

 

contract BaseFixedERC20Token is Lockable {
  using SafeMath for uint;

   
  uint public totalSupply;

  mapping(address => uint) balances;

  mapping(address => mapping (address => uint)) private allowed;

   
  event Transfer(address indexed from, address indexed to, uint value);

   
  event Approval(address indexed owner, address indexed spender, uint value);

   
  function balanceOf(address owner_) public view returns (uint balance) {
    return balances[owner_];
  }

   
  function transfer(address to_, uint value_) whenNotLocked public returns (bool) {
    require(to_ != address(0) && value_ <= balances[msg.sender]);
     
    balances[msg.sender] = balances[msg.sender].sub(value_);
    balances[to_] = balances[to_].add(value_);
    Transfer(msg.sender, to_, value_);
    return true;
  }

   
  function transferFrom(address from_, address to_, uint value_) whenNotLocked public returns (bool) {
    require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
    balances[from_] = balances[from_].sub(value_);
    balances[to_] = balances[to_].add(value_);
    allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
    Transfer(from_, to_, value_);
    return true;
  }

   
  function approve(address spender_, uint value_) whenNotLocked public returns (bool) {
    if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
      revert();
    }
    allowed[msg.sender][spender_] = value_;
    Approval(msg.sender, spender_, value_);
    return true;
  }

   
  function allowance(address owner_, address spender_) view public returns (uint) {
    return allowed[owner_][spender_];
  }
}

 

 
contract BaseICOToken is BaseFixedERC20Token {

   
  uint public availableSupply;

   
  address public ico;

   
  event ICOTokensInvested(address indexed to, uint amount);

   
  event ICOChanged(address indexed icoContract);

   
  function BaseICOToken(uint totalSupply_) public {
    locked = true;
    totalSupply = totalSupply_;
    availableSupply = totalSupply_;
  }

   
  function changeICO(address ico_) onlyOwner public {
    ico = ico_;
    ICOChanged(ico);
  }

  function isValidICOInvestment(address to_, uint amount_) internal view returns(bool) {
    return msg.sender == ico && to_ != address(0) && amount_ <= availableSupply;
  }

   
  function icoInvestment(address to_, uint amount_) public returns (uint) {
    require(isValidICOInvestment(to_, amount_));
    availableSupply -= amount_;
    balances[to_] = balances[to_].add(amount_);
    ICOTokensInvested(to_, amount_);
    return amount_;
  }
}

 

contract DATOToken is BaseICOToken {
    using SafeMath for uint;

    string public constant name = 'DATO token';

    string public constant symbol = 'DATO';

    uint8 public constant decimals = 18;

    uint internal constant ONE_TOKEN = 1e18;

    uint public utilityLockedDate;

     
    event ReservedTokensDistributed(address indexed to, uint8 group, uint amount);

    function DATOToken(uint totalSupplyTokens_,
        uint reservedStaffTokens_,
        uint reservedUtilityTokens_)
    BaseICOToken(totalSupplyTokens_ * ONE_TOKEN) public {
        require(availableSupply == totalSupply);
        utilityLockedDate = block.timestamp + 1 years;
        availableSupply = availableSupply
            .sub(reservedStaffTokens_ * ONE_TOKEN)
            .sub(reservedUtilityTokens_ * ONE_TOKEN);
        reserved[RESERVED_STAFF_GROUP] = reservedStaffTokens_ * ONE_TOKEN;
        reserved[RESERVED_UTILITY_GROUP] = reservedUtilityTokens_ * ONE_TOKEN;
    }

     
    function() external payable {
        revert();
    }

     

    uint8 public RESERVED_STAFF_GROUP = 0x1;

    uint8 public RESERVED_UTILITY_GROUP = 0x2;

     
    mapping(uint8 => uint) public reserved;

     
    function getReservedTokens(uint8 group_) view public returns (uint) {
        return reserved[group_];
    }

     
    function assignReserved(address to_, uint8 group_, uint amount_) onlyOwner public {
        require(to_ != address(0) && (group_ & 0x3) != 0);
        if (group_ == RESERVED_UTILITY_GROUP) {
            require(block.timestamp >= utilityLockedDate);
        }

         
        reserved[group_] = reserved[group_].sub(amount_);
        balances[to_] = balances[to_].add(amount_);
        ReservedTokensDistributed(to_, group_, amount_);
    }
}