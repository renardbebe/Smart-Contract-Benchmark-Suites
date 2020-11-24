 

 

 

pragma solidity ^0.4.21;


contract ChronoBankAssetInterface {
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __approve(address _spender, uint _value, address _sender) public returns(bool);
    function __process(bytes  , address  ) public payable {
        revert();
    }
}

 

 

pragma solidity ^0.4.11;

contract ChronoBankAssetProxyInterface {
    address public chronoBankPlatform;
    bytes32 public smbl;
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __approve(address _spender, uint _value, address _sender) public returns (bool);
    function getLatestVersion() public view returns (address);
    function init(address _chronoBankPlatform, string _symbol, string _name) public;
    function proposeUpgrade(address _newVersion) external returns (bool);
}

 

 

pragma solidity ^0.4.11;


contract ChronoBankPlatformInterface {
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

    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns(uint errorCode);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns(uint errorCode);

    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) public returns(uint errorCode);

    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) public returns(uint errorCode);
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable, address _account) public returns(uint errorCode);
    function reissueAsset(bytes32 _symbol, uint _value) public returns(uint errorCode);
    function revokeAsset(bytes32 _symbol, uint _value) public returns(uint errorCode);

    function hasAssetRights(address _owner, bytes32 _symbol) public view returns (bool);
    function changeOwnership(bytes32 _symbol, address _newOwner) public returns(uint errorCode);
    
    function eventsHistory() public view returns (address);
}

 

 

pragma solidity ^0.4.21;


contract ChronoBankAssetProxy is ChronoBankAssetProxyInterface {}

contract ChronoBankPlatform is ChronoBankPlatformInterface {}


 
 
 
 
 
 
 
 
contract ChronoBankAsset is ChronoBankAssetInterface {

     
    ChronoBankAssetProxy public proxy;

     
    mapping (address => bool) public blacklist;

     
    bool public paused = false;

     
    event Restricted(bytes32 indexed symbol, address restricted);
    event Unrestricted(bytes32 indexed symbol, address unrestricted);

     
    event Paused(bytes32 indexed symbol);
    event Unpaused(bytes32 indexed symbol);

     
    modifier onlyProxy {
        if (proxy == msg.sender) {
            _;
        }
    }

     
    modifier onlyNotPaused(address _sender) {
        if (!paused || isAuthorized(_sender)) {
            _;
        }
    }

     
    modifier onlyAcceptable(address _address) {
        if (!blacklist[_address]) {
            _;
        }
    }

     
    modifier onlyAuthorized {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

     
     
     
     
     
    function init(ChronoBankAssetProxy _proxy) public returns(bool) {
        if (address(proxy) != 0x0) {
            return false;
        }
        proxy = _proxy;
        return true;
    }

     
    function eventsHistory() public view returns (address) {
        ChronoBankPlatform platform = ChronoBankPlatform(proxy.chronoBankPlatform());
        return platform.eventsHistory() != address(platform) ? platform.eventsHistory() : this;
    }

     
    function restrict(address [] _restricted) onlyAuthorized external returns (bool) {
        for (uint i = 0; i < _restricted.length; i++) {
            address restricted = _restricted[i];
            blacklist[restricted] = true;
            _emitRestricted(restricted);
        }
        return true;
    }

     
    function unrestrict(address [] _unrestricted) onlyAuthorized external returns (bool) {
        for (uint i = 0; i < _unrestricted.length; i++) {
            address unrestricted = _unrestricted[i];
            delete blacklist[unrestricted];
            _emitUnrestricted(unrestricted);
        }
        return true;
    }

     
     
    function pause() onlyAuthorized external returns (bool) {
        paused = true;
        _emitPaused();
        return true;
    }

     
     
    function unpause() onlyAuthorized external returns (bool) {
        paused = false;
        _emitUnpaused();
        return true;
    }

     
     
     
     
    function __transferWithReference(
        address _to, 
        uint _value, 
        string _reference, 
        address _sender
    ) 
    onlyProxy 
    public 
    returns (bool) 
    {
        return _transferWithReference(_to, _value, _reference, _sender);
    }

     
     
     
     
    function _transferWithReference(
        address _to, 
        uint _value, 
        string _reference, 
        address _sender
    )
    onlyNotPaused(_sender)
    onlyAcceptable(_to)
    onlyAcceptable(_sender)
    internal
    returns (bool)
    {
        return proxy.__transferWithReference(_to, _value, _reference, _sender);
    }

     
     
     
     
    function __transferFromWithReference(
        address _from, 
        address _to, 
        uint _value, 
        string _reference, 
        address _sender
    ) 
    onlyProxy 
    public 
    returns (bool) 
    {
        return _transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

     
     
     
     
    function _transferFromWithReference(
        address _from, 
        address _to, 
        uint _value, 
        string _reference, 
        address _sender
    )
    onlyNotPaused(_sender)
    onlyAcceptable(_from)
    onlyAcceptable(_to)
    onlyAcceptable(_sender)
    internal
    returns (bool)
    {
        return proxy.__transferFromWithReference(_from, _to, _value, _reference, _sender);
    }

     
     
     
     
    function __approve(address _spender, uint _value, address _sender) onlyProxy public returns (bool) {
        return _approve(_spender, _value, _sender);
    }

     
     
     
    function _approve(address _spender, uint _value, address _sender)
    onlyAcceptable(_spender)
    onlyAcceptable(_sender)
    internal
    returns (bool)
    {
        return proxy.__approve(_spender, _value, _sender);
    }

    function isAuthorized(address _owner)
    public
    view
    returns (bool) {
        ChronoBankPlatform platform = ChronoBankPlatform(proxy.chronoBankPlatform());
        return platform.hasAssetRights(_owner, proxy.smbl());
    }

    function _emitRestricted(address _restricted) private {
        ChronoBankAsset(eventsHistory()).emitRestricted(proxy.smbl(), _restricted);
    }

    function _emitUnrestricted(address _unrestricted) private {
        ChronoBankAsset(eventsHistory()).emitUnrestricted(proxy.smbl(), _unrestricted);
    }

    function _emitPaused() private {
        ChronoBankAsset(eventsHistory()).emitPaused(proxy.smbl());
    }

    function _emitUnpaused() private {
        ChronoBankAsset(eventsHistory()).emitUnpaused(proxy.smbl());
    }

    function emitRestricted(bytes32 _symbol, address _restricted) public {
        emit Restricted(_symbol, _restricted);
    }

    function emitUnrestricted(bytes32 _symbol, address _unrestricted) public {
        emit Unrestricted(_symbol, _unrestricted);
    }

    function emitPaused(bytes32 _symbol) public {
        emit Paused(_symbol);
    }

    function emitUnpaused(bytes32 _symbol) public {
        emit Unpaused(_symbol);
    }
}