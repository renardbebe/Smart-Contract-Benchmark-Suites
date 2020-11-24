 

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


   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
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

 

 
contract StandardToken  {

  using SafeMath for uint256;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) internal balances;


  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    require(_to != address(this));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }



   
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

contract ERC20 is StandardToken {

}

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

contract TXTToken is PausableToken {

using SafeMath for uint256;


string public name;
string public symbol;
uint8 public decimals;

 
address private foundersWallet;
uint256 private tokenStartTime;
uint256 private constant  phasePeriod  = 30 days;
uint256 private constant phaseTokens  = 20 * 10 ** 24;
uint256 private lastPhase = 0;

event TokensReleased(uint256 amount, address to, uint256 phase);
 

constructor (address _foundersWallet) public{
  require(_foundersWallet != address(0x0));
  name = "Tune Trade Token";
  symbol = "TXT";
  decimals = 18;
  foundersWallet = _foundersWallet;
  totalSupply_ = 500 * 10 ** 24;
  balances[foundersWallet] = 30 * 10 ** 24;
  balances[owner] = 250 * 10 **24;  
  transferOwnership(foundersWallet);
  tokenStartTime = now;
  releaseTokens();
}


function _phasesToRelease() internal view returns (uint256)
{
  if (lastPhase == 11) return 0;
  uint256 timeFromStart = now.sub(tokenStartTime);
  uint256 phases = timeFromStart.div(phasePeriod).add(1);
  if (phases > 11) phases = 11;
  return phases.sub(lastPhase);
}

function _readyToRelease() internal view returns(bool) {

  if(_phasesToRelease()> 0) return true;
  return false;

}

function releaseTokens () public returns(bool) {

  require(_readyToRelease());
  uint256 toRelease = _phasesToRelease();

  balances[foundersWallet] = balances[foundersWallet].add(phaseTokens.mul(toRelease));
  lastPhase = lastPhase.add(toRelease);
  emit TokensReleased(phaseTokens*toRelease,foundersWallet,lastPhase);

  return true;
}

function transfer(address _to, uint256 _value) public returns (bool)
{
  if(msg.sender == foundersWallet) {
    if(_readyToRelease()) releaseTokens();
  }
  return super.transfer(_to,_value);

}

function balanceOf(address _owner) public view returns (uint256) {
  if(_owner == foundersWallet)
  {
    return balances[_owner].add( _phasesToRelease().mul(phaseTokens));
  }
  else {
  return balances[_owner];
  }

}

}