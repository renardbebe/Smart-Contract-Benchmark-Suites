 

pragma solidity ^0.4.11;

 

 

pragma solidity ^0.4.23;


 
contract ERC20Interface {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    string public symbol;

    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

 

 

pragma solidity ^0.4.24;


contract ChronoBankAssetChainableInterface {

    function assetType() public pure returns (bytes32);

    function getPreviousAsset() public view returns (ChronoBankAssetChainableInterface);
    function getNextAsset() public view returns (ChronoBankAssetChainableInterface);

    function getChainedAssets() public view returns (bytes32[] _types, address[] _assets);
    function getAssetByType(bytes32 _assetType) public view returns (address);

    function chainAssets(ChronoBankAssetChainableInterface[] _assets) external returns (bool);
    function __chainAssetsFromIdx(ChronoBankAssetChainableInterface[] _assets, uint _startFromIdx) external returns (bool);

    function finalizeAssetChaining() public;
}

 

 

pragma solidity ^0.4.24;



library ChronoBankAssetUtils {

    uint constant ASSETS_CHAIN_MAX_LENGTH = 20;

    function getChainedAssets(ChronoBankAssetChainableInterface _asset)
    public
    view
    returns (bytes32[] _types, address[] _assets)
    {
        bytes32[] memory _tempTypes = new bytes32[](ASSETS_CHAIN_MAX_LENGTH);
        address[] memory _tempAssets = new address[](ASSETS_CHAIN_MAX_LENGTH);

        ChronoBankAssetChainableInterface _next = getHeadAsset(_asset);
        uint _counter = 0;
        do {
            _tempTypes[_counter] = _next.assetType();
            _tempAssets[_counter] = address(_next);
            _counter += 1;

            _next = _next.getNextAsset();
        } while (address(_next) != 0x0);

        _types = new bytes32[](_counter);
        _assets = new address[](_counter);
        for (uint _assetIdx = 0; _assetIdx < _counter; ++_assetIdx) {
            _types[_assetIdx] = _tempTypes[_assetIdx];
            _assets[_assetIdx] = _tempAssets[_assetIdx];
        }
    }

    function getAssetByType(ChronoBankAssetChainableInterface _asset, bytes32 _assetType)
    public
    view
    returns (address)
    {
        ChronoBankAssetChainableInterface _next = getHeadAsset(_asset);
        do {
            if (_next.assetType() == _assetType) {
                return address(_next);
            }

            _next = _next.getNextAsset();
        } while (address(_next) != 0x0);
    }

    function containsAssetInChain(ChronoBankAssetChainableInterface _asset, address _checkAsset)
    public
    view
    returns (bool)
    {
        ChronoBankAssetChainableInterface _next = getHeadAsset(_asset);
        do {
            if (address(_next) == _checkAsset) {
                return true;
            }

            _next = _next.getNextAsset();
        } while (address(_next) != 0x0);
    }

    function getHeadAsset(ChronoBankAssetChainableInterface _asset)
    public
    view
    returns (ChronoBankAssetChainableInterface)
    {
        ChronoBankAssetChainableInterface _head = _asset;
        ChronoBankAssetChainableInterface _previousAsset;
        do {
            _previousAsset = _head.getPreviousAsset();
            if (address(_previousAsset) == 0x0) {
                return _head;
            }
            _head = _previousAsset;
        } while (true);
    }
}

 

 

pragma solidity ^0.4.21;


 
contract EventsHistorySourceAdapter {

     
    function _self()
    internal
    view
    returns (address)
    {
        return msg.sender;
    }
}

 

 

pragma solidity ^0.4.21;



 
contract MultiEventsHistoryAdapter is EventsHistorySourceAdapter {

    address internal localEventsHistory;

    event ErrorCode(address indexed self, uint errorCode);

    function getEventsHistory()
    public
    view
    returns (address)
    {
        address _eventsHistory = localEventsHistory;
        return _eventsHistory != 0x0 ? _eventsHistory : this;
    }

    function emitErrorCode(uint _errorCode) public {
        emit ErrorCode(_self(), _errorCode);
    }

    function _setEventsHistory(address _eventsHistory) internal returns (bool) {
        localEventsHistory = _eventsHistory;
        return true;
    }

    function _emitErrorCode(uint _errorCode) internal returns (uint) {
        MultiEventsHistoryAdapter(getEventsHistory()).emitErrorCode(_errorCode);
        return _errorCode;
    }
}

 

 

pragma solidity ^0.4.21;



 
 
 
 
 
contract ChronoBankPlatformEmitter is MultiEventsHistoryAdapter {

    event Transfer(address indexed from, address indexed to, bytes32 indexed symbol, uint value, string reference);
    event Issue(bytes32 indexed symbol, uint value, address indexed by);
    event Revoke(bytes32 indexed symbol, uint value, address indexed by);
    event RevokeExternal(bytes32 indexed symbol, uint value, address indexed by, string externalReference);
    event OwnershipChange(address indexed from, address indexed to, bytes32 indexed symbol);
    event Approve(address indexed from, address indexed spender, bytes32 indexed symbol, uint value);
    event Recovery(address indexed from, address indexed to, address by);

    function emitTransfer(address _from, address _to, bytes32 _symbol, uint _value, string _reference) public {
        emit Transfer(_from, _to, _symbol, _value, _reference);
    }

    function emitIssue(bytes32 _symbol, uint _value, address _by) public {
        emit Issue(_symbol, _value, _by);
    }

    function emitRevoke(bytes32 _symbol, uint _value, address _by) public {
        emit Revoke(_symbol, _value, _by);
    }

    function emitRevokeExternal(bytes32 _symbol, uint _value, address _by, string _externalReference) public {
        emit RevokeExternal(_symbol, _value, _by, _externalReference);
    }

    function emitOwnershipChange(address _from, address _to, bytes32 _symbol) public {
        emit OwnershipChange(_from, _to, _symbol);
    }

    function emitApprove(address _from, address _spender, bytes32 _symbol, uint _value) public {
        emit Approve(_from, _spender, _symbol, _value);
    }

    function emitRecovery(address _from, address _to, address _by) public {
        emit Recovery(_from, _to, _by);
    }
}

 

 

pragma solidity ^0.4.11;



contract ChronoBankPlatformInterface is ChronoBankPlatformEmitter {
    mapping(bytes32 => address) public proxies;

    function symbols(uint _idx) public view returns (bytes32);
    function symbolsCount() public view returns (uint);
    function isCreated(bytes32 _symbol) public view returns(bool);
    function isOwner(address _owner, bytes32 _symbol) public view returns(bool);
    function owner(bytes32 _symbol) public view returns(address);

    function setProxy(address _address, bytes32 _symbol) public returns(uint errorCode);

    function name(bytes32 _symbol) public view returns(string);

    function totalSupply(bytes32 _symbol) public view returns(uint);
    function balanceOf(address _holder, bytes32 _symbol) public view returns(uint);
    function allowance(address _from, address _spender, bytes32 _symbol) public view returns(uint);
    function baseUnit(bytes32 _symbol) public view returns(uint8);
    function description(bytes32 _symbol) public view returns(string);
    function isReissuable(bytes32 _symbol) public view returns(bool);
    function blockNumber(bytes32 _symbol) public view returns (uint);

    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns(uint errorCode);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns(uint errorCode);

    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) public returns(uint errorCode);

    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable, uint _blockNumber) public returns(uint errorCode);
    function issueAssetWithInitialReceiver(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable, uint _blockNumber, address _account) public returns(uint errorCode);

    function reissueAsset(bytes32 _symbol, uint _value) public returns(uint errorCode);
    function reissueAssetToRecepient(bytes32 _symbol, uint _value, address _to) public returns (uint);

    function revokeAsset(bytes32 _symbol, uint _value) public returns(uint errorCode);
    function revokeAssetWithExternalReference(bytes32 _symbol, uint _value, string _externalReference) public returns (uint);

    function hasAssetRights(address _owner, bytes32 _symbol) public view returns (bool);
    function isDesignatedAssetManager(address _account, bytes32 _symbol) public view returns (bool);
    function changeOwnership(bytes32 _symbol, address _newOwner) public returns(uint errorCode);
}

 

 

pragma solidity ^0.4.21;


contract ChronoBankAssetInterface {
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __approve(address _spender, uint _value, address _sender) public returns(bool);
    function __process(bytes  , address  ) public payable {
        revert("ASSET_PROCESS_NOT_SUPPORTED");
    }
}

 

 

pragma solidity ^0.4.21;


contract ERC20 is ERC20Interface {}

contract ChronoBankAsset is ChronoBankAssetInterface {}



 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract ChronoBankAssetProxy is ERC20 {

     
    uint constant OK = 1;

     
    ChronoBankPlatform public chronoBankPlatform;

     
    bytes32 public smbl;

     
    string public name;

     
    string public symbol;

     
     
     
     
     
     
    function init(ChronoBankPlatform _chronoBankPlatform, string _symbol, string _name) public returns (bool) {
        if (address(chronoBankPlatform) != 0x0) {
            return false;
        }

        chronoBankPlatform = _chronoBankPlatform;
        symbol = _symbol;
        smbl = stringToBytes32(_symbol);
        name = _name;
        return true;
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
           result := mload(add(source, 32))
        }
    }

     
    modifier onlyChronoBankPlatform {
        if (msg.sender == address(chronoBankPlatform)) {
            _;
        }
    }

     
    modifier onlyAssetOwner {
        if (chronoBankPlatform.isOwner(msg.sender, smbl)) {
            _;
        }
    }

     
     
    function _getAsset() internal view returns (ChronoBankAsset) {
        return ChronoBankAsset(getVersionFor(msg.sender));
    }

     
     
    function totalSupply() public view returns (uint) {
        return chronoBankPlatform.totalSupply(smbl);
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint) {
        return chronoBankPlatform.balanceOf(_owner, smbl);
    }

     
     
     
     
    function allowance(address _from, address _spender) public view returns (uint) {
        return chronoBankPlatform.allowance(_from, _spender, smbl);
    }

     
     
    function decimals() public view returns (uint8) {
        return chronoBankPlatform.baseUnit(smbl);
    }

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool) {
        if (_to != 0x0) {
            return _transferWithReference(_to, _value, "");
        }
    }

     
     
     
     
     
    function transferWithReference(address _to, uint _value, string _reference) public returns (bool) {
        if (_to != 0x0) {
            return _transferWithReference(_to, _value, _reference);
        }
    }

     
     
     
    function _transferWithReference(address _to, uint _value, string _reference) internal returns (bool) {
        return _getAsset().__transferWithReference(_to, _value, _reference, msg.sender);
    }

     
     
     
     
     
     
     
     
     
     
    function __transferWithReference(
        address _to,
        uint _value,
        string _reference,
        address _sender
    )
    onlyAccess(_sender)
    public
    returns (bool)
    {
        return chronoBankPlatform.proxyTransferWithReference(_to, _value, smbl, _reference, _sender) == OK;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (_to != 0x0) {
            return _getAsset().__transferFromWithReference(_from, _to, _value, "", msg.sender);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function __transferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string _reference,
        address _sender
    )
    onlyAccess(_sender)
    public
    returns (bool)
    {
        return chronoBankPlatform.proxyTransferFromWithReference(_from, _to, _value, smbl, _reference, _sender) == OK;
    }

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool) {
        if (_spender != 0x0) {
            return _getAsset().__approve(_spender, _value, msg.sender);
        }
    }

     
     
     
     
     
     
    function __approve(address _spender, uint _value, address _sender) onlyAccess(_sender) public returns (bool) {
        return chronoBankPlatform.proxyApprove(_spender, _value, smbl, _sender) == OK;
    }

     
     
    function emitTransfer(address _from, address _to, uint _value) onlyChronoBankPlatform public {
        emit Transfer(_from, _to, _value);
    }

     
     
    function emitApprove(address _from, address _spender, uint _value) onlyChronoBankPlatform public {
        emit Approval(_from, _spender, _value);
    }

     
     
    function () public payable {
        _getAsset().__process.value(msg.value)(msg.data, msg.sender);
    }

     
    event UpgradeProposal(address newVersion);

     
    address latestVersion;

     
    address pendingVersion;

     
    uint pendingVersionTimestamp;

     
    uint constant UPGRADE_FREEZE_TIME = 3 days;

     
     
    mapping(address => address) userOptOutVersion;

     
    modifier onlyAccess(address _sender) {
        address _versionFor = getVersionFor(_sender);
        if (msg.sender == _versionFor ||
            ChronoBankAssetUtils.containsAssetInChain(ChronoBankAssetChainableInterface(_versionFor), msg.sender)
        ) {
            _;
        }
    }

     
     
     
    function getVersionFor(address _sender) public view returns (address) {
        return userOptOutVersion[_sender] == 0 ? latestVersion : userOptOutVersion[_sender];
    }

     
     
    function getLatestVersion() public view returns (address) {
        return latestVersion;
    }

     
     
    function getPendingVersion() public view returns (address) {
        return pendingVersion;
    }

     
     
    function getPendingVersionTimestamp() public view returns (uint) {
        return pendingVersionTimestamp;
    }

     
     
     
     
     
    function proposeUpgrade(address _newVersion) onlyAssetOwner public returns (bool) {
         
        if (pendingVersion != 0x0) {
            return false;
        }

         
        if (_newVersion == 0x0) {
            return false;
        }

         
        if (latestVersion == 0x0) {
            latestVersion = _newVersion;
            return true;
        }

        pendingVersion = _newVersion;
        pendingVersionTimestamp = now;

        emit UpgradeProposal(_newVersion);
        return true;
    }

     
     
     
    function purgeUpgrade() public onlyAssetOwner returns (bool) {
        if (pendingVersion == 0x0) {
            return false;
        }

        delete pendingVersion;
        delete pendingVersionTimestamp;
        return true;
    }

     
     
     
    function commitUpgrade() public returns (bool) {
        if (pendingVersion == 0x0) {
            return false;
        }

        if (pendingVersionTimestamp + UPGRADE_FREEZE_TIME > now) {
            return false;
        }

        latestVersion = pendingVersion;
        delete pendingVersion;
        delete pendingVersionTimestamp;
        return true;
    }

     
     
     
    function optOut() public returns (bool) {
        if (userOptOutVersion[msg.sender] != 0x0) {
            return false;
        }
        userOptOutVersion[msg.sender] = latestVersion;
        return true;
    }

     
     
     
    function optIn() public returns (bool) {
        delete userOptOutVersion[msg.sender];
        return true;
    }
}

 

 

pragma solidity ^0.4.23;



 
 
 
 
contract Owned {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public contractOwner;
    address public pendingContractOwner;

    modifier onlyContractOwner {
        if (msg.sender == contractOwner) {
            _;
        }
    }

    constructor()
    public
    {
        contractOwner = msg.sender;
    }

     
     
     
     
    function changeContractOwnership(address _to)
    public
    onlyContractOwner
    returns (bool)
    {
        if (_to == 0x0) {
            return false;
        }
        pendingContractOwner = _to;
        return true;
    }

     
     
     
    function claimContractOwnership()
    public
    returns (bool)
    {
        if (msg.sender != pendingContractOwner) {
            return false;
        }

        emit OwnershipTransferred(contractOwner, pendingContractOwner);
        contractOwner = pendingContractOwner;
        delete pendingContractOwner;
        return true;
    }

     
     
    function transferOwnership(address newOwner)
    public
    onlyContractOwner
    returns (bool)
    {
        if (newOwner == 0x0) {
            return false;
        }

        emit OwnershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
        delete pendingContractOwner;
        return true;
    }

     
     
     
    function transferContractOwnership(address newOwner)
    public
    returns (bool)
    {
        return transferOwnership(newOwner);
    }

     
     
    function withdrawTokens(address[] tokens)
    public
    onlyContractOwner
    {
        address _contractOwner = contractOwner;
        for (uint i = 0; i < tokens.length; i++) {
            ERC20Interface token = ERC20Interface(tokens[i]);
            uint balance = token.balanceOf(this);
            if (balance > 0) {
                token.transfer(_contractOwner, balance);
            }
        }
    }

     
     
    function withdrawEther()
    public
    onlyContractOwner
    {
        uint balance = address(this).balance;
        if (balance > 0)  {
            contractOwner.transfer(balance);
        }
    }

     
     
     
     
    function transferEther(address _to, uint256 _value)
    public
    onlyContractOwner
    {
        require(_to != 0x0, "INVALID_ETHER_RECEPIENT_ADDRESS");
        if (_value > address(this).balance) {
            revert("INVALID_VALUE_TO_TRANSFER_ETHER");
        }

        _to.transfer(_value);
    }
}

 

 

pragma solidity ^0.4.23;



