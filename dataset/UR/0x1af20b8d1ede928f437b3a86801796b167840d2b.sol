 

 

 

pragma solidity 0.4.24;

 
interface IETokenProxy {

     

     
    function nameProxy(address sender) external view returns(string);

    function symbolProxy(address sender)
        external
        view
        returns(string);

    function decimalsProxy(address sender)
        external
        view
        returns(uint8);

     
    function totalSupplyProxy(address sender)
        external
        view
        returns (uint256);

    function balanceOfProxy(address sender, address who)
        external
        view
        returns (uint256);

    function allowanceProxy(address sender,
                            address owner,
                            address spender)
        external
        view
        returns (uint256);

    function transferProxy(address sender, address to, uint256 value)
        external
        returns (bool);

    function approveProxy(address sender,
                          address spender,
                          uint256 value)
        external
        returns (bool);

    function transferFromProxy(address sender,
                               address from,
                               address to,
                               uint256 value)
        external
        returns (bool);

    function mintProxy(address sender, address to, uint256 value)
        external
        returns (bool);

    function changeMintingRecipientProxy(address sender,
                                         address mintingRecip)
        external;

    function burnProxy(address sender, uint256 value) external;

    function burnFromProxy(address sender,
                           address from,
                           uint256 value)
        external;

    function increaseAllowanceProxy(address sender,
                                    address spender,
                                    uint addedValue)
        external
        returns (bool success);

    function decreaseAllowanceProxy(address sender,
                                    address spender,
                                    uint subtractedValue)
        external
        returns (bool success);

    function pauseProxy(address sender) external;

    function unpauseProxy(address sender) external;

    function pausedProxy(address sender) external view returns (bool);

    function finalizeUpgrade() external;
}

 

 

pragma solidity 0.4.24;


 
interface IEToken {

     

    function upgrade(IETokenProxy upgradedToken) external;

     
    function name() external view returns(string);

    function symbol() external view returns(string);

    function decimals() external view returns(uint8);

     
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external
        returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool);

     
    function mint(address to, uint256 value) external returns (bool);

     
    function burn(uint256 value) external;

    function burnFrom(address from, uint256 value) external;

     
    function increaseAllowance(
        address spender,
        uint addedValue
    )
        external
        returns (bool success);

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function decreaseAllowance(
        address spender,
        uint subtractedValue
    )
        external
        returns (bool success);

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

 

pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
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

 

pragma solidity ^0.4.24;

 
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

 

 

pragma solidity 0.4.24;



 
contract Storage is Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private totalSupply;

    address private _implementor;

    event StorageImplementorTransferred(address indexed from,
                                        address indexed to);

     
    constructor(address owner, address implementor) public {

        require(
            owner != address(0),
            "Owner should not be the zero address"
        );

        require(
            implementor != address(0),
            "Implementor should not be the zero address"
        );

        transferOwnership(owner);
        _implementor = implementor;
    }

     
    function isImplementor() public view returns(bool) {
        return msg.sender == _implementor;
    }

     
    function setBalance(address owner,
                        uint256 value)
        public
        onlyImplementor
    {
        balances[owner] = value;
    }

     
    function increaseBalance(address owner, uint256 addedValue)
        public
        onlyImplementor
    {
        balances[owner] = balances[owner].add(addedValue);
    }

     
    function decreaseBalance(address owner, uint256 subtractedValue)
        public
        onlyImplementor
    {
        balances[owner] = balances[owner].sub(subtractedValue);
    }

     
    function getBalance(address owner)
        public
        view
        returns (uint256)
    {
        return balances[owner];
    }

     
    function setAllowed(address owner,
                        address spender,
                        uint256 value)
        public
        onlyImplementor
    {
        allowed[owner][spender] = value;
    }

     
    function increaseAllowed(
        address owner,
        address spender,
        uint256 addedValue
    )
        public
        onlyImplementor
    {
        allowed[owner][spender] = allowed[owner][spender].add(addedValue);
    }

     
    function decreaseAllowed(
        address owner,
        address spender,
        uint256 subtractedValue
    )
        public
        onlyImplementor
    {
        allowed[owner][spender] = allowed[owner][spender].sub(subtractedValue);
    }

     
    function getAllowed(address owner,
                        address spender)
        public
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }

     
    function setTotalSupply(uint256 value)
        public
        onlyImplementor
    {
        totalSupply = value;
    }

     
    function getTotalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply;
    }

     
    function transferImplementor(address newImplementor)
        public
        requireNonZero(newImplementor)
        onlyImplementorOrOwner
    {
        require(newImplementor != _implementor,
                "Cannot transfer to same implementor as existing");
        address curImplementor = _implementor;
        _implementor = newImplementor;
        emit StorageImplementorTransferred(curImplementor, newImplementor);
    }

     
    modifier onlyImplementorOrOwner() {
        require(isImplementor() || isOwner(), "Is not implementor or owner");
        _;
    }

     
    modifier onlyImplementor() {
        require(isImplementor(), "Is not implementor");
        _;
    }

     
    modifier requireNonZero(address addr) {
        require(addr != address(0), "Expected a non-zero address");
        _;
    }
}

 

 

