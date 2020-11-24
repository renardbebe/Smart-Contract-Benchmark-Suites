 

pragma solidity 0.4.24;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}











 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}









 
contract ContractManager is Ownable {

    event VersionAdded(
        string contractName,
        string versionName,
        address indexed implementation
    );

    event VersionUpdated(
        string contractName,
        string versionName,
        Status status,
        BugLevel bugLevel
    );

    event VersionRecommended(string contractName, string versionName);

    event RecommendedVersionRemoved(string contractName);

     
    enum Status {BETA, RC, PRODUCTION, DEPRECATED}

     
    enum BugLevel {NONE, LOW, MEDIUM, HIGH, CRITICAL}

     
    struct Version {
         
        string versionName;

        Status status;

        BugLevel bugLevel;
         
        address implementation;
         
        uint256 dateAdded;
    }

     
    string[] internal contracts;

     
    mapping(string=>bool) internal contractExists;

     
    mapping(string=>string[]) internal contractVsVersionString;

     
    mapping(string=>mapping(string=>Version)) internal contractVsVersions;

     
    mapping(string=>string) internal contractVsRecommendedVersion;

    modifier nonZeroAddress(address _address) {
        require(
            _address != address(0),
            "The provided address is the 0 address"
        );
        _;
    }

    modifier contractRegistered(string contractName) {

        require(contractExists[contractName], "Contract does not exists");
        _;
    }

    modifier versionExists(string contractName, string versionName) {
        require(
            contractVsVersions[contractName][versionName].implementation != address(0),
            "Version does not exists for contract"
        );
        _;
    }

     
    function addVersion(
        string contractName,
        string versionName,
        Status status,
        address implementation
    )
        external
        onlyOwner
        nonZeroAddress(implementation)
    {
         
        require(bytes(versionName).length>0, "Empty string passed as version");

         
        require(
            bytes(contractName).length>0,
            "Empty string passed as contract name"
        );

         
        require(
            Address.isContract(implementation),
            "Cannot set an implementation to a non-contract address"
        );

        if (!contractExists[contractName]) {
            contracts.push(contractName);
            contractExists[contractName] = true;
        }

         
         
        require(
            contractVsVersions[contractName][versionName].implementation == address(0),
            "Version already exists for contract"
        );
        contractVsVersionString[contractName].push(versionName);

        contractVsVersions[contractName][versionName] = Version({
            versionName:versionName,
            status:status,
            bugLevel:BugLevel.NONE,
            implementation:implementation,
            dateAdded:block.timestamp
        });

        emit VersionAdded(contractName, versionName, implementation);
    }

     
    function updateVersion(
        string contractName,
        string versionName,
        Status status,
        BugLevel bugLevel
    )
        external
        onlyOwner
        contractRegistered(contractName)
        versionExists(contractName, versionName)
    {

        contractVsVersions[contractName][versionName].status = status;
        contractVsVersions[contractName][versionName].bugLevel = bugLevel;

        emit VersionUpdated(
            contractName,
            versionName,
            status,
            bugLevel
        );
    }

     
    function markRecommendedVersion(
        string contractName,
        string versionName
    )
        external
        onlyOwner
        contractRegistered(contractName)
        versionExists(contractName, versionName)
    {
         
        contractVsRecommendedVersion[contractName] = versionName;

        emit VersionRecommended(contractName, versionName);
    }

     
    function getRecommendedVersion(
        string contractName
    )
        external
        view
        contractRegistered(contractName)
        returns (
            string versionName,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
        )
    {
        versionName = contractVsRecommendedVersion[contractName];

        Version storage recommendedVersion = contractVsVersions[
            contractName
        ][
            versionName
        ];

        status = recommendedVersion.status;
        bugLevel = recommendedVersion.bugLevel;
        implementation = recommendedVersion.implementation;
        dateAdded = recommendedVersion.dateAdded;

        return (
            versionName,
            status,
            bugLevel,
            implementation,
            dateAdded
        );
    }

     
    function removeRecommendedVersion(string contractName)
        external
        onlyOwner
        contractRegistered(contractName)
    {
         
        delete contractVsRecommendedVersion[contractName];

        emit RecommendedVersionRemoved(contractName);
    }

     
    function getTotalContractCount() external view returns (uint256 count) {
        count = contracts.length;
        return count;
    }

     
    function getVersionCountForContract(string contractName)
        external
        view
        returns (uint256 count)
    {
        count = contractVsVersionString[contractName].length;
        return count;
    }

     
    function getContractAtIndex(uint256 index)
        external
        view
        returns (string contractName)
    {
        contractName = contracts[index];
        return contractName;
    }

     
    function getVersionAtIndex(string contractName, uint256 index)
        external
        view
        returns (string versionName)
    {
        versionName = contractVsVersionString[contractName][index];
        return versionName;
    }

     
    function getVersionDetails(string contractName, string versionName)
        external
        view
        returns (
            string versionString,
            Status status,
            BugLevel bugLevel,
            address implementation,
            uint256 dateAdded
        )
    {
        Version storage v = contractVsVersions[contractName][versionName];

        versionString = v.versionName;
        status = v.status;
        bugLevel = v.bugLevel;
        implementation = v.implementation;
        dateAdded = v.dateAdded;

        return (
            versionString,
            status,
            bugLevel,
            implementation,
            dateAdded
        );
    }
}