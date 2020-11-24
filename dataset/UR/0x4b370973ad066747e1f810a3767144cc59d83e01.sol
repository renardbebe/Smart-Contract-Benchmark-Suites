 

 

 

pragma solidity ^0.4.25;


 
 
 
contract Delegatable {

     
     
     
     
    function _delegate(address implementation) internal {
        assembly {
             
             
             
            calldatacopy(0, 0, calldatasize)

             
             
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

             
            returndatacopy(0, 0, returndatasize)

            switch result
             
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }
}

 

 

pragma solidity ^0.4.25;



 
 
 
 
 
contract Proxy is Delegatable {

     
     
    function () external payable {
        _fallback();
    }

     
    function _implementation() internal view returns (address);

     
     
     
    function _willFallback() internal {
    }

     
     
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

 

pragma solidity ^0.4.25;

 
library LaborxAddressLib {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

 

pragma solidity ^0.4.25;




 
 
 
 
contract BaseUpgradeabilityProxy is Proxy {

     
     
    event Upgraded(address indexed implementation);

     
     
     
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x00dce392765b11486902ac3a76afbfed3e68464872bbbc647d8773854f05fedb;

     
     
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

     
     
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

     
     
    function _setImplementation(address newImplementation) internal {
        require(LaborxAddressLib.isContract(newImplementation), "PROXY_CANNOT_SET_NON_CONTRACT");

        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

 

 

pragma solidity ^0.4.25;



 
 
 
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {

     
     
     
     
     
     
     
    constructor(address _logic, bytes memory _data) public payable {
        assert(IMPLEMENTATION_SLOT == keccak256("io.laborx.proxy.implementation"));

        _setImplementation(_logic);

        if (_data.length > 0) {
            (bool success,) = _logic.delegatecall(_data);
            require(success, "PROXY_INIT_FAILED");
        }
    }
}

 

 

pragma solidity ^0.4.25;



 
 
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {

     
     
     
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

     
     
    bytes32 private constant PROXY_OWNER_SLOT = 0x9f0cb10b07044a26ed5e46aa863117e6277a419ad770761a6659221f518998bd;

     
    constructor(address _logic, bytes memory _data) public UpgradeabilityProxy(_logic, _data) {
        _setUpgradeabilityOwner(msg.sender);
    }

     
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "PROXY_OWNER_ONLY");
        _;
    }

     
     
    function proxyOwner() public view returns (address owner) {
        bytes32 slot = PROXY_OWNER_SLOT;
        assembly {
            owner := sload(slot)
        }
    }

     
     
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
        require(newOwner != address(0), "PROXY_INVALID_NEW_OWNER");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        _setUpgradeabilityOwner(newOwner);
    }

     
     
    function upgradeTo(address implementation) public onlyProxyOwner {
        _upgradeTo(implementation);
    }

     
     
     
     
     
    function upgradeToAndCall(address implementation, bytes data) external payable onlyProxyOwner {
        upgradeTo(implementation);
        require(this.call.value(msg.value)(data), "PROXY_FAILED_CALL");
    }

     
    function _setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 slot = PROXY_OWNER_SLOT;
        assembly {
            sstore(slot, newProxyOwner)
        }
    }
}