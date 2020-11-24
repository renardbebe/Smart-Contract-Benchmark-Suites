 

 

pragma solidity 0.4.23;


contract RegistryICAPInterface {
    function parse(bytes32 _icap) public view returns(address, bytes32, bool);
    function institutions(bytes32 _institution) public view returns(address);
}


contract EToken2Interface {
    function registryICAP() public view returns(RegistryICAPInterface);
    function baseUnit(bytes32 _symbol) public view returns(uint8);
    function description(bytes32 _symbol) public view returns(string);
    function owner(bytes32 _symbol) public view returns(address);
    function isOwner(address _owner, bytes32 _symbol) public view returns(bool);
    function totalSupply(bytes32 _symbol) public view returns(uint);
    function balanceOf(address _holder, bytes32 _symbol) public view returns(uint);
    function isLocked(bytes32 _symbol) public view returns(bool);

    function issueAsset(
        bytes32 _symbol,
        uint _value,
        string _name,
        string _description,
        uint8 _baseUnit,
        bool _isReissuable)
    public returns(bool);

    function reissueAsset(bytes32 _symbol, uint _value) public returns(bool);
    function revokeAsset(bytes32 _symbol, uint _value) public returns(bool);
    function setProxy(address _address, bytes32 _symbol) public returns(bool);
    function lockAsset(bytes32 _symbol) public returns(bool);

    function proxyTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string _reference,
        address _sender)
    public returns(bool);

    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender)
    public returns(bool);
    
    function allowance(address _from, address _spender, bytes32 _symbol) public view returns(uint);

    function proxyTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        bytes32 _symbol,
        string _reference,
        address _sender)
    public returns(bool);

    function changeOwnership(bytes32 _symbol, address _newOwner) public returns(bool);
}

 

pragma solidity 0.4.23;


contract AssetInterface {
    function _performTransferWithReference(
        address _to,
        uint _value,
        string _reference,
        address _sender)
    public returns(bool);

    function _performTransferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string _reference,
        address _sender)
    public returns(bool);

    function _performApprove(address _spender, uint _value, address _sender)
    public returns(bool);

    function _performTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string _reference,
        address _sender)
    public returns(bool);

    function _performTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string _reference,
        address _sender)
    public returns(bool);

    function _performGeneric(bytes, address) public payable {
        revert();
    }
}

 

pragma solidity 0.4.23;


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

 

pragma solidity 0.4.23;



contract AssetProxyInterface is ERC20Interface {
    function _forwardApprove(address _spender, uint _value, address _sender)
    public returns(bool);

    function _forwardTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string _reference,
        address _sender)
    public returns(bool);

    function _forwardTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string _reference,
        address _sender)
    public returns(bool);

    function recoverTokens(ERC20Interface _asset, address _receiver, uint _value)
    public returns(bool);

     
    function etoken2() public pure returns(address) {}  

     
     
    function etoken2Symbol() public pure returns(bytes32) {}
}

 

pragma solidity 0.4.23;


contract Bytes32 {
    function _bytes32(string _input) internal pure returns(bytes32 result) {
        assembly {
            result := mload(add(_input, 32))
        }
    }
}

 

pragma solidity 0.4.23;


contract ReturnData {
    function _returnReturnData(bool _success) internal pure {
        assembly {
            let returndatastart := 0
            returndatacopy(returndatastart, 0, returndatasize)
            switch _success case 0 { revert(returndatastart, returndatasize) }
                default { return(returndatastart, returndatasize) }
        }
    }

    function _assemblyCall(address _destination, uint _value, bytes _data)
    internal returns(bool success) {
        assembly {
            success := call(gas, _destination, _value, add(_data, 32), mload(_data), 0, 0)
        }
    }
}

 

