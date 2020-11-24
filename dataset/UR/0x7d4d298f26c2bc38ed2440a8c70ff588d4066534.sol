 

pragma solidity ^0.4.19;

 

 

 
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

contract GECO is Ownable {
  using SafeMath for uint256;
  
  event IncomingTransfer(address indexed to, uint256 amount);
  event ContractFinished();
    
  address public wallet;
  uint256 public endTime;
  uint256 public totalSupply;
  mapping(address => uint256) balances;
  bool public contractFinished = false;
  
  function GECO(address _wallet, uint256 _endTime) public {
    require(_wallet != address(0));
    require(_endTime >= now);
    
    wallet = _wallet;
    endTime = _endTime;
  }
  
  function () external payable {
    require(!contractFinished);
    require(now <= endTime);
      
    totalSupply = totalSupply.add(msg.value);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    wallet.transfer(msg.value);
    IncomingTransfer(msg.sender, msg.value);
  }
  
  function finishContract() onlyOwner public returns (bool) {
    contractFinished = true;
    ContractFinished();
    return true;
  }
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  function changeEndTime(uint256 _endTime) onlyOwner public {
    endTime = _endTime;
  }
}