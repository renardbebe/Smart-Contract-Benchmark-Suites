 

pragma solidity ^0.4.23;

library AZTECInterface {
    function validateJoinSplit(bytes32[6][], uint, uint, bytes32[4]) external pure returns (bool) {}
}

 
contract ERC20Interface {
  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);
}

 
contract AZTECERC20Bridge {
    uint private constant groupModulusBoundary = 10944121435919637611123202872628637544274182200208017171849102093287904247808;
    uint private constant groupModulus = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint public scalingFactor;
    mapping(bytes32 => address) public noteRegistry;
    bytes32[4] setupPubKey;
    bytes32 domainHash;
    ERC20Interface token;

    event Created(bytes32 domainHash, address contractAddress);
    event ConfidentialTransfer();

     
    constructor(bytes32[4] _setupPubKey, address _token, uint256 _scalingFactor) public {
        setupPubKey = _setupPubKey;
        token = ERC20Interface(_token);
        scalingFactor = _scalingFactor;
         
        bytes32 _domainHash;
        assembly {
            let m := mload(0x40)
            mstore(m, 0x8d4b25bfecb769291b71726cd5ec8a497664cc7292c02b1868a0534306741fd9)
            mstore(add(m, 0x20), 0x87a23625953c9fb02b3570c86f75403039bbe5de82b48ca671c10157d91a991a)  
            mstore(add(m, 0x40), 0x25130290f410620ec94e7cf11f1cdab5dea284e1039a83fa7b87f727031ff5f4)  
            mstore(add(m, 0x60), 1)  
            mstore(add(m, 0x80), 0x210db872dec2e06c375dd40a5a354307bb4ba52ba65bd84594554580ae6f0639)
            mstore(add(m, 0xa0), address)  
            _domainHash := keccak256(m, 0xc0)
        }
        domainHash = _domainHash;
        emit Created(_domainHash, this);
    }

     
    function validateInputNote(bytes32[6] note, bytes32[3] signature, uint challenge, bytes32 domainHashT) internal {
        bytes32 noteHash;
        bytes32 signatureMessage;
        assembly {
            let m := mload(0x40)
            mstore(m, mload(add(note, 0x40)))
            mstore(add(m, 0x20), mload(add(note, 0x60)))
            mstore(add(m, 0x40), mload(add(note, 0x80)))
            mstore(add(m, 0x60), mload(add(note, 0xa0)))
            noteHash := keccak256(m, 0x80)
            mstore(m, 0x1aba5d08f7cd777136d3fa7eb7baa742ab84001b34c9de5b17d922fc2ca75cce)  
            mstore(add(m, 0x20), noteHash)
            mstore(add(m, 0x40), challenge)
            mstore(add(m, 0x60), caller)
            mstore(add(m, 0x40), keccak256(m, 0x80))
            mstore(add(m, 0x20), domainHashT)
            mstore(m, 0x1901)
            signatureMessage := keccak256(add(m, 0x1e), 0x42)
        }
        address owner = ecrecover(signatureMessage, uint8(signature[0]), signature[1], signature[2]);
        require(noteRegistry[noteHash] == owner, "expected input note to exist in registry");
        noteRegistry[noteHash] = 0;
    }

     
    function validateOutputNote(bytes32[6] note, address owner) internal {
        bytes32 noteHash;  
        assembly {
            let m := mload(0x40)
            mstore(m, mload(add(note, 0x40)))
            mstore(add(m, 0x20), mload(add(note, 0x60)))
            mstore(add(m, 0x40), mload(add(note, 0x80)))
            mstore(add(m, 0x60), mload(add(note, 0xa0)))
            noteHash := keccak256(m, 0x80)
        }
        require(noteRegistry[noteHash] == 0, "expected output note to not exist in registry");
        noteRegistry[noteHash] = owner;
    }

     
    function confidentialTransfer(bytes32[6][] notes, uint256 m, uint256 challenge, bytes32[3][] inputSignatures, address[] outputOwners, bytes) external {
        require(inputSignatures.length == m, "input signature length invalid");
        require(inputSignatures.length + outputOwners.length == notes.length, "array length mismatch");

         
        require(AZTECInterface.validateJoinSplit(notes, m, challenge, setupPubKey), "proof not valid!");

         
        uint256 kPublic = uint(notes[notes.length - 1][0]);

         
        for (uint256 i = 0; i < notes.length; i++) {

             
            if (i < m) {

                 
                 
                 
                validateInputNote(notes[i], inputSignatures[i], challenge, domainHash);
            } else {
                
                 
                 
                 
                validateOutputNote(notes[i], outputOwners[i - m]);
            }
        }

        if (kPublic > 0) {
            if (kPublic < groupModulusBoundary) {

                 
                 
                require(token.transfer(msg.sender, kPublic * scalingFactor), "token transfer to user failed!");
            } else {

                 
                 
                require(token.transferFrom(msg.sender, this, (groupModulus - kPublic) * scalingFactor), "token transfer from user failed!");
            }
        }

         
        emit ConfidentialTransfer();
    }
}