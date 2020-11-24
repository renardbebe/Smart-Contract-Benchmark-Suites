 

 

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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
contract SRC20Detailed {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

 

pragma solidity ^0.5.0;

 
interface ISRC20 {

    event RestrictionsAndRulesUpdated(address restrictions, address rules);

    function transferToken(address to, uint256 value, uint256 nonce, uint256 expirationTime,
        bytes32 msgHash, bytes calldata signature) external returns (bool);
    function transferTokenFrom(address from, address to, uint256 value, uint256 nonce,
        uint256 expirationTime, bytes32 hash, bytes calldata signature) external returns (bool);
    function getTransferNonce() external view returns (uint256);
    function getTransferNonce(address account) external view returns (uint256);
    function executeTransfer(address from, address to, uint256 value) external returns (bool);
    function updateRestrictionsAndRules(address restrictions, address rules) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function increaseAllowance(address spender, uint256 value) external returns (bool);
    function decreaseAllowance(address spender, uint256 value) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
interface ISRC20Managed {
    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    function burn(address account, uint256 value) external returns (bool);
    function mint(address account, uint256 value) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
interface ITransferRules {
    function setSRC(address src20) external returns (bool);
    function doTransfer(address from, address to, uint256 value) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
contract IFreezable {
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);

    function _freezeAccount(address account) internal;
    function _unfreezeAccount(address account) internal;
    function _isAccountFrozen(address account) internal view returns (bool);
}

 

pragma solidity ^0.5.0;

 
contract IPausable{
    event Paused(address account);
    event Unpaused(address account);

    function paused() public view returns (bool);

    function _pause() internal;
    function _unpause() internal;
}

 

pragma solidity ^0.5.0;



 
contract IFeatured is IPausable, IFreezable {
    
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event TokenFrozen();
    event TokenUnfrozen();
    
    uint8 public constant ForceTransfer = 0x01;
    uint8 public constant Pausable = 0x02;
    uint8 public constant AccountBurning = 0x04;
    uint8 public constant AccountFreezing = 0x08;

    function _enable(uint8 features) internal;
    function isEnabled(uint8 feature) public view returns (bool);

    function checkTransfer(address from, address to) external view returns (bool);
    function isAccountFrozen(address account) external view returns (bool);
    function freezeAccount(address account) external;
    function unfreezeAccount(address account) external;
    function isTokenPaused() external view returns (bool);
    function pauseToken() external;
    function unPauseToken() external;
}

 

pragma solidity ^0.5.0;

 
contract ISRC20Roles {
    function isAuthority(address account) external view returns (bool);
    function removeAuthority(address account) external returns (bool);
    function addAuthority(address account) external returns (bool);

    function isDelegate(address account) external view returns (bool);
    function addDelegate(address account) external returns (bool);
    function removeDelegate(address account) external returns (bool);

    function manager() external view returns (address);
    function isManager(address account) external view returns (bool);
    function transferManagement(address newManager) external returns (bool);
    function renounceManagement() external returns (bool);
}

 

pragma solidity ^0.5.0;

 
interface ITransferRestrictions {
    function authorize(address from, address to, uint256 value) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
interface IAssetRegistry {

    event AssetAdded(address indexed src20, bytes32 kyaHash, string kyaUrl, uint256 AssetValueUSD);
    event AssetNVAUSDUpdated(address indexed src20, uint256 AssetValueUSD);
    event AssetKYAUpdated(address indexed src20, bytes32 kyaHash, string kyaUrl);

    function addAsset(address src20, bytes32 kyaHash, string calldata kyaUrl, uint256 netAssetValueUSD) external returns (bool);

    function getNetAssetValueUSD(address src20) external view returns (uint256);
    function updateNetAssetValueUSD(address src20, uint256 netAssetValueUSD) external returns (bool);

    function getKYA(address src20) external view returns (bytes32 kyaHash, string memory kyaUrl);
    function updateKYA(address src20, bytes32 kyaHash, string calldata kyaUrl) external returns (bool);

}

 

pragma solidity ^0.5.0;














 
contract SRC20 is ISRC20, ISRC20Managed, SRC20Detailed, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    uint256 public _totalSupply;
    uint256 public _maxTotalSupply;

    mapping(address => uint256) private _nonce;

    ISRC20Roles public _roles;
    IFeatured public _features;

    IAssetRegistry public _assetRegistry;

     
    ITransferRestrictions public _restrictions;

     
    ITransferRules public _rules;

    modifier onlyAuthority() {
        require(_roles.isAuthority(msg.sender), "Caller not authority");
        _;
    }

    modifier onlyDelegate() {
        require(_roles.isDelegate(msg.sender), "Caller not delegate");
        _;
    }

    modifier onlyManager() {
        require(_roles.isManager(msg.sender), "Caller not manager");
        _;
    }

    modifier enabled(uint8 feature) {
        require(_features.isEnabled(feature), "Token feature is not enabled");
        _;
    }

     
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 maxTotalSupply,
        address[] memory addressList
                     
                     
                     
                     
                     
                     
    )
    SRC20Detailed(name, symbol, decimals)
    public
    {
        _assetRegistry = IAssetRegistry(addressList[5]);
        _transferOwnership(addressList[0]);

        _maxTotalSupply = maxTotalSupply;
        _updateRestrictionsAndRules(addressList[1], addressList[2]);

        _roles = ISRC20Roles(addressList[3]);
        _features = IFeatured(addressList[4]);
    }

     
    function executeTransfer(address from, address to, uint256 value) external onlyAuthority returns (bool) {
        _transfer(from, to, value);
        return true;
    }

     
    function updateRestrictionsAndRules(address restrictions, address rules) external onlyDelegate returns (bool) {
        return _updateRestrictionsAndRules(restrictions, rules);
    }

     
    function _updateRestrictionsAndRules(address restrictions, address rules) internal returns (bool) {

        _restrictions = ITransferRestrictions(restrictions);
        _rules = ITransferRules(rules);

        if (rules != address(0)) {
            require(_rules.setSRC(address(this)), "SRC20 contract already set in transfer rules");
        }

        emit RestrictionsAndRulesUpdated(restrictions, rules);
        return true;
    }

     
    function transferToken(
        address to,
        uint256 value,
        uint256 nonce,
        uint256 expirationTime,
        bytes32 hash,
        bytes calldata signature
    )
        external returns (bool)
    {
        return _transferToken(msg.sender, to, value, nonce, expirationTime, hash, signature);
    }

     
    function transferTokenFrom(
        address from,
        address to,
        uint256 value,
        uint256 nonce,
        uint256 expirationTime,
        bytes32 hash,
        bytes calldata signature
    )
        external returns (bool)
    {
        _transferToken(from, to, value, nonce, expirationTime, hash, signature);
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
        return true;
    }

     
    function transferTokenForced(address from, address to, uint256 value)
        external
        enabled(_features.ForceTransfer())
        onlyOwner
        returns (bool)
    {
        _transfer(from, to, value);
        return true;
    }

     
     
    function getTransferNonce() external view returns (uint256) {
        return _nonce[msg.sender];
    }

     
    function getTransferNonce(address account) external view returns (uint256) {
        return _nonce[account];
    }

     
     
    function burnAccount(address account, uint256 value)
        external
        enabled(_features.AccountBurning())
        onlyOwner
        returns (bool)
    {
        _burn(account, value);
        return true;
    }

     
     
    function burn(address account, uint256 value) external onlyManager returns (bool) {
        _burn(account, value);
        return true;
    }

     
    function mint(address account, uint256 value) external onlyManager returns (bool) {
        _mint(account, value);
        return true;
    }

     
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(_features.checkTransfer(msg.sender, to), "Feature transfer check");

        if (_rules != ITransferRules(0)) {
            require(_rules.doTransfer(msg.sender, to, value), "Transfer failed");
        } else {
            _transfer(msg.sender, to, value);
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(_features.checkTransfer(from, to), "Feature transfer check");

        if (_rules != ITransferRules(0)) {
            _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
            require(_rules.doTransfer(from, to, value), "Transfer failed");
        } else {
            _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
            _transfer(from, to, value);
        }

        return true;
    }

     
    function increaseAllowance(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(value));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(value));
        return true;
    }

     
     
    function _transferToken(
        address from,
        address to,
        uint256 value,
        uint256 nonce,
        uint256 expirationTime,
        bytes32 hash,
        bytes memory signature
    )
        internal returns (bool)
    {
        if (address(_restrictions) != address(0)) {
            require(_restrictions.authorize(from, to, value), "transferToken restrictions failed");
        }

        require(now <= expirationTime, "transferToken params expired");
        require(nonce == _nonce[from], "transferToken params wrong nonce");

        (bytes32 kyaHash, string memory kyaUrl) = _assetRegistry.getKYA(address(this));

        require(
            keccak256(abi.encodePacked(kyaHash, from, to, value, nonce, expirationTime)) == hash,
            "transferToken params bad hash"
        );
        require(_roles.isAuthority(hash.toEthSignedMessageHash().recover(signature)), "transferToken params not authority");

        require(_features.checkTransfer(from, to), "Feature transfer check");
        _transfer(from, to, value);

        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "Recipient is zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        _nonce[from]++;

        emit Transfer(from, to, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), 'burning from zero address');

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);

        emit Transfer(account, address(0), value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), 'minting to zero address');

        _totalSupply = _totalSupply.add(value);
        require(_totalSupply <= _maxTotalSupply || _maxTotalSupply == 0, 'trying to mint too many tokens!');

        _balances[account] = _balances[account].add(value);

        emit Transfer(address(0), account, value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), 'approve from the zero address');
        require(spender != address(0), 'approve to the zero address');

        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

     
    function bulkTransfer (
        address[] calldata _addresses, uint256[] calldata _values) external onlyDelegate returns (bool) {
        require(_addresses.length == _values.length, "Input dataset length mismatch");

        uint256 count = _addresses.length;
        for (uint256 i = 0; i < count; i++) {
            address to = _addresses[i];
            uint256 value = _values[i];
            _approve(owner(), msg.sender, _allowances[owner()][msg.sender].sub(value));
            _transfer(owner(), to, value);
        }

        return true;
    }

     
    function encodedBulkTransfer (
        uint160 _lotSize, uint256[] calldata _transfers) external onlyDelegate returns (bool) {

        uint256 count = _transfers.length;
        for (uint256 i = 0; i < count; i++) {
            uint256 tr = _transfers[i];
            uint256 value = (tr >> 160) * _lotSize;
            address to = address (tr & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            _approve(owner(), msg.sender, _allowances[owner()][msg.sender].sub(value));
            _transfer(owner(), to, value);
        }

        return true;
    }
}