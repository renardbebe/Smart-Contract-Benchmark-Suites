 

pragma solidity ^0.4.13;

 
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



contract InvestorsFeature is Ownable, StandardToken {
    using SafeMath for uint;
    
    address[] public investors;
    mapping(address => bool) isInvestor;
    function deposit(address investor, uint tokens) internal {
        if(isInvestor[investor] == false) {
            investors.push(investor);
            isInvestor[investor] = true;
        }
    }
    
    function sendp(address addr, uint amount) internal {
        require(addr != address(0));
        require(amount > 0);
        deposit(addr, amount);
        
         
        balances[this] = balances[this].sub(amount);
        balances[addr] = balances[addr].add(amount);
        Transfer(this, addr, amount);
    }
    
    function payDividends(uint) onlyOwner public {
        uint threshold = (30000  * (10 ** 8));
        require(balanceOf(this) >= threshold);
        uint total = 0;
        for(uint it = 0; it < investors.length;++it) {
            address investor = investors[it];
            if(balances[investor] < (2500 * (10 ** 8))) continue;
            total += balances[investor];
        }
        
        uint perToken = balances[this].mul(10 ** 10) / total;
        
        
        for(it = 0; it < investors.length;++it) {
            investor =  investors[it];
            if(balances[investor] < (2500 * (10 ** 8))) continue;
            uint out = balances[investor].mul(perToken).div(10 ** 10);
            sendp(investor, out);
            
        }
    }

}

contract FinTab is Ownable, StandardToken, InvestorsFeature  {
    

  string public constant name = "FinTabToken";
  string public constant symbol = "FNT";
  uint8 public constant decimals = 8;
  
  uint256 public constant INITIAL_SUPPLY = (30 * (10**6)) * (10 ** uint256(decimals));
  uint public constant weiPerToken = 1 ether / (750 * (10 ** uint(decimals)));
  
  
  
  function FinTab() public {
    totalSupply = INITIAL_SUPPLY;
    balances[this] = INITIAL_SUPPLY;
    Transfer(address(0), this, INITIAL_SUPPLY);
  }
  
  function fromEther(uint value) private constant returns(uint) {
      return value / weiPerToken;
  }
  
  function send(address addr, uint amount) public onlyOwner {
      sendp(addr, amount);
  }
  
  
  function() public payable {
      uint tokens = fromEther(msg.value);
      sendp(msg.sender, tokens);
  }
  
  function burnRemainder(uint) public onlyOwner {
      uint value = balances[this];
      totalSupply = totalSupply.sub(value);
      balances[this] = 0;
  }
  
  function moneyBack(address addr) public onlyOwner {
      require(addr != 0x0);
      addr.transfer(this.balance);
  }
  
}