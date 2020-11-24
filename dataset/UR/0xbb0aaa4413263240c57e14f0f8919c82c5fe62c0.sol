 

pragma solidity ^0.4.15;

 
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

contract ArbiPreIco is Ownable {
    using SafeMath for uint256;
    
     
    ERC20 arbiToken;
    address public tokenAddress;

      
    address public tokenOwner;
    
    uint public startTime;
    uint public endTime;
    uint public price;

    uint public hardCapAmount = 33333200;

    uint public tokensRemaining = hardCapAmount;

      
    event TokenPurchase(address indexed beneficiary, uint256 amount);

    function ArbiPreIco(address token, address owner, uint start, uint end) public {
        tokenAddress = token;
        tokenOwner = owner;
        arbiToken = ERC20(token);
        startTime = start;
        endTime = end;
        price = 0.005 / 100 * 1 ether;  
    }

     
    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(isActive());
        require(msg.value >= 0.01 ether);
        uint amount = msg.value;
        uint tokenAmount = amount.div(price);
        makePurchase(beneficiary, tokenAmount);
    }

    function sendEther(address _to, uint amount) onlyOwner {
        _to.transfer(amount);
    }
    
    function isActive() constant returns (bool active) {
        return now >= startTime && now <= endTime && tokensRemaining > 0;
    }
    
     
    function sendToken(address _to, uint256 amount) onlyOwner {
        makePurchase(_to, amount);
    }

    function makePurchase(address beneficiary, uint256 amount) private {
        require(amount <= tokensRemaining);
        arbiToken.transferFrom(tokenOwner, beneficiary, amount);
        tokensRemaining = tokensRemaining.sub(amount);
        TokenPurchase(beneficiary, amount);
    }
    
}