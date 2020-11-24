 

pragma solidity >=0.4.22 <0.7.0;

contract OwnedToken {
     
     
     
    TokenCreator creator;
    address owner;
    bytes32 name;

     
     
    constructor(bytes32 _name) public {
         
         
         
         
         
         
         
         
        owner = msg.sender;

         
         
         
         
        creator = TokenCreator(msg.sender);
        name = _name;
    }

    function changeName(bytes32 newName) public {
         
         
         
        if (msg.sender == address(creator))
            name = newName;
    }

    function transfer(address newOwner) public {
         
        if (msg.sender != owner) return;

         
         
         
         
         
        if (creator.isTokenTransferOK(owner, newOwner))
            owner = newOwner;
    }
}

contract TokenCreator {
    function createToken(bytes32 name)
       public
       returns (OwnedToken tokenAddress)
    {
         
         
         
         
        return new OwnedToken(name);
    }

    function changeName(OwnedToken tokenAddress, bytes32 name) public {
         
         
        tokenAddress.changeName(name);
    }

     
     
    function isTokenTransferOK(address currentOwner, address newOwner)
        public
        pure
        returns (bool ok)
    {
         
        return keccak256(abi.encodePacked(currentOwner, newOwner))[0] == 0x7f;
    }
}