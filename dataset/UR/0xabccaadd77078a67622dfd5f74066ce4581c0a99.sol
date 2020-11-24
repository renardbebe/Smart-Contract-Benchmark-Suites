 

 

pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract mameCoin is ERC20, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) internal lockups;

  string public constant name = "mameCoin";
  string public constant symbol = "MAME";
  uint8 public constant decimals = 8;
  uint256 totalSupply_ = 25000000000 * (10 ** uint256(decimals));

  event Burn(address indexed to, uint256 amount);
  event Refund(address indexed to, uint256 amount);
  event Lockup(address indexed to, uint256 lockuptime);

   
  constructor() public {
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _amount) public returns (bool) {
    require(_to != address(0));
    require(_amount <= balances[msg.sender]);
    require(block.timestamp > lockups[msg.sender]);
    require(block.timestamp > lockups[_to]);

    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
    require(_to != address(0));
    require(_amount <= balances[_from]);
    require(_amount <= allowed[_from][msg.sender]);
    require(block.timestamp > lockups[_from]);
    require(block.timestamp > lockups[_to]);

    balances[_from] = balances[_from].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
  }

   
  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function burn(address _to, uint256 _amount) public onlyOwner {
    require(_amount <= balances[_to]);
    require(block.timestamp > lockups[_to]);
     
     

    balances[_to] = balances[_to].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);
    emit Burn(_to, _amount);
    emit Transfer(_to, address(0), _amount);
  }

   
  function refund(address _to, uint256 _amount) public onlyOwner {
    require(block.timestamp > lockups[_to]);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Refund(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

   
  function lockupOf(address _owner) public view returns (uint256) {
    return lockups[_owner];
  }

   
  function lockup(address _to, uint256 _lockupTimeUntil) public onlyOwner {
    require(lockups[_to] < _lockupTimeUntil);
    lockups[_to] = _lockupTimeUntil;
    emit Lockup(_to, _lockupTimeUntil);
  }

   
  function airdrop(address[] _receivers, uint256 _amount) public returns (bool) {
    require(block.timestamp > lockups[msg.sender]);
    require(_receivers.length > 0);
    require(_amount > 0);

    uint256 _total = 0;

    for (uint256 i = 0; i < _receivers.length; i++) {
      require(_receivers[i] != address(0));
      require(block.timestamp > lockups[_receivers[i]]);
      _total = _total.add(_amount);
    }

    require(_total <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_total);

    for (i = 0; i < _receivers.length; i++) {
      balances[_receivers[i]] = balances[_receivers[i]].add(_amount);
      emit Transfer(msg.sender, _receivers[i], _amount);
    }

    return true;
  }

   
  function distribute(address[] _receivers, uint256[] _amounts) public returns (bool) {
    require(block.timestamp > lockups[msg.sender]);
    require(_receivers.length > 0);
    require(_amounts.length > 0);
    require(_receivers.length == _amounts.length);

    uint256 _total = 0;

    for (uint256 i = 0; i < _receivers.length; i++) {
      require(_receivers[i] != address(0));
      require(block.timestamp > lockups[_receivers[i]]);
      require(_amounts[i] > 0);
      _total = _total.add(_amounts[i]);
    }

    require(_total <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_total);

    for (i = 0; i < _receivers.length; i++) {
      balances[_receivers[i]] = balances[_receivers[i]].add(_amounts[i]);
      emit Transfer(msg.sender, _receivers[i], _amounts[i]);
    }

    return true;
  }
}