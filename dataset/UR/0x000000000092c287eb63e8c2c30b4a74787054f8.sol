 

 

pragma solidity ^0.5.8;

 
contract Proxy {
     
    function() external payable {
        _fallback();
    }

     
    function _implementation() internal view returns (address);

     
    function _delegate(address implementation) internal {
        assembly {
             
             
             
            calldatacopy(0, 0, calldatasize)

             
             
            let result := delegatecall(
                gas,
                implementation,
                0,
                calldatasize,
                0,
                0
            )

             
            returndatacopy(0, 0, returndatasize)

            switch result
                 
                case 0 {
                    revert(0, returndatasize)
                }
                default {
                    return(0, returndatasize)
                }
        }
    }

     
    function _willFallback() internal {}

     
    function _fallback() internal {
        _willFallback();
        _delegate(_implementation());
    }
}

 

pragma solidity ^0.5.8;

 
library AddressUtils {
     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

}

 

pragma solidity ^0.5.8;



 
contract BaseUpgradeabilityProxy is Proxy {
     
    event Upgraded(address indexed implementation);

     
    bytes32 internal constant IMPLEMENTATION_SLOT = 0xe99d12b39ab17aef0ca754554afa48519dcb96ca64603696637dea37e965a617;

     
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
        require(
            AddressUtils.isContract(newImplementation),
            "Cannot set a proxy implementation to a non-contract address"
        );

        bytes32 slot = IMPLEMENTATION_SLOT;

        assembly {
            sstore(slot, newImplementation)
        }
    }
}

 

pragma solidity ^0.5.8;


 
contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
     
    constructor(address _logic, bytes memory _data) public payable {
        assert(IMPLEMENTATION_SLOT == keccak256("bts.lab.eth.proxy.impl"));
        _setImplementation(_logic);
        if (_data.length > 0) {
            (bool success, ) = _logic.delegatecall(_data);
            require(success);
        }
    }
}

 

pragma solidity ^0.5.8;


 
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
     
    event AdminChanged(address previousAdmin, address newAdmin);

     
    bytes32 internal constant ADMIN_SLOT = 0xd605002b0407d620d5ea33643507867180e600a98b93d382fc50227c2095905e;

     
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

     
    function admin() external ifAdmin returns (address) {
        return _admin();
    }

     
    function implementation() external ifAdmin returns (address) {
        return _implementation();
    }

     
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

     
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

     
    function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
        _upgradeTo(newImplementation);
        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }

     
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

     
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;

        assembly {
            sstore(slot, newAdmin)
        }
    }

     
    function _willFallback() internal {
        require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
        super._willFallback();
    }
}

 

pragma solidity ^0.5.8;


 
contract AdminUpgradeabilityProxy is
    BaseAdminUpgradeabilityProxy,
    UpgradeabilityProxy
{
     
    constructor(address _logic, address _admin, bytes memory _data)
        public
        payable
        UpgradeabilityProxy(_logic, _data)
    {
        assert(ADMIN_SLOT == keccak256("bts.lab.eth.proxy.admin"));
        _setAdmin(_admin);
    }
}

 

pragma solidity ^0.5.8;


contract TokenFactoryProxy is AdminUpgradeabilityProxy {
    constructor(address _impl, address _admin, bytes memory _data)
        public
        payable
        AdminUpgradeabilityProxy(_impl, _admin, _data)
    {}
}