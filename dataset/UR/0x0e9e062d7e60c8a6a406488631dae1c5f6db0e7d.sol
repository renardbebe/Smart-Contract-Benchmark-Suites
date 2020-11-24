 

 

pragma solidity ^0.4.11;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract TextMessage is owned {
    
    uint cost;
    bool public enabled;
    
    event UpdateCost(uint newCost);
    event UpdateEnabled(string newStatus);
    event NewText(string number, string message);

    function TextMessage() {
        cost = 380000000000000;
        enabled = true;
    }
    
    function changeCost(uint price) onlyOwner {
        cost = price;
        UpdateCost(cost);
    }
    
    function pauseContract() onlyOwner {
        enabled = false;
        UpdateEnabled("Texting has been disabled");
    }
    
    function enableContract() onlyOwner {
        enabled = true;
        UpdateEnabled("Texting has been enabled");
    }
    
    function withdraw() onlyOwner {
        owner.transfer(this.balance);
    }
    
    function costWei() constant returns (uint) {
      return cost;
    }
    
    function sendText(string phoneNumber, string textBody) public payable {
        if(!enabled) throw;
        if(msg.value < cost) throw;
        sendMsg(phoneNumber, textBody);
    }
    
    function sendMsg(string num, string body) internal {
        NewText(num,body);
    }
    
}