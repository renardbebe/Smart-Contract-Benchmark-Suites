 

pragma solidity ^0.4.24;

 

 
contract ImplementationStorage {

     
    bytes32 internal constant IMPLEMENTATION_SLOT = 0xa490aab0d89837371982f93f57ffd20c47991f88066ef92475bc8233036969bb;

     
    constructor() public {
        assert(IMPLEMENTATION_SLOT == keccak256("cvc.proxy.implementation"));
    }

     
    function implementation() public view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

 

 
contract CvcProxy is ImplementationStorage {

     
    event Upgraded(address implementation);

     
    event AdminChanged(address previousAdmin, address newAdmin);

     
    bytes32 private constant ADMIN_SLOT = 0x2bbac3e52eee27be250d682577104e2abe776c40160cd3167b24633933100433;

     
    modifier ifAdmin() {
        if (msg.sender == currentAdmin()) {
            _;
        } else {
            delegate(implementation());
        }
    }

     
    constructor() public {
        assert(ADMIN_SLOT == keccak256("cvc.proxy.admin"));
        setAdmin(msg.sender);
    }

     
    function() external payable {
        require(msg.sender != currentAdmin(), "Message sender is not contract admin");
        delegate(implementation());
    }

     
    function changeAdmin(address _newAdmin) external ifAdmin {
        require(_newAdmin != address(0), "Cannot change contract admin to zero address");
        emit AdminChanged(currentAdmin(), _newAdmin);
        setAdmin(_newAdmin);
    }

     
    function upgradeTo(address _implementation) external ifAdmin {
        upgradeImplementation(_implementation);
    }

     
    function upgradeToAndCall(address _implementation, bytes _data) external payable ifAdmin {
        upgradeImplementation(_implementation);
         
        require(address(this).call.value(msg.value)(_data), "Upgrade error: initialization method call failed");
    }

     
    function admin() external view ifAdmin returns (address) {
        return currentAdmin();
    }

     
    function upgradeImplementation(address _newImplementation) private {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation, "Upgrade error: proxy contract already uses specified implementation");
        setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }

     
    function delegate(address _implementation) private {
        assembly {
             
            calldatacopy(0, 0, calldatasize)

             
            let result := delegatecall(gas, _implementation, 0, calldatasize, 0, 0)

             
            returndatacopy(0, 0, returndatasize)

             
            switch result
            case 0 {revert(0, returndatasize)}
            default {return (0, returndatasize)}
        }
    }

     
    function currentAdmin() private view returns (address proxyAdmin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            proxyAdmin := sload(slot)
        }
    }

     
    function setAdmin(address _newAdmin) private {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, _newAdmin)
        }
    }

     
    function setImplementation(address _newImplementation) private {
        require(
            AddressUtils.isContract(_newImplementation),
            "Cannot set new implementation: no contract code at contract address"
        );
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, _newImplementation)
        }
    }

}