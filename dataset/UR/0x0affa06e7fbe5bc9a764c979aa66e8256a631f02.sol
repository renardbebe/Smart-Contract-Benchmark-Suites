 

 

pragma solidity 0.4.8;

contract EToken2 {
    function baseUnit(bytes32 _symbol) constant returns(uint8);
    function name(bytes32 _symbol) constant returns(string);
    function description(bytes32 _symbol) constant returns(string);
    function owner(bytes32 _symbol) constant returns(address);
    function isOwner(address _owner, bytes32 _symbol) constant returns(bool);
    function totalSupply(bytes32 _symbol) constant returns(uint);
    function balanceOf(address _holder, bytes32 _symbol) constant returns(uint);
    function proxyTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) returns(bool);
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) returns(bool);
    function allowance(address _from, address _spender, bytes32 _symbol) constant returns(uint);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) returns(bool);
}

contract Asset {
    function _performTransferWithReference(address _to, uint _value, string _reference, address _sender) returns(bool);
    function _performTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) returns(bool);
    function _performApprove(address _spender, uint _value, address _sender) returns(bool);    
    function _performTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function _performTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) returns(bool);
    function _performGeneric(bytes _data, address _sender) payable returns(bytes32) {
        throw;
    }
}

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() constant returns(uint256 supply);
    function balanceOf(address _owner) constant returns(uint256 balance);
    function transfer(address _to, uint256 _value) returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns(bool success);
    function approve(address _spender, uint256 _value) returns(bool success);
    function allowance(address _owner, address _spender) constant returns(uint256 remaining);
    function decimals() constant returns(uint8);
}

contract AssetProxyInterface {
    function _forwardApprove(address _spender, uint _value, address _sender) returns(bool);    
    function _forwardTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function _forwardTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) returns(bool);
}

