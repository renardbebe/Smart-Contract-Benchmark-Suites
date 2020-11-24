 

pragma solidity ^0.5.7;

 

 

contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
  address indexed previousOwner,
  address indexed newOwner
  );

 
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
     
    uint256 c = a / b;
     
    return c;
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
    emit Pause();
  }

 

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

contract ERC20Basic is Pausable {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping (address => bool) public frozenAccount;  
  mapping (address => uint256) public frozenTimestamp;  
  mapping(address => uint256) balances;
  uint256 totalSupply_;

 

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

 

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(!frozenAccount[msg.sender]);
    require(now > frozenTimestamp[msg.sender]);
    require(!frozenAccount[_to]);
    require(now > frozenTimestamp[_to]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

 

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   

  function freeze(address _target,bool _freeze) onlyOwner public returns (bool) {
    require(_target != address(0));
    frozenAccount[_target] = _freeze;
    return true;
  }

   

  function multiFreeze(address[] memory _targets,bool[] memory _freezes) onlyOwner public returns (bool) {
    require(_targets.length == _freezes.length);
    uint256 len = _targets.length;
    require(len > 0);
    for (uint256 i = 0; i < len; i= i.add(1)) {
      address _target = _targets[i];
      require(_target != address(0));
      bool _freeze = _freezes[i];
      frozenAccount[_target] = _freeze;
    }
    return true;
  }

   

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  
 

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(!frozenAccount[_from]);
    require(!frozenAccount[_to]);
    require(now > frozenTimestamp[_from]);
    require(now > frozenTimestamp[_to]); 
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

 

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_value == 0 || allowed[msg.sender][_spender] == 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

 

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

 

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

 

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 

contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);

 

  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

contract StandardBurnableToken is BurnableToken, StandardToken {

 

  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

contract MintableToken is StandardBurnableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
  require(!mintingFinished);
  _;
  }

 

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(_to != address(0));
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

 

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract CappedToken is MintableToken {
  uint256 public cap;
  constructor(uint256 _cap) public {
  require(_cap > 0);
  cap = _cap;
  }

 
   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    return super.mint(_to, _amount);
  }
}

contract PausableToken is StandardToken {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract LT_Token is CappedToken, PausableToken {
  string public constant name = "LittleBeeX";  
  string public constant symbol = "LT";  
  uint8 public constant decimals = 18;  
  uint256 public constant INITIAL_SUPPLY = 0;
  uint256 public constant MAX_SUPPLY = 50 * 10000 * 10000 * (10 ** uint256(decimals));

 
  
  constructor() CappedToken(MAX_SUPPLY) public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(uint160(0x0)), msg.sender, INITIAL_SUPPLY);
  }

 
  
  function mint(address _to, uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
    return super.mint(_to, _amount);
  }

 
  
  function finishMinting() onlyOwner canMint whenNotPaused public returns (bool) {
    return super.finishMinting();
  }

 

  function withdraw (uint256 _amount) onlyOwner public returns (bool) {
    msg.sender.transfer(_amount);
    return true;
  }

 

  function() payable external {
    revert();
  }
}