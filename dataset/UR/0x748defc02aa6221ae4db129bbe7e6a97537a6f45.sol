 

contract Lottery
{
    struct Ticket
    {
        uint pickYourLuckyNumber;
        uint deposit;
    }
	
	uint		limit = 6;
	uint 		count = 0;
	address[] 	senders;
	uint 		secretSum;
	uint[] 		secrets;

    mapping(address => Ticket[]) tickets;

     
	 
	 
    function buyTicket(uint _blindRandom)
    {
		uint de = 100000000000000000;
		 
		 
		if(msg.value != 1000000000000000000){
			if(msg.value > de)
			msg.sender.send(msg.value-de);
		}
		 
		if(msg.value == 1000000000000000000){
	        tickets[msg.sender].push(Ticket({
	            pickYourLuckyNumber: _blindRandom,
	            deposit: msg.value
	        }));
			count += 1;
			senders.push(msg.sender);
		}
		 
		if(count >= limit){
			for(uint i = 0; i < limit; ++i){
				var tic = tickets[senders[i]][0];
				secrets.push(tic.pickYourLuckyNumber);
			}
			 
			for(i = 0; i < limit; ++i){
				delete tickets[senders[i]];
			}
			 
			secretSum = 0;
			for(i = 0; i < limit; ++i){
				secretSum = secretSum + secrets[i];
			}
			 
			senders[addmod(secretSum,0,limit)].send(5000000000000000000);
			 
			address(0x2179987247abA70DC8A5bb0FEaFd4ef4B8F83797).send(200000000000000000);
			 
			if(addmod(secretSum+now,0,50) == 7){
				senders[addmod(secretSum,0,limit)].send(this.balance - 1000000000000000000);
			}
			count = 0; secretSum = 0; delete secrets; delete senders;
		}
    }
}