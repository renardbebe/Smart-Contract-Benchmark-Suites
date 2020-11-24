 

 
 
 
 
 

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract MiCarsICO {
	 
	uint128 private decimals = 1000000000000000000;
    address public beneficiary = 0x8f42914C201AcDd8a2769211C862222Ec56eea40;
    address public owner = beneficiary;
	
	 
	uint public startdate = now;
	 
	uint public deadlinePreIcoOne = 1515196740;
	
	 
    uint public deadlinePreIcoTwo = 1515801540;	
	
	 
    uint public deadline = 1518566340;

	
	 
    uint public vminEtherPerPurchase = 0.0011 * 1 ether;
	
	 
    uint public vmaxEtherPerPurchase = 225 * 1 ether;
	
	 
    uint public price = 0.000385901 * 1 ether;
    uint public updatedPrice  = 0.000515185 * 1 ether;
	
	 
    uint public amountRaised;
    uint public sentToken;
    

	

	
	 
    token public tokenReward = token(0xdd5a3aeef473401c23f24c4c6b9cd1b0808fbb36);
    mapping(address => uint256) public balanceOf;
	
    bool crowdsaleClosed = false;
    bool price_rate_changed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function MiCarsICO() {}

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	  }
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		if (a == 0) {
		  return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
  
	modifier isOwner {
	  require(msg.sender == owner);
	  _;
	 }
	

	function kill() isOwner public {
        selfdestruct(beneficiary);
    }

    function EmergencyPause() isOwner public {
        crowdsaleClosed = true;
    }
    function EmergencyUnPause() isOwner public {
        crowdsaleClosed = false;
    }
	
	  
    function safeWithdrawal(uint _amounty) isOwner public {
			uint amounted = _amounty;
            
            if (beneficiary.send(amounted)) {
                FundTransfer(beneficiary, amounted, false);
            }
    }
	
    function UpdatePrice(uint _new_price) isOwner public {
          updatedPrice = _new_price;
		  price_rate_changed = true;
    }

    function () payable   {
        require(crowdsaleClosed == false);

		if (price_rate_changed == false) {
					
			 
			if (now <= deadlinePreIcoOne) {
				price = 0.000385901 * 1 ether;
			}
			
			 
			else if (now > deadlinePreIcoOne && now <= deadlinePreIcoTwo) {
				price = 0.000411628 * 1 ether;
			}
			
			 
			else if (now > deadlinePreIcoTwo && now <= deadline) {
				price = 0.000515185 * 1 ether;
			}
			 
			else {
				price = 0.000515185 * 1 ether;
			}
		 
		} else if (price_rate_changed == true) {
			price = updatedPrice * 1 ether;
		} else {
			price = 0.000515185 * 1 ether;
		}
		
		uint amount = msg.value;

		uint calculedamount = mul(amount, decimals);
		uint tokentosend = div(calculedamount, price);


        if (msg.value >= vminEtherPerPurchase && msg.value <= vmaxEtherPerPurchase) {
				
				balanceOf[msg.sender] += amount;
				FundTransfer(msg.sender, amount, true);
				tokenReward.transfer(msg.sender, tokentosend);

				amountRaised += amount;
				sentToken += tokentosend;
						
							
		} else {
			revert();
		}
        
    }

}