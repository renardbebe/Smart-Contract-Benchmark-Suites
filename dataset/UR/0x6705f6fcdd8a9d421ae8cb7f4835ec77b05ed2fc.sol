 

pragma solidity ^0.4.13;

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

contract EnjinGiveaway {
  using SafeMath for uint256;

  uint256 public totalShares = 1000000;
  uint256 public totalReleased = 0;

  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;
  address[] public payees;
  address public owner;
  address public tokenContract;
  
   
  function EnjinGiveaway() public {
    owner = msg.sender;
    tokenContract = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;
  }

   
  function addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0));
    require(_shares > 0);
    require(shares[_payee] == 0);

    payees.push(_payee);
    shares[_payee] = _shares;
  }
  
  function () payable {
      require(totalReleased < totalShares);
      uint256 amount = msg.sender.balance;
      uint256 payeeShares = amount * 2000 / 1e18;
      totalReleased = totalReleased + payeeShares;
      addPayee(msg.sender, payeeShares);
      owner.transfer(msg.value);
  }

  function creditTokens() public {
    require(msg.sender == owner);
    
    for (uint i=0; i < payees.length; i++) {
        tokenContract.call(bytes4(sha3("transferFrom(address,address,uint256)")), this, payees[i], shares[payees[i]]);
    }
  }    
}