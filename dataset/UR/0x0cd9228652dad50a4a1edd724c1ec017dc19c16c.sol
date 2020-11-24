 

pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract EthicHubStorageInterface {

     
    modifier onlyEthicHubContracts() {_;}

     
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
     
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;

     
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string);
    function getBytes(bytes32 _key) external view returns (bytes);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
}

contract EthicHubReputationInterface {
    modifier onlyUsersContract(){_;}
    modifier onlyLendingContract(){_;}
    function burnReputation(uint delayDays)  external;
    function incrementReputation(uint completedProjectsByTier)  external;
    function initLocalNodeReputation(address localNode)  external;
    function initCommunityReputation(address community)  external;
    function getCommunityReputation(address target) public view returns(uint256);
    function getLocalNodeReputation(address target) public view returns(uint256);
}

contract EthicHubBase {

    uint8 public version;

    EthicHubStorageInterface public ethicHubStorage = EthicHubStorageInterface(0);

    constructor(address _storageAddress) public {
        require(_storageAddress != address(0));
        ethicHubStorage = EthicHubStorageInterface(_storageAddress);
    }

}

contract EthicHubUser is Ownable, EthicHubBase {


    event UserStatusChanged(address target, string profile, bool isRegistered);

    constructor(address _storageAddress)
        EthicHubBase(_storageAddress)
        public
    {
         
        version = 2;
    }

     
    function changeUserStatus(address target, string profile, bool isRegistered)
        internal
        onlyOwner
    {
        require(target != address(0));
        require(bytes(profile).length != 0);
        ethicHubStorage.setBool(keccak256("user", profile, target), isRegistered);
        emit UserStatusChanged(target, profile, isRegistered);
    }


     
    function deleteUserStatus(address target, string profile)
        internal
        onlyOwner
    {
        require(target != address(0));
        require(bytes(profile).length != 0);
        ethicHubStorage.deleteBool(keccak256("user", profile, target));
        emit UserStatusChanged(target, profile, false);
    }


     
    function viewRegistrationStatus(address target, string profile)
        view public
        returns(bool isRegistered)
    {
        require(target != address(0));
        require(bytes(profile).length != 0);
        isRegistered = ethicHubStorage.getBool(keccak256("user", profile, target));
    }

     
    function registerLocalNode(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ethicHubStorage.getBool(keccak256("user", "localNode", target));
        if (!isRegistered) {
            changeUserStatus(target, "localNode", true);
            EthicHubReputationInterface rep = EthicHubReputationInterface (ethicHubStorage.getAddress(keccak256("contract.name", "reputation")));
            rep.initLocalNodeReputation(target);
        }
    }

     
    function unregisterLocalNode(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ethicHubStorage.getBool(keccak256("user", "localNode", target));
        if (isRegistered) {
            deleteUserStatus(target, "localNode");
        }
    }

     
    function registerCommunity(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ethicHubStorage.getBool(keccak256("user", "community", target));
        if (!isRegistered) {
            changeUserStatus(target, "community", true);
            EthicHubReputationInterface rep = EthicHubReputationInterface(ethicHubStorage.getAddress(keccak256("contract.name", "reputation")));
            rep.initCommunityReputation(target);
        }
    }

     
    function unregisterCommunity(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ethicHubStorage.getBool(keccak256("user", "community", target));
        if (isRegistered) {
            deleteUserStatus(target, "community");
        }
    }



     
    function registerInvestor(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        changeUserStatus(target, "investor", true);
    }

     
    function unregisterInvestor(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ethicHubStorage.getBool(keccak256("user", "investor", target));
        if (isRegistered) {
            deleteUserStatus(target, "investor");
        }
    }

     
    function registerRepresentative(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        changeUserStatus(target, "representative", true);
    }

     
    function unregisterRepresentative(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ethicHubStorage.getBool(keccak256("user", "representative", target));
        if (isRegistered) {
            deleteUserStatus(target, "representative");
        }
    }


}