 

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

contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Ownable {
  address public owner;

  constructor() public {
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

contract Luxecoin is ERC20, Ownable {
  using SafeMath for uint256;

  string public name = "LuxeCoin";
  string public symbol = "LXC";
  uint8 public constant decimals = 18;
  uint256 public constant initial_supply = 220000000 * (10 ** uint256(decimals));

  mapping (address => uint256) balances;

  uint256 totalSupply_;
  
  constructor() public {
    owner = msg.sender;
    totalSupply_ = initial_supply;
    balances[owner] = initial_supply;
    emit Transfer(0x0, owner, initial_supply);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    uint256 _balance = balances[msg.sender];
    require(_value <= _balance);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  function transferMany(address[] recipients, uint256[] values) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      require(balances[msg.sender] >= values[i]);
      balances[msg.sender] = balances[msg.sender].sub(values[i]);
      balances[recipients[i]] = balances[recipients[i]].add(values[i]);
      emit Transfer(msg.sender, recipients[i], values[i]);
    }
  }
}