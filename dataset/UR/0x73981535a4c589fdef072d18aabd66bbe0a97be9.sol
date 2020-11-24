 

pragma solidity 0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract SKYFTokenInterface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}


contract SKYFNetworkDevelopmentFund is Ownable{
    using SafeMath for uint256;

    uint256 public constant startTime = 1534334400;
    uint256 public constant firstYearEnd = startTime + 365 days;
    uint256 public constant secondYearEnd = firstYearEnd + 365 days;
    
    uint256 public initialSupply;
    SKYFTokenInterface public token;

    function setToken(address _token) public onlyOwner returns (bool) {
        require(_token != address(0));
        if (token == address(0)) {
            token = SKYFTokenInterface(_token);
            return true;
        }
        return false;
    }

    function transfer(address _to, uint256 _value) public onlyOwner returns (bool) {
        uint256 balance = token.balanceOf(this);
        if (initialSupply == 0) {
            initialSupply = balance;
        }
        
        if (now < firstYearEnd) {
            require(balance.sub(_value).mul(2) >= initialSupply);  
        } else if (now < secondYearEnd) {
            require(balance.sub(_value).mul(20) >= initialSupply.mul(3));  
        }

        token.transfer(_to, _value);

    }
}