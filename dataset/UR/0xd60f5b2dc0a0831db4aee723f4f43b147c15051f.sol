 

pragma solidity ^0.4.11;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }
}
 
contract RevolutionCoin is BasicToken,Ownable {

   using SafeMath for uint256;
   
   string public constant name = "R-evolutioncoin";
   string public constant symbol = "RVL";
   uint256 public constant decimals = 18;
   uint256 public buyPrice = 222222222222222;    
   address public ethStore = 0xDd64EF0c8a41d8a17F09ce2279D79b3397184A10;
   uint256 public constant INITIAL_SUPPLY = 100000000;
   event Debug(string message, address addr, uint256 number);
   
    
    
    function RevolutionCoin() public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        tokenBalances[owner] = INITIAL_SUPPLY * (10 ** uint256(decimals));    
    }

    function buy() payable public returns (uint amount) {
        amount = msg.value.div(buyPrice);                     
        amount = amount * (10 ** uint256(decimals));
        require(tokenBalances[owner] >= amount);                
        tokenBalances[msg.sender] = tokenBalances[msg.sender].add(amount);                   
        tokenBalances[owner] = tokenBalances[owner].sub(amount);                         
        Transfer(owner, msg.sender, amount);                
        ethStore.transfer(msg.value);                        
        return amount;                                     
    }
    function getTokenBalance() public view returns (uint256 balance) {
        balance = tokenBalances[msg.sender].div (10**decimals);  
    }
    function changeBuyPrice(uint newPrice) public onlyOwner {
        buyPrice = newPrice;
    }
}