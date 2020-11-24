 

pragma solidity >=0.4.22 <0.6.0;

 
 
 
 
 
 
 

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TournamentTicket is ERC20Interface {}

contract TournamentTicketSale {

     
     
     
     
    address public ticketContract;
     
     
     
    address payable public ticketOwner;
     
     
     
    bool public paused;
     
     
     
    uint public pricePerTicket;
     
     
     
    address payable public owner;
    address payable private nextOwner;

     
     
     
     
    modifier onlyContractOwner {
        require(msg.sender == owner, "Function called by non-owner.");
        _;
    }
     
     
     
    modifier onlyTicketOwner {
        require(msg.sender == ticketOwner, "Function called by non-ticket-owner.");
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
        TournamentTicket ticket = getTicketContract();

        require(ticket.balanceOf(msg.sender) == 0, "You already have a ticket, and you only need one to participate!");
        require(pricePerTicket > 0, "The price per ticket needs to be more than 0!");
        require(msg.value == pricePerTicket, "The amout sent is not corresponding with the ticket price!");
        
        require(
            ticket.transferFrom(getTicketOwnerAddress(), msg.sender, 1000000000000000000),
            "Ticket transfer failed!"
        );
        
        getTicketOwnerAddress().transfer(msg.value);
    }
     
     
     
    function setTicketPrice(uint price) external onlyTicketOwner {
        pricePerTicket = price;
    }
     
     
     
    function setTicketContract(address value) external onlyContractOwner {
        ticketContract = value;
    }
     
     
     
    function getTicketContract() internal view returns(TournamentTicket) {
        return(TournamentTicket(ticketContract));
    }
     
     
     
    function setTicketOwnerAddress(address payable value) external onlyContractOwner {
        ticketOwner = value;
    }
     
     
     
    function getTicketOwnerAddress() internal view returns(address payable) {
        return(ticketOwner);
    }
     
     
     
    function setPaused(bool value) external onlyContractOwner {
        paused = value;
    }
     
     
     
    function approveNextOwner(address payable _nextOwner) external onlyContractOwner {
        require(_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }
     
     
     
    function acceptNextOwner() external {
        require(msg.sender == nextOwner, "The new owner has to accept the previously set new owner.");
        owner = nextOwner;
    }
     
     
     
     
    function () external payable {}
    
}