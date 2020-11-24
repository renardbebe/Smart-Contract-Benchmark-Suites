 

pragma solidity ^0.5.0;

 

 
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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

 


 
contract RootPlatformAdministratorRole {
    using Roles for Roles.Role;

 
 
 

    event RootPlatformAdministratorAdded(address indexed account);
    event RootPlatformAdministratorRemoved(address indexed account);

 
 
 

    Roles.Role private rootPlatformAdministrators;

 
 
 

    constructor() internal {
        _addRootPlatformAdministrator(msg.sender);
    }

 
 
 

    modifier onlyRootPlatformAdministrator() {
        require(isRootPlatformAdministrator(msg.sender), "no root PFadmin");
        _;
    }

 
 
 

    function isRootPlatformAdministrator(address account) public view returns (bool) {
        return rootPlatformAdministrators.has(account);
    }

    function addRootPlatformAdministrator(address account) public onlyRootPlatformAdministrator {
        _addRootPlatformAdministrator(account);
    }

    function renounceRootPlatformAdministrator() public {
        _removeRootPlatformAdministrator(msg.sender);
    }

    function _addRootPlatformAdministrator(address account) internal {
        rootPlatformAdministrators.add(account);
        emit RootPlatformAdministratorAdded(account);
    }

    function _removeRootPlatformAdministrator(address account) internal {
        rootPlatformAdministrators.remove(account);
        emit RootPlatformAdministratorRemoved(account);
    }
}

 

 


 
contract AssetTokenAdministratorRole is RootPlatformAdministratorRole {

 
 
 

    event AssetTokenAdministratorAdded(address indexed account);
    event AssetTokenAdministratorRemoved(address indexed account);

 
 
 

    Roles.Role private assetTokenAdministrators;

 
 
 

    constructor() internal {
        _addAssetTokenAdministrator(msg.sender);
    }

 
 
 

    modifier onlyAssetTokenAdministrator() {
        require(isAssetTokenAdministrator(msg.sender), "no ATadmin");
        _;
    }

 
 
 

    function isAssetTokenAdministrator(address _account) public view returns (bool) {
        return assetTokenAdministrators.has(_account);
    }

    function addAssetTokenAdministrator(address _account) public onlyRootPlatformAdministrator {
        _addAssetTokenAdministrator(_account);
    }

    function renounceAssetTokenAdministrator() public {
        _removeAssetTokenAdministrator(msg.sender);
    }

    function _addAssetTokenAdministrator(address _account) internal {
        assetTokenAdministrators.add(_account);
        emit AssetTokenAdministratorAdded(_account);
    }

    function removeAssetTokenAdministrator(address _account) public onlyRootPlatformAdministrator {
        _removeAssetTokenAdministrator(_account);
    }

    function _removeAssetTokenAdministrator(address _account) internal {
        assetTokenAdministrators.remove(_account);
        emit AssetTokenAdministratorRemoved(_account);
    }
}

 

 


 
contract At2CsConnectorRole is RootPlatformAdministratorRole {

 
 
 

    event At2CsConnectorAdded(address indexed account);
    event At2CsConnectorRemoved(address indexed account);

 
 
 

    Roles.Role private at2csConnectors;

 
 
 

    constructor() internal {
        _addAt2CsConnector(msg.sender);
    }

 
 
 

    modifier onlyAt2CsConnector() {
        require(isAt2CsConnector(msg.sender), "no at2csAdmin");
        _;
    }

 
 
 

    function isAt2CsConnector(address _account) public view returns (bool) {
        return at2csConnectors.has(_account);
    }

    function addAt2CsConnector(address _account) public onlyRootPlatformAdministrator {
        _addAt2CsConnector(_account);
    }

    function renounceAt2CsConnector() public {
        _removeAt2CsConnector(msg.sender);
    }

    function _addAt2CsConnector(address _account) internal {
        at2csConnectors.add(_account);
        emit At2CsConnectorAdded(_account);
    }

    function removeAt2CsConnector(address _account) public onlyRootPlatformAdministrator {
        _removeAt2CsConnector(_account);
    }

    function _removeAt2CsConnector(address _account) internal {
        at2csConnectors.remove(_account);
        emit At2CsConnectorRemoved(_account);
    }
}

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
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

 

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

 

 

 
 
 
 

 
 
 
 

 
 

library DSMathL {
    function ds_add(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function ds_sub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function ds_mul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function ds_min(uint x, uint y) public pure returns (uint z) {
        return x <= y ? x : y;
    }
    function ds_max(uint x, uint y) public pure returns (uint z) {
        return x >= y ? x : y;
    }
    function ds_imin(int x, int y) public pure returns (int z) {
        return x <= y ? x : y;
    }
    function ds_imax(int x, int y) public pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function ds_wmul(uint x, uint y) public pure returns (uint z) {
        z = ds_add(ds_mul(x, y), WAD / 2) / WAD;
    }
    function ds_rmul(uint x, uint y) public pure returns (uint z) {
        z = ds_add(ds_mul(x, y), RAY / 2) / RAY;
    }
    function ds_wdiv(uint x, uint y) public pure returns (uint z) {
        z = ds_add(ds_mul(x, WAD), y / 2) / y;
    }
    function ds_rdiv(uint x, uint y) public pure returns (uint z) {
        z = ds_add(ds_mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function ds_rpow(uint x, uint n) public pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = ds_rmul(x, x);

            if (n % 2 != 0) {
                z = ds_rmul(z, x);
            }
        }
    }
}

 

 
 

contract YourOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor (address newOwner) public {
        _transferOwnership(newOwner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 



 
contract StandardFeeTable  is YourOwnable {
    using SafeMath for uint256;

 
 
 

    constructor (address newOwner) YourOwnable(newOwner) public {}

 
 
 

    uint256 public defaultFee;

    mapping (bytes32 => uint256) public feeFor;
    mapping (bytes32 => bool) public isFeeDisabled;

 
 
 

     
     
    function setDefaultFee(uint256 _defaultFee) public onlyOwner {
        defaultFee = _defaultFee;
    }

     
     
     
    function setFee(bytes32 _feeName, uint256 _feeValue) public onlyOwner {
        feeFor[_feeName] = _feeValue;
    }

     
     
     
    function setFeeMode(bytes32 _feeName, bool _feeDisabled) public onlyOwner {
        isFeeDisabled[_feeName] = _feeDisabled;
    }

     
     
     
    function getStandardFee(bytes32 _feeName) public view returns (uint256 _feeValue) {
        if (isFeeDisabled[_feeName]) {
            return 0;
        }

        if(feeFor[_feeName] == 0) {
            return defaultFee;
        }

        return feeFor[_feeName];
    }

     
     
     
     
    function getStandardFeeFor(bytes32 _feeName, uint256 _amountInFeeBaseUnit) public view returns (uint256) {
         
         
        return _amountInFeeBaseUnit.mul(getStandardFee(_feeName));
    }
}

 

 


 
contract FeeTable is StandardFeeTable {
    
 
 
 

    constructor (address newOwner) StandardFeeTable(newOwner) public {}

 
 
 

     
    mapping (bytes32 => mapping (address => uint256)) public specialFeeFor;

     
    mapping (bytes32 => mapping (address => bool)) public isSpecialFeeEnabled;

 
 
 

     
     
     
     
    function setSpecialFee(bytes32 _feeName, address _regardingAssetToken, uint256 _feeValue) public onlyOwner {
        specialFeeFor[_feeName][_regardingAssetToken] = _feeValue;
    }

     
     
     
     
    function setSpecialFeeMode(bytes32 _feeName, address _regardingAssetToken, bool _feeEnabled) public onlyOwner {
        isSpecialFeeEnabled[_feeName][_regardingAssetToken] = _feeEnabled;
    }

     
     
     
     
    function getFee(bytes32 _feeName, address _regardingAssetToken) public view returns (uint256) {
        if (isFeeDisabled[_feeName]) {
            return 0;
        }

        if (isSpecialFeeEnabled[_feeName][_regardingAssetToken]) {
            return specialFeeFor[_feeName][_regardingAssetToken];
        }

        return super.getStandardFee(_feeName);
    }

     
     
     
     
     
    function getFeeFor(bytes32 _feeName, address _regardingAssetToken, uint256 _amountInFeeBaseUnit, address  )
        public view returns (uint256) 
    {   
        uint256 fee = getFee(_feeName, _regardingAssetToken);
        
         
         
        return _amountInFeeBaseUnit.mul(fee);
    }
}

 

 


 
contract WhitelistControlRole is RootPlatformAdministratorRole {

 
 
 

    event WhitelistControlAdded(address indexed account);
    event WhitelistControlRemoved(address indexed account);

 
 
 

    Roles.Role private whitelistControllers;

 
 
 

    constructor() internal {
        _addWhitelistControl(msg.sender);
    }

 
 
 

    modifier onlyWhitelistControl() {
        require(isWhitelistControl(msg.sender), "no WLcontrol");
        _;
    }

 
 
 

    function isWhitelistControl(address account) public view returns (bool) {
        return whitelistControllers.has(account);
    }

    function addWhitelistControl(address account) public onlyRootPlatformAdministrator {
        _addWhitelistControl(account);
    }

    function _addWhitelistControl(address account) internal {
        whitelistControllers.add(account);
        emit WhitelistControlAdded(account);
    }

    function removeWhitelistControl(address account) public onlyRootPlatformAdministrator {
        whitelistControllers.remove(account);
        emit WhitelistControlRemoved(account);
    }
}

 

interface IWhitelistAutoExtendExpirationExecutor {
    function recheckIdentity(address _wallet, address _investorKey, address _issuer) external;
}

 

interface IWhitelistAutoExtendExpirationCallback {
    function updateIdentity(address _wallet, bool _isWhitelisted, address _investorKey, address _issuer) external;
}

 

 
contract Whitelist is WhitelistControlRole, IWhitelistAutoExtendExpirationCallback {
    using SafeMath for uint256;

 
 
 

    uint256 public expirationBlocks;
    bool public expirationEnabled;
    bool public autoExtendExpiration;
    address public autoExtendExpirationContract;

    mapping (address => bool) whitelistedWallet;
    mapping (address => uint256) lastIdentityVerificationDate;
    mapping (address => address) whitelistedWalletIssuer;
    mapping (address => address) walletToInvestorKey;

 
 
 

    event WhitelistChanged(address indexed wallet, bool whitelisted, address investorKey, address issuer);
    event ExpirationBlocksChanged(address initiator, uint256 addedBlocksSinceWhitelisting);
    event ExpirationEnabled(address initiator, bool expirationEnabled);
    event UpdatedIdentity(address initiator, address indexed wallet, bool whitelisted, address investorKey, address issuer);
    event SetAutoExtendExpirationContract(address initiator, address expirationContract);
    event UpdatedAutoExtendExpiration(address initiator, bool autoExtendEnabled);

 
 
 

    function getIssuer(address _whitelistedWallet) public view returns (address) {
        return whitelistedWalletIssuer[_whitelistedWallet];
    }

    function getInvestorKey(address _wallet) public view returns (address) {
        return walletToInvestorKey[_wallet];
    }

    function setWhitelisted(address _wallet, bool _isWhitelisted, address _investorKey, address _issuer) public onlyWhitelistControl {
        whitelistedWallet[_wallet] = _isWhitelisted;
        lastIdentityVerificationDate[_wallet] = block.number;
        whitelistedWalletIssuer[_wallet] = _issuer;
        assignWalletToInvestorKey(_wallet, _investorKey);

        emit WhitelistChanged(_wallet, _isWhitelisted, _investorKey, _issuer);
    }

    function assignWalletToInvestorKey(address _wallet, address _investorKey) public onlyWhitelistControl {
        walletToInvestorKey[_wallet] = _investorKey;
    }

     
    function checkWhitelistedWallet(address _wallet) public returns (bool) {
        if(autoExtendExpiration && isExpired(_wallet)) {
            address investorKey = walletToInvestorKey[_wallet];
            address issuer = whitelistedWalletIssuer[_wallet];
            require(investorKey != address(0), "expired, unknown identity");

             
            IWhitelistAutoExtendExpirationExecutor(autoExtendExpirationContract).recheckIdentity(_wallet, investorKey, issuer);
        }

        require(!isExpired(_wallet), "whitelist expired");
        require(whitelistedWallet[_wallet], "not whitelisted");

        return true;
    }

    function isWhitelistedWallet(address _wallet) public view returns (bool) {
        if(isExpired(_wallet)) {
            return false;
        }

        return whitelistedWallet[_wallet];
    }

    function isExpired(address _wallet) private view returns (bool) {
        return expirationEnabled && block.number > lastIdentityVerificationDate[_wallet].add(expirationBlocks);
    }

    function blocksLeftUntilExpired(address _wallet) public view returns (uint256) {
        require(expirationEnabled, "expiration disabled");

        return lastIdentityVerificationDate[_wallet].add(expirationBlocks).sub(block.number);
    }

    function setExpirationBlocks(uint256 _addedBlocksSinceWhitelisting) public onlyRootPlatformAdministrator {
        expirationBlocks = _addedBlocksSinceWhitelisting;

        emit ExpirationBlocksChanged(msg.sender, _addedBlocksSinceWhitelisting);
    }

    function setExpirationEnabled(bool _isEnabled) public onlyRootPlatformAdministrator {
        expirationEnabled = _isEnabled;

        emit ExpirationEnabled(msg.sender, expirationEnabled);
    }

    function setAutoExtendExpirationContract(address _autoExtendContract) public onlyRootPlatformAdministrator {
        autoExtendExpirationContract = _autoExtendContract;

        emit SetAutoExtendExpirationContract(msg.sender, _autoExtendContract);
    }

    function setAutoExtendExpiration(bool _autoExtendEnabled) public onlyRootPlatformAdministrator {
        autoExtendExpiration = _autoExtendEnabled;

        emit UpdatedAutoExtendExpiration(msg.sender, _autoExtendEnabled);
    }

    function updateIdentity(address _wallet, bool _isWhitelisted, address _investorKey, address _issuer) public onlyWhitelistControl {
        setWhitelisted(_wallet, _isWhitelisted, _investorKey, _issuer);

        emit UpdatedIdentity(msg.sender, _wallet, _isWhitelisted, _investorKey, _issuer);
    }
}

 

contract IExchangeRateOracle {
    function resetCurrencyPair(address _currencyA, address _currencyB) public;

    function configureCurrencyPair(address _currencyA, address _currencyB, uint256 maxNextUpdateInBlocks) public;

    function setExchangeRate(address _currencyA, address _currencyB, uint256 _rateFromTo, uint256 _rateToFrom) public;
    function getExchangeRate(address _currencyA, address _currencyB) public view returns (uint256);

    function convert(address _currencyA, address _currencyB, uint256 _amount) public view returns (uint256);
    function convertTT(bytes32 _currencyAText, bytes32 _currencyBText, uint256 _amount) public view returns (uint256);
    function convertTA(bytes32 _currencyAText, address _currencyB, uint256 _amount) public view returns (uint256);
    function convertAT(address _currencyA, bytes32 _currencyBText, uint256 _amount) public view returns (uint256);
}

 

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

interface IBasicAssetToken {
     
    function isTokenAlive() external view returns (bool);

     
    function mint(address _to, uint256 _amount) external returns (bool);
    function finishMinting() external returns (bool);
}

 

 


 
contract StorageAdministratorRole is RootPlatformAdministratorRole {

 
 
 

    event StorageAdministratorAdded(address indexed account);
    event StorageAdministratorRemoved(address indexed account);

 
 
 

    Roles.Role private storageAdministrators;

 
 
 

    constructor() internal {
        _addStorageAdministrator(msg.sender);
    }

 
 
 

    modifier onlyStorageAdministrator() {
        require(isStorageAdministrator(msg.sender), "no SAdmin");
        _;
    }

 
 
 

    function isStorageAdministrator(address account) public view returns (bool) {
        return storageAdministrators.has(account);
    }

    function addStorageAdministrator(address account) public onlyRootPlatformAdministrator {
        _addStorageAdministrator(account);
    }

    function _addStorageAdministrator(address account) internal {
        storageAdministrators.add(account);
        emit StorageAdministratorAdded(account);
    }

    function removeStorageAdministrator(address account) public onlyRootPlatformAdministrator {
        storageAdministrators.remove(account);
        emit StorageAdministratorRemoved(account);
    }
}

 

 


 
contract UintStorage is StorageAdministratorRole
{

 
 
 

    mapping (bytes32 => uint256) private uintStorage;

 
 
 

    function setUint(bytes32 _name, uint256 _value)
        public 
        onlyStorageAdministrator 
    {
        return _setUint(_name, _value);
    }

    function getUint(bytes32 _name) 
        public view 
        returns (uint256) 
    {
        return _getUint(_name);
    }

    function _setUint(bytes32 _name, uint256 _value)
        private 
    {
        if(_name != "") {
            uintStorage[_name] = _value;
        }
    }

    function _getUint(bytes32 _name) 
        private view 
        returns (uint256) 
    {
        return uintStorage[_name];
    }

    function get2Uint(
        bytes32 _name1, 
        bytes32 _name2) 
        public view 
        returns (uint256, uint256) 
    {
        return (_getUint(_name1), _getUint(_name2));
    }
    
    function get3Uint(
        bytes32 _name1, 
        bytes32 _name2, 
        bytes32 _name3) 
        public view 
        returns (uint256, uint256, uint256) 
    {
        return (_getUint(_name1), _getUint(_name2), _getUint(_name3));
    }

    function get4Uint(
        bytes32 _name1, 
        bytes32 _name2, 
        bytes32 _name3, 
        bytes32 _name4) 
        public view 
        returns (uint256, uint256, uint256, uint256) 
    {
        return (_getUint(_name1), _getUint(_name2), _getUint(_name3), _getUint(_name4));
    }

    function get5Uint(
        bytes32 _name1, 
        bytes32 _name2, 
        bytes32 _name3, 
        bytes32 _name4, 
        bytes32 _name5) 
        public view 
        returns (uint256, uint256, uint256, uint256, uint256) 
    {
        return (_getUint(_name1), 
            _getUint(_name2), 
            _getUint(_name3), 
            _getUint(_name4), 
            _getUint(_name5));
    }

    function set2Uint(
        bytes32 _name1, uint256 _value1, 
        bytes32 _name2, uint256 _value2)
        public 
        onlyStorageAdministrator 
    {
        _setUint(_name1, _value1);
        _setUint(_name2, _value2);
    }

    function set3Uint(
        bytes32 _name1, uint256 _value1, 
        bytes32 _name2, uint256 _value2,
        bytes32 _name3, uint256 _value3)
        public 
        onlyStorageAdministrator 
    {
        _setUint(_name1, _value1);
        _setUint(_name2, _value2);
        _setUint(_name3, _value3);
    }

    function set4Uint(
        bytes32 _name1, uint256 _value1, 
        bytes32 _name2, uint256 _value2,
        bytes32 _name3, uint256 _value3,
        bytes32 _name4, uint256 _value4)
        public 
        onlyStorageAdministrator 
    {
        _setUint(_name1, _value1);
        _setUint(_name2, _value2);
        _setUint(_name3, _value3);
        _setUint(_name4, _value4);
    }

    function set5Uint(
        bytes32 _name1, uint256 _value1, 
        bytes32 _name2, uint256 _value2,
        bytes32 _name3, uint256 _value3,
        bytes32 _name4, uint256 _value4,
        bytes32 _name5, uint256 _value5)
        public 
        onlyStorageAdministrator 
    {
        _setUint(_name1, _value1);
        _setUint(_name2, _value2);
        _setUint(_name3, _value3);
        _setUint(_name4, _value4);
        _setUint(_name5, _value5);
    }
}

 

 


 
contract AddrStorage is StorageAdministratorRole
{

 
 
 

    mapping (bytes32 => address) private addrStorage;

 
 
 

    function setAddr(bytes32 _name, address _value)
        public 
        onlyStorageAdministrator 
    {
        return _setAddr(_name, _value);
    }

    function getAddr(bytes32 _name) 
        public view 
        returns (address) 
    {
        return _getAddr(_name);
    }

    function _setAddr(bytes32 _name, address _value)
        private 
    {
        if(_name != "") {
            addrStorage[_name] = _value;
        }
    }

    function _getAddr(bytes32 _name) 
        private view 
        returns (address) 
    {
        return addrStorage[_name];
    }

    function get2Address(
        bytes32 _name1, 
        bytes32 _name2) 
        public view 
        returns (address, address) 
    {
        return (_getAddr(_name1), _getAddr(_name2));
    }
    
    function get3Address(
        bytes32 _name1, 
        bytes32 _name2, 
        bytes32 _name3) 
        public view 
        returns (address, address, address) 
    {
        return (_getAddr(_name1), _getAddr(_name2), _getAddr(_name3));
    }

    function set2Address(
        bytes32 _name1, address _value1, 
        bytes32 _name2, address _value2)
        public 
        onlyStorageAdministrator 
    {
        _setAddr(_name1, _value1);
        _setAddr(_name2, _value2);
    }

    function set3Address(
        bytes32 _name1, address _value1, 
        bytes32 _name2, address _value2,
        bytes32 _name3, address _value3)
        public 
        onlyStorageAdministrator 
    {
        _setAddr(_name1, _value1);
        _setAddr(_name2, _value2);
        _setAddr(_name3, _value3);
    }
}

 

 


 
contract Addr2UintStorage is StorageAdministratorRole
{
    
 
 
 

    mapping (bytes32 => mapping (address => uint256)) private addr2UintStorage;

 
 
 

    function setAddr2Uint(bytes32 _name, address _address, uint256 _value)
        public 
        onlyStorageAdministrator 
    {
        return _setAddr2Uint(_name, _address, _value);
    }

    function getAddr2Uint(bytes32 _name, address _address)
        public view 
        returns (uint256) 
    {
        return _getAddr2Uint(_name, _address);
    }

    function _setAddr2Uint(bytes32 _name, address _address, uint256 _value)
        private 
    {
        if(_name != "") {
            addr2UintStorage[_name][_address] = _value;
        }
    }

    function _getAddr2Uint(bytes32 _name, address _address)
        private view 
        returns (uint256) 
    {
        return addr2UintStorage[_name][_address];
    }

    function get2Addr2Uint(
        bytes32 _name1, address _address1,
        bytes32 _name2, address _address2)
        public view 
        returns (uint256, uint256) 
    {
        return (_getAddr2Uint(_name1, _address1), 
            _getAddr2Uint(_name2, _address2));
    }
    
    function get3Addr2Addr2Uint(
        bytes32 _name1, address _address1,
        bytes32 _name2, address _address2,
        bytes32 _name3, address _address3) 
        public view 
        returns (uint256, uint256, uint256) 
    {
        return (_getAddr2Uint(_name1, _address1), 
            _getAddr2Uint(_name2, _address2), 
            _getAddr2Uint(_name3, _address3));
    }

    function set2Addr2Uint(
        bytes32 _name1, address _address1, uint256 _value1, 
        bytes32 _name2, address _address2, uint256 _value2)
        public 
        onlyStorageAdministrator 
    {
        _setAddr2Uint(_name1, _address1, _value1);
        _setAddr2Uint(_name2, _address2, _value2);
    }

    function set3Addr2Uint(
        bytes32 _name1, address _address1, uint256 _value1, 
        bytes32 _name2, address _address2, uint256 _value2,
        bytes32 _name3, address _address3, uint256 _value3)
        public 
        onlyStorageAdministrator 
    {
        _setAddr2Uint(_name1, _address1, _value1);
        _setAddr2Uint(_name2, _address2, _value2);
        _setAddr2Uint(_name3, _address3, _value3);
    }
}

 

 


 
contract Addr2AddrStorage is StorageAdministratorRole
{
 
 
 

    mapping (bytes32 => mapping (address => address)) private addr2AddrStorage;

 
 
 

    function setAddr2Addr(bytes32 _name, address _address, address _value)
        public 
        onlyStorageAdministrator 
    {
        return _setAddr2Addr(_name, _address, _value);
    }

    function getAddr2Addr(bytes32 _name, address _address)
        public view 
        returns (address) 
    {
        return _getAddr2Addr(_name, _address);
    }

    function _setAddr2Addr(bytes32 _name, address _address, address _value)
        private 
    {
        if(_name != "") {
            addr2AddrStorage[_name][_address] = _value;
        }
    }

    function _getAddr2Addr(bytes32 _name, address _address)
        private view 
        returns (address) 
    {
        return addr2AddrStorage[_name][_address];
    }

    function get2Addr2Addr(
        bytes32 _name1, address _address1,
        bytes32 _name2, address _address2)
        public view 
        returns (address, address) 
    {
        return (_getAddr2Addr(_name1, _address1), 
            _getAddr2Addr(_name2, _address2));
    }
    
    function get3Addr2Addr2Addr(
        bytes32 _name1, address _address1,
        bytes32 _name2, address _address2,
        bytes32 _name3, address _address3) 
        public view 
        returns (address, address, address) 
    {
        return (_getAddr2Addr(_name1, _address1), 
            _getAddr2Addr(_name2, _address2), 
            _getAddr2Addr(_name3, _address3));
    }

    function set2Addr2Addr(
        bytes32 _name1, address _address1, address _value1, 
        bytes32 _name2, address _address2, address _value2)
        public 
        onlyStorageAdministrator 
    {
        _setAddr2Addr(_name1, _address1, _value1);
        _setAddr2Addr(_name2, _address2, _value2);
    }

    function set3Addr2Addr(
        bytes32 _name1, address _address1, address _value1, 
        bytes32 _name2, address _address2, address _value2,
        bytes32 _name3, address _address3, address _value3)
        public 
        onlyStorageAdministrator 
    {
        _setAddr2Addr(_name1, _address1, _value1);
        _setAddr2Addr(_name2, _address2, _value2);
        _setAddr2Addr(_name3, _address3, _value3);
    }
}

 

 


 
contract Addr2BoolStorage is StorageAdministratorRole
{
    
 
 
 

    mapping (bytes32 => mapping (address => bool)) private addr2BoolStorage;

 
 
 

    function setAddr2Bool(bytes32 _name, address _address, bool _value)
        public 
        onlyStorageAdministrator 
    {
        return _setAddr2Bool(_name, _address, _value);
    }

    function getAddr2Bool(bytes32 _name, address _address)
        public view  
        returns (bool) 
    {
        return _getAddr2Bool(_name, _address);
    }

    function _setAddr2Bool(bytes32 _name, address _address, bool _value)
        private 
    {
        if(_name != "") {
            addr2BoolStorage[_name][_address] = _value;
        }
    }

    function _getAddr2Bool(bytes32 _name, address _address)
        private view 
        returns (bool) 
    {
        return addr2BoolStorage[_name][_address];
    }

    function get2Addr2Bool(
        bytes32 _name1, address _address1,
        bytes32 _name2, address _address2)
        public view 
        returns (bool, bool) 
    {
        return (_getAddr2Bool(_name1, _address1), 
            _getAddr2Bool(_name2, _address2));
    }
    
    function get3Address2Address2Bool(
        bytes32 _name1, address _address1,
        bytes32 _name2, address _address2,
        bytes32 _name3, address _address3) 
        public view 
        returns (bool, bool, bool) 
    {
        return (_getAddr2Bool(_name1, _address1), 
            _getAddr2Bool(_name2, _address2), 
            _getAddr2Bool(_name3, _address3));
    }

    function set2Address2Bool(
        bytes32 _name1, address _address1, bool _value1, 
        bytes32 _name2, address _address2, bool _value2)
        public 
        onlyStorageAdministrator 
    {
        _setAddr2Bool(_name1, _address1, _value1);
        _setAddr2Bool(_name2, _address2, _value2);
    }

    function set3Address2Bool(
        bytes32 _name1, address _address1, bool _value1, 
        bytes32 _name2, address _address2, bool _value2,
        bytes32 _name3, address _address3, bool _value3)
        public 
        onlyStorageAdministrator 
    {
        _setAddr2Bool(_name1, _address1, _value1);
        _setAddr2Bool(_name2, _address2, _value2);
        _setAddr2Bool(_name3, _address3, _value3);
    }
}

 

 


 
contract BytesStorage is StorageAdministratorRole
{

 
 
 

    mapping (bytes32 => bytes32) private bytesStorage;

 
 
 

    function setBytes(bytes32 _name, bytes32 _value)
        public 
        onlyStorageAdministrator 
    {
        return _setBytes(_name, _value);
    }

    function getBytes(bytes32 _name) 
        public view 
        returns (bytes32) 
    {
        return _getBytes(_name);
    }

    function _setBytes(bytes32 _name, bytes32 _value)
        private 
    {
        if(_name != "") {
            bytesStorage[_name] = _value;
        }
    }

    function _getBytes(bytes32 _name) 
        private view 
        returns (bytes32) 
    {
        return bytesStorage[_name];
    }

    function get2Bytes(
        bytes32 _name1, 
        bytes32 _name2) 
        public view 
        returns (bytes32, bytes32) 
    {
        return (_getBytes(_name1), _getBytes(_name2));
    }
    
    function get3Bytes(
        bytes32 _name1, 
        bytes32 _name2, 
        bytes32 _name3) 
        public view 
        returns (bytes32, bytes32, bytes32) 
    {
        return (_getBytes(_name1), _getBytes(_name2), _getBytes(_name3));
    }

    function set2Bytes(
        bytes32 _name1, bytes32 _value1, 
        bytes32 _name2, bytes32 _value2)
        public 
        onlyStorageAdministrator 
    {
        _setBytes(_name1, _value1);
        _setBytes(_name2, _value2);
    }

    function set3Bytes(
        bytes32 _name1, bytes32 _value1, 
        bytes32 _name2, bytes32 _value2,
        bytes32 _name3, bytes32 _value3)
        public 
        onlyStorageAdministrator 
    {
        _setBytes(_name1, _value1);
        _setBytes(_name2, _value2);
        _setBytes(_name3, _value3);
    }
}

 

 


 
contract Addr2AddrArrStorage is StorageAdministratorRole
{

 
 
 

    mapping (bytes32 => mapping (address => address[])) private addr2AddrArrStorage;

 
 
 

    function addToAddr2AddrArr(bytes32 _name, address _address, address _value)
        public 
        onlyStorageAdministrator 
    {
        addr2AddrArrStorage[_name][_address].push(_value);
    }

    function getAddr2AddrArr(bytes32 _name, address _address)
        public view 
        returns (address[] memory) 
    {
        return addr2AddrArrStorage[_name][_address];
    }
}

 

 








 
contract StorageHolder is 
    UintStorage,
    BytesStorage,
    AddrStorage,
    Addr2UintStorage,
    Addr2BoolStorage,
    Addr2AddrStorage,
    Addr2AddrArrStorage
{

 
 
 

    function getMixedUBA(bytes32 _uintName, bytes32 _bytesName, bytes32 _addressName) 
        public view
        returns (uint256, bytes32, address) 
    {
        return (getUint(_uintName), getBytes(_bytesName), getAddr(_addressName));
    }

    function getMixedMapA2UA2BA2A(
        bytes32 _a2uName, 
        address _a2uAddress, 
        bytes32 _a2bName, 
        address _a2bAddress, 
        bytes32 _a2aName, 
        address _a2aAddress)
        public view
        returns (uint256, bool, address) 
    {
        return (getAddr2Uint(_a2uName, _a2uAddress), 
            getAddr2Bool(_a2bName, _a2bAddress), 
            getAddr2Addr(_a2aName, _a2aAddress));
    }
}

 

 





 
contract AT2CSStorage is StorageAdministratorRole {

 
 
 

    constructor(address controllerStorage) public {
        storageHolder = StorageHolder(controllerStorage);
    }

 
 
 

    StorageHolder storageHolder;

 
 
 

    function getAssetTokenOfCrowdsale(address _crowdsale) public view returns (address) {
        return storageHolder.getAddr2Addr("cs2at", _crowdsale);
    }

    function getRateFromCrowdsale(address _crowdsale) public view returns (uint256) {
        address assetToken = storageHolder.getAddr2Addr("cs2at", _crowdsale);
        return getRateFromAssetToken(assetToken);
    }

    function getRateFromAssetToken(address _assetToken) public view returns (uint256) {
        require(_assetToken != address(0), "rate assetTokenIs0");
        return storageHolder.getAddr2Uint("rate", _assetToken);
    }

    function getAssetTokenOwnerWalletFromCrowdsale(address _crowdsale) public view returns (address) {
        address assetToken = storageHolder.getAddr2Addr("cs2at", _crowdsale);
        return getAssetTokenOwnerWalletFromAssetToken(assetToken);
    }

    function getAssetTokenOwnerWalletFromAssetToken(address _assetToken) public view returns (address) {
        return storageHolder.getAddr2Addr("at2wallet", _assetToken);
    }

    function getAssetTokensOf(address _wallet) public view returns (address[] memory) {
        return storageHolder.getAddr2AddrArr("wallet2AT", _wallet);
    }

    function isAssignedCrowdsale(address _crowdsale) public view returns (bool) {
        return storageHolder.getAddr2Bool("isCS", _crowdsale);
    }

    function isTrustedAssetTokenRegistered(address _assetToken) public view returns (bool) {
        return storageHolder.getAddr2Bool("trustedAT", _assetToken);
    }

    function isTrustedAssetTokenActive(address _assetToken) public view returns (bool) {
        return storageHolder.getAddr2Bool("ATactive", _assetToken);
    }

    function checkTrustedAssetToken(address _assetToken) public view returns (bool) {
        require(storageHolder.getAddr2Bool("ATactive", _assetToken), "not trusted AT");

        return true;
    }

    function checkTrustedCrowdsaleInternal(address _crowdsale) public view returns (bool) {
        address _assetTokenAddress = storageHolder.getAddr2Addr("cs2at", _crowdsale);
        require(storageHolder.getAddr2Bool("isCS", _crowdsale), "not registered CS");
        require(checkTrustedAssetToken(_assetTokenAddress), "not trusted AT");

        return true;
    }

    function changeActiveTrustedAssetToken(address _assetToken, bool _active) public onlyStorageAdministrator {
        storageHolder.setAddr2Bool("ATactive", _assetToken, _active);
    }

    function addTrustedAssetTokenInternal(address _ownerWallet, address _assetToken, uint256 _rate) public onlyStorageAdministrator {
        require(!storageHolder.getAddr2Bool("trustedAT", _assetToken), "exists");
        require(ERC20Detailed(_assetToken).decimals() == 0, "decimal not 0");

        storageHolder.setAddr2Bool("trustedAT", _assetToken, true);
        storageHolder.setAddr2Bool("ATactive", _assetToken, true);
        storageHolder.addToAddr2AddrArr("wallet2AT", _ownerWallet, _assetToken);
        storageHolder.setAddr2Addr("at2wallet", _assetToken, _ownerWallet);
        storageHolder.setAddr2Uint("rate", _assetToken, _rate);
    }

    function assignCrowdsale(address _assetToken, address _crowdsale) public onlyStorageAdministrator {
        require(storageHolder.getAddr2Bool("trustedAT", _assetToken), "no AT");
        require(!storageHolder.getAddr2Bool("isCS", _crowdsale), "is assigned");
        require(IBasicAssetToken(_assetToken).isTokenAlive(), "not alive");
        require(ERC20Detailed(_assetToken).decimals() == 0, "decimal not 0");
        
        storageHolder.setAddr2Bool("isCS", _crowdsale, true);
        storageHolder.setAddr2Addr("cs2at", _crowdsale, _assetToken);
    }

    function setAssetTokenRate(address _assetToken, uint256 _rate) public onlyStorageAdministrator {
        storageHolder.setAddr2Uint("rate", _assetToken, _rate);
    }
}

 

 








 
library ControllerL {
    using SafeMath for uint256;

 
 
 

    struct Data {
         
        bool feesEnabled;

         
        bool whitelistEnabled;

         
        address crwdToken;

         
        address rootPlatformAddress;

         
        address exchangeRateOracle;

         
        address whitelist;

         
        AT2CSStorage store;

         
        bool blockNew;

         
        mapping ( address => bool ) trustedPlatform;  

         
        mapping ( address => bool ) onceTrustedPlatform;  

         
        mapping ( address => address ) crowdsaleToPlatform;  

         
        mapping ( address => address ) platformToFeeTable;  
    }

 
 
 

     
    function pointMultiplier() private pure returns (uint256) {
        return 1e18;
    }

     
    function getStorageAddress(Data storage _self) public view returns (address) {
        return address(_self.store);
    }

     
     
    function assignStore(Data storage _self, address _storage) public {
        _self.store = AT2CSStorage(_storage);
    }

     
     
     
    function getFeeTableAddressForPlatform(Data storage _self, address _platform) public view returns (address) {
        return _self.platformToFeeTable[_platform];
    }

     
     
     
    function getFeeTableForPlatform(Data storage _self, address _platform) private view returns (FeeTable) {
        return FeeTable(_self.platformToFeeTable[_platform]);
    }

     
     
    function setExchangeRateOracle(Data storage _self, address _oracleAddress) public {
        _self.exchangeRateOracle = _oracleAddress;

        emit ExchangeRateOracleSet(msg.sender, _oracleAddress);
    }

     
     
    function checkWhitelistedWallet(Data storage _self, address _wallet) public returns (bool) {
        require(Whitelist(_self.whitelist).checkWhitelistedWallet(_wallet), "not whitelist");

        return true;
    }

     
     
     
    function isWhitelistedWallet(Data storage _self, address _wallet) public view returns (bool) {
        return Whitelist(_self.whitelist).isWhitelistedWallet(_wallet);
    }

     
     
     
    function convertEthToEurApplyRateGetTokenAmountFromCrowdsale(
        Data storage _self, 
        address _crowdsale,
        uint256 _amountInWei) 
        public view returns (uint256 _effectiveTokensNoDecimals, uint256 _overpaidEthWhenZeroDecimals)
    {
        uint256 amountInEur = convertEthToEur(_self, _amountInWei);
        uint256 tokens = DSMathL.ds_wmul(amountInEur, _self.store.getRateFromCrowdsale(_crowdsale));

        _effectiveTokensNoDecimals = tokens.div(pointMultiplier());
        _overpaidEthWhenZeroDecimals = convertEurToEth(_self, DSMathL.ds_wdiv(tokens.sub(_effectiveTokensNoDecimals.mul(pointMultiplier())), _self.store.getRateFromCrowdsale(_crowdsale)));

        return (_effectiveTokensNoDecimals, _overpaidEthWhenZeroDecimals);
    }

     
     
     
    function checkTrustedCrowdsale(Data storage _self, address _crowdsale) public view returns (bool) {
        require(checkTrustedPlatform(_self, _self.crowdsaleToPlatform[_crowdsale]), "not trusted PF0");
        require(_self.store.checkTrustedCrowdsaleInternal(_crowdsale), "not trusted CS1");

        return true;   
    }

     
     
     
    function checkTrustedAssetToken(Data storage _self, address _assetToken) public view returns (bool) {
         
        require(_self.store.checkTrustedAssetToken(_assetToken), "untrusted AT");

        return true;   
    }

     
     
     
    function checkTrustedPlatform(Data storage _self, address _platformWallet) public view returns (bool) {
        require(isTrustedPlatform(_self, _platformWallet), "not trusted PF3");

        return true;
    }

     
     
     
    function isTrustedPlatform(Data storage _self, address _platformWallet) public view returns (bool) {
        return _self.trustedPlatform[_platformWallet];
    }

     
     
     
    function addTrustedAssetToken(Data storage _self, address _ownerWallet, address _assetToken, uint256 _rate) public {
        require(!_self.blockNew, "blocked. newest version?");

        _self.store.addTrustedAssetTokenInternal(_ownerWallet, _assetToken, _rate);

        emit AssetTokenAdded(msg.sender, _ownerWallet, _assetToken, _rate);
    }

     
     
     
     
    function assignCrowdsale(Data storage _self, address _assetToken, address _crowdsale, address _platformWallet) public {
        require(!_self.blockNew, "blocked. newest version?");
        checkTrustedPlatform(_self, _platformWallet);
        _self.store.assignCrowdsale(_assetToken, _crowdsale);
        _self.crowdsaleToPlatform[_crowdsale] = _platformWallet;

        emit CrowdsaleAssigned(msg.sender, _assetToken, _crowdsale, _platformWallet);
    }

     
     
     
     
    function changeActiveTrustedAssetToken(Data storage _self, address _assetToken, bool _active) public returns (bool) {
        _self.store.changeActiveTrustedAssetToken(_assetToken, _active);
        emit AssetTokenChangedActive(msg.sender, _assetToken, _active);
    }

     
     
     
    function buyFromCrowdsale(
        Data storage _self, 
        address _to, 
        uint256 _amountInWei) 
        public returns (uint256 _tokensCreated, uint256 _overpaidRefund)
    {
        (uint256 effectiveTokensNoDecimals, uint256 overpaidEth) = convertEthToEurApplyRateGetTokenAmountFromCrowdsale(
            _self, 
            msg.sender, 
            _amountInWei);

        checkValidTokenAssignmentFromCrowdsale(_self, _to);
        payFeeFromCrowdsale(_self, effectiveTokensNoDecimals);
        _tokensCreated = doTokenAssignment(_self, _to, effectiveTokensNoDecimals, msg.sender);

        return (_tokensCreated, overpaidEth);
    }

     
     
     
     
     
    function assignFromCrowdsale(Data storage _self, address _to, uint256 _tokensToMint) public returns (uint256 _tokensCreated) {
        checkValidTokenAssignmentFromCrowdsale(_self, _to);
        payFeeFromCrowdsale(_self, _tokensToMint);

        _tokensCreated = doTokenAssignment(_self, _to, _tokensToMint, msg.sender);

        return _tokensCreated;
    }

     
     
     
     
     
    function doTokenAssignment(
        Data storage _self, 
        address _to, 
        uint256 _tokensToMint, 
        address _crowdsale) 
        private returns 
        (uint256 _tokensCreated)
    {
        address assetToken = _self.store.getAssetTokenOfCrowdsale(_crowdsale);
    
        require(assetToken != address(0), "assetTokenIs0");
        ERC20Mintable(assetToken).mint(_to, _tokensToMint);

        return _tokensToMint;
    }

     
     
    function payFeeFromCrowdsale(Data storage _self, uint256 _tokensToMint) private {
        if (_self.feesEnabled) {
            address ownerAssetTokenWallet = _self.store.getAssetTokenOwnerWalletFromCrowdsale(msg.sender);
            payFeeKnowingCrowdsale(_self, msg.sender, ownerAssetTokenWallet, _tokensToMint, "investorInvests");
        }
    }

     
     
    function checkValidTokenAssignmentFromCrowdsale(Data storage _self, address _to) private {
        require(checkTrustedCrowdsale(_self, msg.sender), "untrusted source1");

        if (_self.whitelistEnabled) {
            checkWhitelistedWallet(_self, _to);
        }
    }

     
     
     
     
     
    function payFeeKnowingCrowdsale(
        Data storage _self, 
        address _crowdsale, 
        address _ownerAssetToken, 
        uint256 _tokensToMint,  
        bytes32 _feeName)
        private
    {
        address platform = _self.crowdsaleToPlatform[_crowdsale];

        uint256 feePromilleRootPlatform = getFeeKnowingCrowdsale(
            _self, 
            _crowdsale, 
            getFeeTableAddressForPlatform(_self, _self.rootPlatformAddress),
            _tokensToMint, 
            false, 
            _feeName);

        payWithCrwd(_self, _ownerAssetToken, _self.rootPlatformAddress, feePromilleRootPlatform);

        if(platform != _self.rootPlatformAddress) {
            address feeTable = getFeeTableAddressForPlatform(_self, platform);
            require(feeTable != address(0), "FeeTbl 0 addr");
            uint256 feePromillePlatform = getFeeKnowingCrowdsale(_self, _crowdsale, feeTable, _tokensToMint, false, _feeName);
            payWithCrwd(_self, _ownerAssetToken, platform, feePromillePlatform);
        }
    }

     
     
     
     
     
    function payFeeKnowingAssetToken(
        Data storage _self, 
        address _assetToken, 
        address _initiator, 
        uint256 _tokensToMint,  
        bytes32 _feeName) 
        public 
    {
        uint256 feePromille = getFeeKnowingAssetToken(
            _self, 
            _assetToken, 
            _initiator, 
            _tokensToMint, 
            _feeName);

        payWithCrwd(_self, _initiator, _self.rootPlatformAddress, feePromille);
    }

     
    function payWithCrwd(Data storage _self, address _from, address _to, uint256 _value) private {
        if(_value > 0 && _from != _to) {
            ERC20Mintable(_self.crwdToken).transferFrom(_from, _to, _value);
            emit FeesPaid(_from, _to, _value);
        }
    }

     
     
     
    function convertEthToEur(Data storage _self, uint256 _weiAmount) public view returns (uint256) {
        require(_self.exchangeRateOracle != address(0), "no oracle");
        return IExchangeRateOracle(_self.exchangeRateOracle).convertTT("ETH", "EUR", _weiAmount);
    }

     
     
     
    function convertEurToEth(Data storage _self, uint256 _eurAmount) public view returns (uint256) {
        require(_self.exchangeRateOracle != address(0), "no oracle");
        return IExchangeRateOracle(_self.exchangeRateOracle).convertTT("EUR", "ETH", _eurAmount);
    }

     
     
     
     
     
     
     
    function getFeeKnowingCrowdsale(
        Data storage _self,
        address _crowdsale, 
        address _feeTableAddr, 
        uint256 _amountInTokensOrEth,
        bool _amountRequiresConversion,
        bytes32 _feeName) 
        public view returns (uint256) 
    {
        uint256 tokens = _amountInTokensOrEth;

        if(_amountRequiresConversion) {
            (tokens, ) = convertEthToEurApplyRateGetTokenAmountFromCrowdsale(_self, _crowdsale, _amountInTokensOrEth);
        }
        
        FeeTable feeTable = FeeTable(_feeTableAddr);
        address assetTokenOfCrowdsale = _self.store.getAssetTokenOfCrowdsale(_crowdsale);

        return feeTable.getFeeFor(_feeName, assetTokenOfCrowdsale, tokens, _self.exchangeRateOracle);
    }

     
     
     
     
     
    function getFeeKnowingAssetToken(
        Data storage _self, 
        address _assetToken, 
        address  , 
        uint256 _tokenAmount, 
        bytes32 _feeName) 
        public view returns (uint256) 
    {
        FeeTable feeTable = getFeeTableForPlatform(_self, _self.rootPlatformAddress);
        return feeTable.getFeeFor(_feeName, _assetToken, _tokenAmount, _self.exchangeRateOracle);
    }

     
     
    function setCrwdTokenAddress(Data storage _self, address _crwdToken) public {
        _self.crwdToken = _crwdToken;
        emit CrwdTokenAddressChanged(_crwdToken);
    }

     
     
     
    function setTrustedPlatform(Data storage _self, address _platformWallet, bool _trusted) public {
        setTrustedPlatformInternal(_self, _platformWallet, _trusted, false);
    }

     
     
     
     
    function setTrustedPlatformInternal(Data storage _self, address _platformWallet, bool _trusted, bool _isRootPlatform) private {
        require(_self.rootPlatformAddress != address(0), "no rootPF");

        _self.trustedPlatform[_platformWallet] = _trusted;
        
        if(_trusted && !_self.onceTrustedPlatform[msg.sender]) {
            _self.onceTrustedPlatform[_platformWallet] = true;
            FeeTable ft = new FeeTable(_self.rootPlatformAddress);
            _self.platformToFeeTable[_platformWallet] = address(ft);
        }

        emit PlatformTrustChanged(_platformWallet, _trusted, _isRootPlatform);
    }

     
     
    function setRootPlatform(Data storage _self, address _rootPlatformWallet) public {
        _self.rootPlatformAddress = _rootPlatformWallet;
        emit RootPlatformChanged(_rootPlatformWallet);

        setTrustedPlatformInternal(_self, _rootPlatformWallet, true, true);
    }

     
     
     
     
    function setAssetTokenRate(Data storage _self, address _assetToken, uint256 _rate) public {
        _self.store.setAssetTokenRate(_assetToken, _rate);
        emit AssetTokenRateChanged(_assetToken, _rate);
    }

     
     
     
    function rescueToken(Data storage  , address _foreignTokenAddress, address _to) public
    {
        ERC20Mintable(_foreignTokenAddress).transfer(_to, ERC20(_foreignTokenAddress).balanceOf(address(this)));
    }

 
 
 
    event AssetTokenAdded(address indexed initiator, address indexed wallet, address indexed assetToken, uint256 rate);
    event AssetTokenChangedActive(address indexed initiator, address indexed assetToken, bool active);
    event PlatformTrustChanged(address indexed platformWallet, bool trusted, bool isRootPlatform);
    event CrwdTokenAddressChanged(address indexed crwdToken);
    event AssetTokenRateChanged(address indexed assetToken, uint256 rate);
    event RootPlatformChanged(address indexed _rootPlatformWalletAddress);
    event CrowdsaleAssigned(address initiator, address indexed assetToken, address indexed crowdsale, address platformWallet);
    event ExchangeRateOracleSet(address indexed initiator, address indexed oracleAddress);
    event FeesPaid(address indexed from, address indexed to, uint256 value);
}

 

 
contract LibraryHolder {
    using ControllerL for ControllerL.Data;

 
 
 

    ControllerL.Data internal controllerData;
}

 

 




 
contract PermissionHolder  is AssetTokenAdministratorRole, At2CsConnectorRole, LibraryHolder {

}

 

 


 
contract MainInfoProvider is PermissionHolder {
    
 
 
 

    event AssetTokenAdded(address indexed initiator, address indexed wallet, address indexed assetToken, uint256 rate);
    event AssetTokenChangedActive(address indexed initiator, address indexed assetToken, bool active);
    event CrwdTokenAddressChanged(address indexed crwdToken);
    event ExchangeRateOracleSet(address indexed initiator, address indexed oracleAddress);
    event AssetTokenRateChanged(address indexed assetToken, uint256 rate);
    event RootPlatformChanged(address indexed _rootPlatformWalletAddress);
    event PlatformTrustChanged(address indexed platformWallet, bool trusted, bool isRootPlatform);
    event WhitelistSet(address indexed initiator, address indexed whitelistAddress);
    event CrowdsaleAssigned(address initiator, address indexed assetToken, address indexed crowdsale, address platformWallet);
    event FeesPaid(address indexed from, address indexed to, uint256 value);
    event TokenAssignment(address indexed to, uint256 tokensToMint, address indexed crowdsale, bytes8 tag);

 
 
 

     
     
    function setCrwdTokenAddress(address _crwdToken) public onlyRootPlatformAdministrator {
        controllerData.setCrwdTokenAddress(_crwdToken);
    }

     
     
    function setOracle(address _oracleAddress) public onlyRootPlatformAdministrator {
        controllerData.setExchangeRateOracle(_oracleAddress);
    }

     
     
     
    function getFeeTableAddressForPlatform(address _platform) public view returns (address) {
        return controllerData.getFeeTableAddressForPlatform(_platform);
    }   

     
     
     
     
    function setAssetTokenRate(address _assetToken, uint256 _rate) public onlyRootPlatformAdministrator {
        controllerData.setAssetTokenRate(_assetToken, _rate);
    }

     
     
    function setRootPlatform(address _rootPlatformWallet) public onlyRootPlatformAdministrator {
        controllerData.setRootPlatform(_rootPlatformWallet);
    }

     
    function getRootPlatform() public view returns (address) {
        return controllerData.rootPlatformAddress;
    }
    
     
     
     
    function setTrustedPlatform(address _platformWallet, bool _trusted) public onlyRootPlatformAdministrator {
        controllerData.setTrustedPlatform(_platformWallet, _trusted);
    }

     
     
     
    function isTrustedPlatform(address _platformWallet) public view returns (bool) {
        return controllerData.trustedPlatform[_platformWallet];
    }

     
     
     
    function getPlatformOfCrowdsale(address _crowdsale) public view returns (address) {
        return controllerData.crowdsaleToPlatform[_crowdsale];
    }

     
     
    function setWhitelistContract(address _whitelistAddress) public onlyRootPlatformAdministrator {
        controllerData.whitelist = _whitelistAddress;

        emit WhitelistSet(msg.sender, _whitelistAddress);
    }

     
     
    function getStorageAddress() public view returns (address) {
        return controllerData.getStorageAddress();
    }

     
     
    function setBlockNewState(bool _isBlockNewActive) public onlyRootPlatformAdministrator {
        controllerData.blockNew = _isBlockNewActive;
    }

     
     
    function getBlockNewState() public view returns (bool) {
        return controllerData.blockNew;
    }
}

 

 



 
contract ManageAssetToken  is MainInfoProvider {
    using SafeMath for uint256;

 
 
 

     
     
     
    function addTrustedAssetToken(address _ownerWallet, address _assetToken, uint256 _rate) 
        public 
        onlyAssetTokenAdministrator 
    {
        controllerData.addTrustedAssetToken(_ownerWallet, _assetToken, _rate);
    }

     
     
    function checkTrustedAssetToken(address _assetToken) public view returns (bool) {
        return controllerData.checkTrustedAssetToken(_assetToken);
    }

     
     
     
     
    function changeActiveTrustedAssetToken(address _assetToken, bool _active) public onlyRootPlatformAdministrator returns (bool) {
        return controllerData.changeActiveTrustedAssetToken(_assetToken, _active);
    }

     
     
     
     
     
    function getFeeKnowingAssetToken(
        address _assetToken, 
        address _from, 
        uint256 _tokenAmount, 
        bytes32 _feeName) 
        public view returns (uint256)
    {
        return controllerData.getFeeKnowingAssetToken(_assetToken, _from, _tokenAmount, _feeName);
    }

     
     
     
    function convertEthToTokenAmount(address _crowdsale, uint256 _amountInWei) public view returns (uint256 _tokens) {
        (uint256 tokens, ) = controllerData.convertEthToEurApplyRateGetTokenAmountFromCrowdsale(_crowdsale, _amountInWei);
        return tokens;
    }
}

 

 


 
contract ManageFee is MainInfoProvider {

 
 
 

     
     
     
     
     
    function payFeeKnowingAssetToken(address _assetToken, address _from, uint256 _amount, bytes32 _feeName) internal {
        controllerData.payFeeKnowingAssetToken(_assetToken, _from, _amount, _feeName);
    }
}

 

 


 
contract ManageCrowdsale is MainInfoProvider {

 
 
 

     
     
     
     
    function assignCrowdsale(address _assetToken, address _crowdsale, address _platformWallet) 
        public 
        onlyAt2CsConnector 
    {
        controllerData.assignCrowdsale(_assetToken, _crowdsale, _platformWallet);
    }

     
     
    function checkTrustedCrowdsale(address _crowdsale) public view returns (bool) {
        return controllerData.checkTrustedCrowdsale(_crowdsale);
    }

     
     
     
     
     
     
     
    function getFeeKnowingCrowdsale(
        address _crowdsale, 
        address _feeTableAddr, 
        uint256 _amountInTokensOrEth, 
        bool _amountRequiresConversion,
        bytes32 _feeName) 
        public view returns (uint256) 
    {
        return controllerData.getFeeKnowingCrowdsale(_crowdsale, _feeTableAddr, _amountInTokensOrEth, _amountRequiresConversion, _feeName);
    }
}

 

 



 
contract ManagePlatform  is MainInfoProvider {

 
 
 

     
     
     
    function checkTrustedPlatform(address _platformWallet) public view returns (bool) {
        return controllerData.checkTrustedPlatform(_platformWallet);
    }

     
     
    function isTrustedPlatform(address _platformWallet) public view returns (bool) {
        return controllerData.trustedPlatform[_platformWallet];
    }
}

 

 



 
contract ManageWhitelist  is MainInfoProvider {

 
 
 

     
     
    function checkWhitelistedWallet(address _wallet) public returns (bool) {
        controllerData.checkWhitelistedWallet(_wallet);
    }

     
     
     
    function isWhitelistedWallet(address _wallet) public view returns (bool) {
        controllerData.isWhitelistedWallet(_wallet);
    }
}

 

 






 
contract ManagerHolder is 
    ManageAssetToken, 
    ManageFee, 
    ManageCrowdsale,
    ManagePlatform,
    ManageWhitelist
{
}

 

interface ICRWDController {
    function transferParticipantsVerification(address _underlyingCurrency, address _from, address _to, uint256 _tokenAmount) external returns (bool);  
    function buyFromCrowdsale(address _to, uint256 _amountInWei) external returns (uint256 _tokensCreated, uint256 _overpaidRefund);  
    function assignFromCrowdsale(address _to, uint256 _tokenAmount, bytes8 _tag) external returns (uint256 _tokensCreated);  
    function calcTokensForEth(uint256 _amountInWei) external view returns (uint256 _tokensWouldBeCreated);  
}

 

 
contract CRWDController is ManagerHolder, ICRWDController {

 
 
 

    event GlobalConfigurationChanged(bool feesEnabled, bool whitelistEnabled);

 
 
 

    constructor(bool _feesEnabled, bool _whitelistEnabled, address _rootPlatformAddress, address _storage) public {
        controllerData.assignStore(_storage);
        
        setRootPlatform(_rootPlatformAddress);

        configure(_feesEnabled, _whitelistEnabled);
    }

 
 
 

     
     
     
    function configure(bool _feesEnabled, bool _whitelistEnabled) public onlyRootPlatformAdministrator {
        controllerData.feesEnabled = _feesEnabled;
        controllerData.whitelistEnabled = _whitelistEnabled;

        emit GlobalConfigurationChanged(_feesEnabled, _whitelistEnabled);
    }

     
     
     
     
    function transferParticipantsVerification(address  , address _from, address _to, uint256 _tokenAmount) public returns (bool) {

        if (controllerData.whitelistEnabled) {
            checkWhitelistedWallet(_to);  
        }

         
        require(checkTrustedAssetToken(msg.sender), "untrusted");

        if (controllerData.feesEnabled) {
            payFeeKnowingAssetToken(msg.sender, _from, _tokenAmount, "clearTransferFunds");
        }

        return true;
    }

     
     
     
    function buyFromCrowdsale(address _to, uint256 _amountInWei) public returns (uint256 _tokensCreated, uint256 _overpaidRefund) {
        return controllerData.buyFromCrowdsale(_to, _amountInWei);
    }

     
     
     
    function calcTokensForEth(uint256 _amountInWei) external view returns (uint256 _tokensWouldBeCreated) {
        require(checkTrustedCrowdsale(msg.sender), "untrusted source2");

        return convertEthToTokenAmount(msg.sender, _amountInWei);
    }

     
     
     
     
    function assignFromCrowdsale(address _to, uint256 _tokenAmount, bytes8 _tag) external returns (uint256 _tokensCreated) {
        _tokensCreated = controllerData.assignFromCrowdsale(_to, _tokenAmount);

        emit TokenAssignment(_to, _tokenAmount, msg.sender, _tag);

        return _tokensCreated;
    }

 
 
 

     
     
     
    function rescueToken(address _foreignTokenAddress, address _to)
    public
    onlyRootPlatformAdministrator
    {
        controllerData.rescueToken(_foreignTokenAddress, _to);
    }
}