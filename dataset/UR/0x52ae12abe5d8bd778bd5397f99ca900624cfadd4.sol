 

pragma solidity ^0.4.24;

 

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
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

 

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

     
    function getAddress(bytes32 _contractName) public view returns (address);
}

 

 
contract ContractIds {
     
    bytes32 public constant CONTRACT_FEATURES = "ContractFeatures";
    bytes32 public constant CONTRACT_REGISTRY = "ContractRegistry";

     
    bytes32 public constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 public constant BANCOR_FORMULA = "BancorFormula";
    bytes32 public constant BANCOR_GAS_PRICE_LIMIT = "BancorGasPriceLimit";
    bytes32 public constant BANCOR_CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 public constant BANCOR_CONVERTER_FACTORY = "BancorConverterFactory";

     
    bytes32 public constant BNT_TOKEN = "BNTToken";
    bytes32 public constant BNT_CONVERTER = "BNTConverter";

     
    bytes32 public constant BANCOR_X = "BancorX";
}

 

 
contract ContractRegistry is IContractRegistry, Owned, Utils, ContractIds {
    struct RegistryItem {
        address contractAddress;     
        uint256 nameIndex;           
        bool isSet;                  
    }

    mapping (bytes32 => RegistryItem) private items;     
    string[] public contractNames;                       

     
    event AddressUpdate(bytes32 indexed _contractName, address _contractAddress);

     
    constructor() public {
        registerAddress(ContractIds.CONTRACT_REGISTRY, address(this));
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

         
         
        if (contractNames.length > 1) {
            string memory lastContractNameString = contractNames[contractNames.length - 1];
            uint256 unregisterIndex = items[_contractName].nameIndex;

            contractNames[unregisterIndex] = lastContractNameString;
            bytes32 lastContractName = stringToBytes32(lastContractNameString);
            RegistryItem storage registryItem = items[lastContractName];
            registryItem.nameIndex = unregisterIndex;
        }

         
        contractNames.length--;
         
        items[_contractName].nameIndex = 0;

         
        emit AddressUpdate(_contractName, address(0));
    }

     
    function bytes32ToString(bytes32 _bytes) private pure returns (string) {
        bytes memory byteArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            byteArray[i] = _bytes[i];
        }

        return string(byteArray);
    }

     
    function stringToBytes32(string memory _string) private pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(_string,32))
        }
        return result;
    }

     
    function getAddress(bytes32 _contractName) public view returns (address) {
        return addressOf(_contractName);
    }
}