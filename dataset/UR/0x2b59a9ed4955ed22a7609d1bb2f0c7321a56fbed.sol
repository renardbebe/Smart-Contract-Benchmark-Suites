 

 

pragma solidity 0.4.24;


 
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;


    mapping(bytes32 => uint256[]) internal uintArrayStorage;
    mapping(bytes32 => string[]) internal stringArrayStorage;
    mapping(bytes32 => address[]) internal addressArrayStorage;
     
    mapping(bytes32 => bool[]) internal boolArrayStorage;
    mapping(bytes32 => int256[]) internal intArrayStorage;
    mapping(bytes32 => bytes32[]) internal bytes32ArrayStorage;
}

 

pragma solidity 0.4.24;


 
contract Proxy {

   
    function implementation() public view returns (address);

    function setImplementation(address _newImplementation) external;

   
    function () payable public {
        address _impl = implementation();
        require(_impl != address(0));

        address _innerImpl;
        bytes4 sig;
        address thisAddress = address(this);
        if (_impl.call(0x5c60da1b)) {  
            _innerImpl = Proxy(_impl).implementation();
            this.setImplementation(_innerImpl);
            sig = 0xd784d426;  
        }

        assembly {
             
            let ptr := mload(0x40)
             
            calldatacopy(ptr, 0, calldatasize)
             
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
             
             
            mstore(0x40, add(ptr, returndatasize))
             
            returndatacopy(ptr, 0, returndatasize)

            let retdatasize := returndatasize

            switch sig
            case 0 {}
            default {
                let x := mload(0x40)
                mstore(x, sig)
                mstore(add(x, 0x04), _impl)
                let success := call(gas, thisAddress, 0, x, 0x24, x, 0x0)
            }

             
            switch result
            case 0 { revert(ptr, retdatasize) }
            default { return(ptr, retdatasize) }
        }
    }
}

 

pragma solidity 0.4.24;


 
contract UpgradeabilityStorage {
     
    uint256 internal _version;

     
    address internal _implementation;

     
    function version() public view returns (uint256) {
        return _version;
    }

     
    function implementation() public view returns (address) {
        return _implementation;
    }

    function setImplementation(address _newImplementation) external {
        require(msg.sender == address(this));
        _implementation = _newImplementation;
    }
}

 

pragma solidity 0.4.24;




 
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {
     
    event Upgraded(uint256 version, address indexed implementation);

     
    function _upgradeTo(uint256 version, address implementation) internal {
        require(_implementation != implementation);
        require(version > _version);
        _version = version;
        _implementation = implementation;
        emit Upgraded(version, implementation);
    }
}

 

pragma solidity 0.4.24;


 
contract UpgradeabilityOwnerStorage {
     
    address private _upgradeabilityOwner;

     
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

     
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }
}

 

pragma solidity 0.4.24;




 
contract OwnedUpgradeabilityProxy is UpgradeabilityOwnerStorage, UpgradeabilityProxy {
   
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

     
    constructor() public {
        setUpgradeabilityOwner(msg.sender);
    }

     
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

     
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

     
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

     
    function upgradeTo(uint256 version, address implementation) public onlyProxyOwner {
        _upgradeTo(version, implementation);
    }

     
    function upgradeToAndCall(uint256 version, address implementation, bytes data) payable public onlyProxyOwner {
        upgradeTo(version, implementation);
        require(address(this).call.value(msg.value)(data));
    }
}

 

pragma solidity 0.4.24;




 
contract EternalStorageProxy is OwnedUpgradeabilityProxy, EternalStorage {}