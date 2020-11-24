 

pragma solidity ^0.4.18;

 

 
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

 

contract ReturnVestingRegistry is Ownable {

  mapping (address => address) public returnAddress;

  function record(address from, address to) onlyOwner public {
    require(from != 0);

    returnAddress[from] = to;
  }
}

 

 
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

 

contract TerraformReserve is Ownable {

   
  mapping (address => uint256) public lockedBalance;

   
  uint public totalLocked;

   
  ERC20 public manaToken;

   
  address public landClaim;

   
  bool public acceptingDeposits;

  event LockedBalance(address user, uint mana);
  event LandClaimContractSet(address target);
  event LandClaimExecuted(address user, uint value, bytes data);
  event AcceptingDepositsChanged(bool _acceptingDeposits);

  function TerraformReserve(address _token) {
    require(_token != 0);
    manaToken = ERC20(_token);
    acceptingDeposits = true;
  }

   
  function lockMana(address _from, uint256 mana) public {
    require(acceptingDeposits);
    require(mana >= 1000 * 1e18);
    require(manaToken.transferFrom(_from, this, mana));

    lockedBalance[_from] += mana;
    totalLocked += mana;
    LockedBalance(_from, mana);
  }

   
  function changeContractState(bool _acceptingDeposits) public onlyOwner {
    acceptingDeposits = _acceptingDeposits;
    AcceptingDepositsChanged(acceptingDeposits);
  }

   
  function setTargetContract(address target) public onlyOwner {
    landClaim = target;
    manaToken.approve(landClaim, totalLocked);
    LandClaimContractSet(target);
  }

   
  function () public payable {
    revert();
  }
}

 

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 
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

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;
  bool public revoked;

  uint256 public released;

  ERC20 public token;

   
  function TokenVesting(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool    _revocable,
    address _token
  ) {
    require(_beneficiary != 0x0);
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    start       = _start;
    cliff       = _start.add(_cliff);
    duration    = _duration;
    revocable   = _revocable;
    token       = ERC20(_token);
  }

   
  modifier onlyBeneficiary() {
    require(msg.sender == beneficiary);
    _;
  }

   
  function changeBeneficiary(address target) onlyBeneficiary public {
    require(target != 0);
    beneficiary = target;
  }

   
  function release() onlyBeneficiary public {
    require(now >= cliff);
    _releaseTo(beneficiary);
  }

   
  function releaseTo(address target) onlyBeneficiary public {
    require(now >= cliff);
    _releaseTo(target);
  }

   
  function _releaseTo(address target) internal {
    uint256 unreleased = releasableAmount();

    released = released.add(unreleased);

    token.safeTransfer(target, unreleased);

    Released(released);
  }

   
  function revoke() onlyOwner public {
    require(revocable);
    require(!revoked);

     
    _releaseTo(beneficiary);

     
    token.safeTransfer(owner, token.balanceOf(this));

    revoked = true;

    Revoked();
  }


   
  function releasableAmount() public constant returns (uint256) {
    return vestedAmount().sub(released);
  }

   
  function vestedAmount() public constant returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }

   
  function releaseForeignToken(ERC20 _token, uint256 amount) onlyOwner {
    require(_token != token);
    _token.transfer(owner, amount);
  }
}

 

contract DecentralandVesting is TokenVesting {
  using SafeERC20 for ERC20;

  event LockedMANA(uint256 amount);

  ReturnVestingRegistry public returnVesting;
  TerraformReserve public terraformReserve;

  function DecentralandVesting(
    address               _beneficiary,
    uint256               _start,
    uint256               _cliff,
    uint256               _duration,
    bool                  _revocable,
    ERC20                 _token,
    ReturnVestingRegistry _returnVesting,
    TerraformReserve      _terraformReserve
  )
    TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable, _token)
  {
    returnVesting    = ReturnVestingRegistry(_returnVesting);
    terraformReserve = TerraformReserve(_terraformReserve);
  }

  function lockMana(uint256 amount) onlyBeneficiary public {
     
    require(token.allowance(beneficiary, terraformReserve) >= amount);

     
    require(amount <= token.balanceOf(this));

     
    require(returnVesting.returnAddress(beneficiary) == address(this));

     
    token.safeTransfer(beneficiary, amount);
    terraformReserve.lockMana(beneficiary, amount);

    LockedMANA(amount);
  }
}