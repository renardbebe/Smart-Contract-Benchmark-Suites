 

pragma solidity ^0.4.11;

 
contract ERC20Basic {
  uint256 public totalSupply;
  uint8 public decimals;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract BatchUtils is Ownable {
  using SafeMath for uint256;
  mapping (address => bool) public operational;
  uint256 public sendlimit = 10;
  
  function BatchUtils() {
      operational[msg.sender] = true;
  }
  
  function setLimit(uint256 _limit) onlyOwner public {
      sendlimit = _limit;
  }
  
  function setOperational(address[] addresses, bool op) onlyOwner public {
    for (uint i = 0; i < addresses.length; i++) {
        operational[addresses[i]] = op;
    }
  }
  
  function batchTransfer(address[] _tokens, address[] _receivers, uint256 _value) {
    require(operational[msg.sender]); 
    require(_value <= sendlimit);
    
    uint cnt = _receivers.length;
    require(cnt > 0 && cnt <= 121);
    
    for (uint j = 0; j < _tokens.length; j++) {
        ERC20Basic token = ERC20Basic(_tokens[j]);
        
        uint256 value = _value.mul(10**uint256(token.decimals()));
        uint256 amount = uint256(cnt).mul(value);
        
        require(value > 0 && token.balanceOf(this) >= amount);
        
        for (uint i = 0; i < cnt; i++) {
            token.transfer(_receivers[i], value);
        }
    }
  }
}