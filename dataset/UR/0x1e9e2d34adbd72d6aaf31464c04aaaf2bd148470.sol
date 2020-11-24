 

 
pragma solidity 0.5.10;

 
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

contract TokenRecoverable is Ownable {
    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token, address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Given amount is larger than current balance");
        token.safeTransfer(to, amount);
    }
}

contract NOIAToken is TokenRecoverable, ERC20 {
    using SafeMath for uint256;
    using Address for address;
    using ECDSA for bytes32;

    string public constant name = "NOIA Token";
    string public constant symbol = "NOIA";
    uint8 public constant decimals = uint8(18); 
    uint256 public tokensToMint = 1000000000e18;  
    address public burnAddress;
    mapping(address => bool) public notify;
    mapping(bytes32 => bool) private hashedTxs;
    bool public etherlessTransferEnabled = true;

    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);

    modifier onlyEtherlessTransferEnabled {
        require(etherlessTransferEnabled == true, "Etherless transfer functionality disabled");
        _;
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

     
    function transfer(address to, uint256 value) public returns (bool) {
        bool success = super.transfer(to, value);
        if (success) {
            _postTransfer(msg.sender, to, value);
        }
        return success;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        bool success = super.transferFrom(from, to, value);
        if (success) {
            _postTransfer(from, to, value);
        }
        return success;
    }

    function _postTransfer(address from, address to, uint256 value) internal {
        if (to.isContract()) {
            if (notify[to] == false) return;

            ITokenReceiver(to).tokensReceived(from, to, value);
        } else {
            if (to == burnAddress) {
                _burn(burnAddress, value);
            }
        }
    }

    function _burn(address account, uint256 value) internal {
        require(tokensToMint == 0, "All tokens must be minted before burning");
        super._burn(account, value);
    }

     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(tokensToMint.sub(value) >= 0, "Not enough tokens left");
        tokensToMint = tokensToMint.sub(value);
        _mint(to, value);
        _postTransfer(address(0), to, value);
        return true;
    }

     
    function burn(uint256 value) public {
        require(msg.sender == burnAddress, "Only burnAddress can burn tokens");
        _burn(msg.sender, value);
    }

    function setBurnAddress(address _burnAddress) external onlyOwner {
        require(balanceOf(_burnAddress) == 0, "Burn address must have zero balance!");

        burnAddress = _burnAddress;
    }

     
     
    function transferPreSigned(
        bytes memory _signature,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        onlyEtherlessTransferEnabled
        returns (bool)
    {
        require(_to != address(0), "Transfer to the zero address");

        bytes32 hashedParams = hashForSign(msg.sig, address(this), _to, _value, _fee, _nonce);
        address from = hashedParams.toEthSignedMessageHash().recover(_signature);
        require(from != address(0), "Invalid signature");

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
}

contract NOIAVault is ITokenReceiver {
    using SafeERC20 for IERC20;

    address public constant NOIA_TOKEN_ADDRESS = 0xfc858154C0b2c4A3323046Fb505811F110EBdA57;
    
    address public beneficiary;
    uint256 public lockTill;

    modifier onlyOwner() {
        require(msg.sender == NOIAToken(NOIA_TOKEN_ADDRESS).owner(), "Caller is not NOIA Token owner");
        _;
    }

    function initialize(address _beneficiary, uint256 _lockTill) public {
        require(beneficiary == address(0), "Vault is already initialized");
        require(_beneficiary != address(0), "Locking to the zero address");
        require(_lockTill > now, "Locking time must be in future");

        beneficiary = _beneficiary;
        lockTill = _lockTill;
        NOIAToken(NOIA_TOKEN_ADDRESS).register();
    }

    function release() public {
        if (lockTill > now) return;

        NOIAToken token = NOIAToken(NOIA_TOKEN_ADDRESS);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(beneficiary, balance);
    }

    function recoverTokens(IERC20 token, address to, uint256 amount) public onlyOwner {
        require(address(token) != NOIA_TOKEN_ADDRESS, "Cannot recover NOIA Token");
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Given amount is larger than current balance");
        token.safeTransfer(to, amount);
    }

    function tokensReceived(
        address,
        address,
        uint256
    ) external {
        release();
    }
}

contract NOIAVaultFactory {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public constant NOIA_TOKEN_ADDRESS = 0xfc858154C0b2c4A3323046Fb505811F110EBdA57;
    address public constant NOIA_VAULT_ADDRESS = 0xa1697D2fA05775cDb2c007f0e9b527EB7dC77683;

    mapping(address => address[]) public vaults;

    event VaultCreated(address indexed beneficiary, uint256 lockTill, address vaultAddress);

    modifier onlyOwner() {
        require(msg.sender == Ownable(NOIA_TOKEN_ADDRESS).owner(), "Caller is not NOIA Token owner");
        _;
    }

    function createVault(address _beneficiary, uint256 _lockTill) public {
        address clone = createClone(NOIA_VAULT_ADDRESS);
        NOIAVault(clone).initialize(_beneficiary, _lockTill);
        vaults[_beneficiary].push(clone);

        emit VaultCreated(_beneficiary, _lockTill, clone);
    }

    function unlockableBalanceOf(address _beneficiary) public view returns (uint256) {
        uint256 total = 0;
        address[] memory addrs = vaults[_beneficiary];
        for (uint256 i = 0; i < addrs.length; i++) {
            NOIAVault vault = NOIAVault(addrs[i]);
            if (vault.lockTill() < now) {
                total = total.add(IERC20(NOIA_TOKEN_ADDRESS).balanceOf(addrs[i]));
            }
        }
        return total;
    }

    function totalBalanceOf(address _beneficiary) public view returns (uint256) {
        uint256 total = 0;
        address[] memory addrs = vaults[_beneficiary];
        for (uint256 i = 0; i < addrs.length; i++) {
            total = total.add(IERC20(NOIA_TOKEN_ADDRESS).balanceOf(addrs[i]));
        }
        return total;
    }

    function getVaultsCount(address beneficiary) public view returns (uint256) {
        return vaults[beneficiary].length;
    }

    function recoverTokens(IERC20 token, address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "Given amount is larger than current balance");
        token.safeTransfer(to, amount);
    }

     
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}