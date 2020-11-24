 

contract SHA3_512 {
   function hash(uint64[8]) pure public returns(uint32[16]) {}
}

contract TeikhosBounty {

    address public bipedaljoe = 0x4c5D24A7Ca972aeA90Cc040DA6770A13Fc7D4d9A;  

    SHA3_512 public sha3_512 = SHA3_512(0xbD6361cC42fD113ED9A9fdbEDF7eea27b325a222);  
                                                                                      

    struct Commit {
        uint timestamp;
        bytes signature;
    }    

    mapping(address => Commit) public commitment;

    struct Solution {
        uint timestamp;
        bytes publicKey;  
        bytes32 msgHash;
    }    

    Solution public isSolved;
    
    struct Winner {
        uint timestamp;
        address winner;
    }

    Winner public winner;

    enum State { Commit, Reveal, Payout }
    
    modifier inState(State _state)
    {
        if(_state == State.Commit) { require(isSolved.timestamp == 0); }
        if(_state == State.Reveal) { require(isSolved.timestamp != 0 && now < isSolved.timestamp + 7 days); }
        if(_state == State.Payout) { require(isSolved.timestamp != 0 && now > isSolved.timestamp + 7 days); }
        _;
    }

     
    bytes32 proof_of_public_key1 = hex"ed326f4b0f6eb2bcdfe5caa4b138dca67c37c985d6c2d8d01bd3d852af0da328";
    bytes32 proof_of_public_key2 = hex"7b44c98c94c96d17eaae5aac9c927b2648b25528691244d9258626fbd5119f69";

    function commit(bytes _signature) public inState(State.Commit) {
        require(commitment[msg.sender].timestamp == 0);
        commitment[msg.sender].signature = _signature;
        commitment[msg.sender].timestamp = now;
    }

    function reveal() public inState(State.Reveal) {
        bytes memory signature = commitment[msg.sender].signature;
        require(signature.length != 0);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
        r := mload(add(signature,0x20))
        s := mload(add(signature,0x40))
        v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) v += 27;

        if(ecrecover(isSolved.msgHash, v, r, s) == msg.sender) {
            if(winner.timestamp == 0 || commitment[msg.sender].timestamp < winner.timestamp) {
                winner.winner = msg.sender;
                winner.timestamp = commitment[msg.sender].timestamp;
            }
        }
        delete commitment[msg.sender];
    }

    function reward() public inState(State.Payout) {
        if(winner.winner != 0) selfdestruct(winner.winner);
        else selfdestruct(bipedaljoe);
    }

    function authenticate(bytes _publicKey) public inState(State.Commit) {
        
         
        require(commitment[msg.sender].timestamp != 0);
        
        bytes memory keyHash = getHash(_publicKey);
         
         

        bytes32 hash1;
        bytes32 hash2;

        assembly {
        hash1 := mload(add(keyHash,0x20))
        hash2 := mload(add(keyHash,0x40))
        }

         
        bytes32 r = proof_of_public_key1 ^ hash1;
        bytes32 s = proof_of_public_key2 ^ hash2;

         
        bytes32 msgHash = keccak256("\x19Ethereum Signed Message:\n64", _publicKey);

         
        address signer = address(keccak256(_publicKey));

         
        if(ecrecover(msgHash, 27, r, s) == signer || ecrecover(msgHash, 28, r, s) == signer ) {
            isSolved.timestamp = now;
            isSolved.publicKey = _publicKey; 
            isSolved.msgHash = msgHash;
        }
    }

    
    

   function getHash(bytes _message) view internal returns (bytes messageHash) {

         

        uint64[8] memory input;

         

        bytes memory reversed = new bytes(64);

        for(uint i = 0; i < 64; i++) {
            reversed[i] = _message[63 - i];
        }

        for(i = 0; i < 8; i++) {
            bytes8 oneEigth;
             
            assembly {
                oneEigth := mload(add(reversed, add(32, mul(i, 8)))) 
            }
            input[7 - i] = uint64(oneEigth);
        }

        uint32[16] memory output = sha3_512.hash(input);
        
        bytes memory toBytes = new bytes(64);
        
        for(i = 0; i < 16; i++) {
            bytes4 oneSixteenth = bytes4(output[15 - i]);
             
            assembly { mstore(add(toBytes, add(32, mul(i, 4))), oneSixteenth) }
        }

        messageHash = new bytes(64);

        for(i = 0; i < 64; i++) {
            messageHash[i] = toBytes[63 - i];
        }   
   }
   
    
   
    function() public payable {}

}