pragma solidity 0.4.23;








 
contract AssetProxy is ERC20Interface, AssetProxyInterface, Bytes32, ReturnData {
     
    EToken2Interface public etoken2;

     
    bytes32 public etoken2Symbol;

     
    string public name;
    string public symbol;

     
    function init(EToken2Interface _etoken2, string _symbol, string _name) public returns(bool) {
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

     
    function _getAsset() internal view returns(AssetInterface) {
        return AssetInterface(getVersionFor(msg.sender));
    }

     
    function recoverTokens(ERC20Interface _asset, address _receiver, uint _value)
    public onlyAssetOwner() returns(bool) {
        return _asset.transfer(_receiver, _value);
    }

     
    function totalSupply() public view returns(uint) {
        return etoken2.totalSupply(etoken2Symbol);
    }

     
    function balanceOf(address _owner) public view returns(uint) {
        return etoken2.balanceOf(_owner, etoken2Symbol);
    }

     
    function allowance(address _from, address _spender) public view returns(uint) {
        return etoken2.allowance(_from, _spender, etoken2Symbol);
    }

     
    function decimals() public view returns(uint8) {
        return etoken2.baseUnit(etoken2Symbol);
    }

     
    function transfer(address _to, uint _value) public returns(bool) {
        return transferWithReference(_to, _value, '');
    }

     
    function transferWithReference(address _to, uint _value, string _reference)
    public returns(bool) {
        return _getAsset()._performTransferWithReference(
            _to, _value, _reference, msg.sender);
    }

     
    function transferToICAP(bytes32 _icap, uint _value) public returns(bool) {
        return transferToICAPWithReference(_icap, _value, '');
    }

     
    function transferToICAPWithReference(
        bytes32 _icap,
        uint _value,
        string _reference)
    public returns(bool) {
        return _getAsset()._performTransferToICAPWithReference(
            _icap, _value, _reference, msg.sender);
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns(bool) {
        return transferFromWithReference(_from, _to, _value, '');
    }

     
    function transferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string _reference)
    public returns(bool) {
        return _getAsset()._performTransferFromWithReference(
            _from,
            _to,
            _value,
            _reference,
            msg.sender
        );
    }

     
    function _forwardTransferFromWithReference(
        address _from,
        address _to,
        uint _value,
        string _reference,
        address _sender)
    public onlyImplementationFor(_sender) returns(bool) {
        return etoken2.proxyTransferFromWithReference(
            _from,
            _to,
            _value,
            etoken2Symbol,
            _reference,
            _sender
        );
    }

     
    function transferFromToICAP(address _from, bytes32 _icap, uint _value)
    public returns(bool) {
        return transferFromToICAPWithReference(_from, _icap, _value, '');
    }

     
    function transferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string _reference)
    public returns(bool) {
        return _getAsset()._performTransferFromToICAPWithReference(
            _from,
            _icap,
            _value,
            _reference,
            msg.sender
        );
    }

     
    function _forwardTransferFromToICAPWithReference(
        address _from,
        bytes32 _icap,
        uint _value,
        string _reference,
        address _sender)
    public onlyImplementationFor(_sender) returns(bool) {
        return etoken2.proxyTransferFromToICAPWithReference(
            _from,
            _icap,
            _value,
            _reference,
            _sender
        );
    }

     
    function approve(address _spender, uint _value) public returns(bool) {
        return _getAsset()._performApprove(_spender, _value, msg.sender);
    }

     
    function _forwardApprove(address _spender, uint _value, address _sender)
    public onlyImplementationFor(_sender) returns(bool) {
        return etoken2.proxyApprove(_spender, _value, etoken2Symbol, _sender);
    }

     
    function emitTransfer(address _from, address _to, uint _value) public onlyEToken2() {
        emit Transfer(_from, _to, _value);
    }

     
    function emitApprove(address _from, address _spender, uint _value) public onlyEToken2() {
        emit Approval(_from, _spender, _value);
    }

     
    function () public payable {
        _getAsset()._performGeneric.value(msg.value)(msg.data, msg.sender);
        _returnReturnData(true);
    }

     
    function transferToICAP(string _icap, uint _value) public returns(bool) {
        return transferToICAPWithReference(_icap, _value, '');
    }

    function transferToICAPWithReference(string _icap, uint _value, string _reference)
    public returns(bool) {
        return transferToICAPWithReference(_bytes32(_icap), _value, _reference);
    }

    function transferFromToICAP(address _from, string _icap, uint _value) public returns(bool) {
        return transferFromToICAPWithReference(_from, _icap, _value, '');
    }

    function transferFromToICAPWithReference(
        address _from,
        string _icap,
        uint _value,
        string _reference)
    public returns(bool) {
        return transferFromToICAPWithReference(_from, _bytes32(_icap), _value, _reference);
    }

     
    event UpgradeProposed(address newVersion);
    event UpgradePurged(address newVersion);
    event UpgradeCommited(address newVersion);
    event OptedOut(address sender, address version);
    event OptedIn(address sender, address version);

     
    address internal latestVersion;

     
    address internal pendingVersion;

     
    uint internal pendingVersionTimestamp;

     
    uint internal constant UPGRADE_FREEZE_TIME = 3 days;

     
     
    mapping(address => address) internal userOptOutVersion;

     
    modifier onlyImplementationFor(address _sender) {
        if (getVersionFor(_sender) == msg.sender) {
            _;
        }
    }

     
    function getVersionFor(address _sender) public view returns(address) {
        return userOptOutVersion[_sender] == 0 ? latestVersion : userOptOutVersion[_sender];
    }

     
    function getLatestVersion() public view returns(address) {
        return latestVersion;
    }

     
    function getPendingVersion() public view returns(address) {
        return pendingVersion;
    }

     
    function getPendingVersionTimestamp() public view returns(uint) {
        return pendingVersionTimestamp;
    }

     
    function proposeUpgrade(address _newVersion) public onlyAssetOwner() returns(bool) {
         
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
        emit UpgradeProposed(_newVersion);
        return true;
    }

     
    function purgeUpgrade() public onlyAssetOwner() returns(bool) {
        if (pendingVersion == 0x0) {
            return false;
        }
        emit UpgradePurged(pendingVersion);
        delete pendingVersion;
        delete pendingVersionTimestamp;
        return true;
    }

     
    function commitUpgrade() public returns(bool) {
        if (pendingVersion == 0x0) {
            return false;
        }
         
        if (pendingVersionTimestamp + UPGRADE_FREEZE_TIME > now) {
            return false;
        }
        latestVersion = pendingVersion;
        delete pendingVersion;
        delete pendingVersionTimestamp;
        emit UpgradeCommited(latestVersion);
        return true;
    }

     
    function optOut() public returns(bool) {
        if (userOptOutVersion[msg.sender] != 0x0) {
            return false;
        }
        userOptOutVersion[msg.sender] = latestVersion;
        emit OptedOut(msg.sender, latestVersion);
        return true;
    }

     
    function optIn() public returns(bool) {
        delete userOptOutVersion[msg.sender];
        emit OptedIn(msg.sender, latestVersion);
        return true;
    }

     
    function multiAsset() public view returns(EToken2Interface) {
        return etoken2;
    }
}

 

pragma solidity 0.4.23;



contract VOLUM is AssetProxy {
    function change(string _symbol, string _name) public onlyAssetOwner() returns(bool) {
        if (etoken2.isLocked(etoken2Symbol)) {
            return false;
        }
        name = _name;
        symbol = _symbol;
        return true;
    }
}