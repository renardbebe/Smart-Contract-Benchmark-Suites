 

pragma solidity ^0.4.19;
contract ChessLotto {
 
     
    uint256 private maxTickets;
    uint256 public ticketPrice; 
     
     
    uint256 public lottoIndex;
    uint256 lastTicketTime;
    
     
	uint8 _direction;
    uint256 numtickets;
    uint256 totalBounty;
    
    address worldOwner;   
     
    event NewTicket(address indexed fromAddress, bool success);
    event LottoComplete(address indexed fromAddress, uint indexed lottoIndex, uint256 reward);
    
     
    function ChessLotto() public 
    {
        worldOwner = msg.sender; 
        
        ticketPrice = 0.00064 * 10**18;
        maxTickets = 32;
        
		_direction = 0;
        lottoIndex = 1;
        lastTicketTime = 0;
        
        numtickets = 0;
        totalBounty = 0;
    }

    
    function getBalance() public view returns (uint256 balance)
    {
        balance = 0;
        
        if(worldOwner == msg.sender) balance = this.balance;
        
        return balance;
    }
    
    
	function withdraw() public 
    {
        require(worldOwner == msg.sender);  
        
		 
        lottoIndex += 1;
        numtickets = 0;
        totalBounty = 0;
		
		worldOwner.transfer(this.balance); 
    }
    
    
    function getLastTicketTime() public view returns (uint256 time)
    {
        time = lastTicketTime; 
        return time;
    }
    
	
    function AddTicket() public payable 
    {
        require(msg.value == ticketPrice); 
        require(numtickets < maxTickets);
        
		 
		lastTicketTime = now;
        numtickets += 1;
        totalBounty += ticketPrice;
        bool success = numtickets == maxTickets;
		
        NewTicket(msg.sender, success);
        
		 
        if(success) 
        {
            PayWinner(msg.sender);
        } 
    }
    
    
    function PayWinner( address winner ) private 
    { 
        require(numtickets == maxTickets);
        
		 
        uint ownerTax = totalBounty / 1000;
        uint winnerPrice = totalBounty - ownerTax;
        
        LottoComplete(msg.sender, lottoIndex, winnerPrice);
         
		 
        lottoIndex += 1;
        numtickets = 0;
        totalBounty = 0;
		
		 
		if(_direction == 0 && maxTickets < 64) maxTickets += 1;
		if(_direction == 1 && maxTickets > 32) maxTickets -= 1;
		
		if(_direction == 0 && maxTickets == 64) _direction = 1;
		if(_direction == 1 && maxTickets == 32) _direction = 0;
         
		 
        worldOwner.transfer(ownerTax);
        winner.transfer(winnerPrice); 
    }
}