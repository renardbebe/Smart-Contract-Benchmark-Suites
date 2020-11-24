 

pragma solidity ^0.4.25;

 

contract Dedit {
    event RegistrationCreated(address indexed registrant, bytes32 indexed hash, uint blockNumber, string description);
    event RegistrationUpdated(address indexed registrant, bytes32 indexed hash, uint blockNumber, string description);

    struct Registration {
        address registrant;
        bytes32 hash;
        uint blockNumber;
        string description;
    }

    mapping(bytes32 => Registration) registrations;

    function _register(bytes32 hash, string memory description, address registrant) internal {

        Registration storage registration = registrations[hash];

        if (registration.registrant == address(0)) {          
            registration.registrant = registrant;
            registration.hash = hash;
            registration.blockNumber = block.number;
            registration.description = description;

            emit RegistrationCreated(registrant, hash, block.number, description);
        }
        else if (registration.registrant == registrant) {     
            registration.description = description;

            emit RegistrationUpdated(registrant, hash, registration.blockNumber, description);
        }
        else
            revert("only owner can change his registration");

    }

    function register(bytes32 hash, string memory description) public {

        _register(hash, description, msg.sender);

    }

    function registerOnBehalfOf(bytes32 hash, string memory description, address signer, bytes memory signature) public {

        bytes32 message = this.ethSignedRegistration(hash, description);    
        address actualSigner = recoverSigner(message, signature);

        require(actualSigner != address(0), "wrong signature");
        require(actualSigner == signer, "wrong signer");

        _register(hash, description, actualSigner);
    }

    function retrieve(bytes32 hash) public view returns (address, bytes32, uint, string memory) {

        Registration storage registration = registrations[hash];

        return (registration.registrant, registration.hash, registration.blockNumber, registration.description);

    }

    function ethSignedRegistration(bytes32 hash, string memory description) public view returns (bytes32) {
        bytes32 messageHash = keccak256(abi.encodePacked(hash, description, address(this)));
        return ethSignedMessage(messageHash);
    }

    function ethSignedMessage(bytes32 messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));    
    }

     
    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address)
    {
        if (sig.length != 65) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        }

        return ecrecover(message, v, r, s);
    }

}