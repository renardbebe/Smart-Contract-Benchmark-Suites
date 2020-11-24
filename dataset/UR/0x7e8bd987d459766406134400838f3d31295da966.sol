 

pragma solidity ^0.4.16;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
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

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract BurnableToken is StandardToken {

   
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

  event Burn(address indexed burner, uint indexed value);

}

contract Misscoin is BurnableToken {
    
  string public constant name = "Misscoin";
   
  string public constant symbol = "MISC";
    
  uint32 public constant decimals = 18;

  uint256 public INITIAL_SUPPLY = 1000000000 * 1 ether;

  function Misscoin() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    balances[0x49B25aDDdd6503d275375C7c261A444862360396]=150000000 * 1 ether;
  }
    
}

contract Crowdsale is Ownable {
    
  using SafeMath for uint;
    
  address multisig;

  address restricted;

  bool addtok=false;

  Misscoin public token = new Misscoin();

  uint start;
    
  uint period;

  uint128 constant WAD = 10 ** 18;

  mapping (uint => mapping (address => uint))  public  userBuys;
  mapping (uint => uint)                       public  dailyTotals;
  mapping (uint => mapping (address => bool))  public  claimed;

   function Crowdsale() {
      multisig = 0x49B25aDDdd6503d275375C7c261A444862360396;
      restricted  = 0x49B25aDDdd6503d275375C7c261A444862360396;
      start = 1512741600;
      period = 150;
    }

  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }













  function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
   function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
  }

  function time() constant returns (uint) {
        return block.timestamp;
  }

  function today() constant returns (uint) {
        return dayFor(time());
  }

  function dayFor(uint timestamp) constant returns (uint) {

        return timestamp < start
            ? 0
            : sub(timestamp, start) / 24 hours + 1;
  }

  function buyWithLimit(uint day, uint limit) payable saleIsOn {
        assert(time() >= start && today() <= period);
        assert(msg.value >= 0.001 ether);
        
        assert(day >= today());
        assert(day <= period);

        userBuys[day][msg.sender] += msg.value;
        dailyTotals[day] += msg.value;

        if (limit != 0) {
            assert(dailyTotals[day] <= limit);
        }

  }

    function addtokens() onlyOwner{
      assert(today() >= 149 && !addtok);
      token.transfer(0x49B25aDDdd6503d275375C7c261A444862360396, 100000000 * 1 ether);
      addtok=true;
    }

    function buy() payable {
       buyWithLimit(today(), 0);
    }

    function () payable {
       buy();
    }
  
  function claim(uint day) saleIsOn {
        assert(today() > day);

        if (claimed[day][msg.sender] || dailyTotals[day] == 0) {
            return;
        }

       

        var dailyTotal = cast(dailyTotals[day]);
        var userTotal  = cast(userBuys[day][msg.sender]);
        var price      = wdiv(cast(5000000), dailyTotal);
        var reward     = wmul(price, userTotal);

        claimed[day][msg.sender] = true;
        token.transfer(msg.sender, reward * 1 ether);

  } 

  function claimAll() {
        for (uint i = 0; i < today(); i++) {
            claim(i);
        }
  }

  function collect() onlyOwner{
        assert(today() > 0);  
        multisig.transfer(this.balance);
  }

    
}