 

pragma solidity 0.5.0;
 


 
interface IERC777 {
     
    function name() external view returns (string memory);

     
    function symbol() external view returns (string memory);

     
    function granularity() external view returns (uint256);

     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address owner) external view returns (uint256);

     
    function send(address recipient, uint256 amount, bytes calldata data) external;

     
    function burn(uint256 amount, bytes calldata data) external;

     
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

     
    function authorizeOperator(address operator) external;

     
    function revokeOperator(address operator) external;

     
    function defaultOperators() external view returns (address[] memory);

     
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

     
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

 


 
interface IERC777Recipient {
     
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

 


 
interface IERC777Sender {
     
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

 


 
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

 


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 


 
interface IERC1820Registry {
     
    function setManager(address account, address newManager) external;

     
    function getManager(address account) external view returns (address);

     
    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

     
    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

     
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

     
    function updateERC165Cache(address account, bytes4 interfaceId) external;

     
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

     
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

 









contract EarnERC777 is IERC777, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    uint256 constant RATE_SCALE = 10**18;

    IERC1820Registry internal _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) internal _balances;

    uint256 internal _totalShadow;
    uint256 internal _exchangeRate;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

     
     

     
    bytes32 constant internal TOKENS_SENDER_INTERFACE_HASH =
        0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;

     
    bytes32 constant internal TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

     
    address[] internal _defaultOperatorsArray;

     
    mapping(address => mapping(address => bool)) internal _operators;

     
    mapping (address => mapping (address => uint256)) internal _allowances;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        require(decimals <= 18, "decimals must be less or equal than 18");

        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        _exchangeRate = RATE_SCALE;

         
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function decimals() external view returns (uint8) {
        return _decimals;
    }

     
    function granularity() external view returns (uint256) {
        return 1;
    }

     
    function totalSupply() external view returns (uint256) {
        return _calculateValue(_totalShadow);
    }

    function totalShadow() external view returns (uint256) {
        return _totalShadow;
    }

     
    function balanceOf(address who) external view returns (uint256) {
        return _calculateValue(_balances[who]);
    }

    function shadowOf(address who) external view returns (uint256) {
        return _balances[who];
    }

    function _calculateValue(uint256 shadow) internal view returns (uint256) {
         return shadow.mul(_exchangeRate).div(RATE_SCALE);
    }

    function _calculateShadow(uint256 value) internal view returns (uint256) {
        return value.mul(RATE_SCALE).div(_exchangeRate);
    }

     
    function send(address recipient, uint256 amount, bytes calldata data) external {
        _send(msg.sender, msg.sender, recipient, amount, data, "", true);
    }

     
    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(recipient, amount);
    }

    function _transfer(address recipient, uint256 amount) internal returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = msg.sender;

        uint256 shadow = _calculateShadow(amount);
        uint256 realAmount = _calculateValue(shadow);

        _callTokensToSend(from, from, recipient, realAmount, "", "");

        _move(from, from, recipient, shadow, realAmount, "", "");

        _callTokensReceived(from, from, recipient, realAmount, "", "", false);