contract Manager {
    function isAllowed(address _actor, bytes32 _role) public view returns (bool);
    function hasAccess(address _actor) public view returns (bool);
}


contract Storage is Owned {
    struct Crate {
        mapping(bytes32 => uint) uints;
        mapping(bytes32 => address) addresses;
        mapping(bytes32 => bool) bools;
        mapping(bytes32 => int) ints;
        mapping(bytes32 => uint8) uint8s;
        mapping(bytes32 => bytes32) bytes32s;
        mapping(bytes32 => AddressUInt8) addressUInt8s;
        mapping(bytes32 => string) strings;
    }

    struct AddressUInt8 {
        address _address;
        uint8 _uint8;
    }

    mapping(bytes32 => Crate) internal crates;
    Manager public manager;

    modifier onlyAllowed(bytes32 _role) {
        if (!(msg.sender == address(this) || manager.isAllowed(msg.sender, _role))) {
            revert("STORAGE_FAILED_TO_ACCESS_PROTECTED_FUNCTION");
        }
        _;
    }

    function setManager(Manager _manager)
    external
    onlyContractOwner
    returns (bool)
    {
        manager = _manager;
        return true;
    }

    function setUInt(bytes32 _crate, bytes32 _key, uint _value)
    public
    onlyAllowed(_crate)
    {
        _setUInt(_crate, _key, _value);
    }

    function _setUInt(bytes32 _crate, bytes32 _key, uint _value)
    internal
    {
        crates[_crate].uints[_key] = _value;
    }


    function getUInt(bytes32 _crate, bytes32 _key)
    public
    view
    returns (uint)
    {
        return crates[_crate].uints[_key];
    }

    function setAddress(bytes32 _crate, bytes32 _key, address _value)
    public
    onlyAllowed(_crate)
    {
        _setAddress(_crate, _key, _value);
    }

    function _setAddress(bytes32 _crate, bytes32 _key, address _value)
    internal
    {
        crates[_crate].addresses[_key] = _value;
    }

    function getAddress(bytes32 _crate, bytes32 _key)
    public
    view
    returns (address)
    {
        return crates[_crate].addresses[_key];
    }

    function setBool(bytes32 _crate, bytes32 _key, bool _value)
    public
    onlyAllowed(_crate)
    {
        _setBool(_crate, _key, _value);
    }

    function _setBool(bytes32 _crate, bytes32 _key, bool _value)
    internal
    {
        crates[_crate].bools[_key] = _value;
    }

    function getBool(bytes32 _crate, bytes32 _key)
    public
    view
    returns (bool)
    {
        return crates[_crate].bools[_key];
    }

    function setInt(bytes32 _crate, bytes32 _key, int _value)
    public
    onlyAllowed(_crate)
    {
        _setInt(_crate, _key, _value);
    }

    function _setInt(bytes32 _crate, bytes32 _key, int _value)
    internal
    {
        crates[_crate].ints[_key] = _value;
    }

    function getInt(bytes32 _crate, bytes32 _key)
    public
    view
    returns (int)
    {
        return crates[_crate].ints[_key];
    }

    function setUInt8(bytes32 _crate, bytes32 _key, uint8 _value)
    public
    onlyAllowed(_crate)
    {
        _setUInt8(_crate, _key, _value);
    }

    function _setUInt8(bytes32 _crate, bytes32 _key, uint8 _value)
    internal
    {
        crates[_crate].uint8s[_key] = _value;
    }

    function getUInt8(bytes32 _crate, bytes32 _key)
    public
    view
    returns (uint8)
    {
        return crates[_crate].uint8s[_key];
    }

    function setBytes32(bytes32 _crate, bytes32 _key, bytes32 _value)
    public
    onlyAllowed(_crate)
    {
        _setBytes32(_crate, _key, _value);
    }

    function _setBytes32(bytes32 _crate, bytes32 _key, bytes32 _value)
    internal
    {
        crates[_crate].bytes32s[_key] = _value;
    }

    function getBytes32(bytes32 _crate, bytes32 _key)
    public
    view
    returns (bytes32)
    {
        return crates[_crate].bytes32s[_key];
    }

    function setAddressUInt8(bytes32 _crate, bytes32 _key, address _value, uint8 _value2)
    public
    onlyAllowed(_crate)
    {
        _setAddressUInt8(_crate, _key, _value, _value2);
    }

    function _setAddressUInt8(bytes32 _crate, bytes32 _key, address _value, uint8 _value2)
    internal
    {
        crates[_crate].addressUInt8s[_key] = AddressUInt8(_value, _value2);
    }

    function getAddressUInt8(bytes32 _crate, bytes32 _key)
    public
    view
    returns (address, uint8)
    {
        return (crates[_crate].addressUInt8s[_key]._address, crates[_crate].addressUInt8s[_key]._uint8);
    }

    function setString(bytes32 _crate, bytes32 _key, string _value)
    public
    onlyAllowed(_crate)
    {
        _setString(_crate, _key, _value);
    }

    function _setString(bytes32 _crate, bytes32 _key, string _value)
    internal
    {
        crates[_crate].strings[_key] = _value;
    }

    function getString(bytes32 _crate, bytes32 _key)
    public
    view
    returns (string)
    {
        return crates[_crate].strings[_key];
    }
}

 

 

pragma solidity ^0.4.23;



