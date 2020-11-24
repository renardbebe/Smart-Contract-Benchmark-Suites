 

pragma solidity ^0.5.2;

 
interface RegistryInterface {
    function logic(address logicAddr) external view returns (bool);
    function record(address currentOwner, address nextOwner) external;
}


 
contract AddressRecord {

     
    address public registry;

     
    modifier logicAuth(address logicAddr) {
        require(logicAddr != address(0), "logic-proxy-address-required");
        require(RegistryInterface(registry).logic(logicAddr), "logic-not-authorised");
        _;
    }

}


 
contract UserAuth is AddressRecord {

    event LogSetOwner(address indexed owner);
    address public owner;

     
    modifier auth {
        require(isAuth(msg.sender), "permission-denied");
        _;
    }

     
    function setOwner(address nextOwner) public auth {
        RegistryInterface(registry).record(owner, nextOwner);
        owner = nextOwner;
        emit LogSetOwner(nextOwner);
    }

     
    function isAuth(address src) public view returns (bool) {
        if (src == owner) {
            return true;
        } else if (src == address(this)) {
            return true;
        }
        return false;
    }
}


 
contract UserNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 bar,
        uint wad,
        bytes fax
    );

    modifier note {
        bytes32 foo;
        bytes32 bar;
        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }
        emit LogNote(
            msg.sig, 
            msg.sender, 
            foo, 
            bar, 
            msg.value,
            msg.data
        );
        _;
    }
}


 
contract UserWallet is UserAuth, UserNote {

    event LogExecute(address target, uint srcNum, uint sessionNum);

     
    constructor() public {
        registry = msg.sender;
        owner = msg.sender;
    }

    function() external payable {}

     
    function execute(
        address _target,
        bytes memory _data,
        uint _src,
        uint _session
    ) 
        public
        payable
        note
        auth
        logicAuth(_target)
        returns (bytes memory response)
    {
        emit LogExecute(
            _target,
            _src,
            _session
        );
        
         
        assembly {
            let succeeded := delegatecall(sub(gas, 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
                case 1 {
                     
                    revert(add(response, 0x20), size)
                }
        }
    }

}


 
 
 
contract AddressRegistry {
    event LogSetAddress(string name, address addr);

     
    mapping(bytes32 => address) registry;

     
    modifier isAdmin() {
        require(
            msg.sender == getAddress("admin") || 
            msg.sender == getAddress("owner"),
            "permission-denied"
        );
        _;
    }

     
     
     
    function getAddress(string memory _name) public view returns(address) {
        return registry[keccak256(abi.encodePacked(_name))];
    }

     
     
     
    function setAddress(string memory _name, address _userAddress) public isAdmin {
        registry[keccak256(abi.encodePacked(_name))] = _userAddress;
        emit LogSetAddress(_name, _userAddress);
    }
}


 
 
 
contract LogicRegistry is AddressRegistry {

    event LogEnableStaticLogic(address logicAddress);
    event LogEnableLogic(address logicAddress);
    event LogDisableLogic(address logicAddress);

     
    mapping(address => bool) public logicProxiesStatic;
    
     
    mapping(address => bool) public logicProxies;

     
     
     
    function logic(address _logicAddress) public view returns (bool) {
        if (logicProxiesStatic[_logicAddress] || logicProxies[_logicAddress]) {
            return true;
        }
        return false;
    }

     
     
     
    function logicStatic(address _logicAddress) public view returns (bool) {
        if (logicProxiesStatic[_logicAddress]) {
            return true;
        }
        return false;
    }

     
     
     
     
    function enableStaticLogic(address _logicAddress) public isAdmin {
        logicProxiesStatic[_logicAddress] = true;
        emit LogEnableStaticLogic(_logicAddress);
    }

     
     
    function enableLogic(address _logicAddress) public isAdmin {
        logicProxies[_logicAddress] = true;
        emit LogEnableLogic(_logicAddress);
    }

     
     
    function disableLogic(address _logicAddress) public isAdmin {
        logicProxies[_logicAddress] = false;
        emit LogDisableLogic(_logicAddress);
    }

}


 
contract WalletRegistry is LogicRegistry {
    
    event Created(address indexed sender, address indexed owner, address proxy);
    event LogRecord(address indexed currentOwner, address indexed nextOwner, address proxy);
    
     
    mapping(address => UserWallet) public proxies;
    
     
     
     
    function build() public returns (UserWallet proxy) {
        proxy = build(msg.sender);
    }

     
     
     
    function build(address _owner) public returns (UserWallet proxy) {
        require(proxies[_owner] == UserWallet(0), "multiple-proxy-per-user-not-allowed");
        proxy = new UserWallet();
        proxies[address(this)] = proxy;  
        proxy.setOwner(_owner);
        emit Created(msg.sender, _owner, address(proxy));
    }

     
     
     
    function record(address _currentOwner, address _nextOwner) public {
        require(msg.sender == address(proxies[_currentOwner]), "invalid-proxy-or-owner");
        require(proxies[_nextOwner] == UserWallet(0), "multiple-proxy-per-user-not-allowed");
        proxies[_nextOwner] = proxies[_currentOwner];
        proxies[_currentOwner] = UserWallet(0);
        emit LogRecord(_currentOwner, _nextOwner, address(proxies[_nextOwner]));
    }

}


 
 
contract InstaRegistry is WalletRegistry {

    constructor() public {
        registry[keccak256(abi.encodePacked("admin"))] = msg.sender;
        registry[keccak256(abi.encodePacked("owner"))] = msg.sender;
    }
}