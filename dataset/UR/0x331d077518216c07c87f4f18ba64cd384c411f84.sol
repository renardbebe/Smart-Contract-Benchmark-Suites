 

 
 
 

pragma solidity 0.4.8;

contract Ambi2 {
    function claimFor(address _address, address _owner) returns(bool);
    function hasRole(address _from, bytes32 _role, address _to) constant returns(bool);
    function isOwner(address _node, address _owner) constant returns(bool);
}

contract Ambi2Enabled {
    Ambi2 ambi2;

    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != 0x0 && ambi2.hasRole(this, _role, msg.sender)) {
            _;
        }
    }

     
    function setupAmbi2(Ambi2 _ambi2) returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract Ambi2EnabledFull is Ambi2Enabled {
     
    function setupAmbi2(Ambi2 _ambi2) returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }
        if (!_ambi2.claimFor(this, msg.sender) && !_ambi2.isOwner(this, msg.sender)) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract RegistryICAPInterface {
    function parse(bytes32 _icap) constant returns(address, bytes32, bool);
    function institutions(bytes32 _institution) constant returns(address);
}

contract Cosigner {
    function consumeOperation(bytes32 _opHash, uint _required) returns(bool);
}

contract Emitter {
    function emitTransfer(address _from, address _to, bytes32 _symbol, uint _value, string _reference);
    function emitTransferToICAP(address _from, address _to, bytes32 _icap, uint _value, string _reference);
    function emitIssue(bytes32 _symbol, uint _value, address _by);
    function emitRevoke(bytes32 _symbol, uint _value, address _by);
    function emitOwnershipChange(address _from, address _to, bytes32 _symbol);
    function emitApprove(address _from, address _spender, bytes32 _symbol, uint _value);
    function emitRecovery(address _from, address _to, address _by);
    function emitError(bytes32 _message);
    function emitChange(bytes32 _symbol);
}

