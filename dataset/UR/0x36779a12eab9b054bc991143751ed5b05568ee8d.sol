 

 

pragma solidity ^0.5.11;

 
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

 

pragma solidity ^0.5.11;

 
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

 

pragma solidity ^0.5.11;



 
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

 

pragma solidity ^0.5.11;

 
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

 

pragma solidity ^0.5.11;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

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

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

pragma solidity ^0.5.11;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 

pragma solidity ^0.5.11;

 
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

 

pragma solidity ^0.5.11;



 
contract ERC884 is ERC20 {

     
    event VerifiedAddressAdded(
        address indexed addr,
        bytes32 hash,
        address indexed sender
    );

     
    event VerifiedAddressRemoved(address indexed addr, address indexed sender);

     
    event VerifiedAddressUpdated(
        address indexed addr,
        bytes32 oldHash,
        bytes32 hash,
        address indexed sender
    );

     
    event VerifiedAddressSuperseded(
        address indexed original,
        address indexed replacement,
        address indexed sender
    );

     
    function addVerified(address addr, bytes32 hash) public;

     
    function removeVerified(address addr) public;

     
    function updateVerified(address addr, bytes32 hash) public;

     
    function cancelAndReissue(address original, address replacement) public;
     

     

     
    function isVerified(address addr) public view returns (bool);

     
    function isHolder(address addr) public view returns (bool);

     
    function hasHash(address addr, bytes32 hash) public view returns (bool);

     
    function holderCount() public view returns (uint);

     
    function holderAt(uint256 index) public view returns (address);

     
    function isSuperseded(address addr) public view returns (bool);

     
    function getCurrentFor(address addr) public view returns (address);
}

 

