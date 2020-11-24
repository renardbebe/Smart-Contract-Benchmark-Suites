 

pragma solidity ^0.4.24;

 

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

     
    constructor() public { owner = msg.sender; }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
    function transferOwnership(address newOwner) public onlyOwner {
       require(newOwner != address(0));
       emit OwnershipTransferred(owner, newOwner);
       owner = newOwner;
    }
}

 

contract Destructible is Ownable {
	function selfDestruct() public onlyOwner {
		selfdestruct(owner);
	}
}

 

contract ZapCoordinatorInterface is Ownable {
	function addImmutableContract(string contractName, address newAddress) external;
	function updateContract(string contractName, address newAddress) external;
	function getContractName(uint index) public view returns (string);
	function getContract(string contractName) public view returns (address);
	function updateAllDependencies() external;
}

 

pragma solidity ^0.4.24;

contract Upgradable {

	address coordinatorAddr;
	ZapCoordinatorInterface coordinator;

	constructor(address c) public{
		coordinatorAddr = c;
		coordinator = ZapCoordinatorInterface(c);
	}

    function updateDependencies() external coordinatorOnly {
       _updateDependencies();
    }

    function _updateDependencies() internal;

    modifier coordinatorOnly() {
    	require(msg.sender == coordinatorAddr, "Error: Coordinator Only Function");
    	_;
    }
}

 

contract DatabaseInterface is Ownable {
	function setStorageContract(address _storageContract, bool _allowed) public;
	 
	function getBytes32(bytes32 key) external view returns(bytes32);
	function setBytes32(bytes32 key, bytes32 value) external;
	 
	function getNumber(bytes32 key) external view returns(uint256);
	function setNumber(bytes32 key, uint256 value) external;
	 
	function getBytes(bytes32 key) external view returns(bytes);
	function setBytes(bytes32 key, bytes value) external;
	 
	function getString(bytes32 key) external view returns(string);
	function setString(bytes32 key, string value) external;
	 
	function getBytesArray(bytes32 key) external view returns (bytes32[]);
	function getBytesArrayIndex(bytes32 key, uint256 index) external view returns (bytes32);
	function getBytesArrayLength(bytes32 key) external view returns (uint256);
	function pushBytesArray(bytes32 key, bytes32 value) external;
	function setBytesArrayIndex(bytes32 key, uint256 index, bytes32 value) external;
	function setBytesArray(bytes32 key, bytes32[] value) external;
	 
	function getIntArray(bytes32 key) external view returns (int[]);
	function getIntArrayIndex(bytes32 key, uint256 index) external view returns (int);
	function getIntArrayLength(bytes32 key) external view returns (uint256);
	function pushIntArray(bytes32 key, int value) external;
	function setIntArrayIndex(bytes32 key, uint256 index, int value) external;
	function setIntArray(bytes32 key, int[] value) external;
	 
	function getAddressArray(bytes32 key) external view returns (address[]);
	function getAddressArrayIndex(bytes32 key, uint256 index) external view returns (address);
	function getAddressArrayLength(bytes32 key) external view returns (uint256);
	function pushAddressArray(bytes32 key, address value) external;
	function setAddressArrayIndex(bytes32 key, uint256 index, address value) external;
	function setAddressArray(bytes32 key, address[] value) external;
}

 

 

contract RegistryInterface {
    function initiateProvider(uint256, bytes32) public returns (bool);
    function initiateProviderCurve(bytes32, int256[], address) public returns (bool);
    function setEndpointParams(bytes32, bytes32[]) public;
    function getEndpointParams(address, bytes32) public view returns (bytes32[]);
    function getProviderPublicKey(address) public view returns (uint256);
    function getProviderTitle(address) public view returns (bytes32);
    function setProviderParameter(bytes32, bytes) public;
    function getProviderParameter(address, bytes32) public view returns (bytes);
    function getAllProviderParams(address) public view returns (bytes32[]);
    function getProviderCurveLength(address, bytes32) public view returns (uint256);
    function getProviderCurve(address, bytes32) public view returns (int[]);
    function isProviderInitiated(address) public view returns (bool);
    function getAllOracles() external view returns (address[]);
    function getProviderEndpoints(address) public view returns (bytes32[]);
    function getEndpointBroker(address, bytes32) public view returns (address);
}

 

 





contract Registry is Destructible, RegistryInterface, Upgradable {

    event NewProvider(
        address indexed provider,
        bytes32 indexed title
    );

    event NewCurve(
        address indexed provider,
        bytes32 indexed endpoint,
        int[] curve,
        address indexed broker
    );

    DatabaseInterface public db;

    constructor(address c) Upgradable(c) public {
        _updateDependencies();
    }

    function _updateDependencies() internal {
        address databaseAddress = coordinator.getContract("DATABASE");
        db = DatabaseInterface(databaseAddress);
    }

     
     
     
     
    function initiateProvider(
        uint256 publicKey,
        bytes32 title
    )
        public
        returns (bool)
    {
        require(!isProviderInitiated(msg.sender), "Error: Provider is already initiated");
        createOracle(msg.sender, publicKey, title);
        addOracle(msg.sender);
        emit NewProvider(msg.sender, title);
        return true;
    }

     
     
     
     
     
    function initiateProviderCurve(
        bytes32 endpoint,
        int256[] curve,
        address broker
    )
        returns (bool)
    {
         
        require(isProviderInitiated(msg.sender), "Error: Provider is not yet initiated");
         
        require(getCurveUnset(msg.sender, endpoint), "Error: Curve is already set");

        setCurve(msg.sender, endpoint, curve);        
        db.pushBytesArray(keccak256(abi.encodePacked('oracles', msg.sender, 'endpoints')), endpoint);
        db.setBytes32(keccak256(abi.encodePacked('oracles', msg.sender, endpoint, 'broker')), bytes32(broker));

        emit NewCurve(msg.sender, endpoint, curve, broker);

        return true;
    }

     
    function setProviderParameter(bytes32 key, bytes value) public {
         
        require(isProviderInitiated(msg.sender), "Error: Provider is not yet initiated");

        if(!isProviderParamInitialized(msg.sender, key)){
             
            db.setNumber(keccak256(abi.encodePacked('oracles', msg.sender, 'is_param_set', key)), 1);
            db.pushBytesArray(keccak256(abi.encodePacked('oracles', msg.sender, 'providerParams')), key);
        }
        db.setBytes(keccak256(abi.encodePacked('oracles', msg.sender, 'providerParams', key)), value);
    }

     
    function getProviderParameter(address provider, bytes32 key) public view returns (bytes){
         
        require(isProviderInitiated(provider), "Error: Provider is not yet initiated");
        require(isProviderParamInitialized(provider, key), "Error: Provider Parameter is not yet initialized");
        return db.getBytes(keccak256(abi.encodePacked('oracles', provider, 'providerParams', key)));
    }

     
    function getAllProviderParams(address provider) public view returns (bytes32[]){
         
        require(isProviderInitiated(provider), "Error: Provider is not yet initiated");
        return db.getBytesArray(keccak256(abi.encodePacked('oracles', provider, 'providerParams')));
    }

     
    function setEndpointParams(bytes32 endpoint, bytes32[] endpointParams) public {
         
        require(isProviderInitiated(msg.sender), "Error: Provider is not yet initialized");
         
        require(!getCurveUnset(msg.sender, endpoint), "Error: Curve is not yet set");

        db.setBytesArray(keccak256(abi.encodePacked('oracles', msg.sender, 'endpointParams', endpoint)), endpointParams);
    }

     
    function getProviderPublicKey(address provider) public view returns (uint256) {
        return getPublicKey(provider);
    }

     
    function getProviderTitle(address provider) public view returns (bytes32) {
        return getTitle(provider);
    }


     
    function getProviderCurve(
        address provider,
        bytes32 endpoint
    )
        public
        view
        returns (int[])
    {
        require(!getCurveUnset(provider, endpoint), "Error: Curve is not yet set");
        return db.getIntArray(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint)));
    }

    function getProviderCurveLength(address provider, bytes32 endpoint) public view returns (uint256){
        require(!getCurveUnset(provider, endpoint), "Error: Curve is not yet set");
        return db.getIntArray(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint))).length;
    }

     
     
     
    function isProviderInitiated(address oracleAddress) public view returns (bool) {
        return getProviderTitle(oracleAddress) != 0;
    }

     
     
    function getPublicKey(address provider) public view returns (uint256) {
        return db.getNumber(keccak256(abi.encodePacked("oracles", provider, "publicKey")));
    }

     
    function getTitle(address provider) public view returns (bytes32) {
        return db.getBytes32(keccak256(abi.encodePacked("oracles", provider, "title")));
    }

     
    function getProviderEndpoints(address provider) public view returns (bytes32[]) {
        return db.getBytesArray(keccak256(abi.encodePacked("oracles", provider, "endpoints")));
    }

     
    function getEndpointParams(address provider, bytes32 endpoint) public view returns (bytes32[]) {
        return db.getBytesArray(keccak256(abi.encodePacked('oracles', provider, 'endpointParams', endpoint)));
    }

     
    function getEndpointBroker(address oracleAddress, bytes32 endpoint) public view returns (address) {
        return address(db.getBytes32(keccak256(abi.encodePacked('oracles', oracleAddress, endpoint, 'broker'))));
    }

    function getCurveUnset(address provider, bytes32 endpoint) public view returns (bool) {
        return db.getIntArrayLength(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint))) == 0;
    }

     
    function getOracleAddress(uint256 index) public view returns (address) {
        return db.getAddressArrayIndex(keccak256(abi.encodePacked('oracleIndex')), index);
    }

     
    function getAllOracles() external view returns (address[]) {
        return db.getAddressArray(keccak256(abi.encodePacked('oracleIndex')));
    }

     
    function createOracle(address provider, uint256 publicKey, bytes32 title) private {
        db.setNumber(keccak256(abi.encodePacked('oracles', provider, "publicKey")), uint256(publicKey));
        db.setBytes32(keccak256(abi.encodePacked('oracles', provider, "title")), title);
    }

     
    function addOracle(address provider) private {
        db.pushAddressArray(keccak256(abi.encodePacked('oracleIndex')), provider);
    }

     
     
     
     
    function setCurve(
        address provider,
        bytes32 endpoint,
        int[] curve
    )
        private
    {
        uint prevEnd = 1;
        uint index = 0;

         
        while ( index < curve.length ) {
             
            int len = curve[index];
            require(len > 0, "Error: Invalid Curve");

             
            uint endIndex = index + uint(len) + 1;
            require(endIndex < curve.length, "Error: Invalid Curve");

             
            int end = curve[endIndex];
            require(uint(end) > prevEnd, "Error: Invalid Curve");

            prevEnd = uint(end);
            index += uint(len) + 2; 
        }

        db.setIntArray(keccak256(abi.encodePacked('oracles', provider, 'curves', endpoint)), curve);
    }

     
    function isProviderParamInitialized(address provider, bytes32 key) private view returns (bool){
        uint256 val = db.getNumber(keccak256(abi.encodePacked('oracles', provider, 'is_param_set', key)));
        return (val == 1) ? true : false;
    }

     
}