contract Bytes32 {
    function _bytes32(string _input) internal constant returns(bytes32 result) {
        assembly {
            result := mload(add(_input, 32))
        }
    }
}

 
contract PolybiusToken is ERC20, AssetProxyInterface, Bytes32 {
     
    EToken2 public etoken2;

     
    bytes32 public etoken2Symbol;

     
    string public name;
    string public symbol;

     
    function init(EToken2 _etoken2, string _symbol, string _name) returns(bool) {
        if (address(etoken2) != 0x0) {
            return false;
        }
        etoken2 = _etoken2;
        etoken2Symbol = _bytes32(_symbol);
        name = _name;
        symbol = _symbol;
        return true;
    }

     
    modifier onlyEToken2() {
        if (msg.sender == address(etoken2)) {
            _;
        }
    }

     
    modifier onlyAssetOwner() {
        if (etoken2.isOwner(msg.sender, etoken2Symbol)) {
            _;
        }
    }

     
    function _getAsset() internal returns(Asset) {
        return Asset(getVersionFor(msg.sender));
    }

    function recoverTokens(uint _value) onlyAssetOwner() returns(bool) {
        return this.transferWithReference(msg.sender, _value, 'Tokens recovery');
    }

     
    function totalSupply() constant returns(uint) {
        return etoken2.totalSupply(etoken2Symbol);
    }

     
    function balanceOf(address _owner) constant returns(uint) {
        return etoken2.balanceOf(_owner, etoken2Symbol);
    }

     
    function allowance(address _from, address _spender) constant returns(uint) {
        return etoken2.allowance(_from, _spender, etoken2Symbol);
    }

     
    function decimals() constant returns(uint8) {
        return etoken2.baseUnit(etoken2Symbol);
    }

     
    function transfer(address _to, uint _value) returns(bool) {
        return transferWithReference(_to, _value, '');
    }

     
    function transferWithReference(address _to, uint _value, string _reference) returns(bool) {
        return _getAsset()._performTransferWithReference(_to, _value, _reference, msg.sender);
    }

     
    function transferToICAP(bytes32 _icap, uint _value) returns(bool) {
        return transferToICAPWithReference(_icap, _value, '');
    }

     
    function transferToICAPWithReference(bytes32 _icap, uint _value, string _reference) returns(bool) {
        return _getAsset()._performTransferToICAPWithReference(_icap, _value, _reference, msg.sender);
    }

     
    function transferFrom(address _from, address _to, uint _value) returns(bool) {
        return transferFromWithReference(_from, _to, _value, '');
    }

     
    function transferFromWithReference(address _from, address _to, uint _value, string _reference) returns(bool) {
        return _getAsset()._performTransferFromWithReference(_from, _to, _value, _reference, msg.sender);
    }

     
    function _forwardTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) onlyImplementationFor(_sender) returns(bool) {
        return etoken2.proxyTransferFromWithReference(_from, _to, _value, etoken2Symbol, _reference, _sender);
    }

     
    function transferFromToICAP(address _from, bytes32 _icap, uint _value) returns(bool) {
        return transferFromToICAPWithReference(_from, _icap, _value, '');
    }

     
    function transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference) returns(bool) {
        return _getAsset()._performTransferFromToICAPWithReference(_from, _icap, _value, _reference, msg.sender);
    }

     
    function _forwardTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) onlyImplementationFor(_sender) returns(bool) {
        return etoken2.proxyTransferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }

     
    function approve(address _spender, uint _value) returns(bool) {
        return _getAsset()._performApprove(_spender, _value, msg.sender);
    }

     
    function _forwardApprove(address _spender, uint _value, address _sender) onlyImplementationFor(_sender) returns(bool) {
        return etoken2.proxyApprove(_spender, _value, etoken2Symbol, _sender);
    }

     
    function emitTransfer(address _from, address _to, uint _value) onlyEToken2() {
        Transfer(_from, _to, _value);
    }

     
    function emitApprove(address _from, address _spender, uint _value) onlyEToken2() {
        Approval(_from, _spender, _value);
    }

     
    function () payable {
        bytes32 result = _getAsset()._performGeneric.value(msg.value)(msg.data, msg.sender);
        assembly {
            mstore(0, result)
            return(0, 32)
        }
    }

     
    event UpgradeProposal(address newVersion);

     
    address latestVersion;

     
    address pendingVersion;

     
    uint pendingVersionTimestamp;

     
    uint constant UPGRADE_FREEZE_TIME = 3 days;

     
     
    mapping(address => address) userOptOutVersion;

     
    modifier onlyImplementationFor(address _sender) {
        if (getVersionFor(_sender) == msg.sender) {
            _;
        }
    }

     
    function getVersionFor(address _sender) constant returns(address) {
        return userOptOutVersion[_sender] == 0 ? latestVersion : userOptOutVersion[_sender];
    }

     
    function getLatestVersion() constant returns(address) {
        return latestVersion;
    }

     
    function getPendingVersion() constant returns(address) {
        return pendingVersion;
    }

     
    function getPendingVersionTimestamp() constant returns(uint) {
        return pendingVersionTimestamp;
    }

     
    function proposeUpgrade(address _newVersion) onlyAssetOwner() returns(bool) {
         
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
        UpgradeProposal(_newVersion);
        return true;
    }

     
    function purgeUpgrade() onlyAssetOwner() returns(bool) {
        if (pendingVersion == 0x0) {
            return false;
        }
        delete pendingVersion;
        delete pendingVersionTimestamp;
        return true;
    }

     
    function commitUpgrade() returns(bool) {
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

     
    function optOut() returns(bool) {
        if (userOptOutVersion[msg.sender] != 0x0) {
            return false;
        }
        userOptOutVersion[msg.sender] = latestVersion;
        return true;
    }

     
    function optIn() returns(bool) {
        delete userOptOutVersion[msg.sender];
        return true;
    }

     
    function multiAsset() constant returns(EToken2) {
        return etoken2;
    }
}