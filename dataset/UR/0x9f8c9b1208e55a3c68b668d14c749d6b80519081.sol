 

pragma solidity ^0.4.21;

 
 
 
 

contract InteractiveDonation{
    address constant public Donated = 0x7Ec915B8d3FFee3deaAe5Aa90DeF8Ad826d2e110;
    
    event Quote(address Sent, string Text, uint256 AmtDonate);

    string public DonatedBanner = "";
    

    
    function Donate(string quote) public payable {
        require(msg.sender != Donated);  
        
        emit Quote(msg.sender, quote, msg.value);
    }
    
    function Withdraw() public {
        if (msg.sender != Donated){
            emit Quote(msg.sender, "OMG CHEATER ATTEMPTING TO WITHDRAW", 0);
            return;
        }
        address contr = this;
        msg.sender.transfer(contr.balance);
    }   
    
    function DonatorInteract(string text) public {
        require(msg.sender == Donated);
        emit Quote(msg.sender, text, 0);
    }
    
    function DonatorSetBanner(string img) public {
        require(msg.sender == Donated);
        DonatedBanner = img;
    }
    
    function() public payable{
        require(msg.sender != Donated);  
    }
    
}