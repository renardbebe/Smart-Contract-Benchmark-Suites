 

pragma solidity 0.5.13;

 
library SafeMath {
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
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor () public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface token {
    function allowance(address, address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function burn(uint) external;
}

contract TokenSwap is Ownable {
    using SafeMath for uint;
    
     
     
    uint public newTokenUnitsPerOldToken = 1e18;
    
    address public oldTokenAddress;
    address public newTokenAddress;
    
    function setNewTokenUnitsPerOldToken(uint _newTokenUnitsPerOldToken) public onlyOwner {
        newTokenUnitsPerOldToken = _newTokenUnitsPerOldToken;
    }
    
    function setOldTokenAddress(address _oldTokenAddress) public onlyOwner {
        oldTokenAddress = _oldTokenAddress;
    }
    
    function setNewTokenAddress(address _newTokenAddress) public onlyOwner {
        newTokenAddress = _newTokenAddress;
    }
    
    function swapTokens() public {
         
        uint allowance = token(oldTokenAddress).allowance(msg.sender, address(this));
        
         
        require(allowance > 0);

         
        require(token(oldTokenAddress).transferFrom(msg.sender, address(this), allowance));
        
         
        uint amount = allowance.mul(newTokenUnitsPerOldToken).div(1e18);
        
         
        require(token(newTokenAddress).transfer(msg.sender, amount));
        
         
        token(oldTokenAddress).burn(allowance);
    }
    
     
    function transferAnyERC20Token(address tokenAddress, address to, uint tokenUnits) public onlyOwner {
        token(tokenAddress).transfer(to, tokenUnits);
    }
}