library StorageInterface {
    struct Config {
        Storage store;
        bytes32 crate;
    }

    struct UInt {
        bytes32 id;
    }

    struct UInt8 {
        bytes32 id;
    }

    struct Int {
        bytes32 id;
    }

    struct Address {
        bytes32 id;
    }

    struct Bool {
        bytes32 id;
    }

    struct Bytes32 {
        bytes32 id;
    }

    struct String {
        bytes32 id;
    }

    struct Mapping {
        bytes32 id;
    }

    struct StringMapping {
        String id;
    }

    struct UIntBoolMapping {
        Bool innerMapping;
    }

    struct UIntUIntMapping {
        Mapping innerMapping;
    }

    struct UIntBytes32Mapping {
        Mapping innerMapping;
    }

    struct UIntAddressMapping {
        Mapping innerMapping;
    }

    struct UIntEnumMapping {
        Mapping innerMapping;
    }

    struct AddressBoolMapping {
        Mapping innerMapping;
    }

    struct AddressUInt8Mapping {
        bytes32 id;
    }

    struct AddressUIntMapping {
        Mapping innerMapping;
    }

    struct AddressBytes32Mapping {
        Mapping innerMapping;
    }

    struct AddressAddressMapping {
        Mapping innerMapping;
    }

    struct Bytes32UIntMapping {
        Mapping innerMapping;
    }

    struct Bytes32UInt8Mapping {
        UInt8 innerMapping;
    }

    struct Bytes32BoolMapping {
        Bool innerMapping;
    }

    struct Bytes32Bytes32Mapping {
        Mapping innerMapping;
    }

    struct Bytes32AddressMapping {
        Mapping innerMapping;
    }

    struct Bytes32UIntBoolMapping {
        Bool innerMapping;
    }

    struct AddressAddressUInt8Mapping {
        Mapping innerMapping;
    }

    struct AddressAddressUIntMapping {
        Mapping innerMapping;
    }

    struct AddressUIntUIntMapping {
        Mapping innerMapping;
    }

    struct AddressUIntUInt8Mapping {
        Mapping innerMapping;
    }

    struct AddressBytes32Bytes32Mapping {
        Mapping innerMapping;
    }

    struct AddressBytes4BoolMapping {
        Mapping innerMapping;
    }

    struct AddressBytes4Bytes32Mapping {
        Mapping innerMapping;
    }

    struct UIntAddressUIntMapping {
        Mapping innerMapping;
    }

    struct UIntAddressAddressMapping {
        Mapping innerMapping;
    }

    struct UIntAddressBoolMapping {
        Mapping innerMapping;
    }

    struct UIntUIntAddressMapping {
        Mapping innerMapping;
    }

    struct UIntUIntBytes32Mapping {
        Mapping innerMapping;
    }

    struct UIntUIntUIntMapping {
        Mapping innerMapping;
    }

    struct Bytes32UIntUIntMapping {
        Mapping innerMapping;
    }

    struct AddressUIntUIntUIntMapping {
        Mapping innerMapping;
    }

    struct AddressUIntStructAddressUInt8Mapping {
        AddressUInt8Mapping innerMapping;
    }

    struct AddressUIntUIntStructAddressUInt8Mapping {
        AddressUInt8Mapping innerMapping;
    }

    struct AddressUIntUIntUIntStructAddressUInt8Mapping {
        AddressUInt8Mapping innerMapping;
    }

    struct AddressUIntUIntUIntUIntStructAddressUInt8Mapping {
        AddressUInt8Mapping innerMapping;
    }

    struct AddressUIntAddressUInt8Mapping {
        Mapping innerMapping;
    }

    struct AddressUIntUIntAddressUInt8Mapping {
        Mapping innerMapping;
    }

    struct AddressUIntUIntUIntAddressUInt8Mapping {
        Mapping innerMapping;
    }

    struct UIntAddressAddressBoolMapping {
        Bool innerMapping;
    }

    struct UIntUIntUIntBytes32Mapping {
        Mapping innerMapping;
    }

    struct Bytes32UIntUIntUIntMapping {
        Mapping innerMapping;
    }

    bytes32 constant SET_IDENTIFIER = "set";

    struct Set {
        UInt count;
        Mapping indexes;
        Mapping values;
    }

    struct AddressesSet {
        Set innerSet;
    }

    struct CounterSet {
        Set innerSet;
    }

    bytes32 constant ORDERED_SET_IDENTIFIER = "ordered_set";

    struct OrderedSet {
        UInt count;
        Bytes32 first;
        Bytes32 last;
        Mapping nextValues;
        Mapping previousValues;
    }

    struct OrderedUIntSet {
        OrderedSet innerSet;
    }

    struct OrderedAddressesSet {
        OrderedSet innerSet;
    }

    struct Bytes32SetMapping {
        Set innerMapping;
    }

    struct AddressesSetMapping {
        Bytes32SetMapping innerMapping;
    }

    struct UIntSetMapping {
        Bytes32SetMapping innerMapping;
    }

    struct Bytes32OrderedSetMapping {
        OrderedSet innerMapping;
    }

    struct UIntOrderedSetMapping {
        Bytes32OrderedSetMapping innerMapping;
    }

    struct AddressOrderedSetMapping {
        Bytes32OrderedSetMapping innerMapping;
    }

     
    function sanityCheck(bytes32 _currentId, bytes32 _newId) internal pure {
        if (_currentId != 0 || _newId == 0) {
            revert();
        }
    }

    function init(Config storage self, Storage _store, bytes32 _crate) internal {
        self.store = _store;
        self.crate = _crate;
    }

    function init(UInt8 storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(UInt storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(Int storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(Address storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(Bool storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(Bytes32 storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(String storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(Mapping storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StringMapping storage self, bytes32 _id) internal {
        init(self.id, _id);
    }

    function init(UIntAddressMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntEnumMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressAddressUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressBytes32Bytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntAddressUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntAddressBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntUIntAddressMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntAddressAddressMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntUIntBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntAddressAddressBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntUIntUIntBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32UIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32UIntUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUInt8Mapping storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(AddressUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressAddressMapping  storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressBytes4BoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressBytes4Bytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUIntUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUIntUIntUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUIntAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressUIntUIntUIntAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32UIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32UInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32BoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32Bytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32AddressMapping  storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32UIntBoolMapping  storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Set storage self, bytes32 _id) internal {
        init(self.count, keccak256(abi.encodePacked(_id, "count")));
        init(self.indexes, keccak256(abi.encodePacked(_id, "indexes")));
        init(self.values, keccak256(abi.encodePacked(_id, "values")));
    }

    function init(AddressesSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(CounterSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(OrderedSet storage self, bytes32 _id) internal {
        init(self.count, keccak256(abi.encodePacked(_id, "uint/count")));
        init(self.first, keccak256(abi.encodePacked(_id, "uint/first")));
        init(self.last, keccak256(abi.encodePacked(_id, "uint/last")));
        init(self.nextValues, keccak256(abi.encodePacked(_id, "uint/next")));
        init(self.previousValues, keccak256(abi.encodePacked(_id, "uint/prev")));
    }

    function init(OrderedUIntSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(OrderedAddressesSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(Bytes32SetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressesSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(Bytes32OrderedSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(UIntOrderedSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(AddressOrderedSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

     

    function set(Config storage self, UInt storage item, uint _value) internal {
        self.store.setUInt(self.crate, item.id, _value);
    }

    function set(Config storage self, UInt storage item, bytes32 _salt, uint _value) internal {
        self.store.setUInt(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(Config storage self, UInt8 storage item, uint8 _value) internal {
        self.store.setUInt8(self.crate, item.id, _value);
    }

    function set(Config storage self, UInt8 storage item, bytes32 _salt, uint8 _value) internal {
        self.store.setUInt8(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(Config storage self, Int storage item, int _value) internal {
        self.store.setInt(self.crate, item.id, _value);
    }

    function set(Config storage self, Int storage item, bytes32 _salt, int _value) internal {
        self.store.setInt(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(Config storage self, Address storage item, address _value) internal {
        self.store.setAddress(self.crate, item.id, _value);
    }

    function set(Config storage self, Address storage item, bytes32 _salt, address _value) internal {
        self.store.setAddress(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(Config storage self, Bool storage item, bool _value) internal {
        self.store.setBool(self.crate, item.id, _value);
    }

    function set(Config storage self, Bool storage item, bytes32 _salt, bool _value) internal {
        self.store.setBool(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(Config storage self, Bytes32 storage item, bytes32 _value) internal {
        self.store.setBytes32(self.crate, item.id, _value);
    }

    function set(Config storage self, Bytes32 storage item, bytes32 _salt, bytes32 _value) internal {
        self.store.setBytes32(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(Config storage self, String storage item, string _value) internal {
        self.store.setString(self.crate, item.id, _value);
    }

    function set(Config storage self, String storage item, bytes32 _salt, string _value) internal {
        self.store.setString(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(Config storage self, Mapping storage item, uint _key, uint _value) internal {
        self.store.setUInt(self.crate, keccak256(abi.encodePacked(item.id, _key)), _value);
    }

    function set(Config storage self, Mapping storage item, bytes32 _key, bytes32 _value) internal {
        self.store.setBytes32(self.crate, keccak256(abi.encodePacked(item.id, _key)), _value);
    }

    function set(Config storage self, StringMapping storage item, bytes32 _key, string _value) internal {
        set(self, item.id, _key, _value);
    }

    function set(Config storage self, AddressUInt8Mapping storage item, bytes32 _key, address _value1, uint8 _value2) internal {
        self.store.setAddressUInt8(self.crate, keccak256(abi.encodePacked(item.id, _key)), _value1, _value2);
    }

    function set(Config storage self, Mapping storage item, bytes32 _key, bytes32 _key2, bytes32 _value) internal {
        set(self, item, keccak256(abi.encodePacked(_key, _key2)), _value);
    }

    function set(Config storage self, Mapping storage item, bytes32 _key, bytes32 _key2, bytes32 _key3, bytes32 _value) internal {
        set(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)), _value);
    }

    function set(Config storage self, Bool storage item, bytes32 _key, bytes32 _key2, bytes32 _key3, bool _value) internal {
        set(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)), _value);
    }

    function set(Config storage self, UIntAddressMapping storage item, uint _key, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(Config storage self, UIntUIntMapping storage item, uint _key, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(Config storage self, UIntBoolMapping storage item, uint _key, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), _value);
    }

    function set(Config storage self, UIntEnumMapping storage item, uint _key, uint8 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(Config storage self, UIntBytes32Mapping storage item, uint _key, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), _value);
    }

    function set(Config storage self, Bytes32UIntMapping storage item, bytes32 _key, uint _value) internal {
        set(self, item.innerMapping, _key, bytes32(_value));
    }

    function set(Config storage self, Bytes32UInt8Mapping storage item, bytes32 _key, uint8 _value) internal {
        set(self, item.innerMapping, _key, _value);
    }

    function set(Config storage self, Bytes32BoolMapping storage item, bytes32 _key, bool _value) internal {
        set(self, item.innerMapping, _key, _value);
    }

    function set(Config storage self, Bytes32Bytes32Mapping storage item, bytes32 _key, bytes32 _value) internal {
        set(self, item.innerMapping, _key, _value);
    }

    function set(Config storage self, Bytes32AddressMapping storage item, bytes32 _key, address _value) internal {
        set(self, item.innerMapping, _key, bytes32(_value));
    }

    function set(Config storage self, Bytes32UIntBoolMapping storage item, bytes32 _key, uint _key2, bool _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)), _value);
    }

    function set(Config storage self, AddressUIntMapping storage item, address _key, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(Config storage self, AddressBoolMapping storage item, address _key, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), toBytes32(_value));
    }

    function set(Config storage self, AddressBytes32Mapping storage item, address _key, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), _value);
    }

    function set(Config storage self, AddressAddressMapping storage item, address _key, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(Config storage self, AddressAddressUIntMapping storage item, address _key, address _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, AddressUIntUIntMapping storage item, address _key, uint _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, AddressAddressUInt8Mapping storage item, address _key, address _key2, uint8 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, AddressUIntUInt8Mapping storage item, address _key, uint _key2, uint8 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, AddressBytes32Bytes32Mapping storage item, address _key, bytes32 _key2, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), _key2, _value);
    }

    function set(Config storage self, UIntAddressUIntMapping storage item, uint _key, address _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, UIntAddressBoolMapping storage item, uint _key, address _key2, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), toBytes32(_value));
    }

    function set(Config storage self, UIntAddressAddressMapping storage item, uint _key, address _key2, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, UIntUIntAddressMapping storage item, uint _key, uint _key2, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, UIntUIntBytes32Mapping storage item, uint _key, uint _key2, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), _value);
    }

    function set(Config storage self, UIntUIntUIntMapping storage item, uint _key, uint _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, UIntAddressAddressBoolMapping storage item, uint _key, address _key2, address _key3, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3), _value);
    }

    function set(Config storage self, UIntUIntUIntBytes32Mapping storage item, uint _key, uint _key2,  uint _key3, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3), _value);
    }

    function set(Config storage self, Bytes32UIntUIntMapping storage item, bytes32 _key, uint _key2, uint _value) internal {
        set(self, item.innerMapping, _key, bytes32(_key2), bytes32(_value));
    }

    function set(Config storage self, Bytes32UIntUIntUIntMapping storage item, bytes32 _key, uint _key2,  uint _key3, uint _value) internal {
        set(self, item.innerMapping, _key, bytes32(_key2), bytes32(_key3), bytes32(_value));
    }

    function set(Config storage self, AddressUIntUIntUIntMapping storage item, address _key, uint _key2,  uint _key3, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3), bytes32(_value));
    }

    function set(Config storage self, AddressUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)), _value, _value2);
    }

    function set(Config storage self, AddressUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3)), _value, _value2);
    }

    function set(Config storage self, AddressUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2,  uint _key3, uint _key4, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4)), _value, _value2);
    }

    function set(Config storage self, AddressUIntUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2,  uint _key3, uint _key4, uint _key5, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5)), _value, _value2);
    }

    function set(Config storage self, AddressUIntAddressUInt8Mapping storage item, address _key, uint _key2, address _key3, uint8 _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3)), bytes32(_value));
    }

    function set(Config storage self, AddressUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, address _key4, uint8 _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4)), bytes32(_value));
    }

    function set(Config storage self, AddressUIntUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2,  uint _key3, uint _key4, address _key5, uint8 _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5)), bytes32(_value));
    }

    function set(Config storage self, AddressBytes4BoolMapping storage item, address _key, bytes4 _key2, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), toBytes32(_value));
    }

    function set(Config storage self, AddressBytes4Bytes32Mapping storage item, address _key, bytes4 _key2, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), _value);
    }


     

    function add(Config storage self, Set storage item, bytes32 _value) internal {
        add(self, item, SET_IDENTIFIER, _value);
    }

    function add(Config storage self, Set storage item, bytes32 _salt, bytes32 _value) private {
        if (includes(self, item, _salt, _value)) {
            return;
        }
        uint newCount = count(self, item, _salt) + 1;
        set(self, item.values, _salt, bytes32(newCount), _value);
        set(self, item.indexes, _salt, _value, bytes32(newCount));
        set(self, item.count, _salt, newCount);
    }

    function add(Config storage self, AddressesSet storage item, address _value) internal {
        add(self, item.innerSet, bytes32(_value));
    }

    function add(Config storage self, CounterSet storage item) internal {
        add(self, item.innerSet, bytes32(count(self, item) + 1));
    }

    function add(Config storage self, OrderedSet storage item, bytes32 _value) internal {
        add(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function add(Config storage self, OrderedSet storage item, bytes32 _salt, bytes32 _value) private {
        if (_value == 0x0) { revert(); }

        if (includes(self, item, _salt, _value)) { return; }

        if (count(self, item, _salt) == 0x0) {
            set(self, item.first, _salt, _value);
        }

        if (get(self, item.last, _salt) != 0x0) {
            _setOrderedSetLink(self, item.nextValues, _salt, get(self, item.last, _salt), _value);
            _setOrderedSetLink(self, item.previousValues, _salt, _value, get(self, item.last, _salt));
        }

        _setOrderedSetLink(self, item.nextValues, _salt,  _value, 0x0);
        set(self, item.last, _salt, _value);
        set(self, item.count, _salt, get(self, item.count, _salt) + 1);
    }

    function add(Config storage self, Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal {
        add(self, item.innerMapping, _key, _value);
    }

    function add(Config storage self, AddressesSetMapping storage item, bytes32 _key, address _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(Config storage self, UIntSetMapping storage item, bytes32 _key, uint _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(Config storage self, Bytes32OrderedSetMapping storage item, bytes32 _key, bytes32 _value) internal {
        add(self, item.innerMapping, _key, _value);
    }

    function add(Config storage self, UIntOrderedSetMapping storage item, bytes32 _key, uint _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(Config storage self, AddressOrderedSetMapping storage item, bytes32 _key, address _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(Config storage self, OrderedUIntSet storage item, uint _value) internal {
        add(self, item.innerSet, bytes32(_value));
    }

    function add(Config storage self, OrderedAddressesSet storage item, address _value) internal {
        add(self, item.innerSet, bytes32(_value));
    }

    function set(Config storage self, Set storage item, bytes32 _oldValue, bytes32 _newValue) internal {
        set(self, item, SET_IDENTIFIER, _oldValue, _newValue);
    }

    function set(Config storage self, Set storage item, bytes32 _salt, bytes32 _oldValue, bytes32 _newValue) private {
        if (!includes(self, item, _salt, _oldValue)) {
            return;
        }
        uint index = uint(get(self, item.indexes, _salt, _oldValue));
        set(self, item.values, _salt, bytes32(index), _newValue);
        set(self, item.indexes, _salt, _newValue, bytes32(index));
        set(self, item.indexes, _salt, _oldValue, bytes32(0));
    }

    function set(Config storage self, AddressesSet storage item, address _oldValue, address _newValue) internal {
        set(self, item.innerSet, bytes32(_oldValue), bytes32(_newValue));
    }

     

    function remove(Config storage self, Set storage item, bytes32 _value) internal {
        remove(self, item, SET_IDENTIFIER, _value);
    }

    function remove(Config storage self, Set storage item, bytes32 _salt, bytes32 _value) private {
        if (!includes(self, item, _salt, _value)) {
            return;
        }
        uint lastIndex = count(self, item, _salt);
        bytes32 lastValue = get(self, item.values, _salt, bytes32(lastIndex));
        uint index = uint(get(self, item.indexes, _salt, _value));
        if (index < lastIndex) {
            set(self, item.indexes, _salt, lastValue, bytes32(index));
            set(self, item.values, _salt, bytes32(index), lastValue);
        }
        set(self, item.indexes, _salt, _value, bytes32(0));
        set(self, item.values, _salt, bytes32(lastIndex), bytes32(0));
        set(self, item.count, _salt, lastIndex - 1);
    }

    function remove(Config storage self, AddressesSet storage item, address _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(Config storage self, CounterSet storage item, uint _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(Config storage self, OrderedSet storage item, bytes32 _value) internal {
        remove(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function remove(Config storage self, OrderedSet storage item, bytes32 _salt, bytes32 _value) private {
        if (!includes(self, item, _salt, _value)) { return; }

        _setOrderedSetLink(self, item.nextValues, _salt, get(self, item.previousValues, _salt, _value), get(self, item.nextValues, _salt, _value));
        _setOrderedSetLink(self, item.previousValues, _salt, get(self, item.nextValues, _salt, _value), get(self, item.previousValues, _salt, _value));

        if (_value == get(self, item.first, _salt)) {
            set(self, item.first, _salt, get(self, item.nextValues, _salt, _value));
        }

        if (_value == get(self, item.last, _salt)) {
            set(self, item.last, _salt, get(self, item.previousValues, _salt, _value));
        }

        _deleteOrderedSetLink(self, item.nextValues, _salt, _value);
        _deleteOrderedSetLink(self, item.previousValues, _salt, _value);

        set(self, item.count, _salt, get(self, item.count, _salt) - 1);
    }

    function remove(Config storage self, OrderedUIntSet storage item, uint _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(Config storage self, OrderedAddressesSet storage item, address _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(Config storage self, Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal {
        remove(self, item.innerMapping, _key, _value);
    }

    function remove(Config storage self, AddressesSetMapping storage item, bytes32 _key, address _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

    function remove(Config storage self, UIntSetMapping storage item, bytes32 _key, uint _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

    function remove(Config storage self, Bytes32OrderedSetMapping storage item, bytes32 _key, bytes32 _value) internal {
        remove(self, item.innerMapping, _key, _value);
    }

    function remove(Config storage self, UIntOrderedSetMapping storage item, bytes32 _key, uint _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

    function remove(Config storage self, AddressOrderedSetMapping storage item, bytes32 _key, address _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

     

    function copy(Config storage self, Set storage source, Set storage dest) internal {
        uint _destCount = count(self, dest);
        bytes32[] memory _toRemoveFromDest = new bytes32[](_destCount);
        uint _idx;
        uint _pointer = 0;
        for (_idx = 0; _idx < _destCount; ++_idx) {
            bytes32 _destValue = get(self, dest, _idx);
            if (!includes(self, source, _destValue)) {
                _toRemoveFromDest[_pointer++] = _destValue;
            }
        }

        uint _sourceCount = count(self, source);
        for (_idx = 0; _idx < _sourceCount; ++_idx) {
            add(self, dest, get(self, source, _idx));
        }

        for (_idx = 0; _idx < _pointer; ++_idx) {
            remove(self, dest, _toRemoveFromDest[_idx]);
        }
    }

    function copy(Config storage self, AddressesSet storage source, AddressesSet storage dest) internal {
        copy(self, source.innerSet, dest.innerSet);
    }

    function copy(Config storage self, CounterSet storage source, CounterSet storage dest) internal {
        copy(self, source.innerSet, dest.innerSet);
    }

     

    function get(Config storage self, UInt storage item) internal view returns (uint) {
        return self.store.getUInt(self.crate, item.id);
    }

    function get(Config storage self, UInt storage item, bytes32 salt) internal view returns (uint) {
        return self.store.getUInt(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(Config storage self, UInt8 storage item) internal view returns (uint8) {
        return self.store.getUInt8(self.crate, item.id);
    }

    function get(Config storage self, UInt8 storage item, bytes32 salt) internal view returns (uint8) {
        return self.store.getUInt8(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(Config storage self, Int storage item) internal view returns (int) {
        return self.store.getInt(self.crate, item.id);
    }

    function get(Config storage self, Int storage item, bytes32 salt) internal view returns (int) {
        return self.store.getInt(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(Config storage self, Address storage item) internal view returns (address) {
        return self.store.getAddress(self.crate, item.id);
    }

    function get(Config storage self, Address storage item, bytes32 salt) internal view returns (address) {
        return self.store.getAddress(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(Config storage self, Bool storage item) internal view returns (bool) {
        return self.store.getBool(self.crate, item.id);
    }

    function get(Config storage self, Bool storage item, bytes32 salt) internal view returns (bool) {
        return self.store.getBool(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(Config storage self, Bytes32 storage item) internal view returns (bytes32) {
        return self.store.getBytes32(self.crate, item.id);
    }

    function get(Config storage self, Bytes32 storage item, bytes32 salt) internal view returns (bytes32) {
        return self.store.getBytes32(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(Config storage self, String storage item) internal view returns (string) {
        return self.store.getString(self.crate, item.id);
    }

    function get(Config storage self, String storage item, bytes32 salt) internal view returns (string) {
        return self.store.getString(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(Config storage self, Mapping storage item, uint _key) internal view returns (uint) {
        return self.store.getUInt(self.crate, keccak256(abi.encodePacked(item.id, _key)));
    }

    function get(Config storage self, Mapping storage item, bytes32 _key) internal view returns (bytes32) {
        return self.store.getBytes32(self.crate, keccak256(abi.encodePacked(item.id, _key)));
    }

    function get(Config storage self, StringMapping storage item, bytes32 _key) internal view returns (string) {
        return get(self, item.id, _key);
    }

    function get(Config storage self, AddressUInt8Mapping storage item, bytes32 _key) internal view returns (address, uint8) {
        return self.store.getAddressUInt8(self.crate, keccak256(abi.encodePacked(item.id, _key)));
    }

    function get(Config storage self, Mapping storage item, bytes32 _key, bytes32 _key2) internal view returns (bytes32) {
        return get(self, item, keccak256(abi.encodePacked(_key, _key2)));
    }

    function get(Config storage self, Mapping storage item, bytes32 _key, bytes32 _key2, bytes32 _key3) internal view returns (bytes32) {
        return get(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)));
    }

    function get(Config storage self, Bool storage item, bytes32 _key, bytes32 _key2, bytes32 _key3) internal view returns (bool) {
        return get(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)));
    }

    function get(Config storage self, UIntBoolMapping storage item, uint _key) internal view returns (bool) {
        return get(self, item.innerMapping, bytes32(_key));
    }

    function get(Config storage self, UIntEnumMapping storage item, uint _key) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(Config storage self, UIntUIntMapping storage item, uint _key) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(Config storage self, UIntAddressMapping storage item, uint _key) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(Config storage self, Bytes32UIntMapping storage item, bytes32 _key) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key));
    }

    function get(Config storage self, Bytes32AddressMapping storage item, bytes32 _key) internal view returns (address) {
        return address(get(self, item.innerMapping, _key));
    }

    function get(Config storage self, Bytes32UInt8Mapping storage item, bytes32 _key) internal view returns (uint8) {
        return get(self, item.innerMapping, _key);
    }

    function get(Config storage self, Bytes32BoolMapping storage item, bytes32 _key) internal view returns (bool) {
        return get(self, item.innerMapping, _key);
    }

    function get(Config storage self, Bytes32Bytes32Mapping storage item, bytes32 _key) internal view returns (bytes32) {
        return get(self, item.innerMapping, _key);
    }

    function get(Config storage self, Bytes32UIntBoolMapping storage item, bytes32 _key, uint _key2) internal view returns (bool) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)));
    }

    function get(Config storage self, UIntBytes32Mapping storage item, uint _key) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key));
    }

    function get(Config storage self, AddressUIntMapping storage item, address _key) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(Config storage self, AddressBoolMapping storage item, address _key) internal view returns (bool) {
        return toBool(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(Config storage self, AddressAddressMapping storage item, address _key) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(Config storage self, AddressBytes32Mapping storage item, address _key) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key));
    }

    function get(Config storage self, UIntUIntBytes32Mapping storage item, uint _key, uint _key2) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2));
    }

    function get(Config storage self, UIntUIntAddressMapping storage item, uint _key, uint _key2) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, UIntUIntUIntMapping storage item, uint _key, uint _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, Bytes32UIntUIntMapping storage item, bytes32 _key, uint _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key, bytes32(_key2)));
    }

    function get(Config storage self, Bytes32UIntUIntUIntMapping storage item, bytes32 _key, uint _key2, uint _key3) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key, bytes32(_key2), bytes32(_key3)));
    }

    function get(Config storage self, AddressAddressUIntMapping storage item, address _key, address _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, AddressAddressUInt8Mapping storage item, address _key, address _key2) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, AddressUIntUIntMapping storage item, address _key, uint _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, AddressUIntUInt8Mapping storage item, address _key, uint _key2) internal view returns (uint) {
        return uint8(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, AddressBytes32Bytes32Mapping storage item, address _key, bytes32 _key2) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), _key2);
    }

    function get(Config storage self, AddressBytes4BoolMapping storage item, address _key, bytes4 _key2) internal view returns (bool) {
        return toBool(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, AddressBytes4Bytes32Mapping storage item, address _key, bytes4 _key2) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2));
    }

    function get(Config storage self, UIntAddressUIntMapping storage item, uint _key, address _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, UIntAddressBoolMapping storage item, uint _key, address _key2) internal view returns (bool) {
        return toBool(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, UIntAddressAddressMapping storage item, uint _key, address _key2) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(Config storage self, UIntAddressAddressBoolMapping storage item, uint _key, address _key2, address _key3) internal view returns (bool) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3));
    }

    function get(Config storage self, UIntUIntUIntBytes32Mapping storage item, uint _key, uint _key2, uint _key3) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3));
    }

    function get(Config storage self, AddressUIntUIntUIntMapping storage item, address _key, uint _key2, uint _key3) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3)));
    }

    function get(Config storage self, AddressUIntStructAddressUInt8Mapping storage item, address _key, uint _key2) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)));
    }

    function get(Config storage self, AddressUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3)));
    }

    function get(Config storage self, AddressUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, uint _key4) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4)));
    }

    function get(Config storage self, AddressUIntUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, uint _key4, uint _key5) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5)));
    }

    function get(Config storage self, AddressUIntAddressUInt8Mapping storage item, address _key, uint _key2, address _key3) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3))));
    }

    function get(Config storage self, AddressUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, address _key4) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4))));
    }

    function get(Config storage self, AddressUIntUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, uint _key4, address _key5) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5))));
    }

     

    function includes(Config storage self, Set storage item, bytes32 _value) internal view returns (bool) {
        return includes(self, item, SET_IDENTIFIER, _value);
    }

    function includes(Config storage self, Set storage item, bytes32 _salt, bytes32 _value) internal view returns (bool) {
        return get(self, item.indexes, _salt, _value) != 0;
    }

    function includes(Config storage self, AddressesSet storage item, address _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(Config storage self, CounterSet storage item, uint _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(Config storage self, OrderedSet storage item, bytes32 _value) internal view returns (bool) {
        return includes(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function includes(Config storage self, OrderedSet storage item, bytes32 _salt, bytes32 _value) private view returns (bool) {
        return _value != 0x0 && (get(self, item.nextValues, _salt, _value) != 0x0 || get(self, item.last, _salt) == _value);
    }

    function includes(Config storage self, OrderedUIntSet storage item, uint _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(Config storage self, OrderedAddressesSet storage item, address _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(Config storage self, Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, _value);
    }

    function includes(Config storage self, AddressesSetMapping storage item, bytes32 _key, address _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function includes(Config storage self, UIntSetMapping storage item, bytes32 _key, uint _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function includes(Config storage self, Bytes32OrderedSetMapping storage item, bytes32 _key, bytes32 _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, _value);
    }

    function includes(Config storage self, UIntOrderedSetMapping storage item, bytes32 _key, uint _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function includes(Config storage self, AddressOrderedSetMapping storage item, bytes32 _key, address _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function getIndex(Config storage self, Set storage item, bytes32 _value) internal view returns (uint) {
        return getIndex(self, item, SET_IDENTIFIER, _value);
    }

    function getIndex(Config storage self, Set storage item, bytes32 _salt, bytes32 _value) private view returns (uint) {
        return uint(get(self, item.indexes, _salt, _value));
    }

    function getIndex(Config storage self, AddressesSet storage item, address _value) internal view returns (uint) {
        return getIndex(self, item.innerSet, bytes32(_value));
    }

    function getIndex(Config storage self, CounterSet storage item, uint _value) internal view returns (uint) {
        return getIndex(self, item.innerSet, bytes32(_value));
    }

    function getIndex(Config storage self, Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal view returns (uint) {
        return getIndex(self, item.innerMapping, _key, _value);
    }

    function getIndex(Config storage self, AddressesSetMapping storage item, bytes32 _key, address _value) internal view returns (uint) {
        return getIndex(self, item.innerMapping, _key, bytes32(_value));
    }

    function getIndex(Config storage self, UIntSetMapping storage item, bytes32 _key, uint _value) internal view returns (uint) {
        return getIndex(self, item.innerMapping, _key, bytes32(_value));
    }

     

    function count(Config storage self, Set storage item) internal view returns (uint) {
        return count(self, item, SET_IDENTIFIER);
    }

    function count(Config storage self, Set storage item, bytes32 _salt) internal view returns (uint) {
        return get(self, item.count, _salt);
    }

    function count(Config storage self, AddressesSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(Config storage self, CounterSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(Config storage self, OrderedSet storage item) internal view returns (uint) {
        return count(self, item, ORDERED_SET_IDENTIFIER);
    }

    function count(Config storage self, OrderedSet storage item, bytes32 _salt) private view returns (uint) {
        return get(self, item.count, _salt);
    }

    function count(Config storage self, OrderedUIntSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(Config storage self, OrderedAddressesSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(Config storage self, Bytes32SetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(Config storage self, AddressesSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(Config storage self, UIntSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(Config storage self, Bytes32OrderedSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(Config storage self, UIntOrderedSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(Config storage self, AddressOrderedSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function get(Config storage self, Set storage item) internal view returns (bytes32[] result) {
        result = get(self, item, SET_IDENTIFIER);
    }

    function get(Config storage self, Set storage item, bytes32 _salt) private view returns (bytes32[] result) {
        uint valuesCount = count(self, item, _salt);
        result = new bytes32[](valuesCount);
        for (uint i = 0; i < valuesCount; i++) {
            result[i] = get(self, item, _salt, i);
        }
    }

    function get(Config storage self, AddressesSet storage item) internal view returns (address[]) {
        return toAddresses(get(self, item.innerSet));
    }

    function get(Config storage self, CounterSet storage item) internal view returns (uint[]) {
        return toUInt(get(self, item.innerSet));
    }

    function get(Config storage self, Bytes32SetMapping storage item, bytes32 _key) internal view returns (bytes32[]) {
        return get(self, item.innerMapping, _key);
    }

    function get(Config storage self, AddressesSetMapping storage item, bytes32 _key) internal view returns (address[]) {
        return toAddresses(get(self, item.innerMapping, _key));
    }

    function get(Config storage self, UIntSetMapping storage item, bytes32 _key) internal view returns (uint[]) {
        return toUInt(get(self, item.innerMapping, _key));
    }

    function get(Config storage self, Set storage item, uint _index) internal view returns (bytes32) {
        return get(self, item, SET_IDENTIFIER, _index);
    }

    function get(Config storage self, Set storage item, bytes32 _salt, uint _index) private view returns (bytes32) {
        return get(self, item.values, _salt, bytes32(_index+1));
    }

    function get(Config storage self, AddressesSet storage item, uint _index) internal view returns (address) {
        return address(get(self, item.innerSet, _index));
    }

    function get(Config storage self, CounterSet storage item, uint _index) internal view returns (uint) {
        return uint(get(self, item.innerSet, _index));
    }

    function get(Config storage self, Bytes32SetMapping storage item, bytes32 _key, uint _index) internal view returns (bytes32) {
        return get(self, item.innerMapping, _key, _index);
    }

    function get(Config storage self, AddressesSetMapping storage item, bytes32 _key, uint _index) internal view returns (address) {
        return address(get(self, item.innerMapping, _key, _index));
    }

    function get(Config storage self, UIntSetMapping storage item, bytes32 _key, uint _index) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key, _index));
    }

    function getNextValue(Config storage self, OrderedSet storage item, bytes32 _value) internal view returns (bytes32) {
        return getNextValue(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function getNextValue(Config storage self, OrderedSet storage item, bytes32 _salt, bytes32 _value) private view returns (bytes32) {
        return get(self, item.nextValues, _salt, _value);
    }

    function getNextValue(Config storage self, OrderedUIntSet storage item, uint _value) internal view returns (uint) {
        return uint(getNextValue(self, item.innerSet, bytes32(_value)));
    }

    function getNextValue(Config storage self, OrderedAddressesSet storage item, address _value) internal view returns (address) {
        return address(getNextValue(self, item.innerSet, bytes32(_value)));
    }

    function getPreviousValue(Config storage self, OrderedSet storage item, bytes32 _value) internal view returns (bytes32) {
        return getPreviousValue(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function getPreviousValue(Config storage self, OrderedSet storage item, bytes32 _salt, bytes32 _value) private view returns (bytes32) {
        return get(self, item.previousValues, _salt, _value);
    }

    function getPreviousValue(Config storage self, OrderedUIntSet storage item, uint _value) internal view returns (uint) {
        return uint(getPreviousValue(self, item.innerSet, bytes32(_value)));
    }

    function getPreviousValue(Config storage self, OrderedAddressesSet storage item, address _value) internal view returns (address) {
        return address(getPreviousValue(self, item.innerSet, bytes32(_value)));
    }

    function toBool(bytes32 self) internal pure returns (bool) {
        return self != bytes32(0);
    }

    function toBytes32(bool self) internal pure returns (bytes32) {
        return bytes32(self ? 1 : 0);
    }

    function toAddresses(bytes32[] memory self) internal pure returns (address[]) {
        address[] memory result = new address[](self.length);
        for (uint i = 0; i < self.length; i++) {
            result[i] = address(self[i]);
        }
        return result;
    }

    function toUInt(bytes32[] memory self) internal pure returns (uint[]) {
        uint[] memory result = new uint[](self.length);
        for (uint i = 0; i < self.length; i++) {
            result[i] = uint(self[i]);
        }
        return result;
    }

    function _setOrderedSetLink(Config storage self, Mapping storage link, bytes32 _salt, bytes32 from, bytes32 to) private {
        if (from != 0x0) {
            set(self, link, _salt, from, to);
        }
    }

    function _deleteOrderedSetLink(Config storage self, Mapping storage link, bytes32 _salt, bytes32 from) private {
        if (from != 0x0) {
            set(self, link, _salt, from, 0x0);
        }
    }

     
    struct Iterator {
        uint limit;
        uint valuesLeft;
        bytes32 currentValue;
        bytes32 anchorKey;
    }

    function listIterator(Config storage self, OrderedSet storage item, bytes32 anchorKey, bytes32 startValue, uint limit) internal view returns (Iterator) {
        if (startValue == 0x0) {
            return listIterator(self, item, anchorKey, limit);
        }

        return createIterator(anchorKey, startValue, limit);
    }

    function listIterator(Config storage self, OrderedUIntSet storage item, bytes32 anchorKey, uint startValue, uint limit) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, anchorKey, bytes32(startValue), limit);
    }

    function listIterator(Config storage self, OrderedAddressesSet storage item, bytes32 anchorKey, address startValue, uint limit) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, anchorKey, bytes32(startValue), limit);
    }

    function listIterator(Config storage self, OrderedSet storage item, uint limit) internal view returns (Iterator) {
        return listIterator(self, item, ORDERED_SET_IDENTIFIER, limit);
    }

    function listIterator(Config storage self, OrderedSet storage item, bytes32 anchorKey, uint limit) internal view returns (Iterator) {
        return createIterator(anchorKey, get(self, item.first, anchorKey), limit);
    }

    function listIterator(Config storage self, OrderedUIntSet storage item, uint limit) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, limit);
    }

    function listIterator(Config storage self, OrderedUIntSet storage item, bytes32 anchorKey, uint limit) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, anchorKey, limit);
    }

    function listIterator(Config storage self, OrderedAddressesSet storage item, uint limit) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, limit);
    }

    function listIterator(Config storage self, OrderedAddressesSet storage item, uint limit, bytes32 anchorKey) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, anchorKey, limit);
    }

    function listIterator(Config storage self, OrderedSet storage item) internal view returns (Iterator) {
        return listIterator(self, item, ORDERED_SET_IDENTIFIER);
    }

    function listIterator(Config storage self, OrderedSet storage item, bytes32 anchorKey) internal view returns (Iterator) {
        return listIterator(self, item, anchorKey, get(self, item.count, anchorKey));
    }

    function listIterator(Config storage self, OrderedUIntSet storage item) internal view returns (Iterator) {
        return listIterator(self, item.innerSet);
    }

    function listIterator(Config storage self, OrderedUIntSet storage item, bytes32 anchorKey) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, anchorKey);
    }

    function listIterator(Config storage self, OrderedAddressesSet storage item) internal view returns (Iterator) {
        return listIterator(self, item.innerSet);
    }

    function listIterator(Config storage self, OrderedAddressesSet storage item, bytes32 anchorKey) internal view returns (Iterator) {
        return listIterator(self, item.innerSet, anchorKey);
    }

    function listIterator(Config storage self, Bytes32OrderedSetMapping storage item, bytes32 _key) internal view returns (Iterator) {
        return listIterator(self, item.innerMapping, _key);
    }

    function listIterator(Config storage self, UIntOrderedSetMapping storage item, bytes32 _key) internal view returns (Iterator) {
        return listIterator(self, item.innerMapping, _key);
    }

    function listIterator(Config storage self, AddressOrderedSetMapping storage item, bytes32 _key) internal view returns (Iterator) {
        return listIterator(self, item.innerMapping, _key);
    }

    function createIterator(bytes32 anchorKey, bytes32 startValue, uint limit) internal pure returns (Iterator) {
        return Iterator({
            currentValue: startValue,
            limit: limit,
            valuesLeft: limit,
            anchorKey: anchorKey
        });
    }

    function getNextWithIterator(Config storage self, OrderedSet storage item, Iterator iterator) internal view returns (bytes32 _nextValue) {
        if (!canGetNextWithIterator(self, item, iterator)) { revert(); }

        _nextValue = iterator.currentValue;

        iterator.currentValue = getNextValue(self, item, iterator.anchorKey, iterator.currentValue);
        iterator.valuesLeft -= 1;
    }

    function getNextWithIterator(Config storage self, OrderedUIntSet storage item, Iterator iterator) internal view returns (uint _nextValue) {
        return uint(getNextWithIterator(self, item.innerSet, iterator));
    }

    function getNextWithIterator(Config storage self, OrderedAddressesSet storage item, Iterator iterator) internal view returns (address _nextValue) {
        return address(getNextWithIterator(self, item.innerSet, iterator));
    }

    function getNextWithIterator(Config storage self, Bytes32OrderedSetMapping storage item, Iterator iterator) internal view returns (bytes32 _nextValue) {
        return getNextWithIterator(self, item.innerMapping, iterator);
    }

    function getNextWithIterator(Config storage self, UIntOrderedSetMapping storage item, Iterator iterator) internal view returns (uint _nextValue) {
        return uint(getNextWithIterator(self, item.innerMapping, iterator));
    }

    function getNextWithIterator(Config storage self, AddressOrderedSetMapping storage item, Iterator iterator) internal view returns (address _nextValue) {
        return address(getNextWithIterator(self, item.innerMapping, iterator));
    }

    function canGetNextWithIterator(Config storage self, OrderedSet storage item, Iterator iterator) internal view returns (bool) {
        if (iterator.valuesLeft == 0 || !includes(self, item, iterator.anchorKey, iterator.currentValue)) {
            return false;
        }

        return true;
    }

    function canGetNextWithIterator(Config storage self, OrderedUIntSet storage item, Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerSet, iterator);
    }

    function canGetNextWithIterator(Config storage self, OrderedAddressesSet storage item, Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerSet, iterator);
    }

    function canGetNextWithIterator(Config storage self, Bytes32OrderedSetMapping storage item, Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerMapping, iterator);
    }

    function canGetNextWithIterator(Config storage self, UIntOrderedSetMapping storage item, Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerMapping, iterator);
    }

    function canGetNextWithIterator(Config storage self, AddressOrderedSetMapping storage item, Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerMapping, iterator);
    }

    function count(Iterator iterator) internal pure returns (uint) {
        return iterator.valuesLeft;
    }
}

 

 

