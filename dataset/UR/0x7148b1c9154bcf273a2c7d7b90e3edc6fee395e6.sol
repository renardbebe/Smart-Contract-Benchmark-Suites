 

pragma solidity ^0.4.23;

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

     
    function getAddress(bytes32 _contractName) public view returns (address);
}

 
contract Utils {
     
    constructor() public {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
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

 
contract ContractRegistry is IContractRegistry, Owned, Utils {
    struct RegistryItem {
        address contractAddress;     
        uint256 nameIndex;           
        bool isSet;                  
    }

    mapping (bytes32 => RegistryItem) private items;     
    string[] public contractNames;                       

     
    event AddressUpdate(bytes32 indexed _contractName, address _contractAddress);

     
    constructor() public {
    }

     
    function itemCount() public view returns (uint256) {
        return contractNames.length;
    }

     
    function addressOf(bytes32 _contractName) public view returns (address) {
        return items[_contractName].contractAddress;
    }

     
    function registerAddress(bytes32 _contractName, address _contractAddress)
        public
        ownerOnly
        validAddress(_contractAddress)
    {
        require(_contractName.length > 0);  

         
        items[_contractName].contractAddress = _contractAddress;
        
        if (!items[_contractName].isSet) {
             
            items[_contractName].isSet = true;
             
            uint256 i = contractNames.push(bytes32ToString(_contractName));
             
            items[_contractName].nameIndex = i - 1;
        }

         
        emit AddressUpdate(_contractName, _contractAddress);
    }

     
    function unregisterAddress(bytes32 _contractName) public ownerOnly {
        require(_contractName.length > 0);  

         
        items[_contractName].contractAddress = address(0);

        if (items[_contractName].isSet) {
             
            items[_contractName].isSet = false;

             
            if (contractNames.length > 1)
                contractNames[items[_contractName].nameIndex] = contractNames[contractNames.length - 1];

             
            contractNames.length--;
             
            items[_contractName].nameIndex = 0;
        }

         
        emit AddressUpdate(_contractName, address(0));
    }

     
    function bytes32ToString(bytes32 _bytes) private pure returns (string) {
        bytes memory byteArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            byteArray[i] = _bytes[i];
        }

        return string(byteArray);
    }

     
    function getAddress(bytes32 _contractName) public view returns (address) {
        return addressOf(_contractName);
    }
}