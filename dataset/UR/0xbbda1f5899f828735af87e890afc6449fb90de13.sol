 

pragma solidity ^0.4.16;

 
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
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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



contract DEST  is StandardToken {

   
   

  string public constant name = "Decentralized Escrow Token";
  string public constant symbol = "DEST";
  uint   public constant decimals = 18;

  uint public constant ETH_MIN_LIMIT = 500 ether;
  uint public constant ETH_MAX_LIMIT = 1500 ether;

  uint public constant START_TIMESTAMP = 1503824400;  
  uint public constant END_TIMESTAMP   = 1506816000;  

  address public constant wallet = 0x51559EfC1AcC15bcAfc7E0C2fB440848C136A46B;


   
   

  uint public ethCollected;
  mapping (address=>uint) ethInvested;


   
   

  function hasStarted() public constant returns (bool) {
    return now >= START_TIMESTAMP;
  }


   
  function hasFinished() public constant returns (bool) {
    return now >= END_TIMESTAMP || ethCollected >= ETH_MAX_LIMIT;
  }


   
  function tokensAreLiquid() public constant returns (bool) {
    return (ethCollected >= ETH_MIN_LIMIT && now >= END_TIMESTAMP)
      || (ethCollected >= ETH_MAX_LIMIT);
  }


  function price(uint _v) public constant returns (uint) {
    return  
      _v < 7 ether
        ? _v < 3 ether
          ? _v < 1 ether
            ? 1000
            : _v < 2 ether ? 1005 : 1010
          : _v < 4 ether
            ? 1015
            : _v < 5 ether ? 1020 : 1030
        : _v < 14 ether
          ? _v < 10 ether
            ? _v < 9 ether ? 1040 : 1050
            : 1080
          : _v < 100 ether
            ? _v < 20 ether ? 1110 : 1150
            : 1200;
  }


   
   

  function() public payable {
    require(hasStarted() && !hasFinished());
    require(ethCollected + msg.value <= ETH_MAX_LIMIT);

    ethCollected += msg.value;
    ethInvested[msg.sender] += msg.value;

    uint _tokenValue = msg.value * price(msg.value);
    balances[msg.sender] += _tokenValue;
    totalSupply += _tokenValue;
    Transfer(0x0, msg.sender, _tokenValue);
  }


   
  function refund() public {
    require(ethCollected < ETH_MIN_LIMIT && now >= END_TIMESTAMP);
    require(balances[msg.sender] > 0);

    totalSupply -= balances[msg.sender];
    balances[msg.sender] = 0;
    uint _ethRefund = ethInvested[msg.sender];
    ethInvested[msg.sender] = 0;
    msg.sender.transfer(_ethRefund);
  }


   
  function withdraw() public {
    require(ethCollected >= ETH_MIN_LIMIT);
    wallet.transfer(this.balance);
  }


   
   

  function transfer(address _to, uint _value) public returns (bool)
  {
    require(tokensAreLiquid());
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value)
    public returns (bool)
  {
    require(tokensAreLiquid());
    return super.transferFrom(_from, _to, _value);
  }


  function approve(address _spender, uint _value)
    public returns (bool)
  {
    require(tokensAreLiquid());
    return super.approve(_spender, _value);
  }
}