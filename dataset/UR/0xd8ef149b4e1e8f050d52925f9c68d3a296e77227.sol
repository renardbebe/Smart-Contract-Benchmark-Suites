 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

contract Administratable is Ownable {
	mapping (address => bool) public superAdmins;

	event AddSuperAdmin(address indexed admin);
	event RemoveSuperAdmin(address indexed admin);

    modifier validateAddress( address _addr )
    {
        require(_addr != address(0x0));
        require(_addr != address(this));
        _;
    }

	modifier onlySuperAdmins {
		require(msg.sender == owner() || superAdmins[msg.sender]);
		_;
	}

	function addSuperAdmin(address _admin) public onlyOwner validateAddress(_admin){
		require(!superAdmins[_admin]);
		superAdmins[_admin] = true;
		emit AddSuperAdmin(_admin);
	}

	function removeSuperAdmin(address _admin) public onlyOwner validateAddress(_admin){
		require(superAdmins[_admin]);
		superAdmins[_admin] = false;
		emit RemoveSuperAdmin(_admin);
	}
}

 

 
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

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
contract ERC20 is IERC20 {
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
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
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
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
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

   
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

   
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}

 

 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }

   
  function _burn(address who, uint256 value) internal {
    super._burn(who, value);
  }
}

 

contract Whitelistable is Administratable {
    event WhitelistedTransferer(address indexed _transferer, bool _allowTransfer);
	mapping (address => bool) public whitelistedTransferer;

    function setWhitelistedTransferer(address _transferer, bool _allowTransfer) public onlySuperAdmins validateAddress(_transferer) returns (bool) {
        require(_allowTransfer != whitelistedTransferer[_transferer]);
        whitelistedTransferer[_transferer] = _allowTransfer;
        emit WhitelistedTransferer(_transferer, _allowTransfer);
        return true;
    }
}

 

contract Freezable is Whitelistable {
    bool public frozenToken;
    mapping (address => bool) public frozenAccounts;

    event FrozenFunds(address indexed _target, bool _frozen);
    event FrozenToken(bool _frozen);

    modifier isNotFrozen( address _to ) {
        require(!frozenToken);
        require(whitelistedTransferer[_to] || (!frozenAccounts[msg.sender] && !frozenAccounts[_to]));
        _;
    }

    modifier isNotFrozenFrom( address _from, address _to ) {
        require(!frozenToken);
        require(whitelistedTransferer[_to] || (!frozenAccounts[msg.sender] && !frozenAccounts[_from] && !frozenAccounts[_to]));
        _;
    }

    function freezeAccount(address _target, bool _freeze) public onlySuperAdmins validateAddress(_target) {
        require(frozenAccounts[_target] != _freeze);
        frozenAccounts[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    function freezeToken(bool _freeze) public onlySuperAdmins {
        require(frozenToken != _freeze);
        frozenToken = _freeze;
        emit FrozenToken(frozenToken);
    }
}

 

 
pragma solidity ^0.4.24;


contract TimeLockable is Whitelistable {
    mapping (address => uint256) public timelockedAccounts;
    event LockedFunds(address indexed target, uint256 timelocked);

    modifier isNotTimeLocked( address _addr ) {
        require( whitelistedTransferer[_addr] || (now >= timelockedAccounts[msg.sender]));
        _;
    }

    modifier isNotTimeLockedFrom( address _from, address _to) {
        require( whitelistedTransferer[_to] || ( now >= timelockedAccounts[_from] && now >= timelockedAccounts[msg.sender]));
        _;
    }
    
    function timeLockAccount(address _target, uint256 _releaseTime) public onlySuperAdmins validateAddress(_target) {
        require(_releaseTime > now);
        require(timelockedAccounts[_target] != _releaseTime);

        timelockedAccounts[_target] = _releaseTime;
        emit LockedFunds(_target, _releaseTime);
    }
}

 

contract BLUCON is ERC20Burnable, Freezable, TimeLockable
{
    string  public  constant name       = "BLUCON";
    string  public  constant symbol     = "BEP";
    uint8   public  constant decimals   = 18;
    
    event Burn(address indexed _burner, uint256 _value);

    constructor( address _registry, uint256 _totalTokenAmount ) public
    {
        _mint(_registry, _totalTokenAmount);
        addSuperAdmin(_registry);
    }

    function transfer(address _to, uint256 _value) public validateAddress(_to) isNotTimeLocked(_to) isNotFrozen(_to) returns (bool) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public validateAddress(_to) isNotTimeLockedFrom(_from, _to) isNotFrozenFrom(_from, _to) returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public validateAddress(_spender) isNotFrozen(_spender) isNotTimeLocked(_spender) returns (bool) 
    {
        return super.approve(_spender, _value);
    }

    function increaseAllowance( address _spender, uint256 _addedValue ) public validateAddress(_spender) isNotFrozen(_spender) isNotTimeLocked(_spender) returns (bool)
    {
        return super.increaseAllowance(_spender, _addedValue);
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public validateAddress(_spender) isNotFrozen(_spender) isNotTimeLocked(_spender) returns (bool)
    {
        return super.decreaseAllowance(_spender, _subtractedValue);
    }
}

 

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}