 

pragma solidity ^0.4.24;

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
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

 

contract FUTM1 is MintableToken, BurnableToken, RBAC {
  using SafeMath for uint256;

  string public constant name = "Futereum Markets 1";
  string public constant symbol = "FUTM1";
  uint8 public constant decimals = 18;

  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_SUPER = "super";

  uint public swapLimit;
  uint public constant CYCLE_CAP = 100000 * (10 ** uint256(decimals));
  uint public constant BILLION = 10 ** 9;

  event SwapStarted(uint256 startTime);
  event MiningRestart(uint256 endTime);
  event CMCUpdate(string updateType, uint value);

  uint offset = 10**18;
   
  uint public exchangeRateFUTB;

   
  uint public cycleMintSupply = 0;
  bool public isMiningOpen = false;
  uint public CMC = 129238998229;
  uint public cycleEndTime;

  address public constant FUTC = 0xf880d3C6DCDA42A7b2F6640703C5748557865B35;
  address public constant FUTB = 0x30c6Fe3AC0260A855c90caB79AA33e76091d4904;

  constructor() public {
     
    owner = this;
    totalSupply_ = 0;
    addRole(msg.sender, ROLE_ADMIN);
    addRole(msg.sender, ROLE_SUPER);

     
    exchangeRateFUTB = offset.mul(offset).div(CMC.mul(offset).div(BILLION)).mul(65).div(100);
    cycleEndTime = now + 100 days;
  }

  modifier canMine() {
    require(isMiningOpen);
    _;
  }

   
  function mine(uint amount) canMine external {
    require(amount > 0);
    require(cycleMintSupply < CYCLE_CAP);
    require(ERC20(FUTB).transferFrom(msg.sender, address(this), amount));

    uint refund = _mine(exchangeRateFUTB, amount);
    if(refund > 0) {
      ERC20(FUTB).transfer(msg.sender, refund);
    }
    if (cycleMintSupply >= CYCLE_CAP || now > cycleEndTime) {
       
      _startSwap();
    }
  }

  function _mine(uint _rate, uint _inAmount) private returns (uint) {
    assert(_rate > 0);

     
    if (now > cycleEndTime && cycleMintSupply > 0) {
      return _inAmount;
    }
    uint tokens = _rate.mul(_inAmount).div(offset);
    uint refund = 0;

     
    uint futcFeed = tokens.mul(35).div(65);

    if (tokens + futcFeed + cycleMintSupply > CYCLE_CAP) {
      uint overage = tokens + futcFeed + cycleMintSupply - CYCLE_CAP;
      uint tokenOverage = overage.mul(65).div(100);
      futcFeed -= (overage - tokenOverage);
      tokens -= tokenOverage;

       
      refund = tokenOverage.mul(offset).div(_rate);
    }
    cycleMintSupply += (tokens + futcFeed);
    require(futcFeed > 0, "Mining payment too small.");
    MintableToken(this).mint(msg.sender, tokens);
    MintableToken(this).mint(FUTC, futcFeed);

    return refund;
  }

   
  bool public swapOpen = false;
  mapping(address => uint) public swapRates;

  function _startSwap() private {
    swapOpen = true;
    isMiningOpen = false;

     
     
    swapLimit = cycleMintSupply.mul(35).div(100);
    swapRates[FUTB] = ERC20(FUTB).balanceOf(address(this)).mul(offset).mul(35).div(100).div(swapLimit);

    emit SwapStarted(now);
  }

  function swap(uint amt) public {
    require(swapOpen && swapLimit > 0);
    if (amt > swapLimit) {
      amt = swapLimit;
    }
    swapLimit -= amt;
     
    burn(amt);

    if (amt.mul(swapRates[FUTB]) > 0) {
      ERC20(FUTB).transfer(msg.sender, amt.mul(swapRates[FUTB]).div(offset));
    }

    if (swapLimit == 0) {
      _restart();
    }
  }

  function _restart() private {
    require(swapOpen);
    require(swapLimit == 0);

    cycleMintSupply = 0;
    swapOpen = false;
    isMiningOpen = true;
    cycleEndTime = now + 100 days;

    emit MiningRestart(cycleEndTime);
  }

  function updateCMC(uint _cmc) public onlyAdmin {
    require(_cmc > 0);
    CMC = _cmc;
    emit CMCUpdate("TOTAL_CMC", _cmc);
    exchangeRateFUTB = offset.mul(offset).div(CMC.mul(offset).div(BILLION)).mul(65).div(100);
  }

  function setIsMiningOpen(bool isOpen) onlyAdmin external {
    isMiningOpen = isOpen;
  }

  modifier onlySuper() {
    checkRole(msg.sender, ROLE_SUPER);
    _;
  }

  modifier onlyAdmin() {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  function addAdmin(address _addr) public onlySuper {
    addRole(_addr, ROLE_ADMIN);
  }

  function removeAdmin(address _addr) public onlySuper {
    removeRole(_addr, ROLE_ADMIN);
  }

  function changeSuper(address _addr) public onlySuper {
    addRole(_addr, ROLE_SUPER);
    removeRole(msg.sender, ROLE_SUPER);
  }
}