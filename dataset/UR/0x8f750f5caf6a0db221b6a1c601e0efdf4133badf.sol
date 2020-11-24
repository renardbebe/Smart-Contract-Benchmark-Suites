 

pragma solidity ^0.4.15;


 
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

 

 
contract LifPresale is Ownable, Pausable {
  using SafeMath for uint256;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  uint256 public maxCap;

   
  function LifPresale(uint256 _weiRaised, uint256 _maxCap, address _wallet) {
    require(_weiRaised < _maxCap);

    weiRaised = _weiRaised;
    maxCap = _maxCap;
    wallet = _wallet;
    paused = true;
  }

   
  function () whenNotPaused payable {
    require(weiRaised.add(msg.value) <= maxCap);

    weiRaised = weiRaised.add(msg.value);
    wallet.transfer(msg.value);
  }

}