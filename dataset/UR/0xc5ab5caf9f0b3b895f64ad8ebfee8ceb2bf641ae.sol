 

pragma solidity ^0.4.18;

 

 
contract SafeMath {
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

 

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
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

 

 
contract TeamLocker is SafeMath, Ownable {
    using SafeERC20 for ERC20Basic;

    ERC20Basic public token;

    address[] public beneficiaries;
    uint256[] public ratios;
    uint256 public genTime;
    
    uint256 public collectedTokens;

    function TeamLocker(address _token, address[] _beneficiaries, uint256[] _ratios, uint256 _genTime) {

        require(_token != 0x00);
        require(_beneficiaries.length > 0 && _beneficiaries.length == _ratios.length);
        require(_genTime > 0);

        for (uint i = 0; i < _beneficiaries.length; i++) {
            require(_beneficiaries[i] != 0x00);
        }

        token = ERC20Basic(_token);
        beneficiaries = _beneficiaries;
        ratios = _ratios;
        genTime = _genTime;
    }

     
    function release() public {

        uint256 balance = token.balanceOf(address(this));
        uint256 total = add(balance, collectedTokens);

        uint256 lockTime1 = add(genTime, 183 days);  
        uint256 lockTime2 = add(genTime, 1 years);  

        uint256 currentRatio = 20;

        if (now >= lockTime1) {
            currentRatio = 50;
        }

        if (now >= lockTime2) {
            currentRatio = 100;
        }

        uint256 releasedAmount = div(mul(total, currentRatio), 100);
        uint256 grantAmount = sub(releasedAmount, collectedTokens);
        require(grantAmount > 0);
        collectedTokens = add(collectedTokens, grantAmount);


        uint256 grantAmountForEach;  

        for (uint i = 0; i < beneficiaries.length; i++) {
            grantAmountForEach = div(mul(grantAmount, ratios[i]), 100);
            token.safeTransfer(beneficiaries[i], grantAmountForEach);
        }
    }


    function setGenTime(uint256 _genTime) public onlyOwner {
        require(_genTime > 0);
        genTime = _genTime;
    }

    function setToken(address newToken) public onlyOwner {
        require(newToken != 0x00);
        token = ERC20Basic(newToken);
    }
    
    function destruct(address to) public onlyOwner {
        require(to != 0x00);
        selfdestruct(to);
    }
}