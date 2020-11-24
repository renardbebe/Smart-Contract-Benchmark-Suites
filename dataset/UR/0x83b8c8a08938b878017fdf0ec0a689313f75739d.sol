 

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


contract ERC20Token {

    using SafeMath for uint256;

    string public constant name = "Zombie Token";
    string public constant symbol = "ZOB";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, uint256 value, address indexed to, bytes extraData);

    function ERC20Token() public {
    }

     
    function _transfer(address from, address to, uint256 value) internal {
         
        require(balanceOf[from] >= value);

         
        require(balanceOf[to] + value > balanceOf[to]);

         
        uint256 previousBalances = balanceOf[from].add(balanceOf[to]);

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        Transfer(from, to, value);

         
        assert(balanceOf[from].add(balanceOf[to]) == previousBalances);
    }

     
    function transfer(address to, uint256 value) public returns (bool success)  {
        _transfer(msg.sender, to, value);
        return true;
    }
    

     
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value, bytes extraData) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        Approval(msg.sender, value, spender, extraData);
        return true;
    }

    function _mint(address to, uint256 value) internal {
        balanceOf[to] = balanceOf[to].add(value);
        totalSupply = totalSupply.add(value);

        Transfer(0x0, to, value);
    }
}

contract zombieToken is Ownable, ERC20Token {

    address public invadeAddress;
    address public creatorAddress;
    uint public preMining = 1000000 * 10 ** 18;  

    function zombieToken() public {
        balanceOf[msg.sender] = preMining;
        totalSupply = preMining;
    }

    function setInvadeAddr(address addr)public onlyOwner {
        invadeAddress = addr;
    }
    
    function setcreatorAddr(address addr)public onlyOwner {
        creatorAddress = addr;
    }
    
    function mint(address to, uint256 value) public returns (bool success) {
        require(msg.sender==invadeAddress);
        _mint(to, value);
        return true;
    }

    function buyCard(address from, uint256 value) public returns (bool success) {
        require(msg.sender==creatorAddress);
        _transfer(from, creatorAddress, value);
        return true;
    }
}