pragma solidity ^0.4.23;



contract StorageContractAdapter {

    StorageInterface.Config internal store;

    constructor(Storage _store, bytes32 _crate) public {
        StorageInterface.init(store, _store, _crate);
    }
}

 

 

pragma solidity ^0.4.23;




contract StorageInterfaceContract is StorageContractAdapter, Storage {

    bytes32 constant SET_IDENTIFIER = "set";
    bytes32 constant ORDERED_SET_IDENTIFIER = "ordered_set";

     
    function sanityCheck(bytes32 _currentId, bytes32 _newId) internal pure {
        if (_currentId != 0 || _newId == 0) {
            revert("STORAGE_INTERFACE_CONTRACT_SANITY_CHECK_FAILED");
        }
    }

    function init(StorageInterface.Config storage self, bytes32 _crate) internal {
        self.crate = _crate;
    }

    function init(StorageInterface.UInt8 storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.UInt storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.Int storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.Address storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.Bool storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.Bytes32 storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.String storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.Mapping storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.StringMapping storage self, bytes32 _id) internal {
        init(self.id, _id);
    }

    function init(StorageInterface.UIntAddressMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntEnumMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressAddressUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressBytes32Bytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntAddressUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntAddressBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntUIntAddressMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntAddressAddressMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntUIntBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntAddressAddressBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntUIntUIntBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32UIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32UIntUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressBoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUInt8Mapping storage self, bytes32 _id) internal {
        sanityCheck(self.id, _id);
        self.id = _id;
    }

    function init(StorageInterface.AddressUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressBytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressAddressMapping  storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressBytes4BoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressBytes4Bytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUIntUIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUIntUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUIntUIntUIntStructAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUIntAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressUIntUIntUIntAddressUInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32UIntMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32UInt8Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32BoolMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32Bytes32Mapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32AddressMapping  storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32UIntBoolMapping  storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Set storage self, bytes32 _id) internal {
        init(self.count, keccak256(abi.encodePacked(_id, "count")));
        init(self.indexes, keccak256(abi.encodePacked(_id, "indexes")));
        init(self.values, keccak256(abi.encodePacked(_id, "values")));
    }

    function init(StorageInterface.AddressesSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(StorageInterface.CounterSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(StorageInterface.OrderedSet storage self, bytes32 _id) internal {
        init(self.count, keccak256(abi.encodePacked(_id, "uint/count")));
        init(self.first, keccak256(abi.encodePacked(_id, "uint/first")));
        init(self.last, keccak256(abi.encodePacked(_id, "uint/last")));
        init(self.nextValues, keccak256(abi.encodePacked(_id, "uint/next")));
        init(self.previousValues, keccak256(abi.encodePacked(_id, "uint/prev")));
    }

    function init(StorageInterface.OrderedUIntSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(StorageInterface.OrderedAddressesSet storage self, bytes32 _id) internal {
        init(self.innerSet, _id);
    }

    function init(StorageInterface.Bytes32SetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressesSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.Bytes32OrderedSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.UIntOrderedSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

    function init(StorageInterface.AddressOrderedSetMapping storage self, bytes32 _id) internal {
        init(self.innerMapping, _id);
    }

     

    function set(StorageInterface.Config storage self, StorageInterface.UInt storage item, uint _value) internal {
        _setUInt(self.crate, item.id, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UInt storage item, bytes32 _salt, uint _value) internal {
        _setUInt(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UInt8 storage item, uint8 _value) internal {
        _setUInt8(self.crate, item.id, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UInt8 storage item, bytes32 _salt, uint8 _value) internal {
        _setUInt8(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Int storage item, int _value) internal {
        _setInt(self.crate, item.id, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Int storage item, bytes32 _salt, int _value) internal {
        _setInt(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Address storage item, address _value) internal {
        _setAddress(self.crate, item.id, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Address storage item, bytes32 _salt, address _value) internal {
        _setAddress(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bool storage item, bool _value) internal {
        _setBool(self.crate, item.id, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bool storage item, bytes32 _salt, bool _value) internal {
        _setBool(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32 storage item, bytes32 _value) internal {
        _setBytes32(self.crate, item.id, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32 storage item, bytes32 _salt, bytes32 _value) internal {
        _setBytes32(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.String storage item, string _value) internal {
        _setString(self.crate, item.id, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.String storage item, bytes32 _salt, string _value) internal {
        _setString(self.crate, keccak256(abi.encodePacked(item.id, _salt)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Mapping storage item, uint _key, uint _value) internal {
        _setUInt(self.crate, keccak256(abi.encodePacked(item.id, _key)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Mapping storage item, bytes32 _key, bytes32 _value) internal {
        _setBytes32(self.crate, keccak256(abi.encodePacked(item.id, _key)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.StringMapping storage item, bytes32 _key, string _value) internal {
        set(self, item.id, _key, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUInt8Mapping storage item, bytes32 _key, address _value1, uint8 _value2) internal {
        _setAddressUInt8(self.crate, keccak256(abi.encodePacked(item.id, _key)), _value1, _value2);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Mapping storage item, bytes32 _key, bytes32 _key2, bytes32 _value) internal {
        set(self, item, keccak256(abi.encodePacked(_key, _key2)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Mapping storage item, bytes32 _key, bytes32 _key2, bytes32 _key3, bytes32 _value) internal {
        set(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bool storage item, bytes32 _key, bytes32 _key2, bytes32 _key3, bool _value) internal {
        set(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntAddressMapping storage item, uint _key, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntUIntMapping storage item, uint _key, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntBoolMapping storage item, uint _key, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntEnumMapping storage item, uint _key, uint8 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntBytes32Mapping storage item, uint _key, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32UIntMapping storage item, bytes32 _key, uint _value) internal {
        set(self, item.innerMapping, _key, bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32UInt8Mapping storage item, bytes32 _key, uint8 _value) internal {
        set(self, item.innerMapping, _key, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32BoolMapping storage item, bytes32 _key, bool _value) internal {
        set(self, item.innerMapping, _key, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32Bytes32Mapping storage item, bytes32 _key, bytes32 _value) internal {
        set(self, item.innerMapping, _key, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32AddressMapping storage item, bytes32 _key, address _value) internal {
        set(self, item.innerMapping, _key, bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32UIntBoolMapping storage item, bytes32 _key, uint _key2, bool _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntMapping storage item, address _key, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressBoolMapping storage item, address _key, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), toBytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressBytes32Mapping storage item, address _key, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressAddressMapping storage item, address _key, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressAddressUIntMapping storage item, address _key, address _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntMapping storage item, address _key, uint _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressAddressUInt8Mapping storage item, address _key, address _key2, uint8 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUInt8Mapping storage item, address _key, uint _key2, uint8 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressBytes32Bytes32Mapping storage item, address _key, bytes32 _key2, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), _key2, _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntAddressUIntMapping storage item, uint _key, address _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntAddressBoolMapping storage item, uint _key, address _key2, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), toBytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntAddressAddressMapping storage item, uint _key, address _key2, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntUIntAddressMapping storage item, uint _key, uint _key2, address _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntUIntBytes32Mapping storage item, uint _key, uint _key2, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntUIntUIntMapping storage item, uint _key, uint _key2, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntAddressAddressBoolMapping storage item, uint _key, address _key2, address _key3, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.UIntUIntUIntBytes32Mapping storage item, uint _key, uint _key2,  uint _key3, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3), _value);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32UIntUIntMapping storage item, bytes32 _key, uint _key2, uint _value) internal {
        set(self, item.innerMapping, _key, bytes32(_key2), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.Bytes32UIntUIntUIntMapping storage item, bytes32 _key, uint _key2,  uint _key3, uint _value) internal {
        set(self, item.innerMapping, _key, bytes32(_key2), bytes32(_key3), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntMapping storage item, address _key, uint _key2,  uint _key3, uint _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)), _value, _value2);
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3)), _value, _value2);
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2,  uint _key3, uint _key4, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4)), _value, _value2);
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2,  uint _key3, uint _key4, uint _key5, address _value, uint8 _value2) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5)), _value, _value2);
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntAddressUInt8Mapping storage item, address _key, uint _key2, address _key3, uint8 _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3)), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, address _key4, uint8 _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4)), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2,  uint _key3, uint _key4, address _key5, uint8 _value) internal {
        set(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5)), bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressBytes4BoolMapping storage item, address _key, bytes4 _key2, bool _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), toBytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressBytes4Bytes32Mapping storage item, address _key, bytes4 _key2, bytes32 _value) internal {
        set(self, item.innerMapping, bytes32(_key), bytes32(_key2), _value);
    }


     

    function add(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _value) internal {
        add(self, item, SET_IDENTIFIER, _value);
    }

    function add(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt, bytes32 _value) private {
        if (includes(self, item, _salt, _value)) {
            return;
        }
        uint newCount = count(self, item, _salt) + 1;
        set(self, item.values, _salt, bytes32(newCount), _value);
        set(self, item.indexes, _salt, _value, bytes32(newCount));
        set(self, item.count, _salt, newCount);
    }

    function add(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item, address _value) internal {
        add(self, item.innerSet, bytes32(_value));
    }

    function add(StorageInterface.Config storage self, StorageInterface.CounterSet storage item) internal {
        add(self, item.innerSet, bytes32(count(self, item) + 1));
    }

    function add(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _value) internal {
        add(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function add(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _salt, bytes32 _value) private {
        if (_value == 0x0) { revert(); }

        if (includes(self, item, _salt, _value)) { return; }

        if (count(self, item, _salt) == 0x0) {
            set(self, item.first, _salt, _value);
        }

        if (get(self, item.last, _salt) != 0x0) {
            _setOrderedSetLink(self, item.nextValues, _salt, get(self, item.last, _salt), _value);
            _setOrderedSetLink(self, item.previousValues, _salt, _value, get(self, item.last, _salt));
        }

        _setOrderedSetLink(self, item.nextValues, _salt,  _value, 0x0);
        set(self, item.last, _salt, _value);
        set(self, item.count, _salt, get(self, item.count, _salt) + 1);
    }

    function add(StorageInterface.Config storage self, StorageInterface.Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal {
        add(self, item.innerMapping, _key, _value);
    }

    function add(StorageInterface.Config storage self, StorageInterface.AddressesSetMapping storage item, bytes32 _key, address _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(StorageInterface.Config storage self, StorageInterface.UIntSetMapping storage item, bytes32 _key, uint _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(StorageInterface.Config storage self, StorageInterface.Bytes32OrderedSetMapping storage item, bytes32 _key, bytes32 _value) internal {
        add(self, item.innerMapping, _key, _value);
    }

    function add(StorageInterface.Config storage self, StorageInterface.UIntOrderedSetMapping storage item, bytes32 _key, uint _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(StorageInterface.Config storage self, StorageInterface.AddressOrderedSetMapping storage item, bytes32 _key, address _value) internal {
        add(self, item.innerMapping, _key, bytes32(_value));
    }

    function add(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, uint _value) internal {
        add(self, item.innerSet, bytes32(_value));
    }

    function add(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, address _value) internal {
        add(self, item.innerSet, bytes32(_value));
    }

    function set(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _oldValue, bytes32 _newValue) internal {
        set(self, item, SET_IDENTIFIER, _oldValue, _newValue);
    }

    function set(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt, bytes32 _oldValue, bytes32 _newValue) private {
        if (!includes(self, item, _salt, _oldValue)) {
            return;
        }
        uint index = uint(get(self, item.indexes, _salt, _oldValue));
        set(self, item.values, _salt, bytes32(index), _newValue);
        set(self, item.indexes, _salt, _newValue, bytes32(index));
        set(self, item.indexes, _salt, _oldValue, bytes32(0));
    }

    function set(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item, address _oldValue, address _newValue) internal {
        set(self, item.innerSet, bytes32(_oldValue), bytes32(_newValue));
    }

     

    function remove(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _value) internal {
        remove(self, item, SET_IDENTIFIER, _value);
    }

    function remove(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt, bytes32 _value) private {
        if (!includes(self, item, _salt, _value)) {
            return;
        }
        uint lastIndex = count(self, item, _salt);
        bytes32 lastValue = get(self, item.values, _salt, bytes32(lastIndex));
        uint index = uint(get(self, item.indexes, _salt, _value));
        if (index < lastIndex) {
            set(self, item.indexes, _salt, lastValue, bytes32(index));
            set(self, item.values, _salt, bytes32(index), lastValue);
        }
        set(self, item.indexes, _salt, _value, bytes32(0));
        set(self, item.values, _salt, bytes32(lastIndex), bytes32(0));
        set(self, item.count, _salt, lastIndex - 1);
    }

    function remove(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item, address _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(StorageInterface.Config storage self, StorageInterface.CounterSet storage item, uint _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _value) internal {
        remove(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function remove(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _salt, bytes32 _value) private {
        if (!includes(self, item, _salt, _value)) { return; }

        _setOrderedSetLink(self, item.nextValues, _salt, get(self, item.previousValues, _salt, _value), get(self, item.nextValues, _salt, _value));
        _setOrderedSetLink(self, item.previousValues, _salt, get(self, item.nextValues, _salt, _value), get(self, item.previousValues, _salt, _value));

        if (_value == get(self, item.first, _salt)) {
            set(self, item.first, _salt, get(self, item.nextValues, _salt, _value));
        }

        if (_value == get(self, item.last, _salt)) {
            set(self, item.last, _salt, get(self, item.previousValues, _salt, _value));
        }

        _deleteOrderedSetLink(self, item.nextValues, _salt, _value);
        _deleteOrderedSetLink(self, item.previousValues, _salt, _value);

        set(self, item.count, _salt, get(self, item.count, _salt) - 1);
    }

    function remove(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, uint _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, address _value) internal {
        remove(self, item.innerSet, bytes32(_value));
    }

    function remove(StorageInterface.Config storage self, StorageInterface.Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal {
        remove(self, item.innerMapping, _key, _value);
    }

    function remove(StorageInterface.Config storage self, StorageInterface.AddressesSetMapping storage item, bytes32 _key, address _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

    function remove(StorageInterface.Config storage self, StorageInterface.UIntSetMapping storage item, bytes32 _key, uint _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

    function remove(StorageInterface.Config storage self, StorageInterface.Bytes32OrderedSetMapping storage item, bytes32 _key, bytes32 _value) internal {
        remove(self, item.innerMapping, _key, _value);
    }

    function remove(StorageInterface.Config storage self, StorageInterface.UIntOrderedSetMapping storage item, bytes32 _key, uint _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

    function remove(StorageInterface.Config storage self, StorageInterface.AddressOrderedSetMapping storage item, bytes32 _key, address _value) internal {
        remove(self, item.innerMapping, _key, bytes32(_value));
    }

     

    function copy(StorageInterface.Config storage self, StorageInterface.Set storage source, StorageInterface.Set storage dest) internal {
        uint _destCount = count(self, dest);
        bytes32[] memory _toRemoveFromDest = new bytes32[](_destCount);
        uint _idx;
        uint _pointer = 0;
        for (_idx = 0; _idx < _destCount; ++_idx) {
            bytes32 _destValue = get(self, dest, _idx);
            if (!includes(self, source, _destValue)) {
                _toRemoveFromDest[_pointer++] = _destValue;
            }
        }

        uint _sourceCount = count(self, source);
        for (_idx = 0; _idx < _sourceCount; ++_idx) {
            add(self, dest, get(self, source, _idx));
        }

        for (_idx = 0; _idx < _pointer; ++_idx) {
            remove(self, dest, _toRemoveFromDest[_idx]);
        }
    }

    function copy(StorageInterface.Config storage self, StorageInterface.AddressesSet storage source, StorageInterface.AddressesSet storage dest) internal {
        copy(self, source.innerSet, dest.innerSet);
    }

    function copy(StorageInterface.Config storage self, StorageInterface.CounterSet storage source, StorageInterface.CounterSet storage dest) internal {
        copy(self, source.innerSet, dest.innerSet);
    }

     

    function get(StorageInterface.Config storage self, StorageInterface.UInt storage item) internal view returns (uint) {
        return getUInt(self.crate, item.id);
    }

    function get(StorageInterface.Config storage self, StorageInterface.UInt storage item, bytes32 salt) internal view returns (uint) {
        return getUInt(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UInt8 storage item) internal view returns (uint8) {
        return getUInt8(self.crate, item.id);
    }

    function get(StorageInterface.Config storage self, StorageInterface.UInt8 storage item, bytes32 salt) internal view returns (uint8) {
        return getUInt8(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Int storage item) internal view returns (int) {
        return getInt(self.crate, item.id);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Int storage item, bytes32 salt) internal view returns (int) {
        return getInt(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Address storage item) internal view returns (address) {
        return getAddress(self.crate, item.id);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Address storage item, bytes32 salt) internal view returns (address) {
        return getAddress(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bool storage item) internal view returns (bool) {
        return getBool(self.crate, item.id);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bool storage item, bytes32 salt) internal view returns (bool) {
        return getBool(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32 storage item) internal view returns (bytes32) {
        return getBytes32(self.crate, item.id);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32 storage item, bytes32 salt) internal view returns (bytes32) {
        return getBytes32(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.String storage item) internal view returns (string) {
        return getString(self.crate, item.id);
    }

    function get(StorageInterface.Config storage self, StorageInterface.String storage item, bytes32 salt) internal view returns (string) {
        return getString(self.crate, keccak256(abi.encodePacked(item.id, salt)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Mapping storage item, uint _key) internal view returns (uint) {
        return getUInt(self.crate, keccak256(abi.encodePacked(item.id, _key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Mapping storage item, bytes32 _key) internal view returns (bytes32) {
        return getBytes32(self.crate, keccak256(abi.encodePacked(item.id, _key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.StringMapping storage item, bytes32 _key) internal view returns (string) {
        return get(self, item.id, _key);
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUInt8Mapping storage item, bytes32 _key) internal view returns (address, uint8) {
        return getAddressUInt8(self.crate, keccak256(abi.encodePacked(item.id, _key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Mapping storage item, bytes32 _key, bytes32 _key2) internal view returns (bytes32) {
        return get(self, item, keccak256(abi.encodePacked(_key, _key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Mapping storage item, bytes32 _key, bytes32 _key2, bytes32 _key3) internal view returns (bytes32) {
        return get(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bool storage item, bytes32 _key, bytes32 _key2, bytes32 _key3) internal view returns (bool) {
        return get(self, item, keccak256(abi.encodePacked(_key, _key2, _key3)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntBoolMapping storage item, uint _key) internal view returns (bool) {
        return get(self, item.innerMapping, bytes32(_key));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntEnumMapping storage item, uint _key) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntUIntMapping storage item, uint _key) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntAddressMapping storage item, uint _key) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32UIntMapping storage item, bytes32 _key) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32AddressMapping storage item, bytes32 _key) internal view returns (address) {
        return address(get(self, item.innerMapping, _key));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32UInt8Mapping storage item, bytes32 _key) internal view returns (uint8) {
        return get(self, item.innerMapping, _key);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32BoolMapping storage item, bytes32 _key) internal view returns (bool) {
        return get(self, item.innerMapping, _key);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32Bytes32Mapping storage item, bytes32 _key) internal view returns (bytes32) {
        return get(self, item.innerMapping, _key);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32UIntBoolMapping storage item, bytes32 _key, uint _key2) internal view returns (bool) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntBytes32Mapping storage item, uint _key) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntMapping storage item, address _key) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressBoolMapping storage item, address _key) internal view returns (bool) {
        return toBool(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressAddressMapping storage item, address _key) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressBytes32Mapping storage item, address _key) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntUIntBytes32Mapping storage item, uint _key, uint _key2) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntUIntAddressMapping storage item, uint _key, uint _key2) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntUIntUIntMapping storage item, uint _key, uint _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32UIntUIntMapping storage item, bytes32 _key, uint _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key, bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32UIntUIntUIntMapping storage item, bytes32 _key, uint _key2, uint _key3) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key, bytes32(_key2), bytes32(_key3)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressAddressUIntMapping storage item, address _key, address _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressAddressUInt8Mapping storage item, address _key, address _key2) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntMapping storage item, address _key, uint _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUInt8Mapping storage item, address _key, uint _key2) internal view returns (uint) {
        return uint8(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressBytes32Bytes32Mapping storage item, address _key, bytes32 _key2) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), _key2);
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressBytes4BoolMapping storage item, address _key, bytes4 _key2) internal view returns (bool) {
        return toBool(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressBytes4Bytes32Mapping storage item, address _key, bytes4 _key2) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntAddressUIntMapping storage item, uint _key, address _key2) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntAddressBoolMapping storage item, uint _key, address _key2) internal view returns (bool) {
        return toBool(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntAddressAddressMapping storage item, uint _key, address _key2) internal view returns (address) {
        return address(get(self, item.innerMapping, bytes32(_key), bytes32(_key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntAddressAddressBoolMapping storage item, uint _key, address _key2, address _key3) internal view returns (bool) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntUIntUIntBytes32Mapping storage item, uint _key, uint _key2, uint _key3) internal view returns (bytes32) {
        return get(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntMapping storage item, address _key, uint _key2, uint _key3) internal view returns (uint) {
        return uint(get(self, item.innerMapping, bytes32(_key), bytes32(_key2), bytes32(_key3)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntStructAddressUInt8Mapping storage item, address _key, uint _key2) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, uint _key4) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntUIntStructAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, uint _key4, uint _key5) internal view returns (address, uint8) {
        return get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5)));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntAddressUInt8Mapping storage item, address _key, uint _key2, address _key3) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3))));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, address _key4) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4))));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressUIntUIntUIntAddressUInt8Mapping storage item, address _key, uint _key2, uint _key3, uint _key4, address _key5) internal view returns (uint8) {
        return uint8(get(self, item.innerMapping, keccak256(abi.encodePacked(_key, _key2, _key3, _key4, _key5))));
    }

     

    function includes(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _value) internal view returns (bool) {
        return includes(self, item, SET_IDENTIFIER, _value);
    }

    function includes(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt, bytes32 _value) internal view returns (bool) {
        return get(self, item.indexes, _salt, _value) != 0;
    }

    function includes(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item, address _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(StorageInterface.Config storage self, StorageInterface.CounterSet storage item, uint _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _value) internal view returns (bool) {
        return includes(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function includes(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _salt, bytes32 _value) private view returns (bool) {
        return _value != 0x0 && (get(self, item.nextValues, _salt, _value) != 0x0 || get(self, item.last, _salt) == _value);
    }

    function includes(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, uint _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, address _value) internal view returns (bool) {
        return includes(self, item.innerSet, bytes32(_value));
    }

    function includes(StorageInterface.Config storage self, StorageInterface.Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, _value);
    }

    function includes(StorageInterface.Config storage self, StorageInterface.AddressesSetMapping storage item, bytes32 _key, address _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function includes(StorageInterface.Config storage self, StorageInterface.UIntSetMapping storage item, bytes32 _key, uint _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function includes(StorageInterface.Config storage self, StorageInterface.Bytes32OrderedSetMapping storage item, bytes32 _key, bytes32 _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, _value);
    }

    function includes(StorageInterface.Config storage self, StorageInterface.UIntOrderedSetMapping storage item, bytes32 _key, uint _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function includes(StorageInterface.Config storage self, StorageInterface.AddressOrderedSetMapping storage item, bytes32 _key, address _value) internal view returns (bool) {
        return includes(self, item.innerMapping, _key, bytes32(_value));
    }

    function getIndex(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _value) internal view returns (uint) {
        return getIndex(self, item, SET_IDENTIFIER, _value);
    }

    function getIndex(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt, bytes32 _value) private view returns (uint) {
        return uint(get(self, item.indexes, _salt, _value));
    }

    function getIndex(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item, address _value) internal view returns (uint) {
        return getIndex(self, item.innerSet, bytes32(_value));
    }

    function getIndex(StorageInterface.Config storage self, StorageInterface.CounterSet storage item, uint _value) internal view returns (uint) {
        return getIndex(self, item.innerSet, bytes32(_value));
    }

    function getIndex(StorageInterface.Config storage self, StorageInterface.Bytes32SetMapping storage item, bytes32 _key, bytes32 _value) internal view returns (uint) {
        return getIndex(self, item.innerMapping, _key, _value);
    }

    function getIndex(StorageInterface.Config storage self, StorageInterface.AddressesSetMapping storage item, bytes32 _key, address _value) internal view returns (uint) {
        return getIndex(self, item.innerMapping, _key, bytes32(_value));
    }

    function getIndex(StorageInterface.Config storage self, StorageInterface.UIntSetMapping storage item, bytes32 _key, uint _value) internal view returns (uint) {
        return getIndex(self, item.innerMapping, _key, bytes32(_value));
    }

     

    function count(StorageInterface.Config storage self, StorageInterface.Set storage item) internal view returns (uint) {
        return count(self, item, SET_IDENTIFIER);
    }

    function count(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt) internal view returns (uint) {
        return get(self, item.count, _salt);
    }

    function count(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(StorageInterface.Config storage self, StorageInterface.CounterSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item) internal view returns (uint) {
        return count(self, item, ORDERED_SET_IDENTIFIER);
    }

    function count(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _salt) private view returns (uint) {
        return get(self, item.count, _salt);
    }

    function count(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item) internal view returns (uint) {
        return count(self, item.innerSet);
    }

    function count(StorageInterface.Config storage self, StorageInterface.Bytes32SetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(StorageInterface.Config storage self, StorageInterface.AddressesSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(StorageInterface.Config storage self, StorageInterface.UIntSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(StorageInterface.Config storage self, StorageInterface.Bytes32OrderedSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(StorageInterface.Config storage self, StorageInterface.UIntOrderedSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function count(StorageInterface.Config storage self, StorageInterface.AddressOrderedSetMapping storage item, bytes32 _key) internal view returns (uint) {
        return count(self, item.innerMapping, _key);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Set storage item) internal view returns (bytes32[] result) {
        result = get(self, item, SET_IDENTIFIER);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt) private view returns (bytes32[] result) {
        uint valuesCount = count(self, item, _salt);
        result = new bytes32[](valuesCount);
        for (uint i = 0; i < valuesCount; i++) {
            result[i] = get(self, item, _salt, i);
        }
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item) internal view returns (address[]) {
        return toAddresses(get(self, item.innerSet));
    }

    function get(StorageInterface.Config storage self, StorageInterface.CounterSet storage item) internal view returns (uint[]) {
        return toUInt(get(self, item.innerSet));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32SetMapping storage item, bytes32 _key) internal view returns (bytes32[]) {
        return get(self, item.innerMapping, _key);
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressesSetMapping storage item, bytes32 _key) internal view returns (address[]) {
        return toAddresses(get(self, item.innerMapping, _key));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntSetMapping storage item, bytes32 _key) internal view returns (uint[]) {
        return toUInt(get(self, item.innerMapping, _key));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Set storage item, uint _index) internal view returns (bytes32) {
        return get(self, item, SET_IDENTIFIER, _index);
    }

    function get(StorageInterface.Config storage self, StorageInterface.Set storage item, bytes32 _salt, uint _index) private view returns (bytes32) {
        return get(self, item.values, _salt, bytes32(_index+1));
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressesSet storage item, uint _index) internal view returns (address) {
        return address(get(self, item.innerSet, _index));
    }

    function get(StorageInterface.Config storage self, StorageInterface.CounterSet storage item, uint _index) internal view returns (uint) {
        return uint(get(self, item.innerSet, _index));
    }

    function get(StorageInterface.Config storage self, StorageInterface.Bytes32SetMapping storage item, bytes32 _key, uint _index) internal view returns (bytes32) {
        return get(self, item.innerMapping, _key, _index);
    }

    function get(StorageInterface.Config storage self, StorageInterface.AddressesSetMapping storage item, bytes32 _key, uint _index) internal view returns (address) {
        return address(get(self, item.innerMapping, _key, _index));
    }

    function get(StorageInterface.Config storage self, StorageInterface.UIntSetMapping storage item, bytes32 _key, uint _index) internal view returns (uint) {
        return uint(get(self, item.innerMapping, _key, _index));
    }

    function getNextValue(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _value) internal view returns (bytes32) {
        return getNextValue(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function getNextValue(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _salt, bytes32 _value) private view returns (bytes32) {
        return get(self, item.nextValues, _salt, _value);
    }

    function getNextValue(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, uint _value) internal view returns (uint) {
        return uint(getNextValue(self, item.innerSet, bytes32(_value)));
    }

    function getNextValue(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, address _value) internal view returns (address) {
        return address(getNextValue(self, item.innerSet, bytes32(_value)));
    }

    function getPreviousValue(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _value) internal view returns (bytes32) {
        return getPreviousValue(self, item, ORDERED_SET_IDENTIFIER, _value);
    }

    function getPreviousValue(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 _salt, bytes32 _value) private view returns (bytes32) {
        return get(self, item.previousValues, _salt, _value);
    }

    function getPreviousValue(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, uint _value) internal view returns (uint) {
        return uint(getPreviousValue(self, item.innerSet, bytes32(_value)));
    }

    function getPreviousValue(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, address _value) internal view returns (address) {
        return address(getPreviousValue(self, item.innerSet, bytes32(_value)));
    }

    function toBool(bytes32 self) internal pure returns (bool) {
        return self != bytes32(0);
    }

    function toBytes32(bool self) internal pure returns (bytes32) {
        return bytes32(self ? 1 : 0);
    }

    function toAddresses(bytes32[] memory self) internal pure returns (address[]) {
        address[] memory result = new address[](self.length);
        for (uint i = 0; i < self.length; i++) {
            result[i] = address(self[i]);
        }
        return result;
    }

    function toUInt(bytes32[] memory self) internal pure returns (uint[]) {
        uint[] memory result = new uint[](self.length);
        for (uint i = 0; i < self.length; i++) {
            result[i] = uint(self[i]);
        }
        return result;
    }

    function _setOrderedSetLink(StorageInterface.Config storage self, StorageInterface.Mapping storage link, bytes32 _salt, bytes32 from, bytes32 to) private {
        if (from != 0x0) {
            set(self, link, _salt, from, to);
        }
    }

    function _deleteOrderedSetLink(StorageInterface.Config storage self, StorageInterface.Mapping storage link, bytes32 _salt, bytes32 from) private {
        if (from != 0x0) {
            set(self, link, _salt, from, 0x0);
        }
    }

     

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 anchorKey, bytes32 startValue, uint limit) internal view returns (StorageInterface.Iterator) {
        if (startValue == 0x0) {
            return listIterator(self, item, anchorKey, limit);
        }

        return createIterator(anchorKey, startValue, limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, bytes32 anchorKey, uint startValue, uint limit) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, anchorKey, bytes32(startValue), limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, bytes32 anchorKey, address startValue, uint limit) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, anchorKey, bytes32(startValue), limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, uint limit) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item, ORDERED_SET_IDENTIFIER, limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 anchorKey, uint limit) internal view returns (StorageInterface.Iterator) {
        return createIterator(anchorKey, get(self, item.first, anchorKey), limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, uint limit) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, bytes32 anchorKey, uint limit) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, anchorKey, limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, uint limit) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, uint limit, bytes32 anchorKey) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, anchorKey, limit);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item, ORDERED_SET_IDENTIFIER);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, bytes32 anchorKey) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item, anchorKey, get(self, item.count, anchorKey));
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, bytes32 anchorKey) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, anchorKey);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, bytes32 anchorKey) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerSet, anchorKey);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.Bytes32OrderedSetMapping storage item, bytes32 _key) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerMapping, _key);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.UIntOrderedSetMapping storage item, bytes32 _key) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerMapping, _key);
    }

    function listIterator(StorageInterface.Config storage self, StorageInterface.AddressOrderedSetMapping storage item, bytes32 _key) internal view returns (StorageInterface.Iterator) {
        return listIterator(self, item.innerMapping, _key);
    }

    function createIterator(bytes32 anchorKey, bytes32 startValue, uint limit) internal pure returns (StorageInterface.Iterator) {
        return StorageInterface.Iterator({
            currentValue: startValue,
            limit: limit,
            valuesLeft: limit,
            anchorKey: anchorKey
        });
    }

    function getNextWithIterator(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, StorageInterface.Iterator iterator) internal view returns (bytes32 _nextValue) {
        if (!canGetNextWithIterator(self, item, iterator)) { revert(); }

        _nextValue = iterator.currentValue;

        iterator.currentValue = getNextValue(self, item, iterator.anchorKey, iterator.currentValue);
        iterator.valuesLeft -= 1;
    }

    function getNextWithIterator(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, StorageInterface.Iterator iterator) internal view returns (uint _nextValue) {
        return uint(getNextWithIterator(self, item.innerSet, iterator));
    }

    function getNextWithIterator(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, StorageInterface.Iterator iterator) internal view returns (address _nextValue) {
        return address(getNextWithIterator(self, item.innerSet, iterator));
    }

    function getNextWithIterator(StorageInterface.Config storage self, StorageInterface.Bytes32OrderedSetMapping storage item, StorageInterface.Iterator iterator) internal view returns (bytes32 _nextValue) {
        return getNextWithIterator(self, item.innerMapping, iterator);
    }

    function getNextWithIterator(StorageInterface.Config storage self, StorageInterface.UIntOrderedSetMapping storage item, StorageInterface.Iterator iterator) internal view returns (uint _nextValue) {
        return uint(getNextWithIterator(self, item.innerMapping, iterator));
    }

    function getNextWithIterator(StorageInterface.Config storage self, StorageInterface.AddressOrderedSetMapping storage item, StorageInterface.Iterator iterator) internal view returns (address _nextValue) {
        return address(getNextWithIterator(self, item.innerMapping, iterator));
    }

    function canGetNextWithIterator(StorageInterface.Config storage self, StorageInterface.OrderedSet storage item, StorageInterface.Iterator iterator) internal view returns (bool) {
        if (iterator.valuesLeft == 0 || !includes(self, item, iterator.anchorKey, iterator.currentValue)) {
            return false;
        }

        return true;
    }

    function canGetNextWithIterator(StorageInterface.Config storage self, StorageInterface.OrderedUIntSet storage item, StorageInterface.Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerSet, iterator);
    }

    function canGetNextWithIterator(StorageInterface.Config storage self, StorageInterface.OrderedAddressesSet storage item, StorageInterface.Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerSet, iterator);
    }

    function canGetNextWithIterator(StorageInterface.Config storage self, StorageInterface.Bytes32OrderedSetMapping storage item, StorageInterface.Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerMapping, iterator);
    }

    function canGetNextWithIterator(StorageInterface.Config storage self, StorageInterface.UIntOrderedSetMapping storage item, StorageInterface.Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerMapping, iterator);
    }

    function canGetNextWithIterator(StorageInterface.Config storage self, StorageInterface.AddressOrderedSetMapping storage item, StorageInterface.Iterator iterator) internal view returns (bool) {
        return canGetNextWithIterator(self, item.innerMapping, iterator);
    }

    function count(StorageInterface.Iterator iterator) internal pure returns (uint) {
        return iterator.valuesLeft;
    }
}

 

 

pragma solidity ^0.4.11;


 
contract BaseByzantiumRouter {

    function() external payable {
        address _implementation = implementation();

        assembly {
            let calldataMemoryOffset := mload(0x40)
            mstore(0x40, add(calldataMemoryOffset, calldatasize))
            calldatacopy(calldataMemoryOffset, 0x0, calldatasize)
            let r := delegatecall(sub(gas, 10000), _implementation, calldataMemoryOffset, calldatasize, 0, 0)

            let returndataMemoryOffset := mload(0x40)
            mstore(0x40, add(returndataMemoryOffset, returndatasize))
            returndatacopy(returndataMemoryOffset, 0x0, returndatasize)

            switch r
            case 1 {
                return(returndataMemoryOffset, returndatasize)
            }
            default {
                revert(0, 0)
            }
        }
    }

     
     
     
    function implementation() internal view returns (address);
}

 

 

pragma solidity ^0.4.23;



contract StorageAdapter {

    using StorageInterface for *;

    StorageInterface.Config internal store;

    constructor(Storage _store, bytes32 _crate) public {
        store.init(_store, _crate);
    }
}

 

 

pragma solidity ^0.4.24;




contract ChronoBankPlatformBackendProvider is Owned {

    ChronoBankPlatformInterface public platformBackend;

    constructor(ChronoBankPlatformInterface _platformBackend) public {
        updatePlatformBackend(_platformBackend);
    }

    function updatePlatformBackend(ChronoBankPlatformInterface _updatedPlatformBackend)
    public
    onlyContractOwner
    returns (bool)
    {
        require(address(_updatedPlatformBackend) != 0x0, "PLATFORM_BACKEND_PROVIDER_INVALID_PLATFORM_ADDRESS");

        platformBackend = _updatedPlatformBackend;
        return true;
    }
}

 

 

pragma solidity ^0.4.24;







contract ChronoBankPlatformRouterCore {
    address internal platformBackendProvider;
}


contract ChronoBankPlatformCore {

    bytes32 constant CHRONOBANK_PLATFORM_CRATE = "ChronoBankPlatform";

     
    StorageInterface.Bytes32UIntMapping internal assetOwnerIdStorage;
     
    StorageInterface.Bytes32UIntMapping internal assetTotalSupply;
     
    StorageInterface.StringMapping internal assetName;
     
    StorageInterface.StringMapping internal assetDescription;
     
    StorageInterface.Bytes32BoolMapping internal assetIsReissuable;
     
    StorageInterface.Bytes32UInt8Mapping internal assetBaseUnit;
     
    StorageInterface.Bytes32UIntBoolMapping internal assetPartowners;
     
    StorageInterface.Bytes32UIntUIntMapping internal assetWalletBalance;
     
    StorageInterface.Bytes32UIntUIntUIntMapping internal assetWalletAllowance;
     
    StorageInterface.Bytes32UIntMapping internal assetBlockNumber;

     
    StorageInterface.UInt internal holdersCountStorage;
     
    StorageInterface.UIntAddressMapping internal holdersAddressStorage;
     
    StorageInterface.UIntAddressBoolMapping internal holdersTrustStorage;
     
    StorageInterface.AddressUIntMapping internal holderIndexStorage;

     
    StorageInterface.Set internal symbolsStorage;

     
    StorageInterface.Bytes32AddressMapping internal proxiesStorage;

     
    StorageInterface.AddressBoolMapping internal partownersStorage;
}


contract ChronoBankPlatformRouter is
    BaseByzantiumRouter,
    ChronoBankPlatformRouterCore,
    ChronoBankPlatformEmitter,
    StorageAdapter
{
     
    address public contractOwner;

    bytes32 constant CHRONOBANK_PLATFORM_CRATE = "ChronoBankPlatform";

    constructor(address _platformBackendProvider)
    StorageAdapter(Storage(address(this)), CHRONOBANK_PLATFORM_CRATE)
    public
    {
        require(_platformBackendProvider != 0x0, "PLATFORM_ROUTER_INVALID_BACKEND_ADDRESS");

        contractOwner = msg.sender;
        platformBackendProvider = _platformBackendProvider;
    }

    function implementation()
    internal
    view
    returns (address)
    {
        return ChronoBankPlatformBackendProvider(platformBackendProvider).platformBackend();
    }
}

 

 
 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "SAFE_MATH_INVALID_MUL");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SAFE_MATH_INVALID_SUB");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SAFE_MATH_INVALID_ADD");
        return c;
    }
}

 

 

pragma solidity ^0.4.21;






contract ProxyEventsEmitter {
    function emitTransfer(address _from, address _to, uint _value) public;
    function emitApprove(address _from, address _spender, uint _value) public;
}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract ChronoBankPlatform is
    ChronoBankPlatformRouterCore,
    ChronoBankPlatformEmitter,
    StorageInterfaceContract,
    ChronoBankPlatformCore
{
    uint constant OK = 1;

    using SafeMath for uint;

    uint constant CHRONOBANK_PLATFORM_SCOPE = 15000;
    uint constant CHRONOBANK_PLATFORM_PROXY_ALREADY_EXISTS = CHRONOBANK_PLATFORM_SCOPE + 0;
    uint constant CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF = CHRONOBANK_PLATFORM_SCOPE + 1;
    uint constant CHRONOBANK_PLATFORM_INVALID_VALUE = CHRONOBANK_PLATFORM_SCOPE + 2;
    uint constant CHRONOBANK_PLATFORM_INSUFFICIENT_BALANCE = CHRONOBANK_PLATFORM_SCOPE + 3;
    uint constant CHRONOBANK_PLATFORM_NOT_ENOUGH_ALLOWANCE = CHRONOBANK_PLATFORM_SCOPE + 4;
    uint constant CHRONOBANK_PLATFORM_ASSET_ALREADY_ISSUED = CHRONOBANK_PLATFORM_SCOPE + 5;
    uint constant CHRONOBANK_PLATFORM_CANNOT_ISSUE_FIXED_ASSET_WITH_INVALID_VALUE = CHRONOBANK_PLATFORM_SCOPE + 6;
    uint constant CHRONOBANK_PLATFORM_CANNOT_REISSUE_FIXED_ASSET = CHRONOBANK_PLATFORM_SCOPE + 7;
    uint constant CHRONOBANK_PLATFORM_SUPPLY_OVERFLOW = CHRONOBANK_PLATFORM_SCOPE + 8;
    uint constant CHRONOBANK_PLATFORM_NOT_ENOUGH_TOKENS = CHRONOBANK_PLATFORM_SCOPE + 9;
    uint constant CHRONOBANK_PLATFORM_INVALID_NEW_OWNER = CHRONOBANK_PLATFORM_SCOPE + 10;
    uint constant CHRONOBANK_PLATFORM_ALREADY_TRUSTED = CHRONOBANK_PLATFORM_SCOPE + 11;
    uint constant CHRONOBANK_PLATFORM_SHOULD_RECOVER_TO_NEW_ADDRESS = CHRONOBANK_PLATFORM_SCOPE + 12;
    uint constant CHRONOBANK_PLATFORM_ASSET_IS_NOT_ISSUED = CHRONOBANK_PLATFORM_SCOPE + 13;
    uint constant CHRONOBANK_PLATFORM_INVALID_INVOCATION = CHRONOBANK_PLATFORM_SCOPE + 17;

    string public version = "0.2.0";

    struct TransactionContext {
        address from;
        address to;
        address sender;
        uint fromHolderId;
        uint toHolderId;
        uint senderHolderId;
        uint balanceFrom;
        uint balanceTo;
        uint allowanceValue;
    }

     
    modifier onlyOwner(bytes32 _symbol) {
        if (isOwner(msg.sender, _symbol)) {
            _;
        }
    }

    modifier onlyDesignatedManager(bytes32 _symbol) {
        if (isDesignatedAssetManager(msg.sender, _symbol)) {
            _;
        }
    }

     
    modifier onlyOneOfContractOwners() {
        if (contractOwner == msg.sender || partowners(msg.sender)) {
            _;
        }
    }

     
    modifier onlyProxy(bytes32 _symbol) {
        if (proxies(_symbol) == msg.sender) {
            _;
        }
    }

     
    modifier checkTrust(address _from, address _to) {
        if (isTrusted(_from, _to)) {
            _;
        }
    }

     
    modifier onlyAfterBlock(bytes32 _symbol) {
        if (block.number >= blockNumber(_symbol)) {
            _;
        }
    }

    constructor() StorageContractAdapter(this, CHRONOBANK_PLATFORM_CRATE) public {
    }

    function initStorage()
    public
    {
        init(partownersStorage, "partowners");
        init(proxiesStorage, "proxies");
        init(symbolsStorage, "symbols");

        init(holdersCountStorage, "holdersCount");
        init(holderIndexStorage, "holderIndex");
        init(holdersAddressStorage, "holdersAddress");
        init(holdersTrustStorage, "holdersTrust");

        init(assetOwnerIdStorage, "assetOwner");
        init(assetTotalSupply, "assetTotalSupply");
        init(assetName, "assetName");
        init(assetDescription, "assetDescription");
        init(assetIsReissuable, "assetIsReissuable");
        init(assetBlockNumber, "assetBlockNumber");
        init(assetBaseUnit, "assetBaseUnit");
        init(assetPartowners, "assetPartowners");
        init(assetWalletBalance, "assetWalletBalance");
        init(assetWalletAllowance, "assetWalletAllowance");
    }

     
     
     
     
    function assets(bytes32 _symbol) public view returns (
        uint _owner,
        uint _totalSupply,
        string _name,
        string _description,
        bool _isReissuable,
        uint8 _baseUnit,
        uint _blockNumber
    ) {
        _owner = _assetOwner(_symbol);
        _totalSupply = totalSupply(_symbol);
        _name = name(_symbol);
        _description = description(_symbol);
        _isReissuable = isReissuable(_symbol);
        _baseUnit = baseUnit(_symbol);
        _blockNumber = blockNumber(_symbol);
    }

    function holdersCount() public view returns (uint) {
        return get(store, holdersCountStorage);
    }

    function holders(uint _holderId) public view returns (address) {
        return get(store, holdersAddressStorage, _holderId);
    }

    function symbols(uint _idx) public view returns (bytes32) {
        return get(store, symbolsStorage, _idx);
    }

     
     
    function symbolsCount() public view returns (uint) {
        return count(store, symbolsStorage);
    }

    function proxies(bytes32 _symbol) public view returns (address) {
        return get(store, proxiesStorage, _symbol);
    }

    function partowners(address _address) public view returns (bool) {
        return get(store, partownersStorage, _address);
    }

     
     
     
     
    function addPartOwner(address _partowner)
    public
    onlyContractOwner
    returns (uint)
    {
        set(store, partownersStorage, _partowner, true);
        return OK;
    }

     
     
     
     
    function removePartOwner(address _partowner)
    public
    onlyContractOwner
    returns (uint)
    {
        set(store, partownersStorage, _partowner, false);
        return OK;
    }

     
     
     
     
    function setupEventsHistory(address _eventsHistory)
    public
    onlyContractOwner
    returns (uint errorCode)
    {
        _setEventsHistory(_eventsHistory);
        return OK;
    }

     
     
     
    function isCreated(bytes32 _symbol) public view returns (bool) {
        return _assetOwner(_symbol) != 0;
    }

     
     
     
    function baseUnit(bytes32 _symbol) public view returns (uint8) {
        return get(store, assetBaseUnit, _symbol);
    }

     
     
     
    function name(bytes32 _symbol) public view returns (string) {
        return get(store, assetName, _symbol);
    }

     
     
     
    function description(bytes32 _symbol) public view returns (string) {
        return get(store, assetDescription, _symbol);
    }

     
     
     
    function isReissuable(bytes32 _symbol) public view returns (bool) {
        return get(store, assetIsReissuable, _symbol);
    }

     
     
     
    function blockNumber(bytes32 _symbol) public view returns (uint) {
        return get(store, assetBlockNumber, _symbol);
    }

     
     
     
    function owner(bytes32 _symbol) public view returns (address) {
        return _address(_assetOwner(_symbol));
    }

     
     
     
     
    function isOwner(address _owner, bytes32 _symbol) public view returns (bool) {
        return isCreated(_symbol) && (_assetOwner(_symbol) == getHolderId(_owner));
    }

     
     
     
     
    function hasAssetRights(address _owner, bytes32 _symbol) public view returns (bool) {
        uint holderId = getHolderId(_owner);
        return isCreated(_symbol) && (_assetOwner(_symbol) == holderId || get(store, assetPartowners, _symbol, holderId));
    }

     
     
     
     
    function isDesignatedAssetManager(address _manager, bytes32 _symbol) public view returns (bool) {
        uint managerId = getHolderId(_manager);
        return isCreated(_symbol) && get(store, assetPartowners, _symbol, managerId);
    }

     
     
     
    function totalSupply(bytes32 _symbol) public view returns (uint) {
        return get(store, assetTotalSupply, _symbol);
    }

     
     
     
     
    function balanceOf(address _holder, bytes32 _symbol) public view returns (uint) {
        return _balanceOf(getHolderId(_holder), _symbol);
    }

     
     
     
     
    function _balanceOf(uint _holderId, bytes32 _symbol) public view returns (uint) {
        return get(store, assetWalletBalance, _symbol, _holderId);
    }

     
     
     
    function _address(uint _holderId) public view returns (address) {
        return get(store, holdersAddressStorage, _holderId);
    }

     
     
     
     
     
    function addDesignatedAssetManager(bytes32 _symbol, address _manager)
    public
    onlyOneOfContractOwners
    returns (uint)
    {
        uint holderId = _createHolderId(_manager);
        set(store, assetPartowners, _symbol, holderId, true);
        _emitter().emitOwnershipChange(0x0, _manager, _symbol);
        return OK;
    }

     
     
     
     
     
    function removeDesignatedAssetManager(bytes32 _symbol, address _manager)
    public
    onlyOneOfContractOwners
    returns (uint)
    {
        uint holderId = getHolderId(_manager);
        set(store, assetPartowners, _symbol, holderId, false);
        _emitter().emitOwnershipChange(_manager, 0x0, _symbol);
        return OK;
    }

     
     
     
     
     
    function setProxy(address _proxyAddress, bytes32 _symbol)
    public
    onlyOneOfContractOwners
    returns (uint)
    {
        if (proxies(_symbol) != 0x0) {
            return CHRONOBANK_PLATFORM_PROXY_ALREADY_EXISTS;
        }

        set(store, proxiesStorage, _symbol, _proxyAddress);
        return OK;
    }

     
     
     
     
     
     
     
     
    function massTransfer(address[] addresses, uint[] values, bytes32 _symbol)
    external
    onlyAfterBlock(_symbol)
    returns (uint errorCode, uint count)
    {
        require(addresses.length == values.length, "Different length of addresses and values for mass transfer");
        require(_symbol != 0x0, "Asset's symbol cannot be 0");

        return _massTransferDirect(addresses, values, _symbol);
    }

    function _massTransferDirect(address[] addresses, uint[] values, bytes32 _symbol)
    private
    returns (uint errorCode, uint count)
    {
        uint success = 0;

        TransactionContext memory txContext;
        txContext.from = msg.sender;
        txContext.fromHolderId = _createHolderId(txContext.from);

        for (uint idx = 0; idx < addresses.length && gasleft() > 110000; idx++) {
            uint value = values[idx];

            if (value == 0) {
                _emitErrorCode(CHRONOBANK_PLATFORM_INVALID_VALUE);
                continue;
            }

            txContext.balanceFrom = _balanceOf(txContext.fromHolderId, _symbol);

            if (txContext.balanceFrom < value) {
                _emitErrorCode(CHRONOBANK_PLATFORM_INSUFFICIENT_BALANCE);
                continue;
            }

            if (txContext.from == addresses[idx]) {
                _emitErrorCode(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
                continue;
            }

            txContext.toHolderId = _createHolderId(addresses[idx]);
            txContext.balanceTo = _balanceOf(txContext.toHolderId, _symbol);
            _transferDirect(value, _symbol, txContext);
            _emitter().emitTransfer(txContext.from, addresses[idx], _symbol, value, "");

            success++;
        }

        return (OK, success);
    }

     
     
     
    function _transferDirect(
        uint _value,
        bytes32 _symbol,
        TransactionContext memory _txContext
    )
    internal
    {
        set(store, assetWalletBalance, _symbol, _txContext.fromHolderId, _txContext.balanceFrom.sub(_value));
        set(store, assetWalletBalance, _symbol, _txContext.toHolderId, _txContext.balanceTo.add(_value));
    }

     
     
     
     
     
     
     
     
    function _transfer(
        uint _value,
        bytes32 _symbol,
        string _reference,
        TransactionContext memory txContext
    )
    internal
    returns (uint)
    {
         
        if (txContext.fromHolderId == txContext.toHolderId) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }

         
        if (_value == 0) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_INVALID_VALUE);
        }

         
        txContext.balanceFrom = _balanceOf(txContext.fromHolderId, _symbol);
        txContext.balanceTo = _balanceOf(txContext.toHolderId, _symbol);
        if (txContext.balanceFrom < _value) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_INSUFFICIENT_BALANCE);
        }

         
        txContext.allowanceValue = _allowance(txContext.fromHolderId, txContext.senderHolderId, _symbol);
        if (txContext.fromHolderId != txContext.senderHolderId &&
            txContext.allowanceValue < _value
        ) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_NOT_ENOUGH_ALLOWANCE);
        }

        _transferDirect(_value, _symbol, txContext);
         
        _decrementWalletAllowance(_value, _symbol, txContext);
         
         
         
        _emitter().emitTransfer(txContext.from, txContext.to, _symbol, _value, _reference);
        _proxyTransferEvent(_value, _symbol, txContext);
        return OK;
    }

    function _decrementWalletAllowance(
        uint _value,
        bytes32 _symbol,
        TransactionContext memory txContext
    )
    private
    {
        if (txContext.fromHolderId != txContext.senderHolderId) {
            set(store, assetWalletAllowance, _symbol, txContext.fromHolderId, txContext.senderHolderId, txContext.allowanceValue.sub(_value));
        }
    }

     
     
     
     
     
     
     
     
     
     
    function proxyTransferWithReference(
        address _to,
        uint _value,
        bytes32 _symbol,
        string _reference,
        address _sender
    )
    public
    onlyProxy(_symbol)
    onlyAfterBlock(_symbol)
    returns (uint)
    {
        TransactionContext memory txContext;
        txContext.sender = _sender;
        txContext.to = _to;
        txContext.from = _sender;
        txContext.senderHolderId = getHolderId(_sender);
        txContext.toHolderId = _createHolderId(_to);
        txContext.fromHolderId = txContext.senderHolderId;
        return _transfer(_value, _symbol, _reference, txContext);
    }

     
     
     
    function _proxyTransferEvent(uint _value, bytes32 _symbol, TransactionContext memory txContext) internal {
        address _proxy = proxies(_symbol);
        if (_proxy != 0x0) {
             
             
             
            ProxyEventsEmitter(_proxy).emitTransfer(txContext.from, txContext.to, _value);
        }
    }

     
     
     
    function getHolderId(address _holder) public view returns (uint) {
        return get(store, holderIndexStorage, _holder);
    }

     
     
     
    function _createHolderId(address _holder) internal returns (uint) {
        uint _holderId = getHolderId(_holder);
        if (_holderId == 0) {
            _holderId = holdersCount() + 1;
            set(store, holderIndexStorage, _holder, _holderId);
            set(store, holdersAddressStorage, _holderId, _holder);
            set(store, holdersCountStorage, _holderId);
        }

        return _holderId;
    }

    function _assetOwner(bytes32 _symbol) internal view returns (uint) {
        return get(store, assetOwnerIdStorage, _symbol);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function issueAsset(
        bytes32 _symbol,
        uint _value,
        string _name,
        string _description,
        uint8 _baseUnit,
        bool _isReissuable,
        uint _blockNumber
    )
    public
    returns (uint)
    {
        return issueAssetWithInitialReceiver(_symbol, _value, _name, _description, _baseUnit, _isReissuable, _blockNumber, msg.sender);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function issueAssetWithInitialReceiver(
        bytes32 _symbol,
        uint _value,
        string _name,
        string _description,
        uint8 _baseUnit,
        bool _isReissuable,
        uint _blockNumber,
        address _account
    )
    public
    onlyOneOfContractOwners
    returns (uint)
    {
         
        if (_value == 0 && !_isReissuable) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_CANNOT_ISSUE_FIXED_ASSET_WITH_INVALID_VALUE);
        }
         
        if (isCreated(_symbol)) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_ASSET_ALREADY_ISSUED);
        }
        uint holderId = _createHolderId(_account);
        uint creatorId = _account == msg.sender ? holderId : _createHolderId(msg.sender);
        add(store, symbolsStorage, _symbol);
        set(store, assetOwnerIdStorage, _symbol, creatorId);
        set(store, assetTotalSupply, _symbol, _value);
        set(store, assetName, _symbol, _name);
        set(store, assetDescription, _symbol, _description);
        set(store, assetIsReissuable, _symbol, _isReissuable);
        set(store, assetBaseUnit, _symbol, _baseUnit);
        set(store, assetWalletBalance, _symbol, holderId, _value);
        set(store, assetBlockNumber, _symbol, _blockNumber);
         
         
         
        _emitter().emitIssue(_symbol, _value, _address(holderId));
        return OK;
    }

     
     
     
     
     
     
     
     
     
     
    function reissueAsset(bytes32 _symbol, uint _value)
    public
    returns (uint)
    {
        return reissueAssetToRecepient(_symbol, _value, msg.sender);
    }

     
     
     
     
     
     
     
     
     
     
    function reissueAssetToRecepient(bytes32 _symbol, uint _value, address _to)
    public
    onlyDesignatedManager(_symbol)
    onlyAfterBlock(_symbol)
    returns (uint)
    {
        return _reissueAsset(_symbol, _value, _to);
    }

    function _reissueAsset(bytes32 _symbol, uint _value, address _to)
    private
    returns (uint)
    {
        require(_to != 0x0, "CHRONOBANK_PLATFORM_INVALID_RECEPIENT_ADDRESS");

        TransactionContext memory txContext;
        txContext.to = _to;

         
        if (_value == 0) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_INVALID_VALUE);
        }

         
        if (!isReissuable(_symbol)) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_CANNOT_REISSUE_FIXED_ASSET);
        }

        uint _totalSupply = totalSupply(_symbol);
         
        if (_totalSupply + _value < _totalSupply) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_SUPPLY_OVERFLOW);
        }

        txContext.toHolderId = _createHolderId(_to);
        txContext.balanceTo = _balanceOf(txContext.toHolderId, _symbol);
        set(store, assetWalletBalance, _symbol, txContext.toHolderId, txContext.balanceTo.add(_value));
        set(store, assetTotalSupply, _symbol, _totalSupply.add(_value));
         
         
         
        _emitter().emitIssue(_symbol, _value, _to);
        _proxyTransferEvent(_value, _symbol, txContext);
        return OK;
    }

     
     
     
     
     
     
    function revokeAsset(bytes32 _symbol, uint _value) public returns (uint _resultCode) {
        TransactionContext memory txContext;
        txContext.from = msg.sender;
        txContext.fromHolderId = getHolderId(txContext.from);

        _resultCode = _revokeAsset(_symbol, _value, txContext);
        if (_resultCode != OK) {
            return _emitErrorCode(_resultCode);
        }

         
         
         
        _emitter().emitRevoke(_symbol, _value, txContext.from);
        _proxyTransferEvent(_value, _symbol, txContext);
        return OK;
    }

     
     
     
     
     
     
    function revokeAssetWithExternalReference(bytes32 _symbol, uint _value, string _externalReference) public returns (uint _resultCode) {
        TransactionContext memory txContext;
        txContext.from = msg.sender;
        txContext.fromHolderId = getHolderId(txContext.from);

        _resultCode = _revokeAsset(_symbol, _value, txContext);
        if (_resultCode != OK) {
            return _emitErrorCode(_resultCode);
        }

         
         
         
        _emitter().emitRevokeExternal(_symbol, _value, txContext.from, _externalReference);
        _proxyTransferEvent(_value, _symbol, txContext);
        return OK;
    }

    function _revokeAsset(bytes32 _symbol, uint _value, TransactionContext memory txContext) private returns (uint) {
         
        if (_value == 0) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_INVALID_VALUE);
        }

         
        txContext.balanceFrom = _balanceOf(txContext.fromHolderId, _symbol);
        if (txContext.balanceFrom < _value) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_NOT_ENOUGH_TOKENS);
        }

        txContext.balanceFrom = txContext.balanceFrom.sub(_value);
        set(store, assetWalletBalance, _symbol, txContext.fromHolderId, txContext.balanceFrom);
        set(store, assetTotalSupply, _symbol, totalSupply(_symbol).sub(_value));

        return OK;
    }

     
     
     
     
     
     
     
     
     
    function changeOwnership(bytes32 _symbol, address _newOwner)
    public
    onlyOwner(_symbol)
    returns (uint)
    {
        if (_newOwner == 0x0) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_INVALID_NEW_OWNER);
        }

        uint newOwnerId = _createHolderId(_newOwner);
        uint assetOwner = _assetOwner(_symbol);
         
        if (assetOwner == newOwnerId) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }
        address oldOwner = _address(assetOwner);
        set(store, assetOwnerIdStorage, _symbol, newOwnerId);
         
         
         
        _emitter().emitOwnershipChange(oldOwner, _newOwner, _symbol);
        return OK;
    }

     
     
     
     
    function isTrusted(address _from, address _to) public view returns (bool) {
        return get(store, holdersTrustStorage, getHolderId(_from), _to);
    }

     
     
     
    function trust(address _to) public returns (uint) {
        uint fromId = _createHolderId(msg.sender);
         
        if (fromId == getHolderId(_to)) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }
         
        if (isTrusted(msg.sender, _to)) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_ALREADY_TRUSTED);
        }

        set(store, holdersTrustStorage, fromId, _to, true);
        return OK;
    }

     
     
     
    function distrust(address _to)
    public
    checkTrust(msg.sender, _to)
    returns (uint)
    {
        set(store, holdersTrustStorage, getHolderId(msg.sender), _to, false);
        return OK;
    }

     
     
     
     
     
     
     
     
     
     
    function recover(address _from, address _to)
    public
    checkTrust(_from, msg.sender)
    returns (uint errorCode)
    {
         
        if (getHolderId(_to) != 0) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_SHOULD_RECOVER_TO_NEW_ADDRESS);
        }
         
         
        uint _fromHolderId = getHolderId(_from);
        address _fromRef = _address(_fromHolderId);
        set(store, holdersAddressStorage, _fromHolderId, _to);
        set(store, holderIndexStorage, _to, _fromHolderId);
         
         
         
        _emitter().emitRecovery(_fromRef, _to, msg.sender);
        return OK;
    }

     
     
     
     
     
     
     
     
    function _approve(
        uint _value,
        bytes32 _symbol,
        TransactionContext memory txContext
    )
    internal
    returns (uint)
    {
         
        if (!isCreated(_symbol)) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_ASSET_IS_NOT_ISSUED);
        }
         
        if (txContext.fromHolderId == txContext.senderHolderId) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }

         
        txContext.allowanceValue = _allowance(txContext.fromHolderId, txContext.senderHolderId, _symbol);
        if (!(txContext.allowanceValue == 0 || _value == 0)) {
            return _emitErrorCode(CHRONOBANK_PLATFORM_INVALID_INVOCATION);
        }

        set(store, assetWalletAllowance, _symbol, txContext.fromHolderId, txContext.senderHolderId, _value);

         
         
         
        _emitter().emitApprove(txContext.from, txContext.sender, _symbol, _value);
        address _proxy = proxies(_symbol);
        if (_proxy != 0x0) {
             
             
             
            ProxyEventsEmitter(_proxy).emitApprove(txContext.from, txContext.sender, _value);
        }
        return OK;
    }

     
     
     
     
     
     
     
     
     
     
    function proxyApprove(
        address _spender,
        uint _value,
        bytes32 _symbol,
        address _sender
    )
    public
    onlyProxy(_symbol)
    returns (uint)
    {
        TransactionContext memory txContext;
        txContext.sender = _spender;
        txContext.senderHolderId = _createHolderId(_spender);
        txContext.from = _sender;
        txContext.fromHolderId = _createHolderId(_sender);
        return _approve(_value, _symbol, txContext);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function proxyTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        bytes32 _symbol,
        string _reference,
        address _sender
    )
    public
    onlyProxy(_symbol)
    onlyAfterBlock(_symbol)
    returns (uint)
    {
        TransactionContext memory txContext;
        txContext.sender = _sender;
        txContext.to = _to;
        txContext.from = _from;
        txContext.toHolderId = _createHolderId(_to);
        txContext.fromHolderId = getHolderId(_from);
        txContext.senderHolderId = _to == _sender ? txContext.toHolderId : getHolderId(_sender);
        return _transfer(_value, _symbol, _reference, txContext);
    }

     
     
     
     
     
    function allowance(address _from, address _spender, bytes32 _symbol) public view returns (uint) {
        return _allowance(getHolderId(_from), getHolderId(_spender), _symbol);
    }

     
     
     
     
     
    function _allowance(uint _fromId, uint _toId, bytes32 _symbol) internal view returns (uint) {
        return get(store, assetWalletAllowance, _symbol, _fromId, _toId);
    }

    function _emitter() private view returns (ChronoBankPlatformEmitter) {
        return ChronoBankPlatformEmitter(getEventsHistory());
    }
}

 

 

