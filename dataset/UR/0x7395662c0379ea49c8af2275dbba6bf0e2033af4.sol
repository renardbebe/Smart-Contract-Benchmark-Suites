 

pragma solidity 0.4.24;


 
contract Ownable {

  mapping(address => bool) public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AllowOwnership(address indexed allowedAddress);
  event RevokeOwnership(address indexed allowedAddress);

   
  constructor() public {
    owner[msg.sender] = true;
  }

   
  modifier onlyOwner() {
    require(owner[msg.sender], "Error: Transaction sender is not allowed by the contract.");
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner returns (bool success) {
    require(newOwner != address(0), "Error: newOwner cannot be null!");
    emit OwnershipTransferred(msg.sender, newOwner);
    owner[newOwner] = true;
    owner[msg.sender] = false;
    return true;
  }

   
  function allowOwnership(address allowedAddress) public onlyOwner returns (bool success) {
    owner[allowedAddress] = true;
    emit AllowOwnership(allowedAddress);
    return true;
  }

   
  function removeOwnership(address allowedAddress) public onlyOwner returns (bool success) {
    owner[allowedAddress] = false;
    emit RevokeOwnership(allowedAddress);
    return true;
  }

}


 
contract TokenIOStorage is Ownable {


     
		 
		 
		 
		 
    mapping(bytes32 => uint256)    internal uIntStorage;
    mapping(bytes32 => string)     internal stringStorage;
    mapping(bytes32 => address)    internal addressStorage;
    mapping(bytes32 => bytes)      internal bytesStorage;
    mapping(bytes32 => bool)       internal boolStorage;
    mapping(bytes32 => int256)     internal intStorage;

    constructor() public {
				 
				 
				 
        owner[msg.sender] = true;
    }

     

     
    function setAddress(bytes32 _key, address _value) public onlyOwner returns (bool success) {
        addressStorage[_key] = _value;
        return true;
    }

     
    function setUint(bytes32 _key, uint _value) public onlyOwner returns (bool success) {
        uIntStorage[_key] = _value;
        return true;
    }

     
    function setString(bytes32 _key, string _value) public onlyOwner returns (bool success) {
        stringStorage[_key] = _value;
        return true;
    }

     
    function setBytes(bytes32 _key, bytes _value) public onlyOwner returns (bool success) {
        bytesStorage[_key] = _value;
        return true;
    }

     
    function setBool(bytes32 _key, bool _value) public onlyOwner returns (bool success) {
        boolStorage[_key] = _value;
        return true;
    }

     
    function setInt(bytes32 _key, int _value) public onlyOwner returns (bool success) {
        intStorage[_key] = _value;
        return true;
    }

     
		 
		 

     
    function deleteAddress(bytes32 _key) public onlyOwner returns (bool success) {
        delete addressStorage[_key];
        return true;
    }

     
    function deleteUint(bytes32 _key) public onlyOwner returns (bool success) {
        delete uIntStorage[_key];
        return true;
    }

     
    function deleteString(bytes32 _key) public onlyOwner returns (bool success) {
        delete stringStorage[_key];
        return true;
    }

     
    function deleteBytes(bytes32 _key) public onlyOwner returns (bool success) {
        delete bytesStorage[_key];
        return true;
    }

     
    function deleteBool(bytes32 _key) public onlyOwner returns (bool success) {
        delete boolStorage[_key];
        return true;
    }

     
    function deleteInt(bytes32 _key) public onlyOwner returns (bool success) {
        delete intStorage[_key];
        return true;
    }

     

     
    function getAddress(bytes32 _key) public view returns (address _value) {
        return addressStorage[_key];
    }

     
    function getUint(bytes32 _key) public view returns (uint _value) {
        return uIntStorage[_key];
    }

     
    function getString(bytes32 _key) public view returns (string _value) {
        return stringStorage[_key];
    }

     
    function getBytes(bytes32 _key) public view returns (bytes _value) {
        return bytesStorage[_key];
    }

     
    function getBool(bytes32 _key) public view returns (bool _value) {
        return boolStorage[_key];
    }

     
    function getInt(bytes32 _key) public view returns (int _value) {
        return intStorage[_key];
    }

}