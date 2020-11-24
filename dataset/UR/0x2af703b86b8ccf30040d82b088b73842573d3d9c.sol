 

pragma solidity 0.4.23;

contract AssetInterface {
    function _performTransferWithReference(address _to, uint _value, string _reference, address _sender) public returns(bool);
    function _performTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) public returns(bool);
    function _performApprove(address _spender, uint _value, address _sender) public returns(bool);
    function _performTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns(bool);
    function _performTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) public returns(bool);
    function _performGeneric(bytes, address) public payable {
        revert();
    }
}

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    function totalSupply() public view returns(uint256 supply);
    function balanceOf(address _owner) public view returns(uint256 balance);
    function transfer(address _to, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);
    function approve(address _spender, uint256 _value) public returns(bool success);
    function allowance(address _owner, address _spender) public view returns(uint256 remaining);

     
    function decimals() public view returns(uint8);
     
}

contract AssetProxy is ERC20Interface {
    function _forwardApprove(address _spender, uint _value, address _sender) public returns(bool);
    function _forwardTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns(bool);
    function _forwardTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) public returns(bool);
    function recoverTokens(ERC20Interface _asset, address _receiver, uint _value) public returns(bool);
    function etoken2() public pure returns(address) {}  
    function etoken2Symbol() public pure returns(bytes32) {}  
}

contract Bytes32 {
    function _bytes32(string _input) internal pure returns(bytes32 result) {
        assembly {
            result := mload(add(_input, 32))
        }
    }
}

contract ReturnData {
    function _returnReturnData(bool _success) internal pure {
        assembly {
            let returndatastart := 0
            returndatacopy(returndatastart, 0, returndatasize)
            switch _success case 0 { revert(returndatastart, returndatasize) } default { return(returndatastart, returndatasize) }
        }
    }

    function _assemblyCall(address _destination, uint _value, bytes _data) internal returns(bool success) {
        assembly {
            success := call(gas, _destination, _value, add(_data, 32), mload(_data), 0, 0)
        }
    }
}

 
contract Asset is AssetInterface, Bytes32, ReturnData {
     
    AssetProxy public proxy;

     
    modifier onlyProxy() {
        if (proxy == msg.sender) {
            _;
        }
    }

     
    function init(AssetProxy _proxy) public returns(bool) {
        if (address(proxy) != 0x0) {
            return false;
        }
        proxy = _proxy;
        return true;
    }

     
    function _performTransferWithReference(address _to, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferToICAPWithReference(bytes32(_to) << 96, _value, _reference, _sender);
        }
        return _transferWithReference(_to, _value, _reference, _sender);
    }

     
    function _transferWithReference(address _to, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromWithReference(_sender, _to, _value, _reference, _sender);
    }

     
    function _performTransferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        return _transferToICAPWithReference(_icap, _value, _reference, _sender);
    }

     
    function _transferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(_sender, _icap, _value, _reference, _sender);
    }

     
    function _performTransferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        if (isICAP(_to)) {
            return _transferFromToICAPWithReference(_from, bytes32(_to) << 96, _value, _reference, _sender);
        }
        return _transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

     
    function _transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromWithReference(_from, _to, _value, _reference, _sender);
    }

     
    function _performTransferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) public onlyProxy() returns(bool) {
        return _transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }

     
    function _transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) internal returns(bool) {
        return proxy._forwardTransferFromToICAPWithReference(_from, _icap, _value, _reference, _sender);
    }

     
    function _performApprove(address _spender, uint _value, address _sender) public onlyProxy() returns(bool) {
        return _approve(_spender, _value, _sender);
    }

     
    function _approve(address _spender, uint _value, address _sender) internal returns(bool) {
        return proxy._forwardApprove(_spender, _value, _sender);
    }

     
    function _performGeneric(bytes _data, address _sender) public payable onlyProxy() {
        _generic(_data, msg.value, _sender);
    }

    modifier onlyMe() {
        if (this == msg.sender) {
            _;
        }
    }

     
    address public genericSender;
    function _generic(bytes _data, uint _value, address _msgSender) internal {
         
        require(genericSender == 0x0);
        genericSender = _msgSender;
        bool success = _assemblyCall(address(this), _value, _data);
        delete genericSender;
        _returnReturnData(success);
    }

     
    function _sender() internal view returns(address) {
        return this == msg.sender ? genericSender : msg.sender;
    }

     
    function transferToICAP(string _icap, uint _value) public returns(bool) {
        return transferToICAPWithReference(_icap, _value, '');
    }

    function transferToICAPWithReference(string _icap, uint _value, string _reference) public returns(bool) {
        return _transferToICAPWithReference(_bytes32(_icap), _value, _reference, _sender());
    }

    function transferFromToICAP(address _from, string _icap, uint _value) public returns(bool) {
        return transferFromToICAPWithReference(_from, _icap, _value, '');
    }

    function transferFromToICAPWithReference(address _from, string _icap, uint _value, string _reference) public returns(bool) {
        return _transferFromToICAPWithReference(_from, _bytes32(_icap), _value, _reference, _sender());
    }

    function isICAP(address _address) public pure returns(bool) {
        bytes32 a = bytes32(_address) << 96;
        if (a[0] != 'X' || a[1] != 'E') {
            return false;
        }
        if (a[2] < 48 || a[2] > 57 || a[3] < 48 || a[3] > 57) {
            return false;
        }
        for (uint i = 4; i < 20; i++) {
            uint char = uint(a[i]);
            if (char < 48 || char > 90 || (char > 57 && char < 65)) {
                return false;
            }
        }
        return true;
    }
}

