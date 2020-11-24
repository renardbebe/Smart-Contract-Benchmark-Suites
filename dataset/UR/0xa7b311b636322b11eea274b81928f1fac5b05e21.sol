 

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

contract EtherpayCoin is BasicToken,Ownable {

   using SafeMath for uint256;
   
   string public constant name = "Etherpay";
   string public constant symbol = "EPC";
   uint256 public constant decimals = 4;
   uint256 public buyPrice = 111 * 10 ** 12 ;    
   address public ethStore = 0x933252A4Fd45D12BC0ea4211427EAE934912d002;
   uint256 public constant INITIAL_SUPPLY = 21000000;
   event Debug(string message, address addr, uint256 number);
   event Message(string message);
    string buyMessage;
    
   function () public payable {
    buy(msg.sender);
   }
  
    
    
    function EtherpayCoin() public {
        owner = ethStore;
        totalSupply = INITIAL_SUPPLY;
        tokenBalances[owner] = INITIAL_SUPPLY * (10 ** uint256(decimals));    
    }
    
    function buy(address beneficiary) payable public {
        uint amount = msg.value.div(buyPrice);                     
        amount = amount * (10 ** uint256(decimals));
        require(tokenBalances[owner] >= amount);                
        tokenBalances[beneficiary] = tokenBalances[beneficiary].add(amount);                   
        tokenBalances[owner] = tokenBalances[owner].sub(amount);                         
        Transfer(owner, beneficiary, amount);                
        ethStore.transfer(msg.value);                        
        buyMessage = "Thank you for participating in EtherpayCoin ICO";
        Message(buyMessage);
    }
    
    function getTokenBalance() public view returns (uint256 balance) {
        balance = tokenBalances[msg.sender].div (10**decimals);  
    }
 
    function changeBuyPrice(uint newPrice) public onlyOwner {
        buyPrice = newPrice;
    }
}