 

pragma solidity ^0.4.25;

 

contract Ownerable {
     
     
    modifier onlyOwner { require(msg.sender == owner); _; }

    address public owner;

    constructor() public { owner = msg.sender;}

     
     
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

 

 
contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
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

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

contract TeamLocker is Ownerable, SafeMath {
  using SafeERC20 for ERC20Basic;

  ERC20Basic public token;
  address[] public beneficiaries;
  uint256 public baiastm;
  uint256 public releasedAmt;

  constructor (address _token, address[] _beneficiaries, uint256 _baias) public {
    require(_token != 0x00);
    require(_baias != 0x00);

    for (uint i = 0; i < _beneficiaries.length; i++) {
      require(_beneficiaries[i] != 0x00);
    }

    token = ERC20Basic(_token);
    beneficiaries = _beneficiaries;
    baiastm = _baias;
  }

  function release() public {
    require(beneficiaries.length != 0x0);

    uint256 balance = token.balanceOf(address(this));
    uint256 total = add(balance, releasedAmt);

    uint256 lockTime1 = add(baiastm, 183 days);  
    uint256 lockTime2 = add(baiastm, 365 days);  

    uint256 currentRatio = 0;
    if (now >= lockTime1) {
      currentRatio = 50;
    }
    if (now >= lockTime2) {
      currentRatio = 100;   
    }
    require(currentRatio > 0);

    uint256 totalReleaseAmt = div(mul(total, currentRatio), 100);
    uint256 grantAmt = sub(totalReleaseAmt, releasedAmt);
    require(grantAmt > 0);
    releasedAmt = add(releasedAmt, grantAmt);

    uint256 grantAmountForEach = div(grantAmt, beneficiaries.length);
    for (uint i = 0; i < beneficiaries.length; i++) {
        token.safeTransfer(beneficiaries[i], grantAmountForEach);
    }
  }

  function setBaias(uint256 _baias) public onlyOwner {
    require(_baias != 0x00);
    baiastm = _baias;
  }

  function setToken(address newToken) public onlyOwner {
    require(newToken != 0x00);
    token = ERC20Basic(newToken);
  }

  function getBeneficiaryCount() public view returns(uint256) {
    return beneficiaries.length;
  }

  function setBeneficiary(uint256 _i, address _addr) public onlyOwner {
    require(_i < beneficiaries.length);
    beneficiaries[_i] = _addr;
  }

  function claimTokens(address _token) public onlyOwner {
      if (_token == 0x0) {
          owner.transfer( address(this).balance);
          return;
      }

      ERC20Basic __token = ERC20Basic(_token);
      uint balance = __token.balanceOf(address(this));
      __token.transfer(owner, balance);
  }

  function destruct(address to) public onlyOwner returns(bool) {
      selfdestruct(to);
      return true;
  }
}