contract Ambi2 {
    function claimFor(address _address, address _owner) public returns(bool);
    function hasRole(address _from, bytes32 _role, address _to) public view returns(bool);
    function isOwner(address _node, address _owner) public view returns(bool);
}

contract Ambi2Enabled {
    Ambi2 public ambi2;

    modifier onlyRole(bytes32 _role) {
        if (address(ambi2) != 0x0 && ambi2.hasRole(this, _role, msg.sender)) {
            _;
        }
    }

     
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
        if (address(ambi2) != 0x0) {
            return false;
        }

        ambi2 = _ambi2;
        return true;
    }
}

contract Ambi2EnabledFull is Ambi2Enabled {
     
    function setupAmbi2(Ambi2 _ambi2) public returns(bool) {
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

contract ComplianceConfiguration {
    function isTransferAllowed(address _from, address _to, uint _value) public view returns(bool);
    function isTransferToICAPAllowed(address _from, bytes32 _icap, uint _value) public view returns(bool);
    function processTransferResult(address _from, address _to, uint _value, bool _success) public;
    function processTransferToICAPResult(address _from, bytes32 _icap, uint _value, bool _success) public;
}

 

contract AssetWithCompliance is AssetWithAmbi {
    ComplianceConfiguration complianceConfiguration;

    event Error(bytes32 error);
    event ComplianceConfigurationSet(address contractAddress);

     
    modifier isTransferAllowed(address _from, address _to, uint _value) {
        if (address(complianceConfiguration) != 0x0 && !complianceConfiguration.isTransferAllowed(_from, _to, _value)) {
            emit Error('Transfer is not allowed');
            return;
        }
        _;
    }

     
    modifier isTransferToICAPAllowed(address _from, bytes32 _icap, uint _value) {
        if (address(complianceConfiguration) != 0x0 && !complianceConfiguration.isTransferToICAPAllowed(_from, _icap, _value)) {
            emit Error('Transfer is not allowed');
            return;
        }
        _;
    }

     
    function setupComplianceConfiguration(ComplianceConfiguration _complianceConfiguration) public onlyRole('admin') returns(bool) {
        complianceConfiguration = _complianceConfiguration;
        emit ComplianceConfigurationSet(_complianceConfiguration);
        return true;
    }

    function processTransferResult(address _from, address _to, uint _value, bool _success) internal returns(bool) {
        if (address(complianceConfiguration) == 0x0) {
            return _success;
        }
        complianceConfiguration.processTransferResult(_from, _to, _value, _success);
        return _success;
    }

    function processTransferToICAPResult(address _from, bytes32 _icap, uint _value, bool _success) internal returns(bool) {
        if (address(complianceConfiguration) == 0x0) {
            return _success;
        }
        complianceConfiguration.processTransferToICAPResult(_from, _icap, _value, _success);
        return _success;
    }

     
     
    function () public {
        _returnReturnData(_assemblyCall(address(complianceConfiguration), 0, msg.data));
    }

     
     function _transferWithReference(address _to, uint _value, string _reference, address _sender) internal isTransferAllowed(_sender, _to, _value) returns(bool) {
         return processTransferResult(_sender, _to, _value, super._transferWithReference(_to, _value, _reference, _sender));
     }

     
    function _transferToICAPWithReference(bytes32 _icap, uint _value, string _reference, address _sender) internal isTransferToICAPAllowed(_sender, _icap, _value)  returns(bool) {
        return processTransferToICAPResult(_sender, _icap, _value, super._transferToICAPWithReference(_icap, _value, _reference, _sender));
    }

     
    function _transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) internal isTransferAllowed(_from, _to, _value) returns(bool) {
        return processTransferResult(_from, _to, _value, super._transferFromWithReference(_from, _to, _value, _reference, _sender));
    }

     
    function _transferFromToICAPWithReference(address _from, bytes32 _icap, uint _value, string _reference, address _sender) internal isTransferToICAPAllowed(_from, _icap, _value) returns(bool) {
        return processTransferToICAPResult(_from, _icap, _value, super._transferFromToICAPWithReference(_from, _icap, _value, _reference, _sender));
    }
}