pragma solidity ^0.5.11;





 
contract DwarvesFoundationGem is ERC884, ERC20Mintable, Ownable {
    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);

    string public name;
    string public symbol;
    uint256 public decimals;

    mapping(address => bytes32) private verified;
    mapping(address => address) private cancellations;
    mapping(address => uint256) private holderIndices;
    mapping(address => uint256) private restrictedStock;
    mapping(address => uint256) private restrictedStockSendTime;

    address[] public shareholders;

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        decimals = 0;
    }

     
    event TransferRestrictedStock(
        address  owner,
        address indexed receiver,
        uint256 indexed amount,
        uint256 indexed restrictedSendTime
    );

     
    event UpdateRestrictedStockSendTime(
        address indexed addr,
        uint256 indexed newRestrictedSendTime
    );

    modifier isVerifiedAddress(address addr) {
        require(verified[addr] != ZERO_BYTES);
        _;
    }

    modifier isShareholder(address addr) {
        require(holderIndices[addr] != 0);
        _;
    }

    modifier isNotShareholder(address addr) {
        require(holderIndices[addr] == 0);
        _;
    }

    modifier isNotCancelled(address addr) {
        require(cancellations[addr] == ZERO_ADDRESS);
        _;
    }

     
    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(verified[_to] != ZERO_BYTES);
         
         
        updateShareholders(_to);
        return super.mint(_to, _amount);
    }

     
    function holderCount()
        public
        onlyOwner
        view
        returns (uint)
    {
        return shareholders.length;
    }

     
    function holderAt(uint256 index)
        public
        onlyOwner
        view
        returns (address)
    {
        require(index < shareholders.length);
        return shareholders[index];
    }

     
    function addVerified(address addr, bytes32 hash)
        public
        onlyOwner
        isNotCancelled(addr)
    {
        require(addr != ZERO_ADDRESS);
        require(hash != ZERO_BYTES);
        require(verified[addr] == ZERO_BYTES);
        verified[addr] = hash;
        emit VerifiedAddressAdded(addr, hash, msg.sender);
    }

     
    function removeVerified(address addr)
        public
        onlyOwner
    {
        require(verified[addr] != ZERO_BYTES);
        require(availableBalanceOf(addr) == 0);
        verified[addr] = ZERO_BYTES;
        emit VerifiedAddressRemoved(addr, msg.sender);
    }

     
    function updateVerified(address addr, bytes32 hash)
        public
        onlyOwner
        isVerifiedAddress(addr)
    {
        require(hash != ZERO_BYTES);
        bytes32 oldHash = verified[addr];
        if (oldHash != hash) {
            verified[addr] = hash;
            emit VerifiedAddressUpdated(addr, oldHash, hash, msg.sender);
        }
    }

     
    function cancelAndReissue(address original, address replacement)
        public
        onlyOwner
        isShareholder(original)
        isNotShareholder(replacement)
        isVerifiedAddress(replacement)
    {
         
         
        verified[original] = ZERO_BYTES;
        cancellations[original] = replacement;
        uint256 holderIndex = holderIndices[original] - 1;
        shareholders[holderIndex] = replacement;
        holderIndices[replacement] = holderIndices[original];
        holderIndices[original] = 0;
        _transfer(original,replacement,balanceOf(original));
        uint256 restrict = restrictedStock[original];
        uint256 restrictTime = restrictedStockSendTime[original];
        restrictedStock[replacement] = restrict;
        restrictedStockSendTime[replacement] = restrictTime;
        restrictedStock[original] = 0;
        restrictedStockSendTime[original] = 0;
        emit VerifiedAddressSuperseded(original, replacement, msg.sender);
    }

     
    function transfer(address to, uint256 value)
        public
        isVerifiedAddress(to)
        returns (bool)
    {
        require(availableBalanceOf(msg.sender) >= value);
        updateShareholders(to);
        pruneRestrictStock(msg.sender, value);
        pruneShareholders(msg.sender, value);
        return super.transfer(to, value);
    }

     
     function transferRestrictedStock(address to, uint256 value, uint256 time)
        public
        onlyOwner
        isVerifiedAddress(to)
        returns (bool)
     {
        require(availableBalanceOf(msg.sender) >= value);
        require(verified[to] != ZERO_BYTES);
        restrictedStock[to] += value;
        if (restrictedStockSendTime[to] == 0) {
            restrictedStockSendTime[to] = time;
        }
        emit TransferRestrictedStock(msg.sender, to, value, time);
        return transfer(to, value);
     }

     
    function updateRestrictedStockSendTime(address to, uint256 time)
        public
        onlyOwner
        isVerifiedAddress(to)
        returns (bool)
    {
        restrictedStockSendTime[to] = time;
        emit UpdateRestrictedStockSendTime(to, time);
        return true;
    }

     
     function availableBalanceOf(address to) 
        public
        view
        isVerifiedAddress(to)
        returns (uint256)
     {
         uint256 all = balanceOf(to);
         uint256 restrict = 0;
         if (now < restrictedStockSendTime[to]) {
             restrict = restrictedStock[to];
         }

         return all - restrict;
     }

     
     function restrictedStockOf(address _owner)
        public
        view
        returns (uint256)
     {
        return restrictedStock[_owner];
     }

     
     function restrictedStockSendTimeOf(address _owner)
        public
        view
        returns (uint256)
     {
        return restrictedStockSendTime[_owner];
     }

     
    function transferFrom(address from, address to, uint256 value)
        public
        isVerifiedAddress(to)
        returns (bool)
    {
        require(availableBalanceOf(from) >= value);
        updateShareholders(to);
        pruneRestrictStock(msg.sender, value);
        pruneShareholders(from, value);
        return super.transferFrom(from, to, value);
    }

     
    function isVerified(address addr)
        public
        view
        returns (bool)
    {
        return verified[addr] != ZERO_BYTES;
    }

     
    function isHolder(address addr)
        public
        view
        returns (bool)
    {
        return holderIndices[addr] != 0;
    }

     
    function hasHash(address addr, bytes32 hash)
        public
        view
        returns (bool)
    {
        if (addr == ZERO_ADDRESS) {
            return false;
        }
        return verified[addr] == hash;
    }

     
    function isSuperseded(address addr)
        public
        view
        onlyOwner
        returns (bool)
    {
        return cancellations[addr] != ZERO_ADDRESS;
    }

     
    function getCurrentFor(address addr)
        public
        view
        onlyOwner
        returns (address)
    {
        return findCurrentFor(addr);
    }

     
    function findCurrentFor(address addr)
        internal
        view
        returns (address)
    {
        address candidate = cancellations[addr];
        if (candidate == ZERO_ADDRESS) {
            return addr;
        }
        return findCurrentFor(candidate);
    }

     
    function updateShareholders(address addr)
        internal
    {
        if (holderIndices[addr] == 0) {
            holderIndices[addr] = shareholders.push(addr);
        }
    }

     
    function pruneRestrictStock(address addr, uint256 value)
        internal 
    {
        uint256 restrict = restrictedStock[addr];
        if (restrict != 0) {
            if (now > restrictedStockSendTime[addr]) {
                if (value > restrict) {
                     
                    restrictedStock[addr] = 0;
                    restrictedStockSendTime[addr] = 0;
                } else {
                    restrictedStock[addr] = restrict - value;
                }
            }
        }
    }

     
    function pruneShareholders(address addr, uint256 value)
        internal
    {
        uint256 balance = balanceOf(addr) - value;
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
         
        shareholders[holderIndex] = lastHolder;
         
         
        holderIndices[lastHolder] = holderIndices[addr];
         
        shareholders.length--;
         
        holderIndices[addr] = 0;
         
        restrictedStockSendTime[addr] = 0;
    }
}