 

pragma solidity ^0.5.1;


library IterableMapping {
  struct itmap
  {
    mapping(address => IndexValue) data;
    KeyFlag[] keys;
    uint size;
  }
  struct IndexValue { uint keyIndex; uint value; }
  struct KeyFlag { address key; bool deleted; }
  function insert(itmap storage self, address key, uint value) public returns (bool replaced)
  {
    uint keyIndex = self.data[key].keyIndex;
    self.data[key].value = value;
    if (keyIndex > 0)
      return true;
    else
    {
      keyIndex = self.keys.length++;
      self.data[key].keyIndex = keyIndex + 1;
      self.keys[keyIndex].key = key;
      self.size++;
      return false;
    }
  }
  function remove(itmap storage self, address key) public returns (bool success)
  {
    uint keyIndex = self.data[key].keyIndex;
    if (keyIndex == 0)
      return false;
    delete self.data[key];
    self.keys[keyIndex - 1].deleted = true;
    self.size --;
  }
  function contains(itmap storage self, address key) public view returns (bool)
  {
    return self.data[key].keyIndex > 0;
  }
  function iterate_start(itmap storage self) public view returns (uint keyIndex)
  {
    return iterate_next(self, uint(-1));
  }
  function iterate_valid(itmap storage self, uint keyIndex) public view returns (bool)
  {
    return keyIndex < self.keys.length;
  }
  function iterate_next(itmap storage self, uint keyIndex) public view returns (uint)
  {
    uint _tmpKeyIndex = keyIndex;
    _tmpKeyIndex++;
    while (_tmpKeyIndex < self.keys.length && self.keys[_tmpKeyIndex].deleted)
      _tmpKeyIndex++;
    return _tmpKeyIndex;
  }
  function iterate_get(itmap storage self, uint keyIndex) public view returns (address key, uint value)
  {
    key = self.keys[keyIndex].key;
    value = self.data[key].value;
  }
  function iterate_getValue(itmap storage self, address key) public view returns (uint value) {
      return self.data[key].value;
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
    constructor () public {
    	owner = msg.sender;
    }

   
  modifier onlyOwner() {
    require(msg.sender == owner,"called by any account other than the owner");
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0),"owner address should not 0");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused,"callable when the contract is not paused");
    _;
  }

   
  modifier whenPaused() {
    require(paused,"callable when the contract is paused");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused  {
    paused = false;
    emit Unpause();
  }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b > 0);  
    uint256 c = _a / _b;
    assert(_a == _b * c + _a % _b);  
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  IterableMapping.itmap balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {

    require(_value <= IterableMapping.iterate_getValue(balances, msg.sender),"not enough balances");
    require(_to != address(0),"0 address not allow");

    IterableMapping.insert(balances, msg.sender, IterableMapping.iterate_getValue(balances, msg.sender).sub(_value));
    IterableMapping.insert(balances, _to, IterableMapping.iterate_getValue(balances, _to).add(_value));
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
      return IterableMapping.iterate_getValue(balances, _owner);
  }

}



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {

    require(_value <= IterableMapping.iterate_getValue(balances, _from),"balance not enough");
    require(_value <= allowed[_from][msg.sender],"balance not enough");
    require(_to != address(0),"0 address not allow");

    IterableMapping.insert(balances, _from, IterableMapping.iterate_getValue(balances, _from).sub(_value));
    IterableMapping.insert(balances, _to, IterableMapping.iterate_getValue(balances, _to).add(_value));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract LKBT is PausableToken {
    string public name = "LKBT Token";
    string public symbol = "LKBT";
    uint8 public decimals = 18;
    uint256 public INITIAL_SUPPLY = 10000000000 ether;

    constructor () public {
    	totalSupply_ = INITIAL_SUPPLY;
    	IterableMapping.insert(balances, msg.sender, INITIAL_SUPPLY);
    }

    function balancesStart() public view returns(uint256) {
        return IterableMapping.iterate_start(balances);
    }

    function balancesGetBool(uint256 num) public view returns(bool){
        return IterableMapping.iterate_valid(balances, num);
    }

    function balancesGetNext(uint256 num) public view returns(uint256) {
        return IterableMapping.iterate_next(balances, num);
    }
    function balancesGetValue(uint256 num) public view returns(address, uint256) {
        address key;
        uint256 value;
        (key, value) = IterableMapping.iterate_get(balances, num);
        return (key, value);
    }
}