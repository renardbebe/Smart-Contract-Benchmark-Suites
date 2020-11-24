 

 

pragma solidity 0.5.0;

 
contract Proxy {
     
    function () external payable {
        _fallback();
    }

     
    function _implementation() internal view returns (address);

     
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

     
    function _willFallback() internal {
    }

     
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

 

pragma solidity 0.5.0;


 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

 

pragma solidity 0.5.0;



 
contract UpgradeabilityProxy is Proxy {
     
    event Upgraded(address indexed implementation);

     
    bytes32 private constant IMPLEMENTATION_SLOT = 0x69bff8d33f8a81d44ad045cae8c2563876eaefa1bf1355c3840f96d03ef9dc26;

     
    constructor(address _implementation, bytes memory _data) public payable {
        assert(IMPLEMENTATION_SLOT == keccak256("com.yqb.proxy.implementation"));
        _setImplementation(_implementation);
        if(_data.length > 0) {
            (bool success, ) = _implementation.delegatecall(_data); 
            require(success);
        }
    }

     
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

     
    function _setImplementation(address newImplementation) private {
        require(AddressUtils.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}

 

pragma solidity 0.5.0;


 
contract AdminUpgradeabilityProxy is UpgradeabilityProxy {
   
     
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

     
    bytes32 private constant ADMIN_SLOT = 0x6f6d8d7f580c12385c0ffee3db0c8dd22f5ced916dd281b7afe571b5ea7bf38d;
    bytes32 private constant PENDINGADMIN_SLOT = 0xfe6b8cc6ffc46560d1f51755d0370c701a703e339b6c269e0d18ab46fab2c530;

     
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

     
    modifier ifPendingAdmin() {
        if (msg.sender == _pendingAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

     
    constructor(
        address _implementation, 
        address _admin, 
        bytes memory _data
    ) UpgradeabilityProxy(_implementation, _data) public payable {
        require(_admin != address(0), "admin shouldn't be zero address");
        assert(ADMIN_SLOT == keccak256("com.yqb.proxy.admin"));
        assert(PENDINGADMIN_SLOT == keccak256("com.yqb.proxy.pendingAdmin"));
        _setAdmin(_admin);
    }

     
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

     
    function pendingAdmin() external returns (address) {
        if (msg.sender == _admin() || msg.sender == _pendingAdmin()) {
            return _pendingAdmin();
        } else {
            _fallback();
        }
    }

     
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

     
    function changeAdmin(address _newAdmin) external ifAdmin {
        _setPendingAdmin(_newAdmin);
    }

     
    function claimAdmin() external ifPendingAdmin {
        emit AdminChanged(_admin(), _pendingAdmin());
        _setAdmin(_pendingAdmin());
        _setPendingAdmin(address(0));
        
    }  

     
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }
    
     
    function upgradeToAndCall(address _newImplementation, bytes calldata _data) external payable ifAdmin {
        _upgradeTo(_newImplementation);
        (bool success, ) = _newImplementation.delegatecall(_data); 
        require(success);
    }

     
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

     
    function _pendingAdmin() internal view returns (address pendingAdm) {
        bytes32 slot = PENDINGADMIN_SLOT;
        assembly {
            pendingAdm := sload(slot)
        }
    }

     
    function _setAdmin(address _newAdmin) internal { 
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, _newAdmin)
        }
    }

     
    function _setPendingAdmin(address _newAdmin) internal { 
        bytes32 slot = PENDINGADMIN_SLOT;
        assembly {
            sstore(slot, _newAdmin)
        }
    }

     
    function _willFallback() internal {
        require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
        super._willFallback();
    }

}