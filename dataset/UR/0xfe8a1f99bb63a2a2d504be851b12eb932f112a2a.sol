 

 

pragma solidity ^0.4.19;

contract DocSigner {

 
 
 

    address public owner; 
    uint constant maxSigs = 10;  
    uint numSigs = 0;  
    string public docHash;  
    address[10] signatories;  
    mapping(address => string) public messages;

 
 
 

    function DocSigner()
        public
    {
        owner = msg.sender;
    }

 
 
 

    event Signature(address signer, string docHash, string message);

 
 
 

     

    function setup( string   newDocHash,
                    address[] newSigs )
        external
        onlyOwner
    {
        require( newSigs.length <= maxSigs );  

        docHash = newDocHash;
        numSigs = newSigs.length;

        for( uint i = 0; i < numSigs; i++ ){
            signatories[i] = newSigs[i];
        }
    }

     

    function sign( string signingHash,
                   string message )
        external
        onlySigner
    {
        require(keccak256(signingHash) == keccak256(docHash));

         
        messages[msg.sender] = message;

        Signature(msg.sender, docHash, message);
    }

     

    function checkSig(address addr)
        internal
        view
        returns (bool)
    {
        for( uint i = 0; i < numSigs; i++ ){
            if( signatories[i] == addr )
                return true;
        }

        return false;
    }

 
 
 

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    modifier onlySigner
    {
        require(checkSig(msg.sender));
        _;
    }
}