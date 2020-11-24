 

pragma solidity 0.4.23;
 
 
 
 
 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract Recoverable is CanReclaimToken, Claimable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }

}

contract TokenVault is Recoverable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  uint256 public tokensToBeAllocated;

   
  uint256 public tokensAllocated;

   
  uint256 public totalClaimed;

   
  uint256 public lockedAt;

   
  uint256 public unlockedAt;

   
  uint256 public vestingPeriod = 0;

   
  mapping (address => uint256) public allocations;

   
  mapping (address => uint256) public claimed;


   
  event Locked();

   
  event Unlocked();

   
  event Allocated(address indexed beneficiary, uint256 amount);

   
  event Distributed(address indexed beneficiary, uint256 amount);


   
  modifier vaultLoading() {
    require(lockedAt == 0, "Expected vault to be loadable");
    _;
  }

   
  modifier vaultLocked() {
    require(lockedAt > 0, "Expected vault to be locked");
    _;
  }

   
  modifier vaultUnlocked() {
    require(unlockedAt > 0, "Expected the vault to be unlocked");
    _;
  }


   
  constructor(
    ERC20Basic _token,
    uint256 _tokensToBeAllocated,
    uint256 _vestingPeriod
  )
    public
  {
    require(address(_token) != address(0), "Token address should not be blank");
    require(_tokensToBeAllocated > 0, "Token allocation should be greater than zero");

    token = _token;
    tokensToBeAllocated = _tokensToBeAllocated;
    vestingPeriod = _vestingPeriod;
  }

   
  function setAllocation(
    address _beneficiary,
    uint256 _amount
  )
    external
    onlyOwner
    vaultLoading
    returns(bool)
  {
    require(_beneficiary != address(0), "Beneficiary of allocation must not be blank");
    require(_amount != 0, "Amount of allocation must not be zero");
    require(allocations[_beneficiary] == 0, "Allocation amount for this beneficiary is not already set");

     
    allocations[_beneficiary] = allocations[_beneficiary].add(_amount);
    tokensAllocated = tokensAllocated.add(_amount);

    emit Allocated(_beneficiary, _amount);

    return true;
  }

   
  function lock() external onlyOwner vaultLoading {
    require(tokensAllocated == tokensToBeAllocated, "Expected to allocate all tokens");
    require(token.balanceOf(address(this)) == tokensAllocated, "Vault must own enough tokens to distribute");

     
    lockedAt = block.timestamp;

    emit Locked();
  }

   
  function unlock() external onlyOwner vaultLocked {
    require(unlockedAt == 0, "Must not be unlocked yet");
     
    require(block.timestamp >= lockedAt.add(vestingPeriod), "Lock up must be over");

     
    unlockedAt = block.timestamp;

    emit Unlocked();
  }

   
  function claim() public vaultUnlocked returns(bool) {
    return _transferTokens(msg.sender);
  }

   
  function transferFor(
    address _beneficiary
  )
    public
    onlyOwner
    vaultUnlocked
    returns(bool)
  {
    return _transferTokens(_beneficiary);
  }

   

   
  function _claimableTokens(address _beneficiary) internal view returns(uint256) {
    return allocations[_beneficiary].sub(claimed[_beneficiary]);
  }

   
  function _transferTokens(address _beneficiary) internal returns(bool) {
    uint256 _amount = _claimableTokens(_beneficiary);
    require(_amount > 0, "Tokens to claim must be greater than zero");

    claimed[_beneficiary] = claimed[_beneficiary].add(_amount);
    totalClaimed = totalClaimed.add(_amount);

    token.safeTransfer(_beneficiary, _amount);

    emit Distributed(_beneficiary, _amount);

    return true;
  }

}