 

pragma solidity 0.4.25;


interface IOrbsValidatorsRegistry {

    event ValidatorLeft(address indexed validator);
    event ValidatorRegistered(address indexed validator);
    event ValidatorUpdated(address indexed validator);

     
     
     
     
     
     
     
     
    function register(
        string name,
        bytes4 ipAddress,
        string website,
        bytes20 orbsAddress
    )
        external;

     
     
     
     
     
     
    function update(
        string name,
        bytes4 ipAddress,
        string website,
        bytes20 orbsAddress
    )
        external;

     
    function leave() external;

     
     
    function getValidatorData(address validator)
        external
        view
        returns (
            string name,
            bytes4 ipAddress,
            string website,
            bytes20 orbsAddress
        );

     
     
     
    function getRegistrationBlockNumber(address validator)
        external
        view
        returns (uint registeredOn, uint lastUpdatedOn);

     
     
     
    function isValidator(address validator) external view returns (bool);

     
     
     
    function getOrbsAddress(address validator)
        external
        view
        returns (bytes20 orbsAddress);
}


 
contract OrbsValidatorsRegistry is IOrbsValidatorsRegistry {

     
    struct ValidatorData {
        string name;
        bytes4 ipAddress;
        string website;
        bytes20 orbsAddress;
        uint registeredOnBlock;
        uint lastUpdatedOnBlock;
    }

     
    uint public constant VERSION = 1;

     
    mapping(address => ValidatorData) internal validatorsData;

     
    mapping(bytes4 => address) public lookupByIp;
    mapping(bytes20 => address) public lookupByOrbsAddr;

     
    modifier onlyValidator() {
        require(isValidator(msg.sender), "You must be a registered validator");
        _;
    }

     
     
     
     
     
     
     
     
    function register(
        string name,
        bytes4 ipAddress,
        string website,
        bytes20 orbsAddress
    )
        external
    {
        address sender = msg.sender;
        require(bytes(name).length > 0, "Please provide a valid name");
        require(bytes(website).length > 0, "Please provide a valid website");
        require(!isValidator(sender), "Validator already exists");
        require(ipAddress != bytes4(0), "Please pass a valid ip address represented as an array of exactly 4 bytes");
        require(orbsAddress != bytes20(0), "Please provide a valid Orbs Address");
        require(lookupByIp[ipAddress] == address(0), "IP address already in use");
        require(lookupByOrbsAddr[orbsAddress] == address(0), "Orbs Address is already in use by another validator");

        lookupByIp[ipAddress] = sender;
        lookupByOrbsAddr[orbsAddress] = sender;

        validatorsData[sender] = ValidatorData({
            name: name,
            ipAddress: ipAddress,
            website: website,
            orbsAddress: orbsAddress,
            registeredOnBlock: block.number,
            lastUpdatedOnBlock: block.number
        });

        emit ValidatorRegistered(sender);
    }

     
     
     
     
     
     
    function update(
        string name,
        bytes4 ipAddress,
        string website,
        bytes20 orbsAddress
    )
        external
        onlyValidator
    {
        address sender = msg.sender;
        require(bytes(name).length > 0, "Please provide a valid name");
        require(bytes(website).length > 0, "Please provide a valid website");
        require(ipAddress != bytes4(0), "Please pass a valid ip address represented as an array of exactly 4 bytes");
        require(orbsAddress != bytes20(0), "Please provide a valid Orbs Address");
        require(isIpFreeToUse(ipAddress), "IP Address is already in use by another validator");
        require(isOrbsAddressFreeToUse(orbsAddress), "Orbs Address is already in use by another validator");

        ValidatorData storage data = validatorsData[sender];

         
        delete lookupByIp[data.ipAddress];
        delete lookupByOrbsAddr[data.orbsAddress];

         
        lookupByIp[ipAddress] = sender;
        lookupByOrbsAddr[orbsAddress] = sender;

        data.name = name;
        data.ipAddress = ipAddress;
        data.website = website;
        data.orbsAddress = orbsAddress;
        data.lastUpdatedOnBlock = block.number;

        emit ValidatorUpdated(sender);
    }

     
    function leave() external onlyValidator {
        address sender = msg.sender;

        ValidatorData storage data = validatorsData[sender];

        delete lookupByIp[data.ipAddress];
        delete lookupByOrbsAddr[data.orbsAddress];

        delete validatorsData[sender];

        emit ValidatorLeft(sender);
    }

     
     
     
    function getRegistrationBlockNumber(address validator)
        external
        view
        returns (uint registeredOn, uint lastUpdatedOn)
    {
        require(isValidator(validator), "Unlisted Validator");

        ValidatorData storage entry = validatorsData[validator];
        registeredOn = entry.registeredOnBlock;
        lastUpdatedOn = entry.lastUpdatedOnBlock;
    }

     
     
     
    function getOrbsAddress(address validator)
        external
        view
        returns (bytes20)
    {
        return validatorsData[validator].orbsAddress;
    }

     
     
    function getValidatorData(address validator)
        public
        view
        returns (
            string memory name,
            bytes4 ipAddress,
            string memory website,
            bytes20 orbsAddress
        )
    {
        ValidatorData storage entry = validatorsData[validator];
        name = entry.name;
        ipAddress = entry.ipAddress;
        website = entry.website;
        orbsAddress = entry.orbsAddress;
    }

     
     
     
    function isValidator(address validator) public view returns (bool) {
        return validatorsData[validator].registeredOnBlock > 0;
    }

     
     
     
    function isIpFreeToUse(bytes4 ipAddress) internal view returns (bool) {
        return
            lookupByIp[ipAddress] == address(0) ||
            lookupByIp[ipAddress] == msg.sender;
    }

     
     
     
    function isOrbsAddressFreeToUse(bytes20 orbsAddress)
        internal
        view
        returns (bool)
    {
        return
            lookupByOrbsAddr[orbsAddress] == address(0) ||
            lookupByOrbsAddr[orbsAddress] == msg.sender;
    }
}