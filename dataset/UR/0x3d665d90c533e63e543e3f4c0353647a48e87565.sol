 

 

pragma solidity ^0.4.23;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    constructor () public { owner = msg.sender; }

    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) public ownerOnly {
        require(_newOwner != owner && _newOwner != address(0));
        emit OwnerUpdate(owner, _newOwner);
        owner = _newOwner;
        newOwner = address(0);
    }

    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 

pragma solidity ^0.4.23;

 
contract Utils {

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
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

 

pragma solidity ^0.4.23;

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);
}

 

pragma solidity ^0.4.23;

contract ContractIds {
    bytes32 public constant STABLE_TOKEN = "StableToken";
    bytes32 public constant COLLATERAL_TOKEN = "CollateralToken";

    bytes32 public constant PEGUSD_TOKEN = "PEGUSD";

    bytes32 public constant VAULT_A = "VaultA";
    bytes32 public constant VAULT_B = "VaultB";

    bytes32 public constant PEG_LOGIC = "PegLogic";
    bytes32 public constant PEG_LOGIC_ACTIONS = "LogicActions";
    bytes32 public constant AUCTION_ACTIONS = "AuctionActions";

    bytes32 public constant PEG_SETTINGS = "PegSettings";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant FEE_RECIPIENT = "StabilityFeeRecipient";
}

 

pragma solidity ^0.4.23;





 
contract ContractRegistry is IContractRegistry, Owned, Utils, ContractIds {
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

     
    function stringToBytes32(string _string) private pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(_string,32))
        }
        return result;
    }
}