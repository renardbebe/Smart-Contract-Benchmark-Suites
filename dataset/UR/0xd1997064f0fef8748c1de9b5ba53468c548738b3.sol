 

pragma solidity ^0.4.21;

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    function Owned() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract IContractRegistry {
    function getAddress(bytes32 _contractName) public view returns (address);
}

 
contract ContractRegistry is IContractRegistry, Owned {
    mapping (bytes32 => address) addresses;

    event AddressUpdate(bytes32 indexed _contractName, address _contractAddress);

     
    function ContractRegistry() public {
    }

     
    function getAddress(bytes32 _contractName) public view returns (address) {
        return addresses[_contractName];
    }

     
    function registerAddress(bytes32 _contractName, address _contractAddress) public ownerOnly {
        require(_contractName.length > 0);  

        addresses[_contractName] = _contractAddress;
        emit AddressUpdate(_contractName, _contractAddress);
    }
}