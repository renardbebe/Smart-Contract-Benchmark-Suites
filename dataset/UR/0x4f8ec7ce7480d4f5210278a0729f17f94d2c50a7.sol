 

pragma solidity ^0.5.10;



 
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
   address payable public owner;

   event OwnershipTransferred(address indexed _from, address indexed _to);

   constructor() public {
       owner = msg.sender;
   }

   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }

   function transferOwnership(address payable _newOwner) public onlyOwner {
       owner = _newOwner;
   }
}


contract Pausable is Ownable{
 
    bool private _paused = false;

  
  

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
    }

     
    function unpause() public onlyOwner whenPaused {
        _paused = false;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

    
contract TokenSwap is Ownable ,Pausable  {
    
    using SafeMath for uint256;
    ERC20 public oldToken;
    ERC20 public newToken;

    constructor (address _oldToken , address _newToken ) public {
        oldToken = ERC20(_oldToken);
        newToken = ERC20(_newToken);
    
    }
    

    
    function swapTokens() public whenNotPaused{
        uint tokenAllowance = oldToken.allowance(msg.sender, address(this));
        require(tokenAllowance>0 , "token allowence is");
        require(newToken.balanceOf(address(this)) > tokenAllowance , "not enough balance");
        oldToken.transferFrom(msg.sender, address(0), tokenAllowance);
        newToken.transfer(msg.sender, tokenAllowance);

    }
    

    function kill() public onlyOwner {
    selfdestruct(msg.sender);
  }
  
       
    function returnNewTokens() public onlyOwner whenNotPaused {
        newToken.transfer(owner, newToken.balanceOf(address(this)));
    }
    
       
    
       
    function returnOldTokens() public onlyOwner whenNotPaused {
        oldToken.transfer(owner, oldToken.balanceOf(address(this)));
    }
    
    
}