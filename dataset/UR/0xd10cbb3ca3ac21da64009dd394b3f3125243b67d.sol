 

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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
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

 
contract Lockable is Ownable {

  mapping (address => bool) public lockStates;    

  event Lock(address indexed accountAddress);
  event Unlock(address indexed accountAddress);


   
  modifier whenNotLocked(address _address) {
    require(!lockStates[_address]);
    _;
  }

   
  modifier whenLocked(address _address) {
    require(lockStates[_address]);
    _;
  }

   
  function lock(address _address) onlyOwner public {
      lockWorker(_address);
  }

  function lockMultiple(address[] _addresses) onlyOwner public {
      for (uint i=0; i < _addresses.length; i++) {
          lock(_addresses[i]);
      }
  }

  function lockWorker(address _address) internal {
      require(_address != owner);
      require(this != _address);

      lockStates[_address] = true;
      Lock(_address);
  }

   
  function unlock(address _address) onlyOwner public {
      unlockWorker(_address);
  }

  function unlockMultiple(address[] _addresses) onlyOwner public {
      for (uint i=0; i < _addresses.length; i++) {
          unlock(_addresses[i]);
      }
  }

  function unlockWorker(address _address) internal {
      lockStates[_address] = false;
      Unlock(_address);
  }
}

contract ERC20Basic {
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

 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value)  public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns  (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

 
contract TabToken is PausableToken, Lockable {

  event Burn(address indexed burner, uint256 value);
  event EtherReceived(address indexed sender, uint256 weiAmount);
  event EtherSent(address indexed receiver, uint256 weiAmount);
  event EtherAddressChanged(address indexed previousAddress, address newAddress);

  
  string public constant name = "Accounting Blockchain Token";
  string public constant symbol = "TAB";
  uint8 public constant decimals = 18;


  address internal _etherAddress = 0x90CD914C827a12703D485E9E5fA69977E3ea866B;

   
  uint256 internal constant INITIAL_SUPPLY = 22000000000000000000000000000;

   
  function TabToken() public {
    totalSupply_ = INITIAL_SUPPLY;

     
    balances[this] = INITIAL_SUPPLY;
    Transfer(0x0, this, INITIAL_SUPPLY);

     
  }

   
  function () payable public {
    revert();
  }

   
  function fund() payable public onlyOwner {
    require(msg.sender != 0x0);
    require(msg.value > 0);

    EtherReceived(msg.sender, msg.value);
  }

   
  function sendEther() payable public onlyOwner {
    require(msg.value > 0);
    assert(_etherAddress != address(0));      

    EtherSent(_etherAddress, msg.value);
    _etherAddress.transfer(msg.value);
  }

   
  function totalBalance() view public returns (uint256) {
    return this.balance;
  }
  
  function transferFromContract(address[] _addresses, uint256[] _values) public onlyOwner returns (bool) {
    require(_addresses.length == _values.length);
    
    for (uint i=0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0));
      require(_values[i] <= balances[this]);

       
      balances[this] = balances[this].sub(_values[i]);
      balances[_addresses[i]] = balances[_addresses[i]].add(_values[i]);
      Transfer(msg.sender, _addresses[i], _values[i]);

    }
    
    return true;
  }

  function remainingSupply() public view returns(uint256) {
    return balances[this];
  }

   
  function burnFromContract(uint256 amount) public onlyOwner {
    require(amount <= balances[this]);
     
     

    address burner = this;
    balances[burner] = balances[burner].sub(amount);
    totalSupply_ = totalSupply_.sub(amount);
    Burn(burner, amount);
  } 

  function etherAddress() public view onlyOwner returns(address) {
    return _etherAddress;
  }

   
  function setEtherAddress(address newAddress) public onlyOwner {
    require(newAddress != address(0));
    EtherAddressChanged(_etherAddress, newAddress);
    _etherAddress = newAddress;
  }
}