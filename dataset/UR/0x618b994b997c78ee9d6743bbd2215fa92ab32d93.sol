 

pragma solidity ^0.4.24;
 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}


contract MasterRole {
  using Roles for Roles.Role;

  event MasterAdded(address indexed account);
  event MasterRemoved(address indexed account);

  Roles.Role private masters;

  constructor() internal {
    _addMaster(msg.sender);
  }

  modifier onlyMaster() {
    require(isMaster(msg.sender));
    _;
  }

  function isMaster(address account) public view returns (bool) {
    return masters.has(account);
  }

  function addMaster(address account) public onlyMaster {
    _addMaster(account);
  }

  function renounceMaster() public {
    _removeMaster(msg.sender);
  }

  function _addMaster(address account) internal {
    masters.add(account);
    emit MasterAdded(account);
  }

  function _removeMaster(address account) internal {
    masters.remove(account);
    emit MasterRemoved(account);
  }
}

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
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

  event TransferWithData(
    address indexed from,
    address indexed to,
    bytes32 indexed data,
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

contract AddressMapper is MasterRole {
    
    event DoMap(address indexed src, bytes32 indexed target, string rawTarget);
    event DoMapAuto(address indexed src, bytes32 indexed target, string rawTarget);
    event UnMap(address indexed src);

    mapping (address => string) public mapper;

    modifier onlyNotSet(address src) {
        bytes memory tmpTargetBytes = bytes(mapper[src]);
        require(tmpTargetBytes.length == 0);
        _;
    }

    function()
        public
        payable
        onlyNotSet(msg.sender)
    {
        require(msg.value > 0);
        _doMapAuto(msg.sender, string(msg.data));
        msg.sender.transfer(msg.value);
    }

    function isAddressSet(address thisAddr)
        public
        view
        returns(bool)
    {
        bytes memory tmpTargetBytes = bytes(mapper[thisAddr]);
        if(tmpTargetBytes.length == 0) {
            return false;
        } else {
            return true;
        }
    }

    function _doMapAuto(address src, string target)
        internal
    {
        mapper[src] = target;
        bytes32 translated = _stringToBytes32(target);
        emit DoMapAuto(src, translated, target);
    }

    function doMap(address src, string target) 
        public
        onlyMaster
        onlyNotSet(src)
    {
        mapper[src] = target;
        bytes32 translated = _stringToBytes32(target);
        emit DoMap(src, translated, target);
    }

    function unMap(address src) 
        public
        onlyMaster
    {
        mapper[src] = "";
        emit UnMap(src);
    }

    function _stringToBytes32(string memory source) internal returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function submitTransaction(address destination, uint value, bytes data)
        public
        onlyMaster
    {
        external_call(destination, value, data.length, data);
    }

    function external_call(address destination, uint value, uint dataLength, bytes data) private returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)    
            let d := add(data, 32)  
            result := call(
                sub(gas, 34710),    
                                    
                                    
                destination,
                value,
                d,
                dataLength,         
                x,
                0                   
            )
        }
        return result;
    }
}

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) internal _allowed;

  uint256 private _totalSupply;

  AddressMapper public addressMapper;

  constructor(address addressMapperAddr) public {
    addressMapper = AddressMapper(addressMapperAddr);
  }

   
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

   
  function transferWithData(address to, uint256 value, bytes32 data) public returns (bool) {
    _transfer(msg.sender, to, value);
    emit TransferWithData(msg.sender, to, data, value);
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
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function transferFromWithData(
    address from,
    address to,
    uint256 value,
    bytes32 data
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    emit TransferWithData(from, to, data, value);
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
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 
contract ERC20Mintable is ERC20, MinterRole {

  constructor(address addressMapperAddr)
    ERC20(addressMapperAddr)
    public
  {}

   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

 
contract ERC20Capped is ERC20Mintable {

  event SetIsPreventedAddr(address indexed preventedAddr, bool hbool);

  uint256 private _cap;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  mapping ( address => bool ) public isPreventedAddr;

  function transfer(address to, uint256 value) public returns (bool) {
    _checkedTransfer(msg.sender, to, value);
    return true;
  }

  function transferWithData(address to, uint256 value, bytes32 data) public returns (bool) {
    _checkedTransfer(msg.sender, to, value);
    emit TransferWithData(msg.sender, to, data, value);
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
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _checkedTransfer(from, to, value);
    return true;
  }

  function transferFromWithData(
    address from,
    address to,
    uint256 value,
    bytes32 data
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _checkedTransfer(from, to, value);
    emit TransferWithData(from, to, data, value);
    return true;
  }

  function _checkedTransfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    
    if(isPreventedAddr[to]) {
      require(addressMapper.isAddressSet(from));
    }

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  function setIsPreventedAddr(address thisAddr, bool hbool)
    public
    onlyMinter
  {
    isPreventedAddr[thisAddr] = hbool;
    emit SetIsPreventedAddr(thisAddr, hbool);
  }

  constructor(address addressMapperAddr, uint256 cap, string name, string symbol, uint8 decimals)
    ERC20Mintable(addressMapperAddr)
    public
  {
    require(cap > 0);
    _cap = cap;
    _name = name;
    _symbol = symbol;
    _decimals = decimals;

  }

   
  function cap() public view returns(uint256) {
    return _cap;
  }

  function _mint(address account, uint256 value) internal {
    require(totalSupply().add(value) <= _cap);
    super._mint(account, value);
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
  
}