contract Proxy {
    function emitTransfer(address _from, address _to, uint _value);
    function emitApprove(address _from, address _spender, uint _value);
}

 
contract EToken2 is Ambi2EnabledFull {
    mapping(bytes32 => bool) switches;

    function isEnabled(bytes32 _switch) constant returns(bool) {
        return switches[_switch];
    }

    function enableSwitch(bytes32 _switch) onlyRole('issuance') returns(bool) {
        switches[_switch] = true;
        return true;
    }

    modifier checkEnabledSwitch(bytes32 _switch) {
        if (!isEnabled(_switch)) {
            _error('Feature is disabled');
        } else {
            _;
        }
    }

    enum Features { Issue, TransferWithReference, Revoke, ChangeOwnership, Allowances, ICAP }

     
    struct Asset {
        uint owner;                        
        uint totalSupply;                  
        string name;                       
        string description;                
        bool isReissuable;                 
        uint8 baseUnit;                    
        bool isLocked;                     
        mapping(uint => Wallet) wallets;   
    }

     
    struct Wallet {
        uint balance;
        mapping(uint => uint) allowance;
    }

     
    struct Holder {
        address addr;                     
        Cosigner cosigner;                
        mapping(address => bool) trust;   
    }

     
    uint public holdersCount;
    mapping(uint => Holder) public holders;

     
    mapping(address => uint) holderIndex;

     
    mapping(bytes32 => Asset) public assets;

     
    mapping(bytes32 => address) public proxies;

     
    RegistryICAPInterface public registryICAP;

     
    Emitter public eventsHistory;

     
    function _error(bytes32 _message) internal {
        eventsHistory.emitError(_message);
    }

     
    function setupEventsHistory(Emitter _eventsHistory) onlyRole('setup') returns(bool) {
        if (address(eventsHistory) != 0) {
            return false;
        }
        eventsHistory = _eventsHistory;
        return true;
    }

     
    function setupRegistryICAP(RegistryICAPInterface _registryICAP) onlyRole('setup') returns(bool) {
        if (address(registryICAP) != 0) {
            return false;
        }
        registryICAP = _registryICAP;
        return true;
    }

     
    modifier onlyOwner(bytes32 _symbol) {
        if (_isSignedOwner(_symbol)) {
            _;
        } else {
            _error('Only owner: access denied');
        }
    }

     
    modifier onlyProxy(bytes32 _symbol) {
        if (_isProxy(_symbol)) {
            _;
        } else {
            _error('Only proxy: access denied');
        }
    }

     
    modifier checkTrust(address _from, address _to) {
        if (isTrusted(_from, _to)) {
            _;
        } else {
            _error('Only trusted: access denied');
        }
    }

    function _isSignedOwner(bytes32 _symbol) internal checkSigned(getHolderId(msg.sender), 1) returns(bool) {
        return isOwner(msg.sender, _symbol);
    }

     
    function isCreated(bytes32 _symbol) constant returns(bool) {
        return assets[_symbol].owner != 0;
    }

    function isLocked(bytes32 _symbol) constant returns(bool) {
        return assets[_symbol].isLocked;
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
        uint holderId = getHolderId(_holder);
        return holders[holderId].addr == _holder ? _balanceOf(holderId, _symbol) : 0;
    }

     
    function _balanceOf(uint _holderId, bytes32 _symbol) constant internal returns(uint) {
        return assets[_symbol].wallets[_holderId].balance;
    }

     
    function _address(uint _holderId) constant internal returns(address) {
        return holders[_holderId].addr;
    }

    function _isProxy(bytes32 _symbol) constant internal returns(bool) {
        return proxies[_symbol] == msg.sender;
    }

     
    function setProxy(address _address, bytes32 _symbol) onlyOwner(_symbol) returns(bool) {
        if (proxies[_symbol] != 0x0 && assets[_symbol].isLocked) {
            return false;
        }
        proxies[_symbol] = _address;
        return true;
    }

     
    function _transferDirect(uint _fromId, uint _toId, uint _value, bytes32 _symbol) internal {
        assets[_symbol].wallets[_fromId].balance -= _value;
        assets[_symbol].wallets[_toId].balance += _value;
    }

     
    function _transfer(uint _fromId, uint _toId, uint _value, bytes32 _symbol, string _reference, uint _senderId) internal checkSigned(_senderId, 1) returns(bool) {
         
        if (_fromId == _toId) {
            _error('Cannot send to oneself');
            return false;
        }
         
        if (_value == 0) {
            _error('Cannot send 0 value');
            return false;
        }
         
        if (_balanceOf(_fromId, _symbol) < _value) {
            _error('Insufficient balance');
            return false;
        }
         
        if (bytes(_reference).length > 0 && !isEnabled(sha3(_symbol, Features.TransferWithReference))) {
            _error('References feature is disabled');
            return false;
        }
         
        if (_fromId != _senderId && _allowance(_fromId, _senderId, _symbol) < _value) {
            _error('Not enough allowance');
            return false;
        }
         
        if (_fromId != _senderId) {
            assets[_symbol].wallets[_fromId].allowance[_senderId] -= _value;
        }
        _transferDirect(_fromId, _toId, _value, _symbol);
         
         
        eventsHistory.emitTransfer(_address(_fromId), _address(_toId), _symbol, _value, _reference);
        _proxyTransferEvent(_fromId, _toId, _value, _symbol);
        return true;
    }

     
    function _transferToICAP(uint _fromId, bytes32 _icap, uint _value, string _reference, uint _senderId) internal returns(bool) {
        var (to, symbol, success) = registryICAP.parse(_icap);
        if (!success) {
            _error('ICAP is not registered');
            return false;
        }
        if (!isEnabled(sha3(symbol, Features.ICAP))) {
            _error('ICAP feature is disabled');
            return false;
        }
        if (!_isProxy(symbol)) {
            _error('Only proxy: access denied');
            return false;
        }
        uint toId = _createHolderId(to);
        if (!_transfer(_fromId, toId, _value, symbol, _reference, _senderId)) {
            return false;
        }
         
         
        eventsHistory.emitTransferToICAP(_address(_fromId), _address(toId), _icap, _value, _reference);
        return true;
    }

    function proxyTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) returns(bool) {
        return _transferToICAP(getHolderId(_from), _icap, _value, _reference, getHolderId(_sender));
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

     
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) checkEnabledSwitch(sha3(_symbol, _isReissuable, Features.Issue)) returns(bool) {
         
        if (_value == 0 && !_isReissuable) {
            _error('Cannot issue 0 value fixed asset');
            return false;
        }
         
        if (isCreated(_symbol)) {
            _error('Asset already issued');
            return false;
        }
        uint holderId = _createHolderId(msg.sender);

        assets[_symbol] = Asset(holderId, _value, _name, _description, _isReissuable, _baseUnit, false);
        assets[_symbol].wallets[holderId].balance = _value;
         
         
        eventsHistory.emitIssue(_symbol, _value, _address(holderId));
        return true;
    }

    function changeAsset(bytes32 _symbol, string _name, string _description, uint8 _baseUnit) onlyOwner(_symbol) returns(bool) {
        if (isLocked(_symbol)) {
            _error('Asset is locked');
            return false;
        }
        assets[_symbol].name = _name;
        assets[_symbol].description = _description;
        assets[_symbol].baseUnit = _baseUnit;
        eventsHistory.emitChange(_symbol);
        return true;
    }

    function lockAsset(bytes32 _symbol) onlyOwner(_symbol) returns(bool) {
        if (isLocked(_symbol)) {
            _error('Asset is locked');
            return false;
        }
        assets[_symbol].isLocked = true;
        return true;
    }

     
    function reissueAsset(bytes32 _symbol, uint _value) onlyOwner(_symbol) returns(bool) {
         
        if (_value == 0) {
            _error('Cannot reissue 0 value');
            return false;
        }
        Asset asset = assets[_symbol];
         
        if (!asset.isReissuable) {
            _error('Cannot reissue fixed asset');
            return false;
        }
         
        if (asset.totalSupply + _value < asset.totalSupply) {
            _error('Total supply overflow');
            return false;
        }
        uint holderId = getHolderId(msg.sender);
        asset.wallets[holderId].balance += _value;
        asset.totalSupply += _value;
         
         
        eventsHistory.emitIssue(_symbol, _value, _address(holderId));
        _proxyTransferEvent(0, holderId, _value, _symbol);
        return true;
    }

     
    function revokeAsset(bytes32 _symbol, uint _value) checkEnabledSwitch(sha3(_symbol, Features.Revoke)) checkSigned(getHolderId(msg.sender), 1) returns(bool) {
         
        if (_value == 0) {
            _error('Cannot revoke 0 value');
            return false;
        }
        Asset asset = assets[_symbol];
        uint holderId = getHolderId(msg.sender);
         
        if (asset.wallets[holderId].balance < _value) {
            _error('Not enough tokens to revoke');
            return false;
        }
        asset.wallets[holderId].balance -= _value;
        asset.totalSupply -= _value;
         
         
        eventsHistory.emitRevoke(_symbol, _value, _address(holderId));
        _proxyTransferEvent(holderId, 0, _value, _symbol);
        return true;
    }

     
    function changeOwnership(bytes32 _symbol, address _newOwner) checkEnabledSwitch(sha3(_symbol, Features.ChangeOwnership)) onlyOwner(_symbol) returns(bool) {
        Asset asset = assets[_symbol];
        uint newOwnerId = _createHolderId(_newOwner);
         
        if (asset.owner == newOwnerId) {
            _error('Cannot pass ownership to oneself');
            return false;
        }
        address oldOwner = _address(asset.owner);
        asset.owner = newOwnerId;
         
         
        eventsHistory.emitOwnershipChange(oldOwner, _address(newOwnerId), _symbol);
        return true;
    }

    function setCosignerAddress(Cosigner _cosigner) checkSigned(_createHolderId(msg.sender), 1) returns(bool) {
        if (!_checkSigned(_cosigner, getHolderId(msg.sender), 1)) {
            _error('Invalid cosigner');
            return false;
        }
        holders[_createHolderId(msg.sender)].cosigner = _cosigner;
        return true;
    }

    function isCosignerSet(uint _holderId) constant returns(bool) {
        return address(holders[_holderId].cosigner) != 0x0;
    }

    function _checkSigned(Cosigner _cosigner, uint _holderId, uint _required) internal returns(bool) {
        return _cosigner.consumeOperation(sha3(msg.data, _holderId), _required);
    }

    modifier checkSigned(uint _holderId, uint _required) {
        if (!isCosignerSet(_holderId) || _checkSigned(holders[_holderId].cosigner, _holderId, _required)) {
            _;
        } else {
            _error('Cosigner: access denied');
        }
    }

     
    function isTrusted(address _from, address _to) constant returns(bool) {
        return holders[getHolderId(_from)].trust[_to];
    }

     
    function trust(address _to) returns(bool) {
        uint fromId = _createHolderId(msg.sender);
         
        if (fromId == getHolderId(_to)) {
            _error('Cannot trust to oneself');
            return false;
        }
         
        if (isTrusted(msg.sender, _to)) {
            _error('Already trusted');
            return false;
        }
        holders[fromId].trust[_to] = true;
        return true;
    }

     
    function distrust(address _to) checkTrust(msg.sender, _to) returns(bool) {
        holders[getHolderId(msg.sender)].trust[_to] = false;
        return true;
    }

     
    function recover(address _from, address _to) checkTrust(_from, msg.sender) returns(bool) {
        return _grantAccess(getHolderId(_from), _to);
    }

     
    function grantAccess(address _from, address _to) returns(bool) {
        if (!isCosignerSet(getHolderId(_from))) {
            _error('Cosigner not set');
            return false;
        }
        return _grantAccess(getHolderId(_from), _to);
    }

    function _grantAccess(uint _fromId, address _to) internal checkSigned(_fromId, 2) returns(bool) {
         
        if (getHolderId(_to) != 0) {
            _error('Should recover to new address');
            return false;
        }
         
         
        address from = holders[_fromId].addr;
        holders[_fromId].addr = _to;
        holderIndex[_to] = _fromId;
         
         
        eventsHistory.emitRecovery(from, _to, msg.sender);
        return true;
    }

     
    function _approve(uint _spenderId, uint _value, bytes32 _symbol, uint _senderId) internal checkEnabledSwitch(sha3(_symbol, Features.Allowances)) checkSigned(_senderId, 1) returns(bool) {
         
        if (!isCreated(_symbol)) {
            _error('Asset is not issued');
            return false;
        }
         
        if (_senderId == _spenderId) {
            _error('Cannot approve to oneself');
            return false;
        }
        assets[_symbol].wallets[_senderId].allowance[_spenderId] = _value;
         
         
        eventsHistory.emitApprove(_address(_senderId), _address(_spenderId), _symbol, _value);
        if (proxies[_symbol] != 0x0) {
             
             
            Proxy(proxies[_symbol]).emitApprove(_address(_senderId), _address(_spenderId), _value);
        }
        return true;
    }

     
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) onlyProxy(_symbol) returns(bool) {
        return _approve(_createHolderId(_spender), _value, _symbol, _createHolderId(_sender));
    }

     
    function allowance(address _from, address _spender, bytes32 _symbol) constant returns(uint) {
        return _allowance(getHolderId(_from), getHolderId(_spender), _symbol);
    }

     
    function _allowance(uint _fromId, uint _toId, bytes32 _symbol) constant internal returns(uint) {
        return assets[_symbol].wallets[_fromId].allowance[_toId];
    }

     
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) onlyProxy(_symbol) returns(bool) {
        return _transfer(getHolderId(_from), _createHolderId(_to), _value, _symbol, _reference, getHolderId(_sender));
    }
}