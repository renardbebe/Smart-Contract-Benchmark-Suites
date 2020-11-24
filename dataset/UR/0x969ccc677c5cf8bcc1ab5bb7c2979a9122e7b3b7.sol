 

pragma solidity 0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
     
    assert(owner.send(address(this).balance));
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

 

 
contract RTELockingVault is HasNoEther, CanReclaimToken {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  ERC20 public token;

  bool public vaultUnlocked;

  uint256 public cap;

  uint256 public minimumDeposit;

  uint256 public tokensDeposited;

  uint256 public interestRate;

  uint256 public vaultDepositDeadlineTime;

  uint256 public vaultUnlockTime;

  uint256 public vaultLockDays;

  address public rewardWallet;

  mapping(address => uint256) public lockedBalances;

   
  event TokenLocked(address _investor, uint256 _value);

   
  event TokenWithdrawal(address _investor, uint256 _value);

  constructor (
    ERC20 _token,
    uint256 _cap,
    uint256 _minimumDeposit,
    uint256 _interestRate,
    uint256 _vaultDepositDeadlineTime,
    uint256 _vaultUnlockTime,
    uint256 _vaultLockDays,
    address _rewardWallet
  )
    public
  {
    require(_vaultDepositDeadlineTime > now);
     

    vaultUnlocked = false;

    token = _token;
    cap = _cap;
    minimumDeposit = _minimumDeposit;
    interestRate = _interestRate;
    vaultDepositDeadlineTime = _vaultDepositDeadlineTime;
    vaultUnlockTime = _vaultUnlockTime;
    vaultLockDays = _vaultLockDays;
    rewardWallet = _rewardWallet;
  }

   
  function lockToken(uint256 _amount) public {
    require(_amount >= minimumDeposit);
    require(now < vaultDepositDeadlineTime);
    require(tokensDeposited.add(_amount) <= cap);

    token.safeTransferFrom(msg.sender, address(this), _amount);

    lockedBalances[msg.sender] = lockedBalances[msg.sender].add(_amount);

    tokensDeposited = tokensDeposited.add(_amount);

    emit TokenLocked(msg.sender, _amount);
  }

   
  function withdrawToken() public {
     

    uint256 interestAmount = (interestRate.mul(lockedBalances[msg.sender]).div(36500)).mul(vaultLockDays);

    uint256 withdrawAmount = (lockedBalances[msg.sender]).add(interestAmount);
    require(withdrawAmount > 0);

    lockedBalances[msg.sender] = 0;

    token.safeTransfer(msg.sender, withdrawAmount);

    emit TokenWithdrawal(msg.sender, withdrawAmount);
  }

   
  function forceWithdrawToken(address _forceAddress) public onlyOwner {
    require(vaultUnlocked);

    uint256 interestAmount = (interestRate.mul(lockedBalances[_forceAddress]).div(36500)).mul(vaultLockDays);

    uint256 withdrawAmount = (lockedBalances[_forceAddress]).add(interestAmount);
    require(withdrawAmount > 0);

    lockedBalances[_forceAddress] = 0;

    token.safeTransfer(_forceAddress, withdrawAmount);

    emit TokenWithdrawal(_forceAddress, withdrawAmount);
  }

   
  function finalizeVault() public onlyOwner {
     
    require(now >= vaultUnlockTime);

    vaultUnlocked = true;

    uint256 bonusTokens = ((tokensDeposited.mul(interestRate)).div(36500)).mul(vaultLockDays);

    token.safeTransferFrom(rewardWallet, address(this), bonusTokens);
  }
}