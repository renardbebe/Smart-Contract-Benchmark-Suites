 

 

pragma solidity 0.4.26;

 
contract IOwned {
     
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

pragma solidity 0.4.26;

 
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

 

pragma solidity 0.4.26;

 
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

}

 

pragma solidity 0.4.26;

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

     
    function getAddress(bytes32 _contractName) public view returns (address);
}

 

pragma solidity 0.4.26;



 
contract ContractRegistry is IContractRegistry, Owned, Utils {
    struct RegistryItem {
        address contractAddress;     
        uint256 nameIndex;           
    }

    mapping (bytes32 => RegistryItem) private items;     
    string[] public contractNames;                       

     
    event AddressUpdate(bytes32 indexed _contractName, address _contractAddress);

     
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

        if (items[_contractName].contractAddress == address(0)) {
             
            uint256 i = contractNames.push(bytes32ToString(_contractName));
             
            items[_contractName].nameIndex = i - 1;
        }

         
        items[_contractName].contractAddress = _contractAddress;

         
        emit AddressUpdate(_contractName, _contractAddress);
    }

     
    function unregisterAddress(bytes32 _contractName) public ownerOnly {
        require(_contractName.length > 0);  
        require(items[_contractName].contractAddress != address(0));

         
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