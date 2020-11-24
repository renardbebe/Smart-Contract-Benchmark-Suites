 

pragma solidity ^0.4.11;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
 
contract GreedVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(address beneficiary, uint256 amount);
  event Revoked(address beneficiary);

  uint256 public totalVesting;
  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;
  mapping (address => bool) public revocables;
  mapping (address => uint256) public durations;
  mapping (address => uint256) public starts;
  mapping (address => uint256) public cliffs; 
  mapping (address => uint256) public amounts; 
  mapping (address => uint256) public refunded; 
       
   
  function addVesting(ERC20Basic greed, address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, uint256 _amount, bool _revocable) public onlyOwner {
    require(_beneficiary != 0x0);
    require(_amount > 0);
     
    require(starts[_beneficiary] == 0);
     
    require(_cliff <= _duration);
     
    require(totalVesting.add(_amount) <= greed.balanceOf(address(this)));

	revocables[_beneficiary] = _revocable;
    durations[_beneficiary] = _duration;
    cliffs[_beneficiary] = _start.add(_cliff);
    starts[_beneficiary] = _start;
    amounts[_beneficiary] = _amount;
    totalVesting = totalVesting.add(_amount);
  }

   
  function release(address beneficiary, ERC20Basic greed) public {
      
    require(msg.sender == beneficiary || msg.sender == owner);

    uint256 unreleased = releasableAmount(beneficiary);
    
    require(unreleased > 0);

    released[beneficiary] = released[beneficiary].add(unreleased);

    greed.safeTransfer(beneficiary, unreleased);

    Released(beneficiary, unreleased);
  }

   
  function revoke(address beneficiary, ERC20Basic greed) public onlyOwner {
    require(revocables[beneficiary]);
    require(!revoked[beneficiary]);

    uint256 balance = amounts[beneficiary].sub(released[beneficiary]);

    uint256 unreleased = releasableAmount(beneficiary);
    uint256 refund = balance.sub(unreleased);

    revoked[beneficiary] = true;
    if (refund != 0) { 
		greed.safeTransfer(owner, refund);
		refunded[beneficiary] = refunded[beneficiary].add(refund);
	}
    Revoked(beneficiary);
  }

   
  function releasableAmount(address beneficiary) public constant returns (uint256) {
    return vestedAmount(beneficiary).sub(released[beneficiary]);
  }

   
  function vestedAmount(address beneficiary) public constant returns (uint256) {
    uint256 totalBalance = amounts[beneficiary].sub(refunded[beneficiary]);

    if (now < cliffs[beneficiary]) {
      return 0;
    } else if (now >= starts[beneficiary] + durations[beneficiary] || revoked[beneficiary]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now - starts[beneficiary]).div(durations[beneficiary]);
    }
  }
}