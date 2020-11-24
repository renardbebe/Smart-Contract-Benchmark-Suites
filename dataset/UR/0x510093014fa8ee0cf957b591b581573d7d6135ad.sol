 

pragma solidity 0.4.21;

 
 
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


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}


 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  string public constant ROLE_ADMIN = "admin";

   
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
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


 
contract BasicToken is ERC20Basic {
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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


 
contract CryptoniaToken is StandardToken, RBAC {
  string public name = "Cryptonia Poker Chips";
  string public symbol = "CPC";
  uint8 public decimals = 2;
  uint256 public cap = 100000000000;
  bool public mintingFinished = false;
  string constant ROLE_MINTER = "minter";

  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Burn(address indexed burner, uint256 value);

   
  function mint(address _to, uint256 _amount) onlyRole(ROLE_MINTER) public returns (bool) {
    require(!mintingFinished);
    require(totalSupply_.add(_amount) <= cap);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyAdmin public returns (bool) {
    require(!mintingFinished);
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}


 
contract CryptoniaCrowdsale is RBAC {
  using SafeMath for uint256;

  struct Phase {
    uint256 startDate;
    uint256 endDate;
    uint256 tokensPerETH;
    uint256 tokensIssued;
  }

  Phase[] public phases;

   
  CryptoniaToken public token;

   
  address public wallet;

   
  uint256 public minPurchase = 100000000000000000;

   
  uint256 public weiRaised;

   
  uint256 public tokensIssued;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  event PhaseAdded(address indexed sender, uint256 index, uint256 startDate, uint256 endDate, uint256 tokensPerETH);
  event PhaseDeleted(address indexed sender, uint256 index);
  event WalletChanged(address newWallet);
  event OracleChanged(address newOracle);

   
  function CryptoniaCrowdsale(address _wallet, CryptoniaToken _token) public {
    require(_wallet != address(0));
    require(_token != address(0));
    wallet = _wallet;
    token = _token;
  }

   
  function() external payable {
    uint256 weiAmount = msg.value;
    address beneficiary = msg.sender;
    uint256 currentPhaseIndex = getCurrentPhaseIndex();
    uint256 tokens = weiAmount.mul(phases[currentPhaseIndex].tokensPerETH).div(1 ether);
    require(beneficiary != address(0));
    require(weiAmount >= minPurchase);
    weiRaised = weiRaised.add(weiAmount);
    phases[currentPhaseIndex].tokensIssued = phases[currentPhaseIndex].tokensIssued.add(tokens);
    tokensIssued = tokensIssued.add(tokens);
    token.mint(beneficiary, tokens);
    wallet.transfer(msg.value);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

   
  function validatePhaseDates(uint256 _startDate, uint256 _endDate) view public returns (bool) {
    if (_endDate <= _startDate) {
      return false;
    }
    for (uint i = 0; i < phases.length; i++) {
      if (_startDate >= phases[i].startDate && _startDate <= phases[i].endDate) {
        return false;
      }
      if (_endDate >= phases[i].startDate && _endDate <= phases[i].endDate) {
        return false;
      }
    }
    return true;
  }

   
  function addPhase(uint256 _startDate, uint256 _endDate, uint256 _tokensPerETH) public onlyAdmin {
    require(validatePhaseDates(_startDate, _endDate));
    require(_tokensPerETH > 0);
    phases.push(Phase(_startDate, _endDate, _tokensPerETH, 0));
    uint256 index = phases.length - 1;
    emit PhaseAdded(msg.sender, index, _startDate, _endDate, _tokensPerETH);
  }

   
  function delPhase(uint256 index) public onlyAdmin {
    require (index < phases.length);

    for (uint i = index; i < phases.length - 1; i++) {
      phases[i] = phases[i + 1];
    }
    phases.length--;
    emit PhaseDeleted(msg.sender, index);
  }

   
  function getCurrentPhaseIndex() view public returns (uint256) {
    for (uint i = 0; i < phases.length; i++) {
      if (phases[i].startDate <= now && now <= phases[i].endDate) {
        return i;
      }
    }
    revert();
  }

   
  function setWallet(address _newWallet) onlyAdmin public {
    require(_newWallet != address(0));
    wallet = _newWallet;
    emit WalletChanged(_newWallet);
  }
}