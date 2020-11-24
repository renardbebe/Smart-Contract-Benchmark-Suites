 

contract TeikhosBounty {

     
    bytes32 proof_of_public_key1 = hex"94cd5137c63cf80cdd176a2a6285572cc076f2fbea67c8b36e65065be7bc34ec";
    bytes32 proof_of_public_key2 = hex"9f6463aadf1a8aed68b99aa14538f16d67bf586a4bdecb904d56d5edb2cfb13a";
    
    function authenticate(bytes _publicKey) returns (bool) {  

         
        address signer = address(keccak256(_publicKey));

         

        bytes32 publicKey1;
        bytes32 publicKey2;

        assembly {
        publicKey1 := mload(add(_publicKey,0x20))
        publicKey2 := mload(add(_publicKey,0x40))
        }

         
        bytes32 r = proof_of_public_key1 ^ publicKey1;
        bytes32 s = proof_of_public_key2 ^ publicKey2;

        bytes32 msgHash = keccak256("\x19Ethereum Signed Message:\n64", _publicKey);

         
        if(ecrecover(msgHash, 27, r, s) == signer) suicide(msg.sender);
        if(ecrecover(msgHash, 28, r, s) == signer) suicide(msg.sender);
    }
    
    function() payable {}                            

}