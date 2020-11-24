 

pragma solidity >=0.4.22 <0.6.0;

 
 
 
 
 
 
 

contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract TournamentTicket is ERC20Interface {}

contract TournamentTicketSale {

     
     
     
     
    address payable constant public ticketOwner = 0x317D875cA3B9f8d14f960486C0d1D1913be74e90;
     
     
     
    TournamentTicket constant public ticketContract = TournamentTicket(0x22365168c8705E95B2D08876C23a8c13E3ad72E2);
     
     
     
    bool public paused;
     
     
     
    uint public pricePerTicket;
     
     
     
    address payable public owner;

     
     
     
     
    modifier onlyContractOwner {
        require(msg.sender == owner, "Function called by non-owner.");
        _;
    }
     
     
     
    modifier onlyUnpaused {
        require(paused == false, "Exchange is paused.");
        _;
    }

     
     
    constructor() public {
        owner = msg.sender;
    }

     
     
     
     
    function buyOne() onlyUnpaused payable external {
        require(msg.value == pricePerTicket, "The amout sent is not corresponding with the ticket price!");
        
        require(
            ticketContract.transferFrom(ticketOwner, msg.sender, 1),
            "Ticket transfer failed!"
        );
    }
     
     
     
    function setTicketPrice(uint price) external onlyContractOwner {
        pricePerTicket = price;
    }
     
     
     
    function setPaused(bool value) external onlyContractOwner {
        paused = value;
    }
     
     
     
    function withdrawFunds(uint withdrawAmount) external onlyContractOwner {
        ticketOwner.transfer(withdrawAmount);
    }
     
     
     
     
    function kill() external onlyContractOwner {
        selfdestruct(owner);
    }
}