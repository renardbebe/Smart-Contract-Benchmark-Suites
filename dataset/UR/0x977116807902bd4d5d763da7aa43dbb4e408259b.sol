 

pragma solidity ^0.4.24;

contract BlockchainForPeace {
    

     
    uint public raised;
    address public charity; 
    
     
    struct Donation {
        address donor; 
        string message; 
        uint value; 
    }
    
    Donation[] public donations; 
    
     
     
    event Donate(address indexed from, uint amount, string message);
    
     
    constructor () public {
        charity = 0xaf208FF43D2A265E047D52C9F54c753DB86D9D11;
    }
   
     
     function fallback() payable public {
        raised += msg.value;
        charity.transfer(msg.value);
     }
     
    function messageForPeace(string _message) payable public {
        require(msg.value > 0);
        donations.push(Donation(msg.sender, _message, msg.value));
        charity.transfer(msg.value);
        raised += msg.value;
        emit Donate(msg.sender, msg.value, _message);
    }

    function getDonation(uint _index) public view returns (address, string, uint) {
        Donation memory don = donations[_index];
        return (don.donor, don.message, don.value);
    }
    
    function getDonationLength() public view returns (uint){
        return donations.length;
    }

     function getRaised() public view returns (uint){
        return raised;
    }
}