 

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

     
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

     
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

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
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}


 
contract MultiEventsHistoryAdapter {

     
    function _self() constant internal returns (address) {
        return msg.sender;
    }
}

 

contract BMCPlatformEmitter is MultiEventsHistoryAdapter {
    event Transfer(address indexed from, address indexed to, bytes32 indexed symbol, uint value, string reference);
    event Issue(bytes32 indexed symbol, uint value, address by);
    event Revoke(bytes32 indexed symbol, uint value, address by);
    event OwnershipChange(address indexed from, address indexed to, bytes32 indexed symbol);
    event Approve(address indexed from, address indexed spender, bytes32 indexed symbol, uint value);
    event Recovery(address indexed from, address indexed to, address by);
    event Error(bytes32 message);

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

    function emitError(bytes32 _message) {
        Error(_message);
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

contract Proxy {
    function emitTransfer(address _from, address _to, uint _value);
    function emitApprove(address _from, address _spender, uint _value);
}

 
contract BMCPlatform is Object, BMCPlatformEmitter {

    using SafeMath for uint;

    uint constant BMC_PLATFORM_SCOPE = 15000;
    uint constant BMC_PLATFORM_PROXY_ALREADY_EXISTS = BMC_PLATFORM_SCOPE + 0;
    uint constant BMC_PLATFORM_CANNOT_APPLY_TO_ONESELF = BMC_PLATFORM_SCOPE + 1;
    uint constant BMC_PLATFORM_INVALID_VALUE = BMC_PLATFORM_SCOPE + 2;
    uint constant BMC_PLATFORM_INSUFFICIENT_BALANCE = BMC_PLATFORM_SCOPE + 3;
    uint constant BMC_PLATFORM_NOT_ENOUGH_ALLOWANCE = BMC_PLATFORM_SCOPE + 4;
    uint constant BMC_PLATFORM_ASSET_ALREADY_ISSUED = BMC_PLATFORM_SCOPE + 5;
    uint constant BMC_PLATFORM_CANNOT_ISSUE_FIXED_ASSET_WITH_INVALID_VALUE = BMC_PLATFORM_SCOPE + 6;
    uint constant BMC_PLATFORM_CANNOT_REISSUE_FIXED_ASSET = BMC_PLATFORM_SCOPE + 7;
    uint constant BMC_PLATFORM_SUPPLY_OVERFLOW = BMC_PLATFORM_SCOPE + 8;
    uint constant BMC_PLATFORM_NOT_ENOUGH_TOKENS = BMC_PLATFORM_SCOPE + 9;
    uint constant BMC_PLATFORM_INVALID_NEW_OWNER = BMC_PLATFORM_SCOPE + 10;
    uint constant BMC_PLATFORM_ALREADY_TRUSTED = BMC_PLATFORM_SCOPE + 11;
    uint constant BMC_PLATFORM_SHOULD_RECOVER_TO_NEW_ADDRESS = BMC_PLATFORM_SCOPE + 12;
    uint constant BMC_PLATFORM_ASSET_IS_NOT_ISSUED = BMC_PLATFORM_SCOPE + 13;
    uint constant BMC_PLATFORM_ACCESS_DENIED_ONLY_OWNER = BMC_PLATFORM_SCOPE + 14;
    uint constant BMC_PLATFORM_ACCESS_DENIED_ONLY_PROXY = BMC_PLATFORM_SCOPE + 15;
    uint constant BMC_PLATFORM_ACCESS_DENIED_ONLY_TRUSTED = BMC_PLATFORM_SCOPE + 16;
    uint constant BMC_PLATFORM_INVALID_INVOCATION = BMC_PLATFORM_SCOPE + 17;
    uint constant BMC_PLATFORM_HOLDER_EXISTS = BMC_PLATFORM_SCOPE + 18;

     
    struct Asset {
        uint owner;                        
        uint totalSupply;                  
        string name;                       
        string description;                
        bool isReissuable;                 
        uint8 baseUnit;                    
        mapping(uint => Wallet) wallets;   
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

     
    mapping(bytes32 => Asset) public assets;

     
    mapping(bytes32 => address) public proxies;

     
    address public eventsHistory;

     
    function _error(uint _errorCode, bytes32 _message) internal returns(uint) {
        BMCPlatformEmitter(eventsHistory).emitError(_message);
        return _errorCode;
    }

     
    function setupEventsHistory(address _eventsHistory) returns(uint errorCode) {
        errorCode = checkOnlyContractOwner();
        if (errorCode != OK) {
            return errorCode;
        }
        if (eventsHistory != 0x0 && eventsHistory != _eventsHistory) {
            return BMC_PLATFORM_INVALID_INVOCATION;
        }
        eventsHistory = _eventsHistory;
        return OK;
    }

     
    modifier onlyOwner(bytes32 _symbol) {
        if (checkIsOnlyOwner(_symbol) == OK) {
            _;
        }
    }

     
    modifier onlyProxy(bytes32 _symbol) {
        if (checkIsOnlyProxy(_symbol) == OK) {
            _;
        }
    }

     
    modifier checkTrust(address _from, address _to) {
        if (shouldBeTrusted(_from, _to) == OK) {
            _;
        }
    }

    function checkIsOnlyOwner(bytes32 _symbol) internal constant returns(uint errorCode) {
        if (isOwner(msg.sender, _symbol)) {
            return OK;
        }
        return _error(BMC_PLATFORM_ACCESS_DENIED_ONLY_OWNER, "Only owner: access denied");
    }

    function checkIsOnlyProxy(bytes32 _symbol) internal constant returns(uint errorCode) {
        if (proxies[_symbol] == msg.sender) {
            return OK;
        }
        return _error(BMC_PLATFORM_ACCESS_DENIED_ONLY_PROXY, "Only proxy: access denied");
    }

    function shouldBeTrusted(address _from, address _to) internal constant returns(uint errorCode) {
        if (isTrusted(_from, _to)) {
            return OK;
        }
        return _error(BMC_PLATFORM_ACCESS_DENIED_ONLY_TRUSTED, "Only trusted: access denied");
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

     
    function setProxy(address _address, bytes32 _symbol) returns(uint errorCode) {
        errorCode = checkOnlyContractOwner();
        if (errorCode != OK) {
            return errorCode;
        }

        if (proxies[_symbol] != 0x0) {
            return BMC_PLATFORM_PROXY_ALREADY_EXISTS;
        }
        proxies[_symbol] = _address;
        return OK;
    }

    function massTransfer(address[] addresses, uint[] values, bytes32 _symbol) external
    returns (uint errorCode, uint count)
    {
        require(checkIsOnlyOwner(_symbol) == OK);
        require(addresses.length == values.length);
        require(_symbol != 0x0);

         

        uint senderId = _createHolderId(msg.sender);

        uint success = 0;
        for(uint idx = 0; idx < addresses.length && msg.gas > 110000; idx++) {
            uint value = values[idx];

            if (value == 0) {
                _error(BMC_PLATFORM_INVALID_VALUE, "Cannot send 0 value");
                continue;
            }

            if (getHolderId(addresses[idx]) > 0) {
                _error(BMC_PLATFORM_HOLDER_EXISTS, "Already transfered");
                continue;
            }

            if (_balanceOf(senderId, _symbol) < value) {
                _error(BMC_PLATFORM_INSUFFICIENT_BALANCE, "Insufficient balance");
                continue;
            }

            if (msg.sender == addresses[idx]) {
                _error(BMC_PLATFORM_CANNOT_APPLY_TO_ONESELF, "Cannot send to oneself");
                continue;
            }

            uint holderId = _createHolderId(addresses[idx]);

            _transferDirect(senderId, holderId, value, _symbol);
            BMCPlatformEmitter(eventsHistory).emitTransfer(msg.sender, addresses[idx], _symbol, value, "");
            
            success++;
        }

        return (OK, success);
    }

     
    function _transferDirect(uint _fromId, uint _toId, uint _value, bytes32 _symbol) internal {
        assets[_symbol].wallets[_fromId].balance = assets[_symbol].wallets[_fromId].balance.sub(_value);
        assets[_symbol].wallets[_toId].balance = assets[_symbol].wallets[_toId].balance.add(_value);
    }

     
    function _transfer(uint _fromId, uint _toId, uint _value, bytes32 _symbol, string _reference, uint _senderId) internal returns(uint) {
         
        if (_fromId == _toId) {
            return _error(BMC_PLATFORM_CANNOT_APPLY_TO_ONESELF, "Cannot send to oneself");
        }
         
        if (_value == 0) {
            return _error(BMC_PLATFORM_INVALID_VALUE, "Cannot send 0 value");
        }
         
        if (_balanceOf(_fromId, _symbol) < _value) {
            return _error(BMC_PLATFORM_INSUFFICIENT_BALANCE, "Insufficient balance");
        }
         
        if (_fromId != _senderId && _allowance(_fromId, _senderId, _symbol) < _value) {
            return _error(BMC_PLATFORM_NOT_ENOUGH_ALLOWANCE, "Not enough allowance");
        }

        _transferDirect(_fromId, _toId, _value, _symbol);
         
        if (_fromId != _senderId) {
            uint senderAllowance = assets[_symbol].wallets[_fromId].allowance[_senderId];
            assets[_symbol].wallets[_fromId].allowance[_senderId] = senderAllowance.sub(_value);
        }
         
         
         
        BMCPlatformEmitter(eventsHistory).emitTransfer(_address(_fromId), _address(_toId), _symbol, _value, _reference);
        _proxyTransferEvent(_fromId, _toId, _value, _symbol);
        return OK;
    }

     
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) returns(uint errorCode) {
        errorCode = checkIsOnlyProxy(_symbol);
        if (errorCode != OK) {
            return errorCode;
        }

        return _transfer(getHolderId(_sender), _createHolderId(_to), _value, _symbol, _reference, getHolderId(_sender));
    }

     
    function _proxyTransferEvent(uint _fromId, uint _toId, uint _value, bytes32 _symbol) internal {
        if (proxies[_symbol] != 0x0) {
             
             
             
            Proxy(proxies[_symbol]).emitTransfer(_address(_fromId), _address(_toId), _value);
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

     
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) returns(uint errorCode) {
        errorCode = checkOnlyContractOwner();
        if (errorCode != OK) {
            return errorCode;
        }
         
        if (_value == 0 && !_isReissuable) {
            return _error(BMC_PLATFORM_CANNOT_ISSUE_FIXED_ASSET_WITH_INVALID_VALUE, "Cannot issue 0 value fixed asset");
        }
         
        if (isCreated(_symbol)) {
            return _error(BMC_PLATFORM_ASSET_ALREADY_ISSUED, "Asset already issued");
        }
        uint holderId = _createHolderId(msg.sender);

        assets[_symbol] = Asset(holderId, _value, _name, _description, _isReissuable, _baseUnit);
        assets[_symbol].wallets[holderId].balance = _value;
         
         
         
        BMCPlatformEmitter(eventsHistory).emitIssue(_symbol, _value, _address(holderId));
        return OK;
    }

     
    function reissueAsset(bytes32 _symbol, uint _value) returns(uint errorCode) {
        errorCode = checkIsOnlyOwner(_symbol);
        if (errorCode != OK) {
            return errorCode;
        }
         
        if (_value == 0) {
            return _error(BMC_PLATFORM_INVALID_VALUE, "Cannot reissue 0 value");
        }
        Asset asset = assets[_symbol];
         
        if (!asset.isReissuable) {
            return _error(BMC_PLATFORM_CANNOT_REISSUE_FIXED_ASSET, "Cannot reissue fixed asset");
        }
         
        if (asset.totalSupply + _value < asset.totalSupply) {
            return _error(BMC_PLATFORM_SUPPLY_OVERFLOW, "Total supply overflow");
        }
        uint holderId = getHolderId(msg.sender);
        asset.wallets[holderId].balance = asset.wallets[holderId].balance.add(_value);
        asset.totalSupply = asset.totalSupply.add(_value);
         
         
         
        BMCPlatformEmitter(eventsHistory).emitIssue(_symbol, _value, _address(holderId));
        _proxyTransferEvent(0, holderId, _value, _symbol);
        return OK;
    }

     
    function revokeAsset(bytes32 _symbol, uint _value) returns(uint) {
         
        if (_value == 0) {
            return _error(BMC_PLATFORM_INVALID_VALUE, "Cannot revoke 0 value");
        }
        Asset asset = assets[_symbol];
        uint holderId = getHolderId(msg.sender);
         
        if (asset.wallets[holderId].balance < _value) {
            return _error(BMC_PLATFORM_NOT_ENOUGH_TOKENS, "Not enough tokens to revoke");
        }
        asset.wallets[holderId].balance = asset.wallets[holderId].balance.sub(_value);
        asset.totalSupply = asset.totalSupply.sub(_value);
         
         
         
        BMCPlatformEmitter(eventsHistory).emitRevoke(_symbol, _value, _address(holderId));
        _proxyTransferEvent(holderId, 0, _value, _symbol);
        return OK;
    }

     
    function changeOwnership(bytes32 _symbol, address _newOwner) returns(uint errorCode) {
        errorCode = checkIsOnlyOwner(_symbol);
        if (errorCode != OK) {
            return errorCode;
        }

        if (_newOwner == 0x0) {
            return _error(BMC_PLATFORM_INVALID_NEW_OWNER, "Can't change ownership to 0x0");
        }

        Asset asset = assets[_symbol];
        uint newOwnerId = _createHolderId(_newOwner);
         
        if (asset.owner == newOwnerId) {
            return _error(BMC_PLATFORM_CANNOT_APPLY_TO_ONESELF, "Cannot pass ownership to oneself");
        }
        address oldOwner = _address(asset.owner);
        asset.owner = newOwnerId;
         
         
         
        BMCPlatformEmitter(eventsHistory).emitOwnershipChange(oldOwner, _address(newOwnerId), _symbol);
        return OK;
    }

     
    function isTrusted(address _from, address _to) constant returns(bool) {
        return holders[getHolderId(_from)].trust[_to];
    }

     
    function trust(address _to) returns(uint) {
        uint fromId = _createHolderId(msg.sender);
         
        if (fromId == getHolderId(_to)) {
            return _error(BMC_PLATFORM_CANNOT_APPLY_TO_ONESELF, "Cannot trust to oneself");
        }
         
        if (isTrusted(msg.sender, _to)) {
            return _error(BMC_PLATFORM_ALREADY_TRUSTED, "Already trusted");
        }

        holders[fromId].trust[_to] = true;
        return OK;
    }

     
    function distrust(address _to) returns(uint errorCode) {
        errorCode = shouldBeTrusted(msg.sender, _to);
        if (errorCode != OK) {
            return errorCode;
        }
        holders[getHolderId(msg.sender)].trust[_to] = false;
        return OK;
    }

     
    function recover(address _from, address _to) returns(uint errorCode) {
        errorCode = shouldBeTrusted(_from, msg.sender);
        if (errorCode != OK) {
            return errorCode;
        }
         
        if (getHolderId(_to) != 0) {
            return _error(BMC_PLATFORM_SHOULD_RECOVER_TO_NEW_ADDRESS, "Should recover to new address");
        }
         
         
        address from = holders[getHolderId(_from)].addr;
        holders[getHolderId(_from)].addr = _to;
        holderIndex[_to] = getHolderId(_from);
         
         
         
        BMCPlatformEmitter(eventsHistory).emitRecovery(from, _to, msg.sender);
        return OK;
    }

     
    function _approve(uint _spenderId, uint _value, bytes32 _symbol, uint _senderId) internal returns(uint) {
         
        if (!isCreated(_symbol)) {
            return _error(BMC_PLATFORM_ASSET_IS_NOT_ISSUED, "Asset is not issued");
        }
         
        if (_senderId == _spenderId) {
            return _error(BMC_PLATFORM_CANNOT_APPLY_TO_ONESELF, "Cannot approve to oneself");
        }
        assets[_symbol].wallets[_senderId].allowance[_spenderId] = _value;
         
         
         
        BMCPlatformEmitter(eventsHistory).emitApprove(_address(_senderId), _address(_spenderId), _symbol, _value);
        if (proxies[_symbol] != 0x0) {
             
             
             
            Proxy(proxies[_symbol]).emitApprove(_address(_senderId), _address(_spenderId), _value);
        }
        return OK;
    }

     
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) returns(uint errorCode) {
        errorCode = checkIsOnlyProxy(_symbol);
        if (errorCode != OK) {
            return errorCode;
        }
        return _approve(_createHolderId(_spender), _value, _symbol, _createHolderId(_sender));
    }

     
    function allowance(address _from, address _spender, bytes32 _symbol) constant returns(uint) {
        return _allowance(getHolderId(_from), getHolderId(_spender), _symbol);
    }

     
    function _allowance(uint _fromId, uint _toId, bytes32 _symbol) constant internal returns(uint) {
        return assets[_symbol].wallets[_fromId].allowance[_toId];
    }

     
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) returns(uint errorCode) {
        errorCode = checkIsOnlyProxy(_symbol);
        if (errorCode != OK) {
            return errorCode;
        }
        return _transfer(getHolderId(_from), _createHolderId(_to), _value, _symbol, _reference, getHolderId(_sender));
    }
}