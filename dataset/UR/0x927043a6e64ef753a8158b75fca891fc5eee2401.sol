 

pragma solidity ^0.4.24;

 

 
contract OwnableProxy {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    bytes32 private constant OWNER_SLOT = 0x3ca57e4b51fc2e18497b219410298879868edada7e6fe5132c8feceb0a080d22;

     
    constructor() public {
        assert(OWNER_SLOT == keccak256("org.monetha.proxy.owner"));

        _setOwner(msg.sender);
    }

     
    modifier onlyOwner() {
        require(msg.sender == _getOwner());
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_getOwner());
        _setOwner(address(0));
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(_getOwner(), _newOwner);
        _setOwner(_newOwner);
    }

     
    function owner() public view returns (address) {
        return _getOwner();
    }

     
    function _getOwner() internal view returns (address own) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            own := sload(slot)
        }
    }

     
    function _setOwner(address _newOwner) internal {
        bytes32 slot = OWNER_SLOT;

        assembly {
            sstore(slot, _newOwner)
        }
    }
}

 

 
contract ClaimableProxy is OwnableProxy {
     
    bytes32 private constant PENDING_OWNER_SLOT = 0xcfd0c6ea5352192d7d4c5d4e7a73c5da12c871730cb60ff57879cbe7b403bb52;

     
    constructor() public {
        assert(PENDING_OWNER_SLOT == keccak256("org.monetha.proxy.pendingOwner"));
    }

    function pendingOwner() public view returns (address) {
        return _getPendingOwner();
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == _getPendingOwner());
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _setPendingOwner(newOwner);
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_getOwner(), _getPendingOwner());
        _setOwner(_getPendingOwner());
        _setPendingOwner(address(0));
    }

     
    function _getPendingOwner() internal view returns (address penOwn) {
        bytes32 slot = PENDING_OWNER_SLOT;
        assembly {
            penOwn := sload(slot)
        }
    }

     
    function _setPendingOwner(address _newPendingOwner) internal {
        bytes32 slot = PENDING_OWNER_SLOT;

        assembly {
            sstore(slot, _newPendingOwner)
        }
    }
}

 

 
contract DestructibleProxy is OwnableProxy {
     
    function destroy() public onlyOwner {
        selfdestruct(_getOwner());
    }

    function destroyAndSend(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }
}

 

interface IPassportLogicRegistry {
     
    event PassportLogicAdded(string version, address implementation);

     
    event CurrentPassportLogicSet(string version, address implementation);

     
    function getPassportLogic(string _version) external view returns (address);

     
    function getCurrentPassportLogicVersion() external view returns (string);

     
    function getCurrentPassportLogic() external view returns (address);
}

 

 
contract Proxy {
     
    function () payable external {
        _delegate(_implementation());
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
}

 

 
contract Passport is Proxy, ClaimableProxy, DestructibleProxy {

    event PassportLogicRegistryChanged(
        address indexed previousRegistry,
        address indexed newRegistry
    );

     
    bytes32 private constant REGISTRY_SLOT = 0xa04bab69e45aeb4c94a78ba5bc1be67ef28977c4fdf815a30b829a794eb67a4a;

     
    constructor(IPassportLogicRegistry _registry) public {
        assert(REGISTRY_SLOT == keccak256("org.monetha.passport.proxy.registry"));

        _setRegistry(_registry);
    }

     
    function changePassportLogicRegistry(IPassportLogicRegistry _registry) public onlyOwner {
        emit PassportLogicRegistryChanged(address(_getRegistry()), address(_registry));
        _setRegistry(_registry);
    }

     
    function getPassportLogicRegistry() public view returns (address) {
        return _getRegistry();
    }

     
    function _implementation() internal view returns (address) {
        return _getRegistry().getCurrentPassportLogic();
    }

     
    function _getRegistry() internal view returns (IPassportLogicRegistry reg) {
        bytes32 slot = REGISTRY_SLOT;
        assembly {
            reg := sload(slot)
        }
    }

    function _setRegistry(IPassportLogicRegistry _registry) internal {
        require(address(_registry) != 0x0, "Cannot set registry to a zero address");

        bytes32 slot = REGISTRY_SLOT;
        assembly {
            sstore(slot, _registry)
        }
    }
}