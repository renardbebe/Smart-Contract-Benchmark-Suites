 

 

 

pragma solidity ^0.4.23;


 
contract ERC20 {
    
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



contract ChronoBankPlatform is ChronoBankPlatformEmitter {
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


contract ChronoBankAsset {
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __approve(address _spender, uint _value, address _sender) public returns(bool);
    function __process(bytes  , address  ) public payable {
        revert("ASSET_PROCESS_NOT_SUPPORTED");
    }
}

 

 

pragma solidity ^0.4.21;





 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
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
        if (msg.sender == getVersionFor(_sender)) {
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