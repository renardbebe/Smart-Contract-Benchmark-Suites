 

 

 
pragma solidity ^0.4.13;

 
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

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract PeonyToken is Ownable, ERC20 {
  using SafeMath for uint256;
  string public version;
  string public name;
  string public symbol;
  uint256 public decimals;
  address public peony;
  mapping(address => mapping (address => uint256)) allowed;
  mapping(address => uint256) balances;
  uint256 public totalSupply;
  uint256 public totalSupplyLimit;


   
  function PeonyToken(
    string _version,
    uint256 initialSupply,
    uint256 totalSupplyLimit_,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {
    require(totalSupplyLimit_ == 0 || totalSupplyLimit_ >= initialSupply);
    version = _version;
    balances[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    totalSupplyLimit = totalSupplyLimit_;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
  }

   
  modifier isPeonyContract() {
    require(peony != 0x0);
    require(msg.sender == peony);
    _;
  }

   
  modifier isOwnerOrPeonyContract() {
    require(msg.sender != address(0) && (msg.sender == peony || msg.sender == owner));
    _;
  }

   
  function produce(uint256 amount) isPeonyContract returns (bool) {
    require(totalSupplyLimit == 0 || totalSupply.add(amount) <= totalSupplyLimit);

    balances[owner] = balances[owner].add(amount);
    totalSupply = totalSupply.add(amount);

    return true;
  }

   
  function consume(uint256 amount) isPeonyContract returns (bool) {
    require(balances[owner].sub(amount) >= 0);
    require(totalSupply.sub(amount) >= 0);
    balances[owner] = balances[owner].sub(amount);
    totalSupply = totalSupply.sub(amount);

    return true;
  }

   
  function setPeonyAddress(address _address) onlyOwner returns (bool) {
    require(_address != 0x0);

    peony = _address;
    return true;
  }

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    Transfer(msg.sender, _to, _value);

    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

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

   
  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
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