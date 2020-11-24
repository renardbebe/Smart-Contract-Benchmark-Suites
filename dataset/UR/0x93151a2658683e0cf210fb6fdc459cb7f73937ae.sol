 

pragma solidity >=0.5.0;

 
contract Escrow {

     
    address owner;
     
    address payable constant beneficiary = 0x168cF76582Cd7017058771Df6F623882E04FCf0F;

     
    constructor() public {
        owner = msg.sender;  
    }
    
     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }
    
     
    function transfer(uint256 amount) ownerOnly public {
        beneficiary.transfer(amount);  
    }
    
     
    function terminate() ownerOnly public {
        selfdestruct(beneficiary);  
    }
    
     
    function () payable external {}
}