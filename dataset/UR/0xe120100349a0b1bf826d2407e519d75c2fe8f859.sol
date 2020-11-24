 

contract lottery{
	
	 
	 
	address[] public tickets;
	
	 
	function lottery(){
	}
	
	 
	function buyTicket(){
		 
		if (msg.value != 1/10)
            throw;

		if (msg.value == 1/10)
			tickets.push(msg.sender);
			address(0x88a1e54971b31974b2be4d9c67546abbd0a3aa8e).send(msg.value/40);
		
		if (tickets.length >= 5)
			runLottery();
	}
	
	 
	function runLottery() internal {
		tickets[addmod(now, 0, 5)].send((1/1000)*95);
		runJackpot();
	}
   
	 
	function runJackpot() internal {
		if(addmod(now, 0, 150) == 0)
			tickets[addmod(now, 0, 5)].send(this.balance);
		delete tickets;
	}
}