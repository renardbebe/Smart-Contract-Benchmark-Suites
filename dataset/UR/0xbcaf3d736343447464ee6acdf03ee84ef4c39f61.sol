 

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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 

contract PrivateSale is Pausable {
    using SafeMath for uint256;

    ERC20 public token;
    uint256 public rate = 1000;

    function PrivateSale(address _token) public {
        token = ERC20(_token);
    }

    function setToken(address _tokenAddr) public onlyOwner {
        token = ERC20(_tokenAddr);
    }

    function setRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function transferToken(address _to, uint256 _value) public onlyOwner {
        token.transfer(_to, _value);
    }

    function () public payable whenNotPaused {
        require(token != address(0));
        require(msg.value > 0);

        uint256 amount = msg.value.mul(rate);
        uint256 currentBal = token.balanceOf(this);
        if (currentBal >= amount) {
            owner.transfer(msg.value);
            token.transfer(msg.sender, amount);
        } else {
            uint256 value = currentBal.div(rate);
            owner.transfer(value);
            token.transfer(msg.sender, currentBal);
            msg.sender.transfer(msg.value.sub(value));
        }
    }
}