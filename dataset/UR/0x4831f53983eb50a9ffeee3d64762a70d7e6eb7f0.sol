 

pragma solidity ^0.4.24;

 
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

contract MultiSender is Ownable {
    using SafeMath for uint;

    string public constant NAME = "MultiSender";

    event Transfer(address indexed holder, uint amount);
    
    function() public payable {
         
    }
    
    function send(address[] _addresses, uint256[] _values) external onlyOwner {
        require(_addresses.length == _values.length);
        
        uint i;
        uint s;

        for (i = 0; i < _values.length; i++) {
            s = _values[i].add(s);
        }
        
        require(s <= this.balance);
        
        for (i = 0; i < _addresses.length; i++) {
            _addresses[i].transfer(_values[i]);
            Transfer(_addresses[i], _values[i]);
        }
    }
}