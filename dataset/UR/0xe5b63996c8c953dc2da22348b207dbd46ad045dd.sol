 

pragma solidity 0.4.15;

contract AssetInterface {
    function _performTransferWithReference(address _to, uint _value, string _reference, address _sender) returns(bool);
    function _performTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) returns(bool);
    function _performApprove(address _spender, uint _value, address _sender) returns(bool);    
    function _performTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function _performTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) returns(bool);
    function _performGeneric(bytes, address) payable returns(bytes32) {
        revert();
    }
}

contract AssetProxy {
    function _forwardApprove(address _spender, uint _value, address _sender) returns(bool);
    function _forwardTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function _forwardTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) returns(bool);
    function balanceOf(address _owner) constant returns(uint);
}

 
contract Asset is AssetInterface {
     
    AssetProxy public proxy;

     
    modifier onlyProxy() {
        if (proxy == msg.sender) {
            _;
        }
    }

     
    function init(AssetProxy _proxy) returns(bool) {
        if (address(proxy) != 0x0) {
            return false;
        }
        proxy = _proxy;
        return true;
    }

     
    function _performTransferWithReference(address _to, uint _value, string _reference, address _sender) onlyProxy() returns(bool) {
        return _transferWithReference(_to, _value, _reference, _sender);
    }

     
    function _transferWithReference(address _to, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromWithReference(_sender, _to, _value, _reference, _sender);
    }

     
    function _performTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) onlyProxy() returns(bool) {
        return _transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

     
    function _transferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(_sender, _icap, _value, _reference, _sender);
    }

     
    function _performTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) onlyProxy() returns(bool) {
        return _transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

     
    function _transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromWithReference(_from, _to, _value, _reference, _sender);
    }

     
    function _performTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) onlyProxy() returns(bool) {
        return _transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }

     
    function _transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }

     
    function _performApprove(address _spender, uint _value, address _sender) onlyProxy() returns(bool) {
        return _approve(_spender, _value, _sender);
    }

     
    function _approve(address _spender, uint _value, address _sender) internal returns(bool) {
        return proxy._forwardApprove(_spender, _value, _sender);
    }

     
    function _performGeneric(bytes _data, address _sender) payable onlyProxy() returns(bytes32) {
        return _generic(_data, _sender);
    }

    modifier onlyMe() {
        if (this == msg.sender) {
            _;
        }
    }

     
    address genericSender;
    function _generic(bytes _data, address _sender) internal returns(bytes32) {
         
        if (genericSender != 0x0) {
            revert();
        }
        genericSender = _sender;
        bytes32 result = _callReturn(this, _data, msg.value);
        delete genericSender;
        return result;
    }

    function _callReturn(address _target, bytes _data, uint _value) internal returns(bytes32 result) {
        bool success;
        assembly {
            success := call(div(mul(gas, 63), 64), _target, _value, add(_data, 32), mload(_data), 0, 32)
            result := mload(0)
        }
        if (!success) {
            revert();
        }
    }

     
    function _sender() constant internal returns(address) {
        return this == msg.sender ? genericSender : msg.sender;
    }
}

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

contract AssetWithAmbi is Asset, Ambi2EnabledFull {
    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != 0x0 && (ambi2.hasRole(this, _role, _sender()))) {
            _;
        }
    }
}

 

contract AssetWithWingsIntegration is AssetWithAmbi {
     
    uint public totalCollected;

    event Error(bytes32 error);
    event TotalCollected(uint total);

     
    function setTotalCollected(uint _totalCollected) onlyRole('admin') returns(bool) {
        if (totalCollected != 0) {
            Error('Total collected already set');
            return false;
        }

        totalCollected = _totalCollected;
        TotalCollected(totalCollected);
        return true;
    }
}