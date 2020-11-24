 

pragma solidity ^0.4.11;

contract BLOCKCHAIN_DEPOSIT_BETA {
	
	 

	uint constant PAYOUT_INTERVAL = 1 days;

	 	
	uint constant DEPONENT_INTEREST= 10;
	uint constant INTEREST_DENOMINATOR = 1000;

	 

	 
	event Payout(uint paidPeriods, uint depositors);
	
	 
	struct Depositor
	{	
		address etherAddress;
		uint deposit;
		uint depositTime;
	}

	 
	modifier founderOnly { if (msg.sender == contract_founder) _; }

	 

	 
	address private contract_founder;

	 
	uint private contract_latestPayoutTime;

	 
	Depositor[] private contract_depositors;

	
	 

	 
	function BLOCKCHAIN_DEPOSIT_BETA() 
	{
		contract_founder = msg.sender;
		contract_latestPayoutTime = now;		
	}

	 
	function() payable
	{
		addDepositor();
	}

	function Make_Deposit() payable
	{
		addDepositor();	
	}

	function status() constant returns (uint deposit_fond_sum, uint depositorsCount, uint unpaidTime, uint unpaidIntervals)
	{
		deposit_fond_sum = this.balance;
		depositorsCount = contract_depositors.length;
		unpaidTime = now - contract_latestPayoutTime;
		unpaidIntervals = unpaidTime / PAYOUT_INTERVAL;
	}


	 
	function performPayouts()
	{
		uint paidPeriods = 0;
		uint depositorsDepositPayout;

		while(contract_latestPayoutTime + PAYOUT_INTERVAL < now)
		{						
			uint idx;

			 
			 
			for (idx = contract_depositors.length; idx-- > 0; )
			{
				if(contract_depositors[idx].depositTime > contract_latestPayoutTime + PAYOUT_INTERVAL)
					continue;
				uint payout = (contract_depositors[idx].deposit * DEPONENT_INTEREST) / INTEREST_DENOMINATOR;
				if(!contract_depositors[idx].etherAddress.send(payout))
					throw;
				depositorsDepositPayout += payout;	
			}
			
			 
			contract_latestPayoutTime += PAYOUT_INTERVAL;
			paidPeriods++;
		}
			
		 
		Payout(paidPeriods, depositorsDepositPayout);
	}

	 
	function addDepositor() private 
	{
		contract_depositors.push(Depositor(msg.sender, msg.value, now));
	}

	 

	 
	function changeFounderAddress(address newFounder) founderOnly 
	{
		contract_founder = newFounder;
	}
}