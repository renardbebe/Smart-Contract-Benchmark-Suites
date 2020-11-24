 

pragma solidity ^0.4.2;

contract HYIP {
	
	 

	uint constant PAYOUT_INTERVAL = 1 days;

	 	
	uint constant BENEFICIARIES_INTEREST = 37;
	uint constant INVESTORS_INTEREST = 33;
	uint constant INTEREST_DENOMINATOR = 1000;

	 

	 
	event Payout(uint paidPeriods, uint investors, uint beneficiaries);
	
	 
	struct Investor
	{	
		address etherAddress;
		uint deposit;
		uint investmentTime;
	}

	 
	modifier adminOnly { if (msg.sender == m_admin) _; }

	 

	 
	address private m_admin;

	 
	uint private m_latestPaidTime;

	 
	Investor[] private m_investors;

	 
	address[] private m_beneficiaries;
	
	 

	 
	function HYIP() 
	{
		m_admin = msg.sender;
		m_latestPaidTime = now;		
	}

	 
	function() payable
	{
		addInvestor();
	}

	function Invest() payable
	{
		addInvestor();	
	}

	function status() constant returns (uint bank, uint investorsCount, uint beneficiariesCount, uint unpaidTime, uint unpaidIntervals)
	{
		bank = this.balance;
		investorsCount = m_investors.length;
		beneficiariesCount = m_beneficiaries.length;
		unpaidTime = now - m_latestPaidTime;
		unpaidIntervals = unpaidTime / PAYOUT_INTERVAL;
	}


	 
	function performPayouts()
	{
		uint paidPeriods = 0;
		uint investorsPayout;
		uint beneficiariesPayout = 0;

		while(m_latestPaidTime + PAYOUT_INTERVAL < now)
		{						
			uint idx;

			 		
			if(m_beneficiaries.length > 0) 
			{
				beneficiariesPayout = (this.balance * BENEFICIARIES_INTEREST) / INTEREST_DENOMINATOR;
				uint eachBeneficiaryPayout = beneficiariesPayout / m_beneficiaries.length;  
				for(idx = 0; idx < m_beneficiaries.length; idx++)
				{
					if(!m_beneficiaries[idx].send(eachBeneficiaryPayout))
						throw;				
				}
			}

			 
			 
			for (idx = m_investors.length; idx-- > 0; )
			{
				if(m_investors[idx].investmentTime > m_latestPaidTime + PAYOUT_INTERVAL)
					continue;
				uint payout = (m_investors[idx].deposit * INVESTORS_INTEREST) / INTEREST_DENOMINATOR;
				if(!m_investors[idx].etherAddress.send(payout))
					throw;
				investorsPayout += payout;	
			}
			
			 
			m_latestPaidTime += PAYOUT_INTERVAL;
			paidPeriods++;
		}
			
		 
		Payout(paidPeriods, investorsPayout, beneficiariesPayout);
	}

	 
	function addInvestor() private 
	{
		m_investors.push(Investor(msg.sender, msg.value, now));
	}

	 

	 
	function changeAdmin(address newAdmin) adminOnly 
	{
		m_admin = newAdmin;
	}

	 
	function addBeneficiary(address beneficiary) adminOnly
	{
		m_beneficiaries.push(beneficiary);
	}


	 
	function resetBeneficiaryList() adminOnly
	{
		delete m_beneficiaries;
	}
	
}