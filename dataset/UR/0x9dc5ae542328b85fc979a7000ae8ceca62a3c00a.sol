 

pragma solidity ^0.4.24;

 
contract Registrar {
	address private contractOwner;
	bool public paused;

	struct Manifest {
		address registrant;
		bytes32 name;
		uint256 version;
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
	mapping(bytes32 => uint256) private registrantNameVersionCount;
	mapping(bytes32 => uint256) public hashTypeIdLookup;
	mapping(uint256 => HashType) public hashTypes;
	
	  
	event LogManifest(address indexed registrant, bytes32 indexed name, uint256 indexed version, bytes32 hashTypeName, string checksum);

     
	modifier onlyContractOwner {
		require(msg.sender == contractOwner);
		_;
	}

     
	modifier contractIsActive {
		require(paused == false);
		_;
	}

     
    modifier manifestIsValid(bytes32 name, bytes32 hashTypeName, string checksum, address registrant) {
        require(name != bytes32(0x0) && 
            hashTypes[hashTypeIdLookup[hashTypeName]].active == true &&
            bytes(checksum).length != 0 &&
            registrant != address(0x0) &&
            manifests[keccak256(abi.encodePacked(registrant, name, nextVersion(registrant, name)))].name == bytes32(0x0)
            );
        _;
    }
    
	 
	constructor() public {
		contractOwner = msg.sender;
		addHashType('sha256');
	}

     
     
     
    
     
    function addHashType(bytes32 _name) public onlyContractOwner {
        require(hashTypeIdLookup[_name] == 0);
        numHashTypes++;
        hashTypeIdLookup[_name] = numHashTypes;
        HashType storage _hashType = hashTypes[numHashTypes];
        
         
        _hashType.name = _name;
        _hashType.active = true;
    }
    
	 
	function setActiveHashType(bytes32 _name, bool _active) public onlyContractOwner {
        require(hashTypeIdLookup[_name] > 0);
        hashTypes[hashTypeIdLookup[_name]].active = _active;
	}

     
	function setPaused(bool _paused) public onlyContractOwner {
		paused = _paused;
	}
    
     
    function kill() public onlyContractOwner {
		selfdestruct(contractOwner);
	}

     
     
     
	 
	function nextVersion(address _registrant, bytes32 _name) public view returns (uint256) {
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(_registrant, _name));
	    return (registrantNameVersionCount[registrantNameIndex] + 1);
	}
	
	 
	function register(bytes32 _name, bytes32 _hashTypeName, string _checksum) public 
	    contractIsActive
	    manifestIsValid(_name, _hashTypeName, _checksum, msg.sender) {

	     
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(msg.sender, _name));
	    
	     
	    registrantNameVersionCount[registrantNameIndex]++;
	    
	     
	    bytes32 manifestId = keccak256(abi.encodePacked(msg.sender, _name, registrantNameVersionCount[registrantNameIndex]));
	    
        Manifest storage _manifest = manifests[manifestId];
        
         
        _manifest.registrant = msg.sender;
        _manifest.name = _name;
        _manifest.version = registrantNameVersionCount[registrantNameIndex];
        _manifest.index = registrantNameManifests[registrantNameIndex].length;
        _manifest.hashTypeName = _hashTypeName;
        _manifest.checksum = _checksum;
        _manifest.createdOn = now;
        
        registrantManifests[msg.sender].push(manifestId);
        registrantNameManifests[registrantNameIndex].push(manifestId);

	    emit LogManifest(msg.sender, _manifest.name, _manifest.version, _manifest.hashTypeName, _manifest.checksum);
	}

     
	function getManifest(address _registrant, bytes32 _name, uint256 _version) public view 
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	        
	    bytes32 manifestId = keccak256(abi.encodePacked(_registrant, _name, _version));
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

     
	function getManifestById(bytes32 _manifestId) public view
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	    require(manifests[_manifestId].name != bytes32(0x0));

	    Manifest memory _manifest = manifests[_manifestId];
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

     
	function getLatestManifestByName(address _registrant, bytes32 _name) public view
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	        
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(_registrant, _name));
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
	
	 
	function getLatestManifest(address _registrant) public view
	    returns (address, bytes32, uint256, uint256, bytes32, string, uint256) {
	    require(registrantManifests[_registrant].length > 0);
	    
	    bytes32 manifestId = registrantManifests[_registrant][registrantManifests[_registrant].length - 1];
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
	
	 
	function getManifestIdsByRegistrant(address _registrant) public view returns (bytes32[]) {
	    return registrantManifests[_registrant];
	}

     
	function getManifestIdsByName(address _registrant, bytes32 _name) public view returns (bytes32[]) {
	    bytes32 registrantNameIndex = keccak256(abi.encodePacked(_registrant, _name));
	    return registrantNameManifests[registrantNameIndex];
	}
	
	 
	function getManifestId(address _registrant, bytes32 _name, uint256 _version) public view returns (bytes32) {
	    bytes32 manifestId = keccak256(abi.encodePacked(_registrant, _name, _version));
	    require(manifests[manifestId].name != bytes32(0x0));
	    return manifestId;
	}
}