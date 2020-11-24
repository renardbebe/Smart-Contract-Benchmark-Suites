 

 

pragma solidity ^0.4.24;


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
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
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

 
contract TokenVesting is Ownable{
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;
  
  
  ERC20Basic public token;
  
  
  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;
  uint256 public cliff;
  uint256 public start;
  uint256 public duration;
  address public rollback;
  bool public revocable;
  
  uint256 public currentBalance;
  bool public initialized = false;
  
  uint256 public constant initialTokens = 8732*10**8;
  
  
  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;
  
  
  uint256 public totalBalance;
   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable,
    address _rollback,
    ERC20Basic _token
    
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
    token = _token;
    rollback = _rollback;

  }

     
  function initialize() public onlyOwner {
        
      require(tokensAvailable() == initialTokens);  
      currentBalance = token.balanceOf(this);
      totalBalance = currentBalance.add(released[token]);
      initialized = true;
      
  }

  
  function tokensAvailable() public constant returns (uint256) {
    
    return token.balanceOf(this);
  }
  
  
  
  function release() public {
    require(initialized);
    uint256 unreleased = releasableAmount();

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }


  function revoke() public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount();
    uint256 refund = balance.sub(unreleased);
    
    revoked[token] = true;

    token.safeTransfer(rollback, refund);

    emit Revoked();
  }


  function releasableAmount() public returns (uint256) {
    return vestedAmount().sub(released[token]);
  }


  function vestedAmount() public returns (uint256) {
    
    currentBalance = token.balanceOf(this);
    totalBalance = currentBalance.add(released[token]);
    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
        
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}