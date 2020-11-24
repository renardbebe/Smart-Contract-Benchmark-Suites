 

 
 
 

contract Ambi {
    function getNodeAddress(bytes32 _nodeName) constant returns(address);
    function hasRelation(bytes32 _nodeName, bytes32 _relation, address _to) constant returns(bool);
    function addNode(bytes32 _nodeName, address _nodeAddress) constant returns(bool);
}

contract AmbiEnabled {
    Ambi public ambiC;
    bool public isImmortal;
    bytes32 public name;

    modifier checkAccess(bytes32 _role) {
        if(address(ambiC) != 0x0 && ambiC.hasRelation(name, _role, msg.sender)){
            _
        }
    }
    
    function getAddress(bytes32 _name) constant returns (address) {
        return ambiC.getNodeAddress(_name);
    }

    function setAmbiAddress(address _ambi, bytes32 _name) returns (bool){
        if(address(ambiC) != 0x0){
            return false;
        }
        Ambi ambiContract = Ambi(_ambi);
        if(ambiContract.getNodeAddress(_name)!=address(this)) {
            if (!ambiContract.addNode(_name, address(this))){
                return false;
            }
        }
        name = _name;
        ambiC = ambiContract;
        return true;
    }

    function immortality() checkAccess("owner") returns(bool) {
        isImmortal = true;
        return true;
    }

    function remove() checkAccess("owner") returns(bool) {
        if (isImmortal) {
            return false;
        }
        selfdestruct(msg.sender);
        return true;
    }
}

library StackDepthLib {
     
     
     
    uint constant GAS_PER_DEPTH = 400;

    function checkDepth(address self, uint n) constant returns(bool) {
        if (n == 0) return true;
        return self.call.gas(GAS_PER_DEPTH * n)(0x21835af6, n - 1);
    }

    function __dig(uint n) constant {
        if (n == 0) return;
        if (!address(this).delegatecall(0x21835af6, n - 1)) throw;
    }
}

contract Safe {
     
    modifier noValue {
        if (msg.value > 0) {
             
             
             
            _safeSend(msg.sender, msg.value);
        }
        _
    }

    modifier onlyHuman {
        if (_isHuman()) {
            _
        }
    }

    modifier noCallback {
        if (!isCall) {
            _
        }
    }

    modifier immutable(address _address) {
        if (_address == 0) {
            _
        }
    }

    address stackDepthLib;
    function setupStackDepthLib(address _stackDepthLib) immutable(address(stackDepthLib)) returns(bool) {
        stackDepthLib = _stackDepthLib;
        return true;
    }

    modifier requireStackDepth(uint16 _depth) {
        if (stackDepthLib == 0x0) {
            throw;
        }
        if (_depth > 1023) {
            throw;
        }
        if (!stackDepthLib.delegatecall(0x32921690, stackDepthLib, _depth)) {
            throw;
        }
        _
    }

     
    function _safeFalse() internal noValue() returns(bool) {
        return false;
    }

    function _safeSend(address _to, uint _value) internal {
        if (!_unsafeSend(_to, _value)) {
            throw;
        }
    }

    function _unsafeSend(address _to, uint _value) internal returns(bool) {
        return _to.call.value(_value)();
    }

    function _isContract() constant internal returns(bool) {
        return msg.sender != tx.origin;
    }

    function _isHuman() constant internal returns(bool) {
        return !_isContract();
    }

    bool private isCall = false;
    function _setupNoCallback() internal {
        isCall = true;
    }

    function _finishNoCallback() internal {
        isCall = false;
    }
}

 
contract EventsHistory is AmbiEnabled, Safe {
     
    mapping(bytes4 => address) public emitters;

     
    mapping(address => uint) public versions;

     
    mapping(uint => VersionInfo) public versionInfo;

     
    uint public latestVersion;

    struct VersionInfo {
        uint block;         
        address by;         
        address caller;     
        string name;        
        string changelog;   
    }

     
    function addEmitter(bytes4 _eventSignature, address _emitter) noValue() checkAccess("admin") returns(bool) {
        if (emitters[_eventSignature] != 0x0) {
            return false;
        }
        emitters[_eventSignature] = _emitter;
        return true;
    }

     
    function addVersion(address _caller, string _name, string _changelog) noValue() checkAccess("admin") returns(bool) {
        if (versions[_caller] != 0) {
            return false;
        }
        if (bytes(_name).length == 0) {
            return false;
        }
        if (bytes(_changelog).length == 0) {
            return false;
        }
        uint version = ++latestVersion;
        versions[_caller] = version;
        versionInfo[version] = VersionInfo(block.number, msg.sender, _caller, _name, _changelog);
        return true;
    }

     
    function () noValue() {
        if (versions[msg.sender] == 0) {
            return;
        }
         
         
         
        if (!emitters[msg.sig].delegatecall(msg.data)) {
            throw;
        }
    }
}