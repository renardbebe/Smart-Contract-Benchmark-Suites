 

pragma solidity ^0.4.19;

 

 
contract RocketStorageInterface {
     
    modifier onlyLatestRocketNetworkContract() {_;}
     
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string);
    function getBytes(bytes32 _key) external view returns (bytes);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
     
    function setAddress(bytes32 _key, address _value) onlyLatestRocketNetworkContract external;
    function setUint(bytes32 _key, uint _value) onlyLatestRocketNetworkContract external;
    function setString(bytes32 _key, string _value) onlyLatestRocketNetworkContract external;
    function setBytes(bytes32 _key, bytes _value) onlyLatestRocketNetworkContract external;
    function setBool(bytes32 _key, bool _value) onlyLatestRocketNetworkContract external;
    function setInt(bytes32 _key, int _value) onlyLatestRocketNetworkContract external;
     
    function deleteAddress(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteUint(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteString(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBytes(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBool(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteInt(bytes32 _key) onlyLatestRocketNetworkContract external;
     
    function kcck256str(string _key1) external pure returns (bytes32);
    function kcck256strstr(string _key1, string _key2) external pure returns (bytes32);
    function kcck256stradd(string _key1, address _key2) external pure returns (bytes32);
    function kcck256straddadd(string _key1, address _key2, address _key3) external pure returns (bytes32);
}

 

 
 
contract RocketBase {

     

    event ContractAdded (
        address indexed _newContractAddress,                     
        uint256 created                                          
    );

    event ContractUpgraded (
        address indexed _oldContractAddress,                     
        address indexed _newContractAddress,                     
        uint256 created                                          
    );

     

    uint8 public version;                                                    


     

    RocketStorageInterface rocketStorage = RocketStorageInterface(0);        


     

     
    modifier onlyOwner() {
        roleCheck("owner", msg.sender);
        _;
    }

     
    modifier onlyAdmin() {
        roleCheck("admin", msg.sender);
        _;
    }

     
    modifier onlySuperUser() {
        require(roleHas("owner", msg.sender) || roleHas("admin", msg.sender));
        _;
    }

     
    modifier onlyRole(string _role) {
        roleCheck(_role, msg.sender);
        _;
    }

  
     
   
     
    constructor(address _rocketStorageAddress) public {
         
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }


     

     
    function isOwner(address _address) public view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", "owner", _address));
    }

     
    function roleHas(string _role, address _address) internal view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", _role, _address));
    }

      
    function roleCheck(string _role, address _address) view internal {
        require(roleHas(_role, _address) == true);
    }

}

 

 

 
 
contract Upgradable is RocketBase {

     

    event ContractUpgraded (
        address indexed _oldContractAddress,                     
        address indexed _newContractAddress,                     
        uint256 created                                          
    );


         

     
    constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
         
        version = 1;
    }

     

     
    function addContract(string _name, address _newContractAddress) onlyOwner external {

         
        address existing_ = rocketStorage.getAddress(keccak256("contract.name", _name));
        require(existing_ == 0x0);
     
         
         
        rocketStorage.setAddress(keccak256("contract.name", _name), _newContractAddress);
         
         
         
        rocketStorage.setAddress(keccak256("contract.address", _newContractAddress), _newContractAddress);
         
        emit ContractAdded(_newContractAddress, now);
    }

     
     
     
    function upgradeContract(string _name, address _upgradedContractAddress) onlyOwner external {
         
        address oldContractAddress = rocketStorage.getAddress(keccak256("contract.name", _name));
         
        require(oldContractAddress != 0x0);
         
        require(oldContractAddress != _upgradedContractAddress);
         
        rocketStorage.setAddress(keccak256("contract.name", _name), _upgradedContractAddress);
         
        rocketStorage.setAddress(keccak256("contract.address", _upgradedContractAddress), _upgradedContractAddress);
         
        rocketStorage.deleteAddress(keccak256("contract.address", oldContractAddress));
         
        emit ContractUpgraded(oldContractAddress, _upgradedContractAddress, now);
    }

}