 

pragma solidity ^0.4.11;

contract Owned {
     
    address public contractOwner;

     
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

     
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

     
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

     
    function changeContractOwnership(address _to) onlyContractOwner public returns (bool) {
        if (_to == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

     
    function claimContractOwnership() public returns (bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }

     
    function transferContractOwnership(address _to) onlyContractOwner public returns (bool) {
        if (_to == 0x0) {
            return false;
        }

        if (pendingContractOwner != 0x0) {
            pendingContractOwner = 0x0;
        }

        contractOwner = _to;
        return true;
    }
}


contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

contract Object is Owned {
     
    uint constant OK = 1;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }
}

contract MultiEventsHistoryAdapter {

     
    function _self() constant internal returns (address) {
        return msg.sender;
    }
}

contract ChronoBankPlatformEmitter is MultiEventsHistoryAdapter {
    event Transfer(address indexed from, address indexed to, bytes32 indexed symbol, uint value, string reference);
    event Issue(bytes32 indexed symbol, uint value, address indexed by);
    event Revoke(bytes32 indexed symbol, uint value, address indexed by);
    event OwnershipChange(address indexed from, address indexed to, bytes32 indexed symbol);
    event Approve(address indexed from, address indexed spender, bytes32 indexed symbol, uint value);
    event Recovery(address indexed from, address indexed to, address by);
    event Error(uint errorCode);

    function emitTransfer(address _from, address _to, bytes32 _symbol, uint _value, string _reference) {
        Transfer(_from, _to, _symbol, _value, _reference);
    }

    function emitIssue(bytes32 _symbol, uint _value, address _by) {
        Issue(_symbol, _value, _by);
    }

    function emitRevoke(bytes32 _symbol, uint _value, address _by) {
        Revoke(_symbol, _value, _by);
    }

    function emitOwnershipChange(address _from, address _to, bytes32 _symbol) {
        OwnershipChange(_from, _to, _symbol);
    }

    function emitApprove(address _from, address _spender, bytes32 _symbol, uint _value) {
        Approve(_from, _spender, _symbol, _value);
    }

    function emitRecovery(address _from, address _to, address _by) {
        Recovery(_from, _to, _by);
    }

    function emitError(uint _errorCode) {
        Error(_errorCode);
    }
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ProxyEventsEmitter {
    function emitTransfer(address _from, address _to, uint _value);
    function emitApprove(address _from, address _spender, uint _value);
}


contract AssetOwningListener {
    function assetOwnerAdded(bytes32 _symbol, address _platform, address _owner);
    function assetOwnerRemoved(bytes32 _symbol, address _platform, address _owner);
}

 
contract ChronoBankPlatform is Object, ChronoBankPlatformEmitter {
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

     
    struct Asset {
        uint owner;                        
        uint totalSupply;                  
        string name;                       
        string description;                
        bool isReissuable;                 
        uint8 baseUnit;                    
        mapping(uint => Wallet) wallets;   
        mapping(uint => bool) partowners;  
    }

     
    struct Wallet {
        uint balance;
        mapping(uint => uint) allowance;
    }

     
    struct Holder {
        address addr;                     
        mapping(address => bool) trust;   
    }

     
    uint public holdersCount;
    mapping(uint => Holder) public holders;

     
    mapping(address => uint) holderIndex;

     
    bytes32[] public symbols;

     
    mapping(bytes32 => Asset) public assets;

     
    mapping(bytes32 => address) public proxies;

     
    mapping(address => bool) public partowners;

     
    address public eventsHistory;
    address public eventsAdmin;

    address owningListener;

     
    function _error(uint _errorCode) internal returns(uint) {
        ChronoBankPlatformEmitter(eventsHistory).emitError(_errorCode);
        return _errorCode;
    }

     
    modifier onlyOwner(bytes32 _symbol) {
        if (isOwner(msg.sender, _symbol)) {
            _;
        }
    }

     
    modifier onlyEventsAdmin() {
        if (eventsAdmin == msg.sender || contractOwner == msg.sender) {
            _;
        }
    }

     
    modifier onlyOneOfOwners(bytes32 _symbol) {
        if (hasAssetRights(msg.sender, _symbol)) {
            _;
        }
    }

     
    modifier onlyOneOfContractOwners() {
        if (contractOwner == msg.sender || partowners[msg.sender]) {
            _;
        }
    }

     
    modifier onlyProxy(bytes32 _symbol) {
        if (proxies[_symbol] == msg.sender) {
            _;
        }
    }

     
    modifier checkTrust(address _from, address _to) {
        if (isTrusted(_from, _to)) {
            _;
        }
    }

     
    function addPartOwner(address _partowner) onlyContractOwner returns (uint) {
        partowners[_partowner] = true;
        return OK;
    }

     
    function removePartOwner(address _partowner) onlyContractOwner returns (uint) {
        delete partowners[_partowner];
        return OK;
    }

     
    function setupEventsHistory(address _eventsHistory) onlyEventsAdmin returns (uint errorCode) {
        eventsHistory = _eventsHistory;
        return OK;
    }

     
    function setupEventsAdmin(address _eventsAdmin) onlyContractOwner returns (uint errorCode) {
        eventsAdmin = _eventsAdmin;
        return OK;
    }

     
    function setupAssetOwningListener(address _listener) onlyEventsAdmin public returns (uint) {
        owningListener = _listener;
        return OK;
    }

     
    function symbolsCount() public constant returns (uint) {
        return symbols.length;
    }

     
    function isCreated(bytes32 _symbol) constant returns(bool) {
        return assets[_symbol].owner != 0;
    }

     
    function baseUnit(bytes32 _symbol) constant returns(uint8) {
        return assets[_symbol].baseUnit;
    }

     
    function name(bytes32 _symbol) constant returns(string) {
        return assets[_symbol].name;
    }

     
    function description(bytes32 _symbol) constant returns(string) {
        return assets[_symbol].description;
    }

     
    function isReissuable(bytes32 _symbol) constant returns(bool) {
        return assets[_symbol].isReissuable;
    }

     
    function owner(bytes32 _symbol) constant returns(address) {
        return holders[assets[_symbol].owner].addr;
    }

     
    function isOwner(address _owner, bytes32 _symbol) constant returns(bool) {
        return isCreated(_symbol) && (assets[_symbol].owner == getHolderId(_owner));
    }

     
    function hasAssetRights(address _owner, bytes32 _symbol) constant returns (bool) {
        uint holderId = getHolderId(_owner);
        return isCreated(_symbol) && (assets[_symbol].owner == holderId || assets[_symbol].partowners[holderId]);
    }

     
    function totalSupply(bytes32 _symbol) constant returns(uint) {
        return assets[_symbol].totalSupply;
    }

     
    function balanceOf(address _holder, bytes32 _symbol) constant returns(uint) {
        return _balanceOf(getHolderId(_holder), _symbol);
    }

     
    function _balanceOf(uint _holderId, bytes32 _symbol) constant returns(uint) {
        return assets[_symbol].wallets[_holderId].balance;
    }

     
    function _address(uint _holderId) constant returns(address) {
        return holders[_holderId].addr;
    }

     
    function addAssetPartOwner(bytes32 _symbol, address _partowner) onlyOneOfOwners(_symbol) public returns (uint) {
        uint holderId = _createHolderId(_partowner);
        assets[_symbol].partowners[holderId] = true;
        _delegateAssetOwnerAdded(_symbol, _partowner);
        ChronoBankPlatformEmitter(eventsHistory).emitOwnershipChange(0x0, _partowner, _symbol);
        return OK;
    }

     
    function removeAssetPartOwner(bytes32 _symbol, address _partowner) onlyOneOfOwners(_symbol) public returns (uint) {
        uint holderId = getHolderId(_partowner);
        delete assets[_symbol].partowners[holderId];
        _delegateAssetOwnerRemoved(_symbol, _partowner);
        ChronoBankPlatformEmitter(eventsHistory).emitOwnershipChange(_partowner, 0x0, _symbol);
        return OK;
    }

     
    function setProxy(address _proxyAddress, bytes32 _symbol) onlyOneOfContractOwners returns(uint) {
        if (proxies[_symbol] != 0x0) {
            return CHRONOBANK_PLATFORM_PROXY_ALREADY_EXISTS;
        }

        proxies[_symbol] = _proxyAddress;
        return OK;
    }

     
    function _transferDirect(uint _fromId, uint _toId, uint _value, bytes32 _symbol) internal {
        assets[_symbol].wallets[_fromId].balance = assets[_symbol].wallets[_fromId].balance.sub(_value);
        assets[_symbol].wallets[_toId].balance = assets[_symbol].wallets[_toId].balance.add(_value);
    }

     
    function _transfer(uint _fromId, uint _toId, uint _value, bytes32 _symbol, string _reference, uint _senderId) internal returns(uint) {
         
        if (_fromId == _toId) {
            return _error(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }
         
        if (_value == 0) {
            return _error(CHRONOBANK_PLATFORM_INVALID_VALUE);
        }
         
        if (_balanceOf(_fromId, _symbol) < _value) {
            return _error(CHRONOBANK_PLATFORM_INSUFFICIENT_BALANCE);
        }
         
        if (_fromId != _senderId && _allowance(_fromId, _senderId, _symbol) < _value) {
            return _error(CHRONOBANK_PLATFORM_NOT_ENOUGH_ALLOWANCE);
        }

        _transferDirect(_fromId, _toId, _value, _symbol);
         
        if (_fromId != _senderId) {
            assets[_symbol].wallets[_fromId].allowance[_senderId] = assets[_symbol].wallets[_fromId].allowance[_senderId].sub(_value);
        }
         
         
         
        ChronoBankPlatformEmitter(eventsHistory).emitTransfer(_address(_fromId), _address(_toId), _symbol, _value, _reference);
        _proxyTransferEvent(_fromId, _toId, _value, _symbol);
        return OK;
    }

     
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) onlyProxy(_symbol) returns(uint) {
        return _transfer(getHolderId(_sender), _createHolderId(_to), _value, _symbol, _reference, getHolderId(_sender));
    }

     
    function _proxyTransferEvent(uint _fromId, uint _toId, uint _value, bytes32 _symbol) internal {
        if (proxies[_symbol] != 0x0) {
             
             
             
            ProxyEventsEmitter(proxies[_symbol]).emitTransfer(_address(_fromId), _address(_toId), _value);
        }
    }

     
    function getHolderId(address _holder) constant returns(uint) {
        return holderIndex[_holder];
    }

     
    function _createHolderId(address _holder) internal returns(uint) {
        uint holderId = holderIndex[_holder];
        if (holderId == 0) {
            holderId = ++holdersCount;
            holders[holderId].addr = _holder;
            holderIndex[_holder] = holderId;
        }
        return holderId;
    }

     
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) public returns(uint) {
        return issueAsset(_symbol, _value, _name, _description, _baseUnit, _isReissuable, msg.sender);
    }

     
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable, address _account) onlyOneOfContractOwners public returns(uint) {
         
        if (_value == 0 && !_isReissuable) {
            return _error(CHRONOBANK_PLATFORM_CANNOT_ISSUE_FIXED_ASSET_WITH_INVALID_VALUE);
        }
         
        if (isCreated(_symbol)) {
            return _error(CHRONOBANK_PLATFORM_ASSET_ALREADY_ISSUED);
        }
        uint holderId = _createHolderId(_account);
        uint creatorId = _account == msg.sender ? holderId : _createHolderId(msg.sender);

        symbols.push(_symbol);
        assets[_symbol] = Asset(creatorId, _value, _name, _description, _isReissuable, _baseUnit);
        assets[_symbol].wallets[holderId].balance = _value;
         
         
         
        _delegateAssetOwnerAdded(_symbol, _address(creatorId));
        ChronoBankPlatformEmitter(eventsHistory).emitIssue(_symbol, _value, _address(holderId));
        return OK;
    }

     
    function reissueAsset(bytes32 _symbol, uint _value) onlyOneOfOwners(_symbol) public returns(uint) {
         
        if (_value == 0) {
            return _error(CHRONOBANK_PLATFORM_INVALID_VALUE);
        }
        Asset storage asset = assets[_symbol];
         
        if (!asset.isReissuable) {
            return _error(CHRONOBANK_PLATFORM_CANNOT_REISSUE_FIXED_ASSET);
        }
         
        if (asset.totalSupply + _value < asset.totalSupply) {
            return _error(CHRONOBANK_PLATFORM_SUPPLY_OVERFLOW);
        }
        uint holderId = getHolderId(msg.sender);
        asset.wallets[holderId].balance = asset.wallets[holderId].balance.add(_value);
        asset.totalSupply = asset.totalSupply.add(_value);
         
         
         
        ChronoBankPlatformEmitter(eventsHistory).emitIssue(_symbol, _value, _address(holderId));
        _proxyTransferEvent(0, holderId, _value, _symbol);
        return OK;
    }

     
    function revokeAsset(bytes32 _symbol, uint _value) public returns(uint) {
         
        if (_value == 0) {
            return _error(CHRONOBANK_PLATFORM_INVALID_VALUE);
        }
        Asset storage asset = assets[_symbol];
        uint holderId = getHolderId(msg.sender);
         
        if (asset.wallets[holderId].balance < _value) {
            return _error(CHRONOBANK_PLATFORM_NOT_ENOUGH_TOKENS);
        }
        asset.wallets[holderId].balance = asset.wallets[holderId].balance.sub(_value);
        asset.totalSupply = asset.totalSupply.sub(_value);
         
         
         
        ChronoBankPlatformEmitter(eventsHistory).emitRevoke(_symbol, _value, _address(holderId));
        _proxyTransferEvent(holderId, 0, _value, _symbol);
        return OK;
    }

     
    function changeOwnership(bytes32 _symbol, address _newOwner) onlyOwner(_symbol) public returns(uint) {
        if (_newOwner == 0x0) {
            return _error(CHRONOBANK_PLATFORM_INVALID_NEW_OWNER);
        }

        Asset storage asset = assets[_symbol];
        uint newOwnerId = _createHolderId(_newOwner);
         
        if (asset.owner == newOwnerId) {
            return _error(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }
        address oldOwner = _address(asset.owner);
        asset.owner = newOwnerId;
         
         
         
        _delegateAssetOwnerRemoved(_symbol, oldOwner);
        _delegateAssetOwnerAdded(_symbol, _newOwner);
        ChronoBankPlatformEmitter(eventsHistory).emitOwnershipChange(oldOwner, _newOwner, _symbol);
        return OK;
    }

     
    function isTrusted(address _from, address _to) constant returns(bool) {
        return holders[getHolderId(_from)].trust[_to];
    }

     
    function trust(address _to) returns(uint) {
        uint fromId = _createHolderId(msg.sender);
         
        if (fromId == getHolderId(_to)) {
            return _error(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }
         
        if (isTrusted(msg.sender, _to)) {
            return _error(CHRONOBANK_PLATFORM_ALREADY_TRUSTED);
        }

        holders[fromId].trust[_to] = true;
        return OK;
    }

     
    function distrust(address _to) checkTrust(msg.sender, _to) public returns (uint) {
        holders[getHolderId(msg.sender)].trust[_to] = false;
        return OK;
    }

     
    function recover(address _from, address _to) checkTrust(_from, msg.sender) public returns (uint errorCode) {
         
        if (getHolderId(_to) != 0) {
            return _error(CHRONOBANK_PLATFORM_SHOULD_RECOVER_TO_NEW_ADDRESS);
        }
         
         
        address from = holders[getHolderId(_from)].addr;
        holders[getHolderId(_from)].addr = _to;
        holderIndex[_to] = getHolderId(_from);
         
         
         
        ChronoBankPlatformEmitter(eventsHistory).emitRecovery(from, _to, msg.sender);
        return OK;
    }

     
    function _approve(uint _spenderId, uint _value, bytes32 _symbol, uint _senderId) internal returns(uint) {
         
        if (!isCreated(_symbol)) {
            return _error(CHRONOBANK_PLATFORM_ASSET_IS_NOT_ISSUED);
        }
         
        if (_senderId == _spenderId) {
            return _error(CHRONOBANK_PLATFORM_CANNOT_APPLY_TO_ONESELF);
        }

         
        if (assets[_symbol].wallets[_senderId].allowance[_spenderId] != 0 && _value != 0) {
            return _error(CHRONOBANK_PLATFORM_INVALID_INVOCATION);
        }

        assets[_symbol].wallets[_senderId].allowance[_spenderId] = _value;

         
         
         
        ChronoBankPlatformEmitter(eventsHistory).emitApprove(_address(_senderId), _address(_spenderId), _symbol, _value);
        if (proxies[_symbol] != 0x0) {
             
             
             
            ProxyEventsEmitter(proxies[_symbol]).emitApprove(_address(_senderId), _address(_spenderId), _value);
        }
        return OK;
    }

     
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) onlyProxy(_symbol) public returns (uint) {
        return _approve(_createHolderId(_spender), _value, _symbol, _createHolderId(_sender));
    }

     
    function allowance(address _from, address _spender, bytes32 _symbol) constant returns(uint) {
        return _allowance(getHolderId(_from), getHolderId(_spender), _symbol);
    }

     
    function _allowance(uint _fromId, uint _toId, bytes32 _symbol) constant internal returns(uint) {
        return assets[_symbol].wallets[_fromId].allowance[_toId];
    }

     
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) onlyProxy(_symbol) public returns (uint) {
        return _transfer(getHolderId(_from), _createHolderId(_to), _value, _symbol, _reference, getHolderId(_sender));
    }

     
    function _delegateAssetOwnerAdded(bytes32 _symbol, address _owner) private {
        if (owningListener != 0x0) {
            AssetOwningListener(owningListener).assetOwnerAdded(_symbol, this, _owner);
        }
    }

     
    function _delegateAssetOwnerRemoved(bytes32 _symbol, address _owner) private {
        if (owningListener != 0x0) {
            AssetOwningListener(owningListener).assetOwnerRemoved(_symbol, this, _owner);
        }
    }
}