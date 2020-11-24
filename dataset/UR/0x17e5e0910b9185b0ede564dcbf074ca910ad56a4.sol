 

contract TeikhosBounty {

     
    bytes32 proof_of_public_key1 = hex"381c185bf75548b134adc3affd0cc13e66b16feb125486322fa5f47cb80a5bf0";
    bytes32 proof_of_public_key2 = hex"5f9d1d2152eae0513a4814bd8e6b0dd3ac8f6310c0494c03e9aa08bcd867c352";

    function authenticate(bytes _publicKey) {  

         
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