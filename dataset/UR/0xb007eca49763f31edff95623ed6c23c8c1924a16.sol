 

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

 

contract ZapCoordinator is Ownable, ZapCoordinatorInterface {

	event UpdatedContract(string name, address previousAddr, address newAddr);
	event UpdatedDependencies(uint timestamp, string contractName, address contractAddr);

	mapping(string => address) contracts; 

	 
	string[] public loadedContracts;

	DatabaseInterface public db;

	 
	function addImmutableContract(string contractName, address newAddress) external onlyOwner {
		assert(contracts[contractName] == address(0));
		contracts[contractName] = newAddress;

		 
		bytes32 hash = keccak256(abi.encodePacked(contractName));
		if(hash == keccak256(abi.encodePacked("DATABASE"))) db = DatabaseInterface(newAddress);
	}

	 
	function updateContract(string contractName, address newAddress) external onlyOwner {
		address prev = contracts[contractName];
		if (prev == address(0) ) {
			 
			loadedContracts.push(contractName);
		} else {
			 
			db.setStorageContract(prev, false);
		}
		 
		db.setStorageContract(newAddress, true);

		emit UpdatedContract(contractName, prev, newAddress);
		contracts[contractName] = newAddress;
	}

	function getContractName(uint index) public view returns (string) {
		return loadedContracts[index];
	}

	function getContract(string contractName) public view returns (address) {
		return contracts[contractName];
	}

	function updateAllDependencies() external onlyOwner {
		for ( uint i = 0; i < loadedContracts.length; i++ ) {
			address c = contracts[loadedContracts[i]];
			Upgradable(c).updateDependencies();
			emit UpdatedDependencies(block.timestamp, loadedContracts[i], c);
		}
	}

}