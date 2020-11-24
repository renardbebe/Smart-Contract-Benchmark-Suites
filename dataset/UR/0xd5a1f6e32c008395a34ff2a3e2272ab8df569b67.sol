 

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

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
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

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract NOBLECASH is ERC20, Ownable, Pausable {

  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 initialSupply;
  uint256 totalSupply_;

  mapping(address => uint256) balances;
  mapping(address => bool) internal locks;
  mapping(address => mapping(address => uint256)) internal allowed;

  function NOBLECASH() public {
    name = "NOBLECASH";
    symbol = "NCC";
    decimals = 18;
    initialSupply = 2105120000;
    totalSupply_ = initialSupply * 10 ** uint(decimals);
    balances[owner] = totalSupply_;
    Transfer(address(0), owner, totalSupply_);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(locks[msg.sender] == false);
    
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(locks[_from] == false);
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    require(_value > 0);
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function burn(uint256 _value) public onlyOwner returns (bool success) {
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    return true;
  }
  
  function lock(address _owner) public onlyOwner returns (bool) {
    require(locks[_owner] == false);
    locks[_owner] = true;
    return true;
  }

  function unlock(address _owner) public onlyOwner returns (bool) {
    require(locks[_owner] == true);
    locks[_owner] = false;
    return true;
  }

  function showLockState(address _owner) public view returns (bool) {
    return locks[_owner];
  }

  function () public payable {
    revert();
  }

  function distribute(address _to, uint256 _value) public onlyOwner returns (bool) {
    require(_to != address(0));
    require(_value <= balances[owner]);

    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(owner, _to, _value);
    return true;
  }
}