        return true;
    }

     
    function burn(uint256 amount, bytes calldata data) external {
        _burn(msg.sender, msg.sender, amount, data, "");
    }

     
    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return operator == tokenHolder ||
            _operators[tokenHolder][operator];
    }

     
    function authorizeOperator(address operator) external {
        require(msg.sender != operator, "ERC777: authorizing self as operator");

       _operators[msg.sender][operator] = true;

        emit AuthorizedOperator(operator, msg.sender);
    }

     
    function revokeOperator(address operator) external {
        require(operator != msg.sender, "ERC777: revoking self as operator");

        delete _operators[msg.sender][operator];

        emit RevokedOperator(operator, msg.sender);
    }

     
    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperatorsArray;
    }

     
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        _send(msg.sender, sender, recipient, amount, data, operatorData, true);
    }

     
    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData) external {
        require(isOperatorFor(msg.sender, account), "ERC777: caller is not an operator for holder");
        _burn(msg.sender, account, amount, data, operatorData);
    }

     
    function allowance(address holder, address spender) external view returns (uint256) {
        return _allowances[holder][spender];
    }

     
    function approve(address spender, uint256 value) external returns (bool) {
        address holder = msg.sender;
        _approve(holder, spender, value);
        return true;
    }

    
    function transferFrom(address holder, address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(holder, recipient, amount);
    }

    function _transferFrom(address holder, address recipient, uint256 amount) internal returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = msg.sender;

        uint256 shadow = _calculateShadow(amount);
        uint256 realAmount = _calculateValue(shadow);

        _callTokensToSend(spender, holder, recipient, realAmount, "", "");

        _move(spender, holder, recipient, shadow, realAmount, "", "");
        _approve(holder, spender, _allowances[holder][spender].sub(realAmount));

        _callTokensReceived(spender, holder, recipient, realAmount, "", "", false);

        return true;
    }

     
    function _mint(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
    internal
    {
        require(account != address(0), "ERC777: mint to the zero address");

        uint shadow = _calculateShadow(amount);
        uint realAmount = _calculateValue(shadow);

         
        _totalShadow = _totalShadow.add(shadow);
        _balances[account] = _balances[account].add(shadow);

        _callTokensReceived(operator, address(0), account, realAmount, userData, operatorData, false);

        emit Minted(operator, account, realAmount, userData, operatorData);
        emit Transfer(address(0), account, realAmount);
    }

     
    function _send(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        internal
    {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        uint256 shadow = _calculateShadow(amount);
        uint256 realAmount = _calculateValue(shadow);

        _callTokensToSend(operator, from, to, realAmount, userData, operatorData);

        _move(operator, from, to, shadow, realAmount, userData, operatorData);

        _callTokensReceived(operator, from, to, realAmount, userData, operatorData, requireReceptionAck);
    }

     
    function _burn(
        address operator,
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    )
        internal
    {
        require(from != address(0), "ERC777: burn from the zero address");

        uint256 shadow = _calculateShadow(amount);
        uint256 realAmount = _calculateValue(shadow);

        _callTokensToSend(operator, from, address(0), realAmount, data, operatorData);

         
        _totalShadow = _totalShadow.sub(shadow);
        _balances[from] = _balances[from].sub(shadow);

        emit Burned(operator, from, realAmount, data, operatorData);
        emit Transfer(from, address(0), realAmount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 shadow,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        internal
    {
        _balances[from] = _balances[from].sub(shadow);
        _balances[to] = _balances[to].add(shadow);

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    function _approve(address holder, address spender, uint256 value) internal {
         
         
         
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

     
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        internal
    {
        address implementer = _erc1820.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

     
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        internal
    {
        address implementer = _erc1820.getInterfaceImplementer(to, TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    function _distributeRevenue(address account) internal returns (bool) {
        uint256 shadow = _balances[account];

        require(_totalShadow != 0, 'Token: total shadow must be zero');
        require(shadow > 0, 'Token: the revenue must large than 0');

        uint256 value = _calculateValue(shadow);

        _balances[account] = 0;
        _totalShadow = _totalShadow.sub(shadow);
        _exchangeRate = _exchangeRate.add(value.mul(RATE_SCALE).div(_totalShadow));

        emit Transfer(account, address(0), value);
        emit RevenueDistributed(account, value);

        return true;
    }

    function exchangeRate() external view returns (uint256) {
        return _exchangeRate;
    }

    event RevenueDistributed(address indexed account, uint256 value);
}

 


 
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

 


 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 




 contract MinterRole is Ownable {
     using Roles for Roles.Role;

     event MinterAdded(address indexed operator, address indexed account);
     event MinterRemoved(address indexed operator, address indexed account);

     Roles.Role private _minters;

     constructor () internal {
         _addMinter(msg.sender);
     }

     modifier onlyMinter() {
         require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
         _;
     }

     function isMinter(address account) public view returns (bool) {
         return _minters.has(account);
     }

     function addMinter(address account) public onlyOwner {
         _addMinter(account);
     }

     function removeMinter(address account) public onlyOwner {
         _removeMinter(account);
     }

     function _addMinter(address account) internal {
         _minters.add(account);
         emit MinterAdded(msg.sender, account);
     }

     function _removeMinter(address account) internal {
         _minters.remove(account);
         emit MinterRemoved(msg.sender, account);
     }
 }

 



 
contract Pausable is Ownable {
     
    event Paused(address indexed account);

     
    event Unpaused(address indexed account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 



contract SwitchTransferable is Ownable {
    event TransferEnabled(address indexed operator);
    event TransferDisabled(address indexed operator);

    bool private _transferable;

    constructor () internal {
        _transferable = false;
    }

    modifier whenTransferable() {
        require(_transferable, "transferable must be true");
        _;
    }

    modifier whenNotTransferable() {
        require(!_transferable, "transferable must not be true");
        _;
    }

    function transferable() public view returns (bool) {
        return _transferable;
    }

    function enableTransfer() public onlyOwner whenNotTransferable {
        _transferable = true;
        emit TransferEnabled(msg.sender);
    }

    function disableTransfer() public onlyOwner whenTransferable {
        _transferable = false;
        emit TransferDisabled(msg.sender);
    }
}

 






contract IMBTC is EarnERC777, MinterRole, Pausable, SwitchTransferable {
    address internal _revenueAddress;

    constructor() EarnERC777("IMBTC","IMBTC",8) public {
    }

    function transfer(address recipient, uint256 amount) external whenNotPaused whenTransferable returns (bool) {
        return super._transfer(recipient, amount);
    }

    function send(address recipient, uint256 amount, bytes calldata data) external whenTransferable whenNotPaused {
        super._send(msg.sender, msg.sender, recipient, amount, data, "", true);
    }

    function burn(uint256 amount, bytes calldata data) external whenTransferable whenNotPaused {
        super._burn(msg.sender, msg.sender, amount, data, "");
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external whenTransferable whenNotPaused {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        super._send(msg.sender, sender, recipient, amount, data, operatorData, true);
    }

    function operatorBurn(address account, uint256 amount, bytes calldata data, bytes calldata operatorData)
        external whenTransferable whenNotPaused {
        require(isOperatorFor(msg.sender, account), "ERC777: caller is not an operator for holder");
        super._burn(msg.sender, account, amount, data, operatorData);
    }

    function mint(address recipient, uint256 amount,
            bytes calldata userData, bytes calldata operatorData) external onlyMinter whenNotPaused {
        super._mint(msg.sender, recipient, amount, userData, operatorData);
    }

    function transferFrom(address holder, address recipient, uint256 amount) external whenNotPaused returns (bool) {
        require(transferable(), "Token: transferable must be true");
        return super._transferFrom(holder, recipient, amount);
   }

   function setRevenueAddress(address account) external onlyOwner {
       _revenueAddress = account;

       emit RevenueAddressSet(account);
   }

   function revenueAddress() external view returns (address) {
       return _revenueAddress;
   }

   function revenue() external view returns (uint256) {
       return _calculateValue(_balances[_revenueAddress]);
   }

   event RevenueAddressSet(address indexed account);

   function distributeRevenue() external whenNotPaused {
       require(_revenueAddress != address(0), 'Token: revenue address must not be zero');

       _distributeRevenue(_revenueAddress);
   }
}