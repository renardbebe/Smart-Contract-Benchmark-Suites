 

pragma solidity ^0.4.13;

contract EthicHubStorage {

	mapping(bytes32 => uint256) internal uintStorage;
	mapping(bytes32 => string) internal stringStorage;
	mapping(bytes32 => address) internal addressStorage;
	mapping(bytes32 => bytes) internal bytesStorage;
	mapping(bytes32 => bool) internal boolStorage;
	mapping(bytes32 => int256) internal intStorage;



     

     
    modifier onlyEthicHubContracts() {
         
        require(addressStorage[keccak256("contract.address", msg.sender)] != 0x0);
        _;
    }

    constructor() public {
		addressStorage[keccak256("contract.address", msg.sender)] = msg.sender;
    }

	 

	 
	function getAddress(bytes32 _key) external view returns (address) {
		return addressStorage[_key];
	}

	 
	function getUint(bytes32 _key) external view returns (uint) {
		return uintStorage[_key];
	}

	 
	function getString(bytes32 _key) external view returns (string) {
		return stringStorage[_key];
	}

	 
	function getBytes(bytes32 _key) external view returns (bytes) {
		return bytesStorage[_key];
	}

	 
	function getBool(bytes32 _key) external view returns (bool) {
		return boolStorage[_key];
	}

	 
	function getInt(bytes32 _key) external view returns (int) {
		return intStorage[_key];
	}

	 

	 
	function setAddress(bytes32 _key, address _value) onlyEthicHubContracts external {
		addressStorage[_key] = _value;
	}

	 
	function setUint(bytes32 _key, uint _value) onlyEthicHubContracts external {
		uintStorage[_key] = _value;
	}

	 
	function setString(bytes32 _key, string _value) onlyEthicHubContracts external {
		stringStorage[_key] = _value;
	}

	 
	function setBytes(bytes32 _key, bytes _value) onlyEthicHubContracts external {
		bytesStorage[_key] = _value;
	}

	 
	function setBool(bytes32 _key, bool _value) onlyEthicHubContracts external {
		boolStorage[_key] = _value;
	}

	 
	function setInt(bytes32 _key, int _value) onlyEthicHubContracts external {
		intStorage[_key] = _value;
	}

	 

	 
	function deleteAddress(bytes32 _key) onlyEthicHubContracts external {
		delete addressStorage[_key];
	}

	 
	function deleteUint(bytes32 _key) onlyEthicHubContracts external {
		delete uintStorage[_key];
	}

	 
	function deleteString(bytes32 _key) onlyEthicHubContracts external {
		delete stringStorage[_key];
	}

	 
	function deleteBytes(bytes32 _key) onlyEthicHubContracts external {
		delete bytesStorage[_key];
	}

	 
	function deleteBool(bytes32 _key) onlyEthicHubContracts external {
		delete boolStorage[_key];
	}

	 
	function deleteInt(bytes32 _key) onlyEthicHubContracts external {
		delete intStorage[_key];
	}

}