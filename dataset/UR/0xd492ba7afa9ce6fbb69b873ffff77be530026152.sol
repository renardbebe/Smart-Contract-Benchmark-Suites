 

 

pragma solidity 0.5.12;

contract ITransferRules {
     
     
     
     
     
    function detectTransferRestriction(
        address token,
        address from,
        address to,
        uint256 value
    ) external view returns (uint8);

     
     
     
    function messageForTransferRestriction(uint8 restrictionCode)
        external
        view
        returns (string memory);

    function checkSuccess(uint8 restrictionCode) external view returns (bool);
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

pragma solidity 0.5.12;




 
 
 
contract RestrictedToken is ERC20 {
  using SafeMath for uint256;

  string public symbol;
  string public name;
  uint8 public decimals;
  ITransferRules public transferRules;

  using Roles for Roles.Role;
  Roles.Role private _contractAdmins;
  Roles.Role private _transferAdmins;

  uint256 public maxTotalSupply;
  uint256 public contractAdminCount;

   
   
  mapping(address => uint256) private _maxBalances;
  mapping(address => uint256) private _lockUntil;  
  mapping(address => uint256) private _transferGroups;  
  mapping(uint256 => mapping(uint256 => uint256)) private _allowGroupTransfers;  
  mapping(address => bool) private _frozenAddresses;

  bool public isPaused = false;

  uint256 public constant MAX_UINT256 = ((2 ** 255 - 1) * 2) + 1;  

  event RoleChange(address indexed grantor, address indexed grantee, string role, bool indexed status);
  event AddressMaxBalance(address indexed admin, address indexed addr, uint256 indexed value);
  event AddressTimeLock(address indexed admin, address indexed addr, uint256 indexed value);
  event AddressTransferGroup(address indexed admin, address indexed addr, uint256 indexed value);
  event AddressFrozen(address indexed admin, address indexed addr, bool indexed status);
  event AllowGroupTransfer(address indexed admin, uint256 indexed fromGroup, uint256 indexed toGroup, uint256 lockedUntil);

  event Pause(address admin, bool status);
  event Upgrade(address admin, address oldRules, address newRules);

  constructor(
    address transferRules_,
    address contractAdmin_,
    address tokenReserveAdmin_,
    string memory symbol_,
    string memory name_,
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 maxTotalSupply_
  ) public {
    require(transferRules_ != address(0), "Transfer rules address cannot be 0x0");
    require(contractAdmin_ != address(0), "Token owner address cannot be 0x0");
    require(tokenReserveAdmin_ != address(0), "Token reserve admin address cannot be 0x0");

     
     
    transferRules = ITransferRules(transferRules_);
    symbol = symbol_;
    name = name_;
    decimals = decimals_;
    maxTotalSupply = maxTotalSupply_;

    _contractAdmins.add(contractAdmin_);
    contractAdminCount = 1;

    _mint(tokenReserveAdmin_, totalSupply_);
  }

  modifier onlyContractAdmin() {
    require(_contractAdmins.has(msg.sender), "DOES NOT HAVE CONTRACT OWNER ROLE");
    _;
  }

   modifier onlyTransferAdmin() {
    require(_transferAdmins.has(msg.sender), "DOES NOT HAVE TRANSFER ADMIN ROLE");
    _;
  }

  modifier onlyTransferAdminOrContractAdmin() {
    require((_contractAdmins.has(msg.sender) || _transferAdmins.has(msg.sender)),
    "DOES NOT HAVE TRANSFER ADMIN OR CONTRACT ADMIN ROLE");
    _;
  }

  modifier validAddress(address addr) {
    require(addr != address(0), "Address cannot be 0x0");
    _;
  }

   
   
  function grantTransferAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    _transferAdmins.add(addr);
    emit RoleChange(msg.sender, addr, "TransferAdmin", true);
  }

   
   
  function revokeTransferAdmin(address addr) external validAddress(addr) onlyContractAdmin  {
    _transferAdmins.remove(addr);
    emit RoleChange(msg.sender, addr, "TransferAdmin", false);
  }

   
   
   
  function checkTransferAdmin(address addr) external view returns(bool hasPermission) {
    return _transferAdmins.has(addr);
  }

   
   
   
  function grantContractAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    _contractAdmins.add(addr);
    contractAdminCount = contractAdminCount.add(1);
    emit RoleChange(msg.sender, addr, "ContractAdmin", true);
  }

   
   
   
  function revokeContractAdmin(address addr) external validAddress(addr) onlyContractAdmin {
    require(contractAdminCount > 1, "Must have at least one contract admin");
    _contractAdmins.remove(addr);
    contractAdminCount = contractAdminCount.sub(1);
    emit RoleChange(msg.sender, addr, "ContractAdmin", false);
  }

   
   
   
  function checkContractAdmin(address addr) external view returns(bool hasPermission) {
    return _contractAdmins.has(addr);
  }

   
   
   
   
   
   
  function enforceTransferRestrictions(address from, address to, uint256 value) private view {
    uint8 restrictionCode = detectTransferRestriction(from, to, value);
    require(transferRules.checkSuccess(restrictionCode), messageForTransferRestriction(restrictionCode));
  }

   
   
   
   
   
  function detectTransferRestriction(address from, address to, uint256 value) public view returns(uint8) {
    return transferRules.detectTransferRestriction(address(this), from, to, value);
  }

   
   
  function messageForTransferRestriction(uint8 restrictionCode) public view returns(string memory) {
    return transferRules.messageForTransferRestriction(restrictionCode);
  }

   
   
   
   
  function setMaxBalance(address addr, uint256 updatedValue) public validAddress(addr) onlyTransferAdmin {
    _maxBalances[addr] = updatedValue;
    emit AddressMaxBalance(msg.sender, addr, updatedValue);
  }

   
   
  function getMaxBalance(address addr) external view returns(uint256) {
    return _maxBalances[addr];
  }

   
   
   
   
  function setLockUntil(address addr, uint256 timestamp) public validAddress(addr)  onlyTransferAdmin {
    _lockUntil[addr] = timestamp;
    emit AddressTimeLock(msg.sender, addr, timestamp);
  }
   
   
   
  function removeLockUntil(address addr) external validAddress(addr) onlyTransferAdmin {
    _lockUntil[addr] = 0;
    emit AddressTimeLock(msg.sender, addr, 0);
  }

   
   
   
   
  function getLockUntil(address addr) external view returns(uint256 timestamp) {
    return _lockUntil[addr];
  }

   
   
   
  function setTransferGroup(address addr, uint256 groupID) public validAddress(addr) onlyTransferAdmin {
    _transferGroups[addr] = groupID;
    emit AddressTransferGroup(msg.sender, addr, groupID);
  }

   
   
   
  function getTransferGroup(address addr) external view returns(uint256 groupID) {
    return _transferGroups[addr];
  }

   
   
   
   
  function freeze(address addr, bool status) public validAddress(addr)  onlyTransferAdminOrContractAdmin {
    _frozenAddresses[addr] = status;
    emit AddressFrozen(msg.sender, addr, status);
  }

   
   
   
  function getFrozenStatus(address addr) external view returns(bool status) {
    return _frozenAddresses[addr];
  }

   
   
   
   
   
   
   
   
  function setAddressPermissions(address addr, uint256 groupID, uint256 timeLockUntil,
    uint256 maxBalance, bool status) public validAddress(addr) onlyTransferAdmin {
    setTransferGroup(addr, groupID);
    setLockUntil(addr, timeLockUntil);
    setMaxBalance(addr, maxBalance);
    freeze(addr, status);
  }

   
   
   
   
   
   
   
  function setAllowGroupTransfer(uint256 from, uint256 to, uint256 lockedUntil) external onlyTransferAdmin {
    _allowGroupTransfers[from][to] = lockedUntil;
    emit AllowGroupTransfer(msg.sender, from, to, lockedUntil);
  }

   
   
   
   
   
  function getAllowTransferTime(address from, address to) external view returns(uint timestamp) {
    return _allowGroupTransfers[_transferGroups[from]][_transferGroups[to]];
  }

   
   
   
   
   
  function getAllowGroupTransferTime(uint from, uint to) external view returns(uint timestamp) {
    return _allowGroupTransfers[from][to];
  }

   
   
   
  function burn(address from, uint256 value) external validAddress(from) onlyContractAdmin {
    require(value <= balanceOf(from), "Insufficent tokens to burn");
    _burn(from, value);
  }

   
   
   
   
  function mint(address to, uint256 value) external validAddress(to) onlyContractAdmin  {
    require(SafeMath.add(totalSupply(), value) <= maxTotalSupply, "Cannot mint more than the max total supply");
    _mint(to, value);
  }

   
  function pause() external onlyContractAdmin() {
    isPaused = true;
    emit Pause(msg.sender, true);
  }

   
  function unpause() external onlyContractAdmin() {
    isPaused = false;
    emit Pause(msg.sender, false);
  }

   
   
   
  function upgradeTransferRules(ITransferRules newTransferRules) external onlyContractAdmin {
    require(address(newTransferRules) != address(0x0), "Address cannot be 0x0");
    address oldRules = address(transferRules);
    transferRules = newTransferRules;
    emit Upgrade(msg.sender, oldRules, address(newTransferRules));
  }

  function transfer(address to, uint256 value) public validAddress(to) returns(bool success) {
    require(value <= balanceOf(msg.sender), "Insufficent tokens");
    enforceTransferRestrictions(msg.sender, to, value);
    super.transfer(to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public validAddress(from) validAddress(to) returns(bool success) {
    require(value <= allowance(from, to), "The approved allowance is lower than the transfer amount");
    require(value <= balanceOf(from), "Insufficent tokens");
    enforceTransferRestrictions(from, to, value);
    super.transferFrom(from, to, value);
    return true;
  }

  function safeApprove(address spender, uint256 value) public {
     
     
     
    require((value == 0) || (allowance(address(msg.sender), spender) == 0),
        "Cannot approve from non-zero to non-zero allowance"
    );
    approve(spender, value);
  }
}

 

pragma solidity 0.5.12;




contract TransferRules is ITransferRules {
    using SafeMath for uint256;
    mapping(uint8 => string) internal errorMessage;

    uint8 public constant SUCCESS = 0;
    uint8 public constant GREATER_THAN_RECIPIENT_MAX_BALANCE = 1;
    uint8 public constant SENDER_TOKENS_TIME_LOCKED = 2;
    uint8 public constant DO_NOT_SEND_TO_TOKEN_CONTRACT = 3;
    uint8 public constant DO_NOT_SEND_TO_EMPTY_ADDRESS = 4;
    uint8 public constant SENDER_ADDRESS_FROZEN = 5;
    uint8 public constant ALL_TRANSFERS_PAUSED = 6;
    uint8 public constant TRANSFER_GROUP_NOT_APPROVED = 7;
    uint8 public constant TRANSFER_GROUP_NOT_ALLOWED_UNTIL_LATER = 8;

  constructor() public {
    errorMessage[SUCCESS] = "SUCCESS";
    errorMessage[GREATER_THAN_RECIPIENT_MAX_BALANCE] = "GREATER THAN RECIPIENT MAX BALANCE";
    errorMessage[SENDER_TOKENS_TIME_LOCKED] = "SENDER TOKENS LOCKED";
    errorMessage[DO_NOT_SEND_TO_TOKEN_CONTRACT] = "DO NOT SEND TO TOKEN CONTRACT";
    errorMessage[DO_NOT_SEND_TO_EMPTY_ADDRESS] = "DO NOT SEND TO EMPTY ADDRESS";
    errorMessage[SENDER_ADDRESS_FROZEN] = "SENDER ADDRESS IS FROZEN";
    errorMessage[ALL_TRANSFERS_PAUSED] = "ALL TRANSFERS PAUSED";
    errorMessage[TRANSFER_GROUP_NOT_APPROVED] = "TRANSFER GROUP NOT APPROVED";
    errorMessage[TRANSFER_GROUP_NOT_ALLOWED_UNTIL_LATER] = "TRANSFER GROUP NOT ALLOWED UNTIL LATER";
  }

   
   
   
   
   
  function detectTransferRestriction(address _token, address from, address to, uint256 value) external view returns(uint8) {
    RestrictedToken token = RestrictedToken(_token);
    if (token.isPaused()) return ALL_TRANSFERS_PAUSED;
    if (to == address(0)) return DO_NOT_SEND_TO_EMPTY_ADDRESS;
    if (to == address(token)) return DO_NOT_SEND_TO_TOKEN_CONTRACT;

    if (token.balanceOf(to).add(value) > token.getMaxBalance(to)) return GREATER_THAN_RECIPIENT_MAX_BALANCE;
    if (now < token.getLockUntil(from)) return SENDER_TOKENS_TIME_LOCKED;
    if (token.getFrozenStatus(from)) return SENDER_ADDRESS_FROZEN;

    uint256 lockedUntil = token.getAllowTransferTime(from, to);
    if (0 == lockedUntil) return TRANSFER_GROUP_NOT_APPROVED;
    if (now < lockedUntil) return TRANSFER_GROUP_NOT_ALLOWED_UNTIL_LATER;

    return SUCCESS;
  }

   
   
   
  function messageForTransferRestriction(uint8 restrictionCode) external view returns(string memory) {
    return errorMessage[restrictionCode];
  }

   
   
   
   
   
   
  function checkSuccess(uint8 restrictionCode) external view returns(bool isSuccess) {
    return restrictionCode == SUCCESS;
  }
}