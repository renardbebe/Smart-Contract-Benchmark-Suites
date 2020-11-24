 

pragma solidity ^0.4.23;

 
contract IngressRegistrar {
	address private owner;
	bool public paused;

	struct Manifest {
		address registrant;
		bytes32 name;
		bytes32 version;
		uint256 index;
		bytes32 hashTypeName;
		string checksum;
		uint256 createdOn;
	}
	
	struct HashType {
	    bytes32 name;
	    bool active;
	}
	
	uint256 public numHashTypes;
	mapping(bytes32 => Manifest) private manifests;
	mapping(address => bytes32[]) private registrantManifests;
	mapping(bytes32 => bytes32[]) private registrantNameManifests;
	mapping(bytes32 => uint256) public hashTypeIdLookup;
	mapping(uint256 => HashType) public hashTypes;
	
	  
	event LogManifest(address indexed registrant, bytes32 indexed name, bytes32 indexed version, bytes32 hashTypeName, string checksum);

     
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

     
	modifier contractIsActive {
		require(paused == false);
		_;
	}

     
    modifier manifestIsValid(bytes32 name, bytes32 version, bytes32 hashTypeName, string checksum, address registrant) {
        require(name != bytes32(0x0) && 
            version != bytes32(0x0) && 
            hashTypes[hashTypeIdLookup[hashTypeName]].active == true &&
            bytes(checksum).length != 0 &&
            registrant != address(0x0) &&
            manifests[keccak256(registrant, name, version)].name == bytes32(0x0)
            );
        _;
    }
    
	 
	constructor() public {
		owner = msg.sender;
		addHashType('md5');
		addHashType('sha1');
	}

     
     
     
    
     
    function addHashType(bytes32 name) public onlyOwner {
        require(hashTypeIdLookup[name] == 0);
        numHashTypes++;
        hashTypeIdLookup[name] = numHashTypes;
        HashType storage _hashType = hashTypes[numHashTypes];
        
         
        _hashType.name = name;
        _hashType.active = true;
    }
    
	 
	function setActiveHashType(bytes32 name, bool active) public onlyOwner {
        require(hashTypeIdLookup[name] > 0);
        hashTypes[hashTypeIdLookup[name]].active = active;
	}
    
     
    function kill() public onlyOwner {
		selfdestruct(owner);
	}

     
	function setPaused(bool _paused) public onlyOwner {
		paused = _paused;
	}
	
     
     
     
	
	 
	function register(bytes32 name, bytes32 version, bytes32 hashTypeName, string checksum) public 
	    contractIsActive
	    manifestIsValid(name, version, hashTypeName, checksum, msg.sender) {
	    
	     
	    bytes32 manifestId = keccak256(msg.sender, name, version);
	    
	     
	    bytes32 registrantNameIndex = keccak256(msg.sender, name);

        Manifest storage _manifest = manifests[manifestId];
        
         
        _manifest.registrant = msg.sender;
        _manifest.name = name;
        _manifest.version = version;
        _manifest.index = registrantNameManifests[registrantNameIndex].length;
        _manifest.hashTypeName = hashTypeName;
        _manifest.checksum = checksum;
        _manifest.createdOn = now;
        
        registrantManifests[msg.sender].push(manifestId);
        registrantNameManifests[registrantNameIndex].push(manifestId);

	    emit LogManifest(msg.sender, name, version, hashTypeName, checksum);
	}

     
	function getManifest(address registrant, bytes32 name, bytes32 version) public view 
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
	        
	    bytes32 manifestId = keccak256(registrant, name, version);
	    require(manifests[manifestId].name != bytes32(0x0));

	    Manifest memory _manifest = manifests[manifestId];
	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}

     
	function getManifestById(bytes32 manifestId) public view
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
	    require(manifests[manifestId].name != bytes32(0x0));

	    Manifest memory _manifest = manifests[manifestId];
	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}

     
	function getLatestManifestByName(address registrant, bytes32 name) public view
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
	        
	    bytes32 registrantNameIndex = keccak256(registrant, name);
	    require(registrantNameManifests[registrantNameIndex].length > 0);
	    
	    bytes32 manifestId = registrantNameManifests[registrantNameIndex][registrantNameManifests[registrantNameIndex].length - 1];
	    Manifest memory _manifest = manifests[manifestId];

	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}
	
	 
	function getLatestManifest(address registrant) public view
	    returns (address, bytes32, bytes32, uint256, bytes32, string, uint256) {
	    require(registrantManifests[registrant].length > 0);
	    
	    bytes32 manifestId = registrantManifests[registrant][registrantManifests[registrant].length - 1];
	    Manifest memory _manifest = manifests[manifestId];

	    return (
	        _manifest.registrant,
	        _manifest.name,
	        _manifest.version,
	        _manifest.index,
	        _manifest.hashTypeName,
	        _manifest.checksum,
	        _manifest.createdOn
	   );
	}
	
	 
	function getManifestIdsByRegistrant(address registrant) public view returns (bytes32[]) {
	    return registrantManifests[registrant];
	}

     
	function getManifestIdsByName(address registrant, bytes32 name) public view returns (bytes32[]) {
	    bytes32 registrantNameIndex = keccak256(registrant, name);
	    return registrantNameManifests[registrantNameIndex];
	}
	
	 
	function getManifestId(address registrant, bytes32 name, bytes32 version) public view returns (bytes32) {
	    bytes32 manifestId = keccak256(registrant, name, version);
	    require(manifests[manifestId].name != bytes32(0x0));
	    return manifestId;
	}
}