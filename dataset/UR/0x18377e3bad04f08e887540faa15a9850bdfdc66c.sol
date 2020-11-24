 

 

pragma solidity ^0.4.23;

library SafeMath {

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

contract ERC20Basic {
   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  function totalSupply() public view returns (uint256);
  function balanceOf(address addr) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract ERC20 is ERC20Basic {
   
  event Approval(address indexed owner, address indexed agent, uint256 value);

   
  function allowance(address owner, address agent) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address agent, uint256 value) public returns (bool);

}


contract Ownable {

   
  address public owner;

   
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function setOwner(address _owner) internal {
    owner = _owner;
    emit OwnershipTransferred(address(0), owner);
  }
}


contract Freezer {

  address freezer;


  modifier onlyFreezer() {
    require(msg.sender == freezer);
    _;
  }

  function transferFreezership(address newFreezer) public onlyFreezer {
    require(newFreezer != address(0));
    freezer = newFreezer;
  }

  function renounceFreezership() public onlyFreezer {
    freezer = address(0);
  }

  function setFreezer(address _freezer) internal {
    freezer = _freezer;
  }
}


contract Freezeable is Freezer {
   

   
  mapping(address => bool) _freezeList;

   
  event Freezed(address indexed freezedAddr);
  event UnFreezed(address indexed unfreezedAddr);

   
  function freeze(address addr) public onlyFreezer returns (bool) {
    require(true != _freezeList[addr]);

    _freezeList[addr] = true;

    emit Freezed(addr);
    return true;
  }

  function unfreeze(address addr) public onlyFreezer returns (bool) {
    require(true == _freezeList[addr]);

    _freezeList[addr] = false;

    emit UnFreezed(addr);
    return true;
  }

  modifier whenNotFreezed() {
    require(true != _freezeList[msg.sender]);
    _;
  }

  function isFreezed(address addr) public view returns (bool) {
    if (true == _freezeList[addr]) {
      return true;
    } else {
      return false;
    }
  }
   
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

   
  string public name;
  string public symbol;
  uint8 public decimals = 18;

   
  uint256 _totalSupply;
  mapping(address => uint256) _balances;

   

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address addr) public view returns (uint256 balance) {
    return _balances[addr];
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= _balances[msg.sender]);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

}

contract StandardToken is ERC20, BasicToken {
   

   
  mapping (address => mapping (address => uint256)) _allowances;

   

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= _balances[from]);
    require(value <= _allowances[from][msg.sender]);

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  function approve(address agent, uint256 value) public returns (bool) {
    _allowances[msg.sender][agent] = value;
    emit Approval(msg.sender, agent, value);
    return true;
  }

  function allowance(address owner, address agent) public view returns (uint256) {
    return _allowances[owner][agent];
  }

  function increaseApproval(address agent, uint value) public returns (bool) {
    _allowances[msg.sender][agent] = _allowances[msg.sender][agent].add(value);
    emit Approval(msg.sender, agent, _allowances[msg.sender][agent]);
    return true;
  }

  function decreaseApproval(address agent, uint value) public returns (bool) {
    uint allowanceValue = _allowances[msg.sender][agent];
    if (value > allowanceValue) {
      _allowances[msg.sender][agent] = 0;
    } else {
      _allowances[msg.sender][agent] = allowanceValue.sub(value);
    }
    emit Approval(msg.sender, agent, _allowances[msg.sender][agent]);
    return true;
  }
   
}

contract FreezeableToken is StandardToken, Freezeable, Ownable {
   

   

   

   
  function transfer(address to, uint256 value) public whenNotFreezed returns (bool) {
    require(true != _freezeList[to]);
    return super.transfer(to, value);
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(true != _freezeList[from]);
    require(true != _freezeList[to]);
    return super.transferFrom(from, to, value);
  }

  function approve(address agent, uint256 value) public whenNotFreezed returns (bool) {
    require(true != _freezeList[agent]);
    return super.approve(agent, value);
  }

  function increaseApproval(address agent, uint value) public whenNotFreezed returns (bool success) {
    require(true != _freezeList[agent]);
    return super.increaseApproval(agent, value);
  }

  function decreaseApproval(address agent, uint value) public whenNotFreezed returns (bool success) {
    require(true != _freezeList[agent]);
    return super.decreaseApproval(agent, value);
  }

   
}

contract PBCToken is FreezeableToken {
   
  string public name = "PBC Token";
  string public symbol = "PBC";
  uint8 public decimals = 18;

   
  constructor(address _owner) public {
    _totalSupply = 500000000 * (10 ** uint256(decimals));

    _balances[_owner] = _totalSupply;
    emit Transfer(0x0, _owner, _totalSupply);

    setOwner(_owner);
    setFreezer(_owner);
  }
}