pragma solidity ^0.4.21;



contract ChronoBankAssetProxyInterface is ChronoBankAssetProxy {}



contract EtherTokenExchange {

    uint constant OK = 1;

    event LogEtherDeposited(address indexed sender, uint amount);
    event LogEtherWithdrawn(address indexed sender, uint amount);

    ERC20Interface private token;
    uint private reentrancyFallbackGuard = 1;

    constructor(address _token) public {
        token = ERC20Interface(_token);
    }

    function getToken() public view returns (address) {
        return token;
    }

    function deposit() external payable {
        _deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) external {
        require(token.allowance(msg.sender, address(this)) >= _amount, "ETHER_TOKEN_EXCHANGE_NO_APPROVE_PROVIDED");

        uint _guardState = reentrancyFallbackGuard;

        require(token.transferFrom(msg.sender, address(this), _amount), "ETHER_TOKEN_EXCHANGE_TRANSFER_FROM_FAILED");

        if (reentrancyFallbackGuard == _guardState) {
            _withdraw(msg.sender, _amount);
        }
    }

    function tokenFallback(address _from, uint _value, bytes) external {
        _incrementGuard();

        if (msg.sender == address(token)) {
            _withdraw(_from, _value);
            return;
        }

        ChronoBankAssetProxyInterface _proxy = ChronoBankAssetProxyInterface(address(token));
        address _versionFor = _proxy.getVersionFor(_from);
        if (!(msg.sender == _versionFor ||
            ChronoBankAssetUtils.containsAssetInChain(ChronoBankAssetChainableInterface(_versionFor), msg.sender))
        ) {
            revert("ETHER_TOKEN_EXCHANGE_INVALID_TOKEN");
        }
        _withdraw(_from, _value);
    }

    function () external payable {
        revert("ETHER_TOKEN_EXCHANGE_USE_DEPOSIT_INSTEAD");
    }

     

    function _deposit(address _to, uint _amount) private {
        require(_amount > 0, "ETHER_TOKEN_EXCHANGE_INVALID_AMOUNT");

        ChronoBankAssetProxyInterface _token = ChronoBankAssetProxyInterface(token);
        ChronoBankPlatform _platform = ChronoBankPlatform(_token.chronoBankPlatform());
        require(OK == _platform.reissueAsset(_token.smbl(), _amount), "ETHER_TOKEN_EXCHANGE_ISSUE_FAILURE");
        require(_token.transfer(_to, _amount), "ETHER_TOKEN_EXCHANGE_TRANSFER_FAILURE");

        emit LogEtherDeposited(_to, _amount);
    }

    function _withdraw(address _from, uint _amount) private {
        require(_amount > 0, "ETHER_TOKEN_EXCHANGE_INVALID_AMOUNT");

        ChronoBankAssetProxyInterface _token = ChronoBankAssetProxyInterface(token);
        ChronoBankPlatform _platform = ChronoBankPlatform(_token.chronoBankPlatform());
        require(OK == _platform.revokeAsset(_token.smbl(), _amount), "ETHER_TOKEN_EXCHANGE_REVOKE_FAILURE");

        _from.transfer(_amount);

        emit LogEtherWithdrawn(_from, _amount);
    }


    function _incrementGuard() public {
        reentrancyFallbackGuard += 1;
    }
}