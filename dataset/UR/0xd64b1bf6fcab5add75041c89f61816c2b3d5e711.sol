 

pragma solidity 0.4.25;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}


interface IOrbsGuardians {

    event GuardianRegistered(address indexed guardian);
    event GuardianLeft(address indexed guardian);
    event GuardianUpdated(address indexed guardian);

     
     
     
    function register(string name, string website) external payable;

     
     
     
    function update(string name, string website) external;

     
    function leave() external;

     
     
    function isGuardian(address guardian) external view returns (bool);

     
     
    function getGuardianData(address guardian)
        external
        view
        returns (string name, string website);

     
     
    function getRegistrationBlockNumber(address guardian)
        external
        view
        returns (uint registeredOn, uint lastUpdatedOn);

     
     
     
    function getGuardians(uint offset, uint limit)
        external
        view
        returns (address[]);

     
     
     
    function getGuardiansBytes20(uint offset, uint limit)
        external
        view
        returns (bytes20[]);
}


contract OrbsGuardians is IOrbsGuardians {
    using SafeMath for uint256;

    struct GuardianData {
        string name;
        string website;
        uint index;
        uint registeredOnBlock;
        uint lastUpdatedOnBlock;
        uint registeredOn;
    }

     
    uint public constant VERSION = 1;

     
    uint public registrationDepositWei;
     
    uint public registrationMinTime;

     
    address[] internal guardians;

     
    mapping(address => GuardianData) internal guardiansData;

     
    modifier onlyGuardian() {
        require(isGuardian(msg.sender), "You must be a registered guardian");
        _;
    }

     
    modifier onlyEOA() {
        require(!Address.isContract(msg.sender),"Only EOA may register as Guardian");
        _;
    }

     
     
     
    constructor(uint registrationDepositWei_, uint registrationMinTime_) public {
        require(registrationDepositWei_ > 0, "registrationDepositWei_ must be positive");

        registrationMinTime = registrationMinTime_;
        registrationDepositWei = registrationDepositWei_;
    }

     
     
     
    function register(string name, string website)
        external
        payable
        onlyEOA
    {
        address sender = msg.sender;
        require(bytes(name).length > 0, "Please provide a valid name");
        require(bytes(website).length > 0, "Please provide a valid website");
        require(!isGuardian(sender), "Cannot be a guardian");
        require(msg.value == registrationDepositWei, "Please provide the exact registration deposit");

        uint index = guardians.length;
        guardians.push(sender);
        guardiansData[sender] = GuardianData({
            name: name,
            website: website,
            index: index ,
            registeredOnBlock: block.number,
            lastUpdatedOnBlock: block.number,
            registeredOn: now
        });

        emit GuardianRegistered(sender);
    }

     
     
     
    function update(string name, string website)
        external
        onlyGuardian
        onlyEOA
    {
        address sender = msg.sender;
        require(bytes(name).length > 0, "Please provide a valid name");
        require(bytes(website).length > 0, "Please provide a valid website");


        guardiansData[sender].name = name;
        guardiansData[sender].website = website;
        guardiansData[sender].lastUpdatedOnBlock = block.number;

        emit GuardianUpdated(sender);
    }

     
    function leave() external onlyGuardian onlyEOA {
        address sender = msg.sender;
        require(now >= guardiansData[sender].registeredOn.add(registrationMinTime), "Minimal guardian time didnt pass");

        uint i = guardiansData[sender].index;

        assert(guardians[i] == sender);  

         
        guardians[i] = guardians[guardians.length - 1];  
        guardiansData[guardians[i]].index = i;  
        guardians.length--;  

         
        delete guardiansData[sender];

         
        sender.transfer(registrationDepositWei);

        emit GuardianLeft(sender);
    }

     
     
     
    function getGuardiansBytes20(uint offset, uint limit)
        external
        view
        returns (bytes20[])
    {
        address[] memory guardianAddresses = getGuardians(offset, limit);
        uint guardianAddressesLength = guardianAddresses.length;

        bytes20[] memory result = new bytes20[](guardianAddressesLength);

        for (uint i = 0; i < guardianAddressesLength; i++) {
            result[i] = bytes20(guardianAddresses[i]);
        }

        return result;
    }

     
     
    function getRegistrationBlockNumber(address guardian)
        external
        view
        returns (uint registeredOn, uint lastUpdatedOn)
    {
        require(isGuardian(guardian), "Please provide a listed Guardian");

        GuardianData storage entry = guardiansData[guardian];
        registeredOn = entry.registeredOnBlock;
        lastUpdatedOn = entry.lastUpdatedOnBlock;
    }

     
     
     
    function getGuardians(uint offset, uint limit)
        public
        view
        returns (address[] memory)
    {
        if (offset >= guardians.length) {  
            return new address[](0);
        }

        if (offset.add(limit) > guardians.length) {  
            limit = guardians.length.sub(offset);
        }

        address[] memory result = new address[](limit);

        uint resultLength = result.length;
        for (uint i = 0; i < resultLength; i++) {
            result[i] = guardians[offset.add(i)];
        }

        return result;
    }

     
     
    function getGuardianData(address guardian)
        public
        view
        returns (string memory name, string memory website)
    {
        require(isGuardian(guardian), "Please provide a listed Guardian");
        name = guardiansData[guardian].name;
        website = guardiansData[guardian].website;
    }

     
     
    function isGuardian(address guardian) public view returns (bool) {
        return guardiansData[guardian].registeredOnBlock > 0;
    }
}