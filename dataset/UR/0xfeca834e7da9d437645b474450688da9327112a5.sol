 

pragma solidity ^0.4.24;

 

 
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract Dcmc is MintableToken, BurnableToken{
  string public name = 'Digital Currency Mining Coin';
  string public symbol = 'DCMC';
  uint public decimals = 18;
  address public admin_wallet = 0xae9e15896fd32e59c7d89ce7a95a9352d6ebd70e;

  mapping(address => uint256) internal lockups;
  event Lockup(address indexed to, uint256 lockuptime);
  mapping (address => bool) public frozenAccount;
  event FrozenFunds(address indexed target, bool frozen);
  
  mapping(address => uint256[7]) lockupBalances;
  mapping(address => uint256[7]) releaseTimes;
  constructor() public {
  }

  function lockup(address _to, uint256 _lockupTimeUntil) public onlyOwner {
    lockups[_to] = _lockupTimeUntil;
    emit Lockup(_to, _lockupTimeUntil);
  }
  function lockupAccounts(address[] targets, uint256 _lockupTimeUntil) public onlyOwner {
    require(targets.length > 0);
    for (uint j = 0; j < targets.length; j++) {
      require(targets[j] != 0x0);
      lockups[targets[j]] = _lockupTimeUntil;
      emit Lockup(targets[j], _lockupTimeUntil);
    }
  }

  function lockupOf(address _owner) public view returns (uint256) {
    return lockups[_owner];
  }

  function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
    require(targets.length > 0);
    for (uint j = 0; j < targets.length; j++) {
      require(targets[j] != 0x0);
      frozenAccount[targets[j]] = isFrozen;
      emit FrozenFunds(targets[j], isFrozen);
    }
  }
  function freezeOf(address _owner) public view returns (bool) {
    return frozenAccount[_owner];
  }

  function distribute(address _to, uint256 _first_release, uint256[] amount) onlyOwner external returns (bool) {
    require(_to != address(0));
    require(amount.length == 7);
    _updateLockUpAmountOf(msg.sender);
    uint256 __total = 0;
    for(uint j = 0; j < amount.length; j++){
      require(lockupBalances[_to][j] == 0);
      __total = __total.add(amount[j]);
      lockupBalances[_to][j] = lockupBalances[_to][j].add(amount[j]);
      releaseTimes[_to][j] = _first_release + (j * 30 days) ;
    }
    balances[msg.sender] = balances[msg.sender].sub(__total);
    emit Transfer(msg.sender, _to, __total);
    return true;
  }

  function lockupBalancesOf(address _address) public view returns(uint256[7]){
    return ( lockupBalances[_address]);
  }

  function releaseTimeOf(address _address) public view returns(uint256[7]){
    return (releaseTimes[_address]);
  }

  function _updateLockUpAmountOf(address _address) internal {
    for(uint i = 0; i < 7; i++){
      if(releaseTimes[_address][i] != 0 && now >= releaseTimes[_address][i]){
        balances[_address] = balances[_address].add(lockupBalances[_address][i]);
        lockupBalances[_address][i] = 0;
        releaseTimes[_address][i] = 0;
      }
    }
  }

  function retrieve(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
    require(_value <= balances[_from]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    uint256 balance = 0;
    balance = balance.add(balances[_owner]);
    for(uint i = 0; i < 7; i++){
      balance = balance.add(lockupBalances[_owner][i]);
    }
    return balance;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_to != address(this));
    _updateLockUpAmountOf(msg.sender);
    uint256 _fee = _value.mul(15).div(10000);
    require(_value.add(_fee) <= balances[msg.sender]);
    require(block.timestamp > lockups[msg.sender]);
    require(block.timestamp > lockups[_to]);
    require(frozenAccount[msg.sender] == false);
    require(frozenAccount[_to] == false);

    balances[msg.sender] = balances[msg.sender].sub(_value.add(_fee));
    balances[_to] = balances[_to].add(_value);
    balances[admin_wallet] = balances[admin_wallet].add(_fee);
    emit Transfer(msg.sender, _to, _value);
    emit Transfer(msg.sender, admin_wallet, _fee);
    return true;
  }
}