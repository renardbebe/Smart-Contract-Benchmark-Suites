 

 
pragma solidity 0.5.11;

 
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


 
library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
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

 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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


interface ITokenReceiver {
    function tokensReceived(
        address from,
        address to,
        uint256 amount
    ) external;
}


interface ITokenMigrator {
    function migrate(address from, address to, uint256 amount) external returns (bool);
}

contract TokenRecoverable is Ownable {
    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token, address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Given amount is larger than current balance");
        token.safeTransfer(to, amount);
    }
}

contract Burner is TokenRecoverable, ITokenReceiver {
    address payable public token;

    address public migrator;

    constructor(address payable _token) public TokenRecoverable() {
        token = _token;
    }

    function setMigrator(address _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function tokensReceived(address from, address to, uint256 amount) external {
        require(token != address(0), "Burner is not initialized");
        require(msg.sender == token, "Only Parsiq Token can notify");
        require(ParsiqToken(token).burningEnabled(), "Burning is disabled");
        if (migrator != address(0)) {
            ITokenMigrator(migrator).migrate(from, to, amount);
        }
        ParsiqToken(token).burn(amount);
    }
}


contract ParsiqToken is TokenRecoverable, ERC20 {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Address for address;

    uint256 internal constant MAX_UINT256 = ~uint256(0);
    uint256 internal constant TOTAL_TOKENS = 500000000e18;  
    string public constant name = "Parsiq Token";
    string public constant symbol = "PRQ";
    uint8 public constant decimals = uint8(18);

    mapping(address => bool) public notify;
    mapping(address => Timelock[]) public timelocks;
    mapping(address => Timelock[]) public relativeTimelocks;
    mapping(bytes32 => bool) public hashedTxs;
    mapping(address => bool) public whitelisted;
    uint256 public transfersUnlockTime = MAX_UINT256;  
    address public burnerAddress;
    bool public burningEnabled;
    bool public etherlessTransferEnabled = true;

    struct Timelock {
        uint256 time;
        uint256 amount;
    }

    event TransferPreSigned(
        address indexed from,
        address indexed to,
        address indexed delegate,
        uint256 amount,
        uint256 fee);
    event TransferLocked(address indexed from, address indexed to, uint256 amount, uint256 until);
    event TransferLockedRelative(address indexed from, address indexed to, uint256 amount, uint256 duration);
    event Released(address indexed to, uint256 amount);
    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    modifier onlyWhenEtherlessTransferEnabled {
        require(etherlessTransferEnabled == true, "Etherless transfer functionality disabled");
        _;
    }
    
    modifier onlyBurner() {
        require(msg.sender == burnerAddress, "Only burnAddress can burn tokens");
        _;
    }

    modifier onlyWhenTransfersUnlocked(address from, address to) {
        require(
            transfersUnlockTime <= now ||
            whitelisted[from] == true ||
            whitelisted[to] == true, "Transfers locked");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender] == true, "Not whitelisted");
        _;
    }

    modifier notTokenAddress(address _address) {
        require(_address != address(this), "Cannot transfer to token contract");
        _;
    }

    modifier notBurnerUntilBurnIsEnabled(address _address) {
        require(burningEnabled == true || _address != burnerAddress, "Cannot transfer to burner address, until burning is not enabled");
        _;
    }

    constructor() public TokenRecoverable() {
        _mint(msg.sender, TOTAL_TOKENS);
        _addWhitelisted(msg.sender);
        burnerAddress = address(new Burner(address(this)));
        notify[burnerAddress] = true;  
        Burner(burnerAddress).transferOwnership(msg.sender);
    }

    function () external payable {
        _release(msg.sender);
        if (msg.value > 0) {
            msg.sender.transfer(msg.value);
        }
    }

    function register() public {
        notify[msg.sender] = true;
    }

    function unregister() public {
        notify[msg.sender] = false;
    }

    function enableEtherlessTransfer() public onlyOwner {
        etherlessTransferEnabled = true;
    }

    function disableEtherlessTransfer() public onlyOwner {
        etherlessTransferEnabled = false;
    }

    function addWhitelisted(address _address) public onlyOwner {
        _addWhitelisted(_address);
    }

    function removeWhitelisted(address _address) public onlyOwner {
        _removeWhitelisted(_address);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(msg.sender);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _removeWhitelisted(owner());
        super.transferOwnership(newOwner);
        _addWhitelisted(newOwner);
    }

    function renounceOwnership() public onlyOwner {
        renounceWhitelisted();
        super.renounceOwnership();
    }

    function unlockTransfers(uint256 when) public onlyOwner {
        require(transfersUnlockTime == MAX_UINT256, "Transfers already unlocked");
        require(when >= now, "Transfer unlock must not be in past");
        transfersUnlockTime = when;
    }

    function transfer(address to, uint256 value) public
        onlyWhenTransfersUnlocked(msg.sender, to)
        notTokenAddress(to)
        notBurnerUntilBurnIsEnabled(to)
        returns (bool)
    {
        bool success = super.transfer(to, value);
        if (success) {
            _postTransfer(msg.sender, to, value);
        }
        return success;
    }

    function transferFrom(address from, address to, uint256 value) public
        onlyWhenTransfersUnlocked(from, to)
        notTokenAddress(to)
        notBurnerUntilBurnIsEnabled(to)
        returns (bool)
    {
        bool success = super.transferFrom(from, to, value);
        if (success) {
            _postTransfer(from, to, value);
        }
        return success;
    }

     
    function transferBatch(address[] memory to, uint256[] memory value) public returns (bool) {
        require(to.length == value.length, "Array sizes must be equal");
        uint256 n = to.length;
        for (uint256 i = 0; i < n; i++) {
            transfer(to[i], value[i]);
        }
        return true;
    }

    function transferLocked(address to, uint256 value, uint256 until) public
        onlyWhitelisted
        notTokenAddress(to)
        returns (bool)
    {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value > 0, "Value must be positive");
        require(until > now, "Until must be future value");
        require(timelocks[to].length.add(relativeTimelocks[to].length) <= 100, "Too many locks on address");

        _transfer(msg.sender, address(this), value);

        timelocks[to].push(Timelock({ time: until, amount: value }));

        emit TransferLocked(msg.sender, to, value, until);
        return true;
    }

     
    function transferLockedRelative(address to, uint256 value, uint256 duration) public
        onlyWhitelisted
        notTokenAddress(to)
        returns (bool)
    {
        require(transfersUnlockTime > now, "Relative locks are disabled. Use transferLocked() instead");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value > 0, "Value must be positive");
        require(timelocks[to].length.add(relativeTimelocks[to].length) <= 100, "Too many locks on address");

        _transfer(msg.sender, address(this), value);

        relativeTimelocks[to].push(Timelock({ time: duration, amount: value }));

        emit TransferLockedRelative(msg.sender, to, value, duration);
        return true;
    }

    function release() public {
        _release(msg.sender);
    }

    function lockedBalanceOf(address who) public view returns (uint256) {
        return _lockedBalanceOf(timelocks[who])
            .add(_lockedBalanceOf(relativeTimelocks[who]));
    }
    
    function unlockableBalanceOf(address who) public view returns (uint256) {
        uint256 tokens = _unlockableBalanceOf(timelocks[who], 0);
        if (transfersUnlockTime > now) return tokens;

        return tokens.add(_unlockableBalanceOf(relativeTimelocks[who], transfersUnlockTime));
    }

    function totalBalanceOf(address who) public view returns (uint256) {
        return balanceOf(who).add(lockedBalanceOf(who));
    }

     
    function burn(uint256 value) public onlyBurner {
        _burn(msg.sender, value);
    }

    function enableBurning() public onlyOwner {
        burningEnabled = true;
    }

     
     
    function transferPreSigned(
        bytes memory _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        onlyWhenEtherlessTransferEnabled
        notTokenAddress(_to)
        notBurnerUntilBurnIsEnabled(_to)
        returns (bool)
    {
        require(_to != address(0), "Transfer to the zero address");

        bytes32 hashedParams = hashForSign(msg.sig, address(this), _to, _value, _fee, _nonce);
        address from = hashedParams.toEthSignedMessageHash().recover(_signature);
        require(from != address(0), "Invalid signature");

        require(
            transfersUnlockTime <= now ||
            whitelisted[from] == true ||
            whitelisted[_to] == true, "Transfers are locked");

        bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
        require(hashedTxs[hashedTx] == false, "Nonce already used");
        hashedTxs[hashedTx] = true;

        if (msg.sender == _to) {
            _transfer(from, _to, _value.add(_fee));
            _postTransfer(from, _to, _value.add(_fee));
        } else {
            _transfer(from, _to, _value);
            _postTransfer(from, _to, _value);
            _transfer(from, msg.sender, _fee);
            _postTransfer(from, msg.sender, _fee);
        }

        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

     
    function hashForSign(
        bytes4 _selector,
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_selector, _token, _to, _value, _fee, _nonce));
    }

    function releasePreSigned(bytes memory _signature, uint256 _fee, uint256 _nonce)
        public
        onlyWhenEtherlessTransferEnabled
        returns (bool)
    {
        bytes32 hashedParams = hashForReleaseSign(msg.sig, address(this), _fee, _nonce);
        address from = hashedParams.toEthSignedMessageHash().recover(_signature);
        require(from != address(0), "Invalid signature");

        bytes32 hashedTx = keccak256(abi.encodePacked(from, hashedParams));
        require(hashedTxs[hashedTx] == false, "Nonce already used");
        hashedTxs[hashedTx] = true;

        uint256 released = _release(from);
        require(released > _fee, "Too small release");
        if (from != msg.sender) {  
            _transfer(from, msg.sender, _fee);
            _postTransfer(from, msg.sender, _fee);
        }
        return true;
    }

     
    function hashForReleaseSign(
        bytes4 _selector,
        address _token,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_selector, _token, _fee, _nonce));
    }

    function recoverTokens(IERC20 token, address to, uint256 amount) public onlyOwner {
        require(address(token) != address(this), "Cannot recover Parsiq tokens");
        super.recoverTokens(token, to,  amount);
    }

    function _release(address beneficiary) internal
        notBurnerUntilBurnIsEnabled(beneficiary)
        returns (uint256) {
        uint256 tokens = _releaseLocks(timelocks[beneficiary], 0);
        if (transfersUnlockTime <= now) {
            tokens = tokens.add(_releaseLocks(relativeTimelocks[beneficiary], transfersUnlockTime));
        }

        if (tokens == 0) return 0;
        _transfer(address(this), beneficiary, tokens);
        _postTransfer(address(this), beneficiary, tokens);
        emit Released(beneficiary, tokens);
        return tokens;
    }

    function _releaseLocks(Timelock[] storage locks, uint256 relativeTime) internal returns (uint256) {
        uint256 tokens = 0;
        uint256 lockCount = locks.length;
        uint256 i = lockCount;
        while (i > 0) {
            i--;
            Timelock storage timelock = locks[i]; 
            if (relativeTime.add(timelock.time) > now) continue;
            
            tokens = tokens.add(timelock.amount);
            lockCount--;
            if (i != lockCount) {
                locks[i] = locks[lockCount];
            }
        }
        locks.length = lockCount;
        return tokens;
    }

    function _lockedBalanceOf(Timelock[] storage locks) internal view returns (uint256) {
        uint256 tokens = 0;
        uint256 n = locks.length;
        for (uint256 i = 0; i < n; i++) {
            tokens = tokens.add(locks[i].amount);
        }
        return tokens;
    }

    function _unlockableBalanceOf(Timelock[] storage locks, uint256 relativeTime) internal view returns (uint256) {
        uint256 tokens = 0;
        uint256 n = locks.length;
        for (uint256 i = 0; i < n; i++) {
            Timelock storage timelock = locks[i];
            if (relativeTime.add(timelock.time) <= now) {
                tokens = tokens.add(timelock.amount);
            }
        }
        return tokens;
    }

    function _postTransfer(address from, address to, uint256 value) internal {
        if (!to.isContract()) return;
        if (notify[to] == false) return;

        ITokenReceiver(to).tokensReceived(from, to, value);
    }

    function _addWhitelisted(address _address) internal {
        whitelisted[_address] = true;
        emit WhitelistedAdded(_address);
    }

    function _removeWhitelisted(address _address) internal {
        whitelisted[_address] = false;
        emit WhitelistedRemoved(_address);
    }
}