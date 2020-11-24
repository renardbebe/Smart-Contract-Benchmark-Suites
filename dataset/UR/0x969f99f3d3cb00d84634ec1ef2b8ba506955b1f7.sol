 

pragma solidity ^0.4.18;

 

 
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

 

 
contract WeSendReserve is Ownable {
  using SafeMath for uint256;

  mapping (address => bool) internal authorized;
  mapping(address => uint256) internal deposits;
  mapping(address => uint256) internal releases;

  ERC20 public token;
  uint256 public minRelease = 1;

  event Deposit(address indexed from, uint256 amount);
  event Release(address indexed to, uint256 amount);

  modifier isAuthorized() {
    require(authorized[msg.sender]);
    _;
  }

   
  function WeSendReserve(address _address) public {
    token = ERC20(_address);
  }

   
  function setAuthorized(address _address) public onlyOwner {
    authorized[_address] = true;
  }

   
  function revokeAuthorized(address _address) public onlyOwner {
    authorized[_address] = false;
  }

   
  function getDeposits(address _address) public view returns (uint256) {
    return deposits[_address];
  }

   
  function getWithdraws(address _address) public view returns (uint256) {
    return releases[_address];
  }

   
  function setMinRelease(uint256 amount) public onlyOwner {
    minRelease = amount;
  }

   
  function deposit(uint256 _amount) public returns (bool) {
    token.transferFrom(msg.sender, address(this), _amount);
    deposits[msg.sender] = deposits[msg.sender].add(_amount);
    Deposit(msg.sender, _amount);
    return true;
  }

   
  function release(address _address, uint256 _amount) public isAuthorized returns (uint256) {
    require(_amount >= minRelease);
    token.transfer(_address, _amount);
    releases[_address] = releases[_address].add(_amount);
    Release(_address, _amount);
  }

}