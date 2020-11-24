 

pragma solidity 0.5.3;

  

contract License {
    
    mapping (address => bool) signatories;
    
    function sign() public {
        signatories[msg.sender] = true;
    }
        
    function unsign() public {
        signatories[msg.sender] = false;
    }
        
    function did_address_sign(address _address) public view returns (bool) {
        return signatories[_address];
    }
}