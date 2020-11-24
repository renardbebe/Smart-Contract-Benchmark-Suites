 

pragma solidity ^0.4.24;


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

}

 
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
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 

 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}

 
contract StandardToken is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
  
}

contract Recoverable is Ownable {

   
  constructor() public {
  }

   
   
  function recoverTokens(IERC20 token) onlyOwner public {
    token.transfer(owner, tokensToBeReturned(token));
  }

   
   
   
  function tokensToBeReturned(IERC20 token) public view returns (uint) {
    return token.balanceOf(this);
  }
}

 
contract BurnableToken is StandardToken, Ownable {

  event BurningAgentAdded(address indexed account);
  event BurningAgentRemoved(address indexed account);
  
  
   
  mapping (address => bool) public isBurningAgent;
  
   
  modifier canBurn() {
    require(isBurningAgent[msg.sender]);
    _;
  }
  
   
  function setBurningAgent(address _address, bool _status) public onlyOwner {
    require(_address != address(0));
    isBurningAgent[_address] = _status;
    if(_status) {
        emit BurningAgentAdded(_address);
    } else {
        emit BurningAgentRemoved(_address);
    }
  }
  
   
  function burn(
      uint256 _value
  ) 
    public 
    canBurn
    returns (bool)
  {
    _burn(msg.sender, _value);
    return true;
  }
  
}


 
contract MintableToken is StandardToken, Ownable {

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  uint256 mintLockPeriod = 1575158399;  

   
  mapping (address => bool) public isMinter;
  
   
  modifier canMint() {
    require(isMinter[msg.sender]);
    _;
  }
  
   
  function setMintingAgent(address _address, bool _status) public onlyOwner {
    require(_address != address(0));
     
    isMinter[_address] = _status;
    if(_status) {
        emit MinterAdded(_address);
    } else {
        emit MinterRemoved(_address);
    }
  }

   
  function mint(
    address _to,
    uint256 _value
  )
    public
    canMint
    returns (bool)
  {
    require(block.timestamp > mintLockPeriod);
    _mint(_to, _value);
    return true;
  }
}


 
contract Pausable is Ownable {
  event Paused();
  event Unpaused();

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
    emit Paused();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpaused();
  }
}



 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

 
contract ReleasableToken is StandardToken, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }

    _;
  }
  
   
  constructor() public {
      releaseAgent = msg.sender;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        revert();
    }
    _;
  }

   
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        revert();
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}


 
contract UpgradeableToken is StandardToken {

  using SafeMath for uint;
  
   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  constructor() public {
    upgradeMaster = msg.sender;
  }

   
  function upgrade(uint256 value) public {
    UpgradeState state = getUpgradeState();
    require((state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));

     
    require (value != 0);
    
     
    _burn(msg.sender, value);

    totalUpgraded = totalUpgraded.add(value);

     
    upgradeAgent.upgradeFrom(msg.sender, value);
    emit Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {
    require(canUpgrade());

    require(agent != address(0));
     
    require(msg.sender == upgradeMaster);
     
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

     
    require(upgradeAgent.isUpgradeAgent());
     
    require(upgradeAgent.originalSupply() == totalSupply());

    emit UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == address(0)) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
    require(master != 0x0);
    require(msg.sender == upgradeMaster);
    upgradeMaster = master;
  }

   
  function canUpgrade() public pure returns(bool) {
     return true;
  }

}


 
contract TrustEdToken is ReleasableToken, PausableToken, Recoverable, BurnableToken, UpgradeableToken, MintableToken {

   
  string public name;
  string public symbol;
  uint256 public decimals;
  
  uint256 TOTAL_SUPPLY;

   
  event UpdatedTokenInformation(string newName, string newSymbol);

  constructor() public {
    name = "TrustEd Token";
    symbol = "TED";
    decimals = 18;
    
    TOTAL_SUPPLY = 1720000000 * (10**decimals);  
    _mint(msg.sender, TOTAL_SUPPLY);

  }

   
  function setTokenInformation(string _name, string _symbol) onlyOwner external{
    name = _name;
    symbol = _symbol;
    emit UpdatedTokenInformation(name, symbol);
  }

}