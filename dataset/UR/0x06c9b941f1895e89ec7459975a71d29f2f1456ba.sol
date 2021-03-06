 

 
contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}





 
contract Pausable is Ownable {
  event Unpause();

  bool public paused = true;


   
  modifier whenNotPaused() {
      require(!paused);
    _;
  }

   
  modifier whenPaused {
      require(paused);
    _;
  }

   
  function unpause() onlyOwner whenPaused public returns (bool) {
    paused = false;
    Unpause();
    return true;
  }

     
  function pause() onlyOwner whenNotPaused public returns (bool) {
    paused = true;
    return false;
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant public returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  function transfer(address _to, uint _value) public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant public returns (uint balance) {
    return balances[_owner];
  }

}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) public {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) public {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant public returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}




 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused public {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused public {
    super.transferFrom(_from, _to, _value);
  }
}






 
contract GODToken is PausableToken {
  using SafeMath for uint256;

  string public name = "GOD Token";
  string public symbol = "GOD";
  uint public decimals = 18;


  uint256 private constant INITIAL_SUPPLY = 3000000000 ether;


   
  function GODToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }

  function changeSymbolName(string symbolName) onlyOwner public
  {
      symbol = symbolName;
  }

   function changeName(string symbolName) onlyOwner public
  {
      name = symbolName;
  }
}





contract DatumTokenDistributor is Ownable {
  GODToken public token;
  
  function DatumTokenDistributor(GODToken _token) public
  {
     
    token = _token;
  }

  function distributeToken(address[] addresses, uint256[] amounts) onlyOwner public {
     require(addresses.length == amounts.length);
     for (uint i = 0; i < addresses.length; i++) {
         token.transfer(addresses[i], amounts[i]);
     }
  }

  function setTokenSymbolName(string symbol) onlyOwner public
  {
    token.changeSymbolName(symbol);
  }

  function setTokenName(string name) onlyOwner public
  {
    token.changeName(name);
  }

  function releaseToken() onlyOwner public
  {
    token.unpause();
  }
}