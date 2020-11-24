 

pragma solidity ^0.4.0;

contract IProperty {
    event RegistrationCreated(address indexed registrant, bytes32 indexed hash, uint blockNumber, string description);
    event RegistrationUpdated(address indexed registrant, bytes32 indexed hash, uint blockNumber, string description);

    struct Registration {
        address registrant;
        bytes32 hash;
        uint blockNumber;
        string description;
    }

    mapping(bytes32 => Registration) registrations;

    function register(bytes32 hash, string description) public {

        Registration storage registration = registrations[hash];

        if (registration.registrant == address(0)) {          
            registration.registrant = msg.sender;
            registration.hash = hash;
            registration.blockNumber = block.number;
            registration.description = description;

            emit RegistrationCreated(msg.sender, hash, block.number, description);
        }
        else if (registration.registrant == msg.sender) {     
            registration.description = description;

            emit RegistrationUpdated(msg.sender, hash, registration.blockNumber, description);
        }
        else
            revert("only owner can change his registration");

    }

    function retrieve(bytes32 hash) public view returns (address, bytes32, uint, string) {

        Registration storage registration = registrations[hash];

        return (registration.registrant, registration.hash, registration.blockNumber, registration.description);

    }
}