pragma solidity 0.4.24;



 
contract ERC20 {
    using SafeMath for uint256;

    Storage private externalStorage;

    string private name_;
    string private symbol_;
    uint8 private decimals_;

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

     
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        Storage _externalStorage,
        bool initialDeployment
    )
        public
    {

        require(
            (_externalStorage != address(0) && (!initialDeployment)) ||
            (_externalStorage == address(0) && initialDeployment),
            "Cannot both create external storage and use the provided one.");

        name_ = name;
        symbol_ = symbol;
        decimals_ = decimals;

        if (initialDeployment) {
            externalStorage = new Storage(msg.sender, this);
        } else {
            externalStorage = _externalStorage;
        }
    }

     
    function getExternalStorage() public view returns(Storage) {
        return externalStorage;
    }

     
    function _name() internal view returns(string) {
        return name_;
    }

     
    function _symbol() internal view returns(string) {
        return symbol_;
    }

     
    function _decimals() internal view returns(uint8) {
        return decimals_;
    }

     
    function _totalSupply() internal view returns (uint256) {
        return externalStorage.getTotalSupply();
    }

     
    function _balanceOf(address owner) internal view returns (uint256) {
        return externalStorage.getBalance(owner);
    }

     
    function _allowance(address owner, address spender)
        internal
        view
        returns (uint256)
    {
        return externalStorage.getAllowed(owner, spender);
    }

     
    function _transfer(address originSender, address to, uint256 value)
        internal
        returns (bool)
    {
        require(to != address(0));

        externalStorage.decreaseBalance(originSender, value);
        externalStorage.increaseBalance(to, value);

        emit Transfer(originSender, to, value);

        return true;
    }

     
    function _approve(address originSender, address spender, uint256 value)
        internal
        returns (bool)
    {
        require(spender != address(0));

        externalStorage.setAllowed(originSender, spender, value);
        emit Approval(originSender, spender, value);

        return true;
    }

     
    function _transferFrom(
        address originSender,
        address from,
        address to,
        uint256 value
    )
        internal
        returns (bool)
    {

        externalStorage.decreaseAllowed(from, originSender, value);

        _transfer(from, to, value);

        emit Approval(
            from,
            originSender,
            externalStorage.getAllowed(from, originSender)
        );

        return true;
    }

     
    function _increaseAllowance(
        address originSender,
        address spender,
        uint256 addedValue
    )
        internal
        returns (bool)
    {
        require(spender != address(0));

        externalStorage.increaseAllowed(originSender, spender, addedValue);

        emit Approval(
            originSender, spender,
            externalStorage.getAllowed(originSender, spender)
        );

        return true;
    }

     
    function _decreaseAllowance(
        address originSender,
        address spender,
        uint256 subtractedValue
    )
        internal
        returns (bool)
    {
        require(spender != address(0));

        externalStorage.decreaseAllowed(originSender,
                                        spender,
                                        subtractedValue);

        emit Approval(
            originSender, spender,
            externalStorage.getAllowed(originSender, spender)
        );

        return true;
    }

     
    function _mint(address account, uint256 value) internal returns (bool)
    {
        require(account != 0);

        externalStorage.setTotalSupply(
            externalStorage.getTotalSupply().add(value));
        externalStorage.increaseBalance(account, value);

        emit Transfer(address(0), account, value);

        return true;
    }

     
    function _burn(address originSender, uint256 value) internal returns (bool)
    {
        require(originSender != 0);

        externalStorage.setTotalSupply(
            externalStorage.getTotalSupply().sub(value));
        externalStorage.decreaseBalance(originSender, value);

        emit Transfer(originSender, address(0), value);

        return true;
    }

     
    function _burnFrom(address originSender, address account, uint256 value)
        internal
        returns (bool)
    {
        require(value <= externalStorage.getAllowed(account, originSender));

        externalStorage.decreaseAllowed(account, originSender, value);
        _burn(account, value);

        emit Approval(account, originSender,
                      externalStorage.getAllowed(account, originSender));

        return true;
    }
}

 

 

