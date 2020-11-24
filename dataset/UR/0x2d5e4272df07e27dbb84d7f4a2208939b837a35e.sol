 

pragma solidity 0.4.21;

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

contract ZerochainToken is MintableToken {
    string public constant name = "0chain";
    string public constant symbol = "ZCN";
    uint8 public constant decimals = 10;
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
    RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
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

 

 
contract MultipleTokenVesting is Pausable, RBAC {
    using SafeMath for uint256;

    event Released(address indexed beneficiary, uint256 indexed amount);
    event Vested(address indexed beneficiary, uint256 indexed amount);
    event Activated();
    event VestingFinished();
    event Airdrop(address indexed beneficiary);

     
    mapping (address => uint256) public beneficiaries;
     
    mapping (address => uint256) public released;

    ZerochainToken public token;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    bool public isActive = false;
    bool public canIssueIndividual = true;

    uint256 public constant AIRDROP_AMOUNT = 10 * (10 ** 10);
    string public constant UTILITY_ROLE = "utility";
    address public utilityAccount;
    uint256 public hardCap;

     
    function MultipleTokenVesting(
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        address _utilityAccount,
        uint256 _hardCap
    )
    public
    {
        require(_cliff <= _duration);
        require(_utilityAccount != address(0));
        require(_hardCap > 0);

        token = new ZerochainToken();
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;
        utilityAccount = _utilityAccount;
        addRole(_utilityAccount, UTILITY_ROLE);
        hardCap = _hardCap;
    }

    function changeUtilityAccount (
        address newAddress
    ) public onlyOwner {
        require(newAddress != address(0));
        removeRole(utilityAccount, UTILITY_ROLE);
        utilityAccount = newAddress;
        addRole(utilityAccount, UTILITY_ROLE);
    }

    function activate() public onlyOwner {
        require(!isActive);
        isActive = true;
        Activated();
    }

    function finalise() public onlyOwner {
        token.finishMinting();
        VestingFinished();
    }

    function stopIssuingIndividualTokens() public onlyOwner {
        require(canIssueIndividual);
        canIssueIndividual = false;
    }

    function issueIndividualTokens(
        address beneficiary,
        uint256 amount
    ) public onlyOwner {
        require(beneficiary != address(0));
        require(amount != 0);
        require(canIssueIndividual);
        require(token.totalSupply().add(amount) <= hardCap);

        token.mint(beneficiary, amount);
    }

     
    function addVestingForBeneficiaries(
        address[] _beneficiaries,
        uint256[] _amounts
    ) public onlyRole(UTILITY_ROLE) whenNotPaused {
        require(_beneficiaries.length == _amounts.length);
        for (uint i = 0; i < _beneficiaries.length; i++) {
            addVestingForBeneficiary(_beneficiaries[i], _amounts[i]);
        }
    }

    function releaseMultiple(
        address[] _beneficiaries
    ) public onlyRole(UTILITY_ROLE) whenNotPaused {
        require(isActive);
        for (uint i = 0; i < _beneficiaries.length; i++) {
            release(_beneficiaries[i]);
        }
    }

    function airdropMultiple(
        address[] _beneficiaries
    ) public onlyRole(UTILITY_ROLE) whenNotPaused {
        require(isActive);
        require(block.timestamp >= cliff);
        for (uint i = 0; i < _beneficiaries.length; i++) {
            require(_beneficiaries[i] != address(0));
            airdrop(_beneficiaries[i]);
        }
    }

     
    function releasableAmount() public view returns (uint256) {
        return _releasableAmount(msg.sender);
    }

     
    function vestedAmount() public view returns (uint256) {
        return _vestedAmount(msg.sender);
    }

     
    function release(
        address beneficiary
    ) internal {

        uint256 unreleased = _releasableAmount(beneficiary);

        require(unreleased > 0);

        released[beneficiary] = released[beneficiary].add(unreleased);

        token.transfer(beneficiary, unreleased);

        Released(beneficiary, unreleased);
    }

    function _releasableAmount(
        address beneficiary
    ) internal view returns (uint256) {
        return _vestedAmount(beneficiary).sub(released[beneficiary]);
    }

    function addVestingForBeneficiary(
        address _beneficiary,
        uint256 _amount
    ) internal {
        require(_beneficiary != address(0));
        require(_amount > 0);
        require(beneficiaries[_beneficiary] == 0);
        require(token.totalSupply().add(_amount) <= hardCap);

        beneficiaries[_beneficiary] = _amount;
        token.mint(this, _amount);
        Vested(_beneficiary, _amount);
    }

    function airdrop(
        address _beneficiary
    ) internal {
        require(token.totalSupply().add(AIRDROP_AMOUNT) <= hardCap);

        token.mint(_beneficiary, AIRDROP_AMOUNT);
        Airdrop(_beneficiary);
    }

    function _vestedAmount(
        address beneficiary
    ) internal view returns (uint256) {
        uint256 totalBalance = beneficiaries[beneficiary];

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
}