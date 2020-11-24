 

pragma solidity ^0.4.18;

  
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

  
contract SafeMath {
  function safeMul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

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

  
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);  
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function decimals() public constant returns (uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract SilentNotaryTokenStorage is SafeMath, Ownable {

   
  struct FrozenPortion {
     
    uint unfreezeTime;

     
    uint portionPercent;

     
    uint portionAmount;

     
    bool isUnfrozen;
  }

   
  event Unfrozen(uint tokenAmount);

   
  ERC20 public token;

   
  FrozenPortion[] public frozenPortions;

   
  address public teamWallet;

   
  uint public deployedTime;

   
  bool public amountFixed;

   
   
   
   
   
  function SilentNotaryTokenStorage (address _token, address _teamWallet, uint[] _freezePeriods, uint[] _freezePortions) public {
    require(_token > 0);
    require(_teamWallet > 0);
    require(_freezePeriods.length > 0);
    require(_freezePeriods.length == _freezePortions.length);

    token = ERC20(_token);
    teamWallet = _teamWallet;
    deployedTime = now;

    var cumulativeTime = deployedTime;
    uint cumulativePercent = 0;
    for (uint i = 0; i < _freezePeriods.length; i++) {
      require(_freezePortions[i] > 0 && _freezePortions[i] <= 100);
      cumulativePercent = safeAdd(cumulativePercent, _freezePortions[i]);
      cumulativeTime = safeAdd(cumulativeTime, _freezePeriods[i]);
      frozenPortions.push(FrozenPortion({
        portionPercent: _freezePortions[i],
        unfreezeTime: cumulativeTime,
        portionAmount: 0,
        isUnfrozen: false}));
    }
    assert(cumulativePercent == 100);
  }

   
  function unfreeze() public onlyOwner {
    require(amountFixed);

    uint unfrozenTokens = 0;
    for (uint i = 0; i < frozenPortions.length; i++) {
      var portion = frozenPortions[i];
      if (portion.isUnfrozen)
        continue;
      if (portion.unfreezeTime < now) {
        unfrozenTokens = safeAdd(unfrozenTokens, portion.portionAmount);
        portion.isUnfrozen = true;
      }
      else
        break;
    }
    transferTokens(unfrozenTokens);
  }

   
  function fixAmount() public onlyOwner {
    require(!amountFixed);
    amountFixed = true;

    uint currentBalance = token.balanceOf(this);
    for (uint i = 0; i < frozenPortions.length; i++) {
      var portion = frozenPortions[i];
      portion.portionAmount = safeDiv(safeMul(currentBalance, portion.portionPercent), 100);
    }
  }

   
  function withdrawRemainder() public onlyOwner {
    for (uint i = 0; i < frozenPortions.length; i++) {
      if (!frozenPortions[i].isUnfrozen)
        revert();
    }
    transferTokens(token.balanceOf(this));
  }

  function transferTokens(uint tokenAmount) private {
    require(tokenAmount > 0);
    var transferSuccess = token.transfer(teamWallet, tokenAmount);
    assert(transferSuccess);
    Unfrozen(tokenAmount);
  }
}