pragma solidity 0.4.24;




 
contract UpgradeSupport is Ownable, ERC20 {

    event Upgraded(address indexed to);
    event UpgradeFinalized(address indexed upgradedFrom);

     
    address private _upgradedFrom;
    bool private enabled;
    IETokenProxy private upgradedToken;

     
    constructor(bool initialDeployment, address upgradedFrom) internal {
        require((upgradedFrom != address(0) && (!initialDeployment)) ||
                (upgradedFrom == address(0) && initialDeployment),
                "Cannot both be upgraded and initial deployment.");

        if (! initialDeployment) {
             
            enabled = false;
            _upgradedFrom = upgradedFrom;
        } else {
            enabled = true;
        }
    }

    modifier upgradeExists() {
        require(_upgradedFrom != address(0),
                "Must have a contract to upgrade from");
        _;
    }

     
    function finalizeUpgrade()
        external
        upgradeExists
        onlyProxy
    {
        enabled = true;
        emit UpgradeFinalized(msg.sender);
    }

     
    function upgrade(IETokenProxy _upgradedToken) public onlyOwner {
        require(!isUpgraded(), "Token is already upgraded");
        require(_upgradedToken != IETokenProxy(0),
                "Cannot upgrade to null address");
        require(_upgradedToken != IETokenProxy(this),
                "Cannot upgrade to myself");
        require(getExternalStorage().isImplementor(),
                "I don't own my storage. This will end badly.");

        upgradedToken = _upgradedToken;
        getExternalStorage().transferImplementor(_upgradedToken);
        _upgradedToken.finalizeUpgrade();
        emit Upgraded(_upgradedToken);
    }

     
    function isUpgraded() public view returns (bool) {
        return upgradedToken != IETokenProxy(0);
    }

     
    function getUpgradedToken() public view returns (IETokenProxy) {
        return upgradedToken;
    }

     
    modifier onlyProxy () {
        require(msg.sender == _upgradedFrom,
                "Proxy is the only allowed caller");
        _;
    }

     
    modifier isEnabled () {
        require(enabled, "Token disabled");
        _;
    }
}

 

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

 

 

pragma solidity 0.4.24;



 
contract PauserRole is Ownable {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private pausers;

    constructor() internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "not pauser");
        _;
    }

    modifier requirePauser(address account) {
        require(isPauser(account), "not pauser");
        _;
    }

     
    function isPauser(address account) public view returns (bool) {
        return pausers.has(account);
    }

     
    function addPauser(address account) public onlyOwner {
        _addPauser(account);
    }

     
    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

     
    function renouncePauser() public {
        _removePauser(msg.sender);
    }

     
    function _addPauser(address account) internal {
        pausers.add(account);
        emit PauserAdded(account);
    }

     
    function _removePauser(address account) internal {
        pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

 

pragma solidity 0.4.24;


 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private paused_;

    constructor() internal {
        paused_ = false;
    }

     
    function _paused() internal view returns(bool) {
        return paused_;
    }

     
    modifier whenNotPaused() {
        require(!paused_);
        _;
    }

     
    modifier whenPaused() {
        require(paused_);
        _;
    }

     
    modifier requireIsPauser(address account) {
        require(isPauser(account));
        _;
    }

     
    function _pause(address originSender)
        internal
    {
        paused_ = true;
        emit Paused(originSender);
    }

     
    function _unpause(address originSender)
        internal
    {
        paused_ = false;
        emit Unpaused(originSender);
    }
}

 

 

pragma solidity 0.4.24;



 
contract WhitelistAdminRole is Ownable {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private whitelistAdmins;

    constructor() internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "not whitelistAdmin");
        _;
    }

    modifier requireWhitelistAdmin(address account) {
        require(isWhitelistAdmin(account), "not whitelistAdmin");
        _;
    }

     
    function isWhitelistAdmin(address account) public view returns (bool) {
        return whitelistAdmins.has(account);
    }

     
    function addWhitelistAdmin(address account) public onlyOwner {
        _addWhitelistAdmin(account);
    }

     
    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

     
    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

     
    function _addWhitelistAdmin(address account) internal {
        whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

     
    function _removeWhitelistAdmin(address account) internal {
        whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 

 

pragma solidity 0.4.24;



 
contract BlacklistAdminRole is Ownable {
    using Roles for Roles.Role;

    event BlacklistAdminAdded(address indexed account);
    event BlacklistAdminRemoved(address indexed account);

    Roles.Role private blacklistAdmins;

    constructor() internal {
        _addBlacklistAdmin(msg.sender);
    }

    modifier onlyBlacklistAdmin() {
        require(isBlacklistAdmin(msg.sender), "not blacklistAdmin");
        _;
    }

    modifier requireBlacklistAdmin(address account) {
        require(isBlacklistAdmin(account), "not blacklistAdmin");
        _;
    }

     
    function isBlacklistAdmin(address account) public view returns (bool) {
        return blacklistAdmins.has(account);
    }

     
    function addBlacklistAdmin(address account) public onlyOwner {
        _addBlacklistAdmin(account);
    }

     
    function removeBlacklistAdmin(address account) public onlyOwner {
        _removeBlacklistAdmin(account);
    }

     
    function renounceBlacklistAdmin() public {
        _removeBlacklistAdmin(msg.sender);
    }

     
    function _addBlacklistAdmin(address account) internal {
        blacklistAdmins.add(account);
        emit BlacklistAdminAdded(account);
    }

     
    function _removeBlacklistAdmin(address account) internal {
        blacklistAdmins.remove(account);
        emit BlacklistAdminRemoved(account);
    }
}

 

 

pragma solidity 0.4.24;




 
contract Accesslist is WhitelistAdminRole, BlacklistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);
    event BlacklistAdded(address indexed account);
    event BlacklistRemoved(address indexed account);

    Roles.Role private whitelist;
    Roles.Role private blacklist;

     
    function addWhitelisted(address account)
        public
        onlyWhitelistAdmin
    {
        _addWhitelisted(account);
    }

     
    function removeWhitelisted(address account)
        public
        onlyWhitelistAdmin
    {
        _removeWhitelisted(account);
    }

     
    function addBlacklisted(address account)
        public
        onlyBlacklistAdmin
    {
        _addBlacklisted(account);
    }

     
    function removeBlacklisted(address account)
        public
        onlyBlacklistAdmin
    {
        _removeBlacklisted(account);
    }

     
    function isWhitelisted(address account)
        public
        view
        returns (bool)
    {
        return whitelist.has(account);
    }

     
    function isBlacklisted(address account)
        public
        view
        returns (bool)
    {
        return blacklist.has(account);
    }

     
    function hasAccess(address account)
        public
        view
        returns (bool)
    {
        return isWhitelisted(account) && !isBlacklisted(account);
    }


     
    function _addWhitelisted(address account) internal {
        whitelist.add(account);
        emit WhitelistAdded(account);
    }

     
    function _removeWhitelisted(address account) internal {
        whitelist.remove(account);
        emit WhitelistRemoved(account);
    }

     
    function _addBlacklisted(address account) internal {
        blacklist.add(account);
        emit BlacklistAdded(account);
    }

     
    function _removeBlacklisted(address account) internal {
        blacklist.remove(account);
        emit BlacklistRemoved(account);
    }
}

 

 

pragma solidity 0.4.24;


 
contract AccesslistGuarded {

    Accesslist private accesslist;
    bool private whitelistEnabled;

     
    constructor(
        Accesslist _accesslist,
        bool _whitelistEnabled
    )
        public
    {
        require(
            _accesslist != Accesslist(0),
            "Supplied accesslist is null"
        );
        accesslist = _accesslist;
        whitelistEnabled = _whitelistEnabled;
    }

     
    modifier requireHasAccess(address account) {
        require(hasAccess(account), "no access");
        _;
    }

     
    modifier onlyHasAccess() {
        require(hasAccess(msg.sender), "no access");
        _;
    }

     
    modifier requireWhitelisted(address account) {
        require(isWhitelisted(account), "no access");
        _;
    }

     
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "no access");
        _;
    }

     
    modifier requireNotBlacklisted(address account) {
        require(isNotBlacklisted(account), "no access");
        _;
    }

     
    modifier onlyNotBlacklisted() {
        require(isNotBlacklisted(msg.sender), "no access");
        _;
    }

     
    function hasAccess(address account) public view returns (bool) {
        if (whitelistEnabled) {
            return accesslist.hasAccess(account);
        } else {
            return isNotBlacklisted(account);
        }
    }

     
    function isWhitelisted(address account) public view returns (bool) {
        return accesslist.isWhitelisted(account);
    }

     
    function isNotBlacklisted(address account) public view returns (bool) {
        return !accesslist.isBlacklisted(account);
    }
}

 

 

pragma solidity 0.4.24;



 
contract BurnerRole is Ownable {
    using Roles for Roles.Role;

    event BurnerAdded(address indexed account);
    event BurnerRemoved(address indexed account);

    Roles.Role private burners;

    constructor() Ownable() internal {
        _addBurner(msg.sender);
    }

    modifier onlyBurner() {
        require(isBurner(msg.sender), "not burner");
        _;
    }

    modifier requireBurner(address account) {
        require(isBurner(account), "not burner");
        _;
    }

     
    function isBurner(address account) public view returns (bool) {
        return burners.has(account);
    }

     
    function addBurner(address account) public onlyOwner {
        _addBurner(account);
    }

     
    function removeBurner(address account) public onlyOwner {
        _removeBurner(account);
    }

     
    function renounceBurner() public {
        _removeBurner(msg.sender);
    }

     
    function _addBurner(address account) internal {
        burners.add(account);
        emit BurnerAdded(account);
    }

     
    function _removeBurner(address account) internal {
        burners.remove(account);
        emit BurnerRemoved(account);
    }
}

 

 

pragma solidity 0.4.24;



 
contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private minters;

     
    modifier onlyMinter() {
        require(isMinter(msg.sender), "not minter");
        _;
    }

     
    modifier requireMinter(address account) {
        require(isMinter(account), "not minter");
        _;
    }

     
    function isMinter(address account) public view returns (bool) {
        return minters.has(account);
    }

     
    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

     
    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
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

 

 

pragma solidity 0.4.24;


 
contract RestrictedMinter  {

    address private mintingRecipientAccount;

    event MintingRecipientAccountChanged(address prev, address next);

     
    constructor(address _mintingRecipientAccount) internal {
        _changeMintingRecipient(msg.sender, _mintingRecipientAccount);
    }

    modifier requireMintingRecipient(address account) {
        require(account == mintingRecipientAccount,
                "is not mintingRecpientAccount");
        _;
    }

     
    function getMintingRecipient() public view returns (address) {
        return mintingRecipientAccount;
    }

     
    function _changeMintingRecipient(
        address originSender,
        address _mintingRecipientAccount
    )
        internal
    {
        originSender;

        require(_mintingRecipientAccount != address(0),
                "zero minting recipient");
        address prev = mintingRecipientAccount;
        mintingRecipientAccount = _mintingRecipientAccount;
        emit MintingRecipientAccountChanged(prev, mintingRecipientAccount);
    }

}

 

 

pragma solidity 0.4.24;










 
contract ETokenGuarded is
    Pausable,
    ERC20,
    UpgradeSupport,
    AccesslistGuarded,
    BurnerRole,
    MinterRole,
    RestrictedMinter
{

    modifier requireOwner(address addr) {
        require(owner() == addr, "is not owner");
        _;
    }

     
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        Accesslist accesslist,
        bool whitelistEnabled,
        Storage externalStorage,
        address initialMintingRecipient,
        bool initialDeployment
    )
        internal
        ERC20(name, symbol, decimals, externalStorage, initialDeployment)
        AccesslistGuarded(accesslist, whitelistEnabled)
        RestrictedMinter(initialMintingRecipient)
    {

    }

     
    function nameGuarded(address originSender)
        internal
        view
        returns(string)
    {
         
        originSender;

        return _name();
    }

     
    function symbolGuarded(address originSender)
        internal
        view
        returns(string)
    {
         
        originSender;

        return _symbol();
    }

     
    function decimalsGuarded(address originSender)
        internal
        view
        returns(uint8)
    {
         
        originSender;

        return _decimals();
    }

     
    function totalSupplyGuarded(address originSender)
        internal
        view
        isEnabled
        returns(uint256)
    {
         
        originSender;

        return _totalSupply();
    }

     
    function balanceOfGuarded(address originSender, address who)
        internal
        view
        isEnabled
        returns(uint256)
    {
         
        originSender;

        return _balanceOf(who);
    }

     
    function allowanceGuarded(
        address originSender,
        address owner,
        address spender
    )
        internal
        view
        isEnabled
        returns(uint256)
    {
         
        originSender;

        return _allowance(owner, spender);
    }

     
    function transferGuarded(address originSender, address to, uint256 value)
        internal
        isEnabled
        whenNotPaused
        requireHasAccess(to)
        requireHasAccess(originSender)
        returns (bool)
    {
        _transfer(originSender, to, value);
        return true;
    }

     
    function approveGuarded(
        address originSender,
        address spender,
        uint256 value
    )
        internal
        isEnabled
        whenNotPaused
        requireHasAccess(spender)
        requireHasAccess(originSender)
        returns (bool)
    {
        _approve(originSender, spender, value);
        return true;
    }


     
    function transferFromGuarded(
        address originSender,
        address from,
        address to,
        uint256 value
    )
        internal
        isEnabled
        whenNotPaused
        requireHasAccess(originSender)
        requireHasAccess(from)
        requireHasAccess(to)
        returns (bool)
    {
        _transferFrom(
            originSender,
            from,
            to,
            value
        );
        return true;
    }


     
    function increaseAllowanceGuarded(
        address originSender,
        address spender,
        uint256 addedValue
    )
        internal
        isEnabled
        whenNotPaused
        requireHasAccess(originSender)
        requireHasAccess(spender)
        returns (bool)
    {
        _increaseAllowance(originSender, spender, addedValue);
        return true;
    }

     
    function decreaseAllowanceGuarded(
        address originSender,
        address spender,
        uint256 subtractedValue
    )
        internal
        isEnabled
        whenNotPaused
        requireHasAccess(originSender)
        requireHasAccess(spender)
        returns (bool)  {
        _decreaseAllowance(originSender, spender, subtractedValue);
        return true;
    }

     
    function burnGuarded(address originSender, uint256 value)
        internal
        isEnabled
        requireBurner(originSender)
    {
        _burn(originSender, value);
    }

     
    function burnFromGuarded(address originSender, address from, uint256 value)
        internal
        isEnabled
        requireBurner(originSender)
    {
        _burnFrom(originSender, from, value);
    }

     
    function mintGuarded(address originSender, address to, uint256 value)
        internal
        isEnabled
        requireMinter(originSender)
        requireMintingRecipient(to)
        returns (bool success)
    {
         
        originSender;

        _mint(to, value);
        return true;
    }

     
    function changeMintingRecipientGuarded(
        address originSender,
        address mintingRecip
    )
        internal
        isEnabled
        requireOwner(originSender)
    {
        _changeMintingRecipient(originSender, mintingRecip);
    }

     
    function pauseGuarded(address originSender)
        internal
        isEnabled
        requireIsPauser(originSender)
        whenNotPaused
    {
        _pause(originSender);
    }

     
    function unpauseGuarded(address originSender)
        internal
        isEnabled
        requireIsPauser(originSender)
        whenPaused
    {
        _unpause(originSender);
    }

     
    function pausedGuarded(address originSender)
        internal
        view
        isEnabled
        returns (bool)
    {
         
        originSender;
        return _paused();
    }
}

 

 

pragma solidity 0.4.24;




 
contract ETokenProxy is IETokenProxy, ETokenGuarded {

     
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        Accesslist accesslist,
        bool whitelistEnabled,
        Storage externalStorage,
        address initialMintingRecipient,
        address upgradedFrom,
        bool initialDeployment
    )
        internal
        UpgradeSupport(initialDeployment, upgradedFrom)
        ETokenGuarded(
            name,
            symbol,
            decimals,
            accesslist,
            whitelistEnabled,
            externalStorage,
            initialMintingRecipient,
            initialDeployment
        )
    {

    }

     
    function nameProxy(address sender)
        external
        view
        isEnabled
        onlyProxy
        returns(string)
    {
        if (isUpgraded()) {
            return getUpgradedToken().nameProxy(sender);
        } else {
            return nameGuarded(sender);
        }
    }

     
    function symbolProxy(address sender)
        external
        view
        isEnabled
        onlyProxy
        returns(string)
    {
        if (isUpgraded()) {
            return getUpgradedToken().symbolProxy(sender);
        } else {
            return symbolGuarded(sender);
        }
    }

     
    function decimalsProxy(address sender)
        external
        view
        isEnabled
        onlyProxy
        returns(uint8)
    {
        if (isUpgraded()) {
            return getUpgradedToken().decimalsProxy(sender);
        } else {
            return decimalsGuarded(sender);
        }
    }

     
    function totalSupplyProxy(address sender)
        external
        view
        isEnabled
        onlyProxy
        returns (uint256)
    {
        if (isUpgraded()) {
            return getUpgradedToken().totalSupplyProxy(sender);
        } else {
            return totalSupplyGuarded(sender);
        }
    }

     
    function balanceOfProxy(address sender, address who)
        external
        view
        isEnabled
        onlyProxy
        returns (uint256)
    {
        if (isUpgraded()) {
            return getUpgradedToken().balanceOfProxy(sender, who);
        } else {
            return balanceOfGuarded(sender, who);
        }
    }

     
    function allowanceProxy(address sender, address owner, address spender)
        external
        view
        isEnabled
        onlyProxy
        returns (uint256)
    {
        if (isUpgraded()) {
            return getUpgradedToken().allowanceProxy(sender, owner, spender);
        } else {
            return allowanceGuarded(sender, owner, spender);
        }
    }


     
    function transferProxy(address sender, address to, uint256 value)
        external
        isEnabled
        onlyProxy
        returns (bool)
    {
        if (isUpgraded()) {
            return getUpgradedToken().transferProxy(sender, to, value);
        } else {
            return transferGuarded(sender, to, value);
        }

    }

     
    function approveProxy(address sender, address spender, uint256 value)
        external
        isEnabled
        onlyProxy
        returns (bool)
    {

        if (isUpgraded()) {
            return getUpgradedToken().approveProxy(sender, spender, value);
        } else {
            return approveGuarded(sender, spender, value);
        }
    }

     
    function transferFromProxy(
        address sender,
        address from,
        address to,
        uint256 value
    )
        external
        isEnabled
        onlyProxy
        returns (bool)
    {
        if (isUpgraded()) {
            getUpgradedToken().transferFromProxy(
                sender,
                from,
                to,
                value
            );
        } else {
            transferFromGuarded(
                sender,
                from,
                to,
                value
            );
        }
    }

     
    function mintProxy(address sender, address to, uint256 value)
        external
        isEnabled
        onlyProxy
        returns (bool)
    {
        if (isUpgraded()) {
            return getUpgradedToken().mintProxy(sender, to, value);
        } else {
            return mintGuarded(sender, to, value);
        }
    }

     
    function changeMintingRecipientProxy(address sender,
                                         address mintingRecip)
        external
        isEnabled
        onlyProxy
    {
        if (isUpgraded()) {
            getUpgradedToken().changeMintingRecipientProxy(sender, mintingRecip);
        } else {
            changeMintingRecipientGuarded(sender, mintingRecip);
        }
    }

     
    function burnProxy(address sender, uint256 value)
        external
        isEnabled
        onlyProxy
    {
        if (isUpgraded()) {
            getUpgradedToken().burnProxy(sender, value);
        } else {
            burnGuarded(sender, value);
        }
    }

     
    function burnFromProxy(address sender, address from, uint256 value)
        external
        isEnabled
        onlyProxy
    {
        if (isUpgraded()) {
            getUpgradedToken().burnFromProxy(sender, from, value);
        } else {
            burnFromGuarded(sender, from, value);
        }
    }

     
    function increaseAllowanceProxy(
        address sender,
        address spender,
        uint addedValue
    )
        external
        isEnabled
        onlyProxy
        returns (bool)
    {
        if (isUpgraded()) {
            return getUpgradedToken().increaseAllowanceProxy(
                sender, spender, addedValue);
        } else {
            return increaseAllowanceGuarded(sender, spender, addedValue);
        }
    }

     
    function decreaseAllowanceProxy(
        address sender,
        address spender,
        uint subtractedValue
    )
        external
        isEnabled
        onlyProxy
        returns (bool)
    {
        if (isUpgraded()) {
            return getUpgradedToken().decreaseAllowanceProxy(
                sender, spender, subtractedValue);
        } else {
            return decreaseAllowanceGuarded(sender, spender, subtractedValue);
        }
    }

     
    function pauseProxy(address sender)
        external
        isEnabled
        onlyProxy
    {
        if (isUpgraded()) {
            getUpgradedToken().pauseProxy(sender);
        } else {
            pauseGuarded(sender);
        }
    }

     
    function unpauseProxy(address sender)
        external
        isEnabled
        onlyProxy
    {
        if (isUpgraded()) {
            getUpgradedToken().unpauseProxy(sender);
        } else {
            unpauseGuarded(sender);
        }
    }

     
    function pausedProxy(address sender)
        external
        view
        isEnabled
        onlyProxy
        returns (bool)
    {
        if (isUpgraded()) {
            return getUpgradedToken().pausedProxy(sender);
        } else {
            return pausedGuarded(sender);
        }
    }
}

 

 

pragma solidity 0.4.24;



 
contract EToken is IEToken, ETokenProxy {

     
    constructor(
        string name,
        string symbol,
        uint8 decimals,
        Accesslist accesslist,
        bool whitelistEnabled,
        Storage externalStorage,
        address initialMintingRecipient,
        address upgradedFrom,
        bool initialDeployment
    )
        public
        ETokenProxy(
            name,
            symbol,
            decimals,
            accesslist,
            whitelistEnabled,
            externalStorage,
            initialMintingRecipient,
            upgradedFrom,
            initialDeployment
        )
    {

    }

     
    function name() public view returns(string) {
        if (isUpgraded()) {
            return getUpgradedToken().nameProxy(msg.sender);
        } else {
            return nameGuarded(msg.sender);
        }
    }

     
    function symbol() public view returns(string) {
        if (isUpgraded()) {
            return getUpgradedToken().symbolProxy(msg.sender);
        } else {
            return symbolGuarded(msg.sender);
        }
    }

     
    function decimals() public view returns(uint8) {
        if (isUpgraded()) {
            return getUpgradedToken().decimalsProxy(msg.sender);
        } else {
            return decimalsGuarded(msg.sender);
        }
    }

     
    function totalSupply() public view returns (uint256) {
        if (isUpgraded()) {
            return getUpgradedToken().totalSupplyProxy(msg.sender);
        } else {
            return totalSupplyGuarded(msg.sender);
        }
    }

     
    function balanceOf(address who) public view returns (uint256) {
        if (isUpgraded()) {
            return getUpgradedToken().balanceOfProxy(msg.sender, who);
        } else {
            return balanceOfGuarded(msg.sender, who);
        }
    }

     
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        if (isUpgraded()) {
            return getUpgradedToken().allowanceProxy(
                msg.sender,
                owner,
                spender
            );
        } else {
            return allowanceGuarded(msg.sender, owner, spender);
        }
    }


     
    function transfer(address to, uint256 value) public returns (bool) {
        if (isUpgraded()) {
            return getUpgradedToken().transferProxy(msg.sender, to, value);
        } else {
            return transferGuarded(msg.sender, to, value);
        }
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        if (isUpgraded()) {
            return getUpgradedToken().approveProxy(msg.sender, spender, value);
        } else {
            return approveGuarded(msg.sender, spender, value);
        }
    }

     
    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool)
    {
        if (isUpgraded()) {
            return getUpgradedToken().transferFromProxy(
                msg.sender,
                from,
                to,
                value
            );
        } else {
            return transferFromGuarded(
                msg.sender,
                from,
                to,
                value
            );
        }
    }

     
    function mint(address to, uint256 value) public returns (bool) {
        if (isUpgraded()) {
            return getUpgradedToken().mintProxy(msg.sender, to, value);
        } else {
            return mintGuarded(msg.sender, to, value);
        }
    }

     
    function burn(uint256 value) public {
        if (isUpgraded()) {
            getUpgradedToken().burnProxy(msg.sender, value);
        } else {
            burnGuarded(msg.sender, value);
        }
    }

     
    function burnFrom(address from, uint256 value) public {
        if (isUpgraded()) {
            getUpgradedToken().burnFromProxy(msg.sender, from, value);
        } else {
            burnFromGuarded(msg.sender, from, value);
        }
    }

     
    function increaseAllowance(
        address spender,
        uint addedValue
    )
        public
        returns (bool success)
    {
        if (isUpgraded()) {
            return getUpgradedToken().increaseAllowanceProxy(
                msg.sender,
                spender,
                addedValue
            );
        } else {
            return increaseAllowanceGuarded(msg.sender, spender, addedValue);
        }
    }

     
    function decreaseAllowance(
        address spender,
        uint subtractedValue
    )
        public
        returns (bool success)
    {
        if (isUpgraded()) {
            return getUpgradedToken().decreaseAllowanceProxy(
                msg.sender,
                spender,
                subtractedValue
            );
        } else {
            return super.decreaseAllowanceGuarded(
                msg.sender,
                spender,
                subtractedValue
            );
        }
    }

     
    function changeMintingRecipient(address mintingRecip) public {
        if (isUpgraded()) {
            getUpgradedToken().changeMintingRecipientProxy(
                msg.sender,
                mintingRecip
            );
        } else {
            changeMintingRecipientGuarded(msg.sender, mintingRecip);
        }
    }

     
    function pause() public {
        if (isUpgraded()) {
            getUpgradedToken().pauseProxy(msg.sender);
        } else {
            pauseGuarded(msg.sender);
        }
    }

     
    function unpause() public {
        if (isUpgraded()) {
            getUpgradedToken().unpauseProxy(msg.sender);
        } else {
            unpauseGuarded(msg.sender);
        }
    }

     
    function paused() public view returns (bool) {
        if (isUpgraded()) {
            return getUpgradedToken().pausedProxy(msg.sender);
        } else {
            return pausedGuarded(msg.sender);
        }
    }
}