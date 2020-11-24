 

pragma solidity ^0.4.15;


 
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


 

library Math {
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


 
contract Ownable {

  address public owner;

   
  function Ownable() internal {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


 
contract Pausable is Ownable {

  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() external onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() external onlyOwner whenPaused {
    paused = false;
    Unpause();
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

  mapping(address => uint256) internal balances;

   
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
}


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }
}


 

contract AlvalorToken is PausableToken {

  using SafeMath for uint256;

   
  string public constant name = "Alvalor";
  string public constant symbol = "TVAL";
  uint8 public constant decimals = 12;

   
  bool public frozen = false;

   
   
  uint256 public constant maxSupply = 18446744073709551615;
  uint256 public constant dropSupply = 3689348814741910323;

   
  uint256 public claimedSupply = 0;

   
  mapping(address => uint256) private claims;

   
  event Freeze();
  event Drop(address indexed receiver, uint256 value);
  event Mint(address indexed receiver, uint256 value);
  event Claim(address indexed receiver, uint256 value);
  event Burn(address indexed receiver, uint256 value);

   
   
  modifier whenNotFrozen() {
    require(!frozen);
    _;
  }

  modifier whenFrozen() {
    require(frozen);
    _;
  }

   
   
  function AlvalorToken() public {
    claims[owner] = dropSupply;
  }

   
   
  function freeze() external onlyOwner whenNotFrozen {
    frozen = true;
    Freeze();
  }

   
   
  function mint(address _receiver, uint256 _value) onlyOwner whenNotFrozen public returns (bool) {
    require(_value > 0);
    require(_value <= maxSupply.sub(totalSupply).sub(dropSupply));
    totalSupply = totalSupply.add(_value);
    balances[_receiver] = balances[_receiver].add(_value);
    Mint(_receiver, _value);
    return true;
  }

  function claimable(address _receiver) constant public returns (uint256) {
    if (claimedSupply >= dropSupply) {
      return 0;
    }
    return claims[_receiver];
  }

   
   
  function drop(address _receiver, uint256 _value) onlyOwner whenNotFrozen public returns (bool) {
    require(claimedSupply < dropSupply);
    require(_receiver != owner);
    claims[_receiver] = _value;
    Drop(_receiver, _value);
    return true;
  }

   
   
  function claim() whenNotPaused whenFrozen public returns (bool) {
    require(claimedSupply < dropSupply);
    uint value = Math.min256(claims[msg.sender], dropSupply.sub(claimedSupply));
    claims[msg.sender] = claims[msg.sender].sub(value);
    claimedSupply = claimedSupply.add(value);
    totalSupply = totalSupply.add(value);
    balances[msg.sender] = balances[msg.sender].add(value);
    Claim(msg.sender, value);
    return true;
  }
}