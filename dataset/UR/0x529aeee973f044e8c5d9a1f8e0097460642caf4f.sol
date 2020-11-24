 

pragma solidity >=0.5.7 <0.6.0;

contract SmartLockerRegistrar {

     
    mapping(address=>bytes32) registrar;

     
    mapping(bytes32=>address) reverseRegistrar;

     
    function() external {}

     
    event SmartLockerCreated(bytes32 name, address smartLockerAddress);

     
    function createSmartLocker(bytes32 name, bytes32 keyname) external payable
        returns (address) {

         
        require(name != bytes32(0));

         
        require(reverseRegistrar[name] == address(0));

         
        require(keyname != bytes32(0));

         
        SmartLocker smartLocker = (new SmartLocker).value(msg.value)(msg.sender, keyname);

         
        address smartLockerAddress = address(smartLocker);
        registrar[smartLockerAddress] = name;

         
        reverseRegistrar[name] = smartLockerAddress;

         
        emit SmartLockerCreated(name, smartLockerAddress);

         
        return smartLockerAddress;
    }

     
    function getName(address smartLockerAddress) external view
        returns (bytes32) {

        return registrar[smartLockerAddress];
    }

     
    function getAddress(bytes32 name) external view
        returns (address) {

        return reverseRegistrar[name];
    }
}

contract SmartLocker {

     
    using ECDSA for bytes32;

     
    struct Key {
        uint256 index;
        bool authorised;
        bytes32 keyname;
         
    }

     
    mapping(address=>Key) keys;

     
    uint256 authorisedKeyCount;

     
    address[] keyList;

     
    uint256 nextNonce;

     
    event KeyAdded(address key, bytes32 keyname);
    event KeyRemoved(address key);
    event KeyUpdated(address key, bytes32 keyname);
    event SignedExecuted(address from, address to, uint value, bytes data, uint256 nonce, uint gasPrice, uint gasLimit, bytes result);

     
    modifier onlyAuthorisedKeysOrSelf(address sender) {

        require(keys[sender].authorised || sender == address(this));
        _;
    }

     
    function() external payable {}

     
    constructor(address key, bytes32 keyname) public payable {

         
        require(key != address(0));

         
        require(keyname != bytes32(0));

         
        _addKey(key, keyname);
    }

     
    function addKey(address key, bytes32 keyname) external
        onlyAuthorisedKeysOrSelf(msg.sender) {

         
        require(key != address(0));

         
        require(!keys[key].authorised);

         
        require(keyname != bytes32(0));

         
        _addKey(key, keyname);
    }

     
    function _addKey(address key, bytes32 keyname) internal {

         
        keys[key].index = keyList.length;
        keys[key].authorised = true;
        keys[key].keyname = keyname;
        authorisedKeyCount++;

         
        keyList.push(key);

         
        emit KeyAdded(key, keyname);
    }

     
    function removeKey(address key) external
        onlyAuthorisedKeysOrSelf(msg.sender) {

         
        require(keys[key].authorised);

         
        require(authorisedKeyCount > 1);

         
        keys[key].authorised = false;
        authorisedKeyCount--;

         
        delete keyList[keys[key].index];

         
        emit KeyRemoved(key);
    }

     
    function updateKey(address key, bytes32 keyname) external
        onlyAuthorisedKeysOrSelf(msg.sender) {

         
        require(keyname != bytes32(0));

         
        keys[key].keyname = keyname;
         

         
        emit KeyUpdated(key, keyname);
    }

     
    function executeSigned(address to, uint value, bytes calldata data, uint gasPrice, uint gasLimit, bytes calldata signature) external
        onlyAuthorisedKeysOrSelf(_recoverSigner(address(this), to, value, data, nextNonce, gasPrice, gasLimit, signature))
        returns (bytes memory) {

         
        uint256 gasUsed = gasleft();

         
        (bool success, bytes memory result) = to.call.value(value)(data);

         
        gasUsed = gasUsed - gasleft();

         
        require(success);

         
        require(gasUsed <= gasLimit);

         
        emit SignedExecuted(address(this), to, value, data, nextNonce, gasPrice, gasLimit, result);

         
        nextNonce++;

         
        msg.sender.transfer((gasUsed + 40000 + (msg.data.length * 68)) * gasPrice);

         
        return result;
    }

     
    function _recoverSigner(address from, address to, uint value, bytes memory data, uint256 nonce, uint gasPrice, uint gasLimit, bytes memory signature) internal pure
        returns (address) {

        bytes32 hash = keccak256(abi.encodePacked(from, to, value, data, nonce, gasPrice, gasLimit));
        return hash.toEthSignedMessageHash().recover(signature);
    }

     
    function isAuthorisedKey(address key) external view
        returns (bool) {

        return keys[key].authorised;
    }

     
    function getKey(address key) external view
        returns (bytes32) {

        return keys[key].keyname;
         
    }

     
    function getAuthorisedKeyCount() external view
        returns (uint256) {

        return authorisedKeyCount;
    }

     
    function getKeyList() external view
        returns (address[] memory) {

        return keyList;
    }

     
    function getNextNonce() external view
        returns (uint256) {

        return nextNonce;
    }
}
pragma solidity ^0.5.2;

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}