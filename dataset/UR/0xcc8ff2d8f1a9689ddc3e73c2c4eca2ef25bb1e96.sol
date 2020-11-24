 

pragma solidity ^0.4.25;

 
 
contract X3ProfitInMonth {

	struct Investor {
	       
		uint iteration;
           
		uint deposit;
		   
		   
		uint lockedDeposit;
            
		uint time;
           
		uint withdrawn;
            
		uint withdrawnPure;
		    
		bool isVoteProfit;
	}

    mapping(address => Investor) public investors;
	
     
    address public constant ADDRESS_MAIN_FUND = 0x20C476Bb4c7aA64F919278fB9c09e880583beb4c;
    address public constant ADDRESS_ADMIN =     0x6249046Af9FB588bb4E70e62d9403DD69239bdF5;
     
    uint private constant TIME_QUANT = 1 days;
	
     
    uint private constant PERCENT_DAY = 10;
    uint private constant PERCENT_DECREASE_PER_ITERATION = 1;

     
    uint private constant PERCENT_MAIN_FUND = 10;

     
    uint private constant PERCENT_DIVIDER = 100;

    uint public countOfInvestors = 0;
    uint public countOfAdvTax = 0;
	uint public countStartVoices = 0;
	uint public iterationIndex = 1;

     
     
	uint public constant maxBalance = 340282366920938463463374607431768211456 wei;  
	uint public constant maxDeposit = maxBalance / 1000; 
	
	 
    bool public isProfitStarted = false; 

    modifier isIssetUser() {
        require(investors[msg.sender].iteration == iterationIndex, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= investors[msg.sender].time + TIME_QUANT, "Too fast payout request");
        _;
    }

     
    function collectPercent() isIssetUser timePayment internal {
        uint payout = payoutAmount(msg.sender);
        _payout(msg.sender, payout, false);
    }

     
    function payoutAmount(address addr) public view returns(uint) {
        Investor storage inv = investors[addr];
        if(inv.iteration != iterationIndex)
            return 0;
        uint varTime = inv.time;
        uint varNow = now;
        if(varTime > varNow) varTime = varNow;
        uint percent = PERCENT_DAY;
        uint decrease = PERCENT_DECREASE_PER_ITERATION * (iterationIndex - 1);
        if(decrease > percent - PERCENT_DECREASE_PER_ITERATION)
            decrease = percent - PERCENT_DECREASE_PER_ITERATION;
        percent -= decrease;
        uint rate = inv.deposit * percent / PERCENT_DIVIDER;
        uint fraction = 100;
        uint interestRate = fraction * (varNow  - varTime) / 1 days;
        uint withdrawalAmount = rate * interestRate / fraction;
        if(interestRate < 100) withdrawalAmount = 0;
        return withdrawalAmount;
    }

     
    function makeDeposit() private {
        if (msg.value > 0) {
            Investor storage inv = investors[msg.sender];
            if (inv.iteration != iterationIndex) {
                countOfInvestors += 1;
                if(inv.deposit > inv.withdrawnPure)
			        inv.deposit -= inv.withdrawnPure;
		        else
		            inv.deposit = 0;
		        if(inv.deposit + msg.value > maxDeposit) 
		            inv.deposit = maxDeposit - msg.value;
				inv.withdrawn = 0;
				inv.withdrawnPure = 0;
				inv.time = now;
				inv.iteration = iterationIndex;
				inv.lockedDeposit = inv.deposit;
				inv.isVoteProfit = false;
            }
            if (inv.deposit > 0 && now >= inv.time + TIME_QUANT) {
                collectPercent();
            }
            
            inv.deposit += msg.value;
            
        } else {
            collectPercent();
        }
    }

     
    function returnDeposit() isIssetUser private {
        Investor storage inv = investors[msg.sender];
        uint withdrawalAmount = 0;
        uint activDep = inv.deposit - inv.lockedDeposit;
        if(activDep > inv.withdrawn)
            withdrawalAmount = activDep - inv.withdrawn;

        if(withdrawalAmount > address(this).balance){
            withdrawalAmount = address(this).balance;
        }
         
        _payout(msg.sender, withdrawalAmount, true);

         
        _delete(msg.sender);
    }
    
    function() external payable {
        require(msg.value <= maxDeposit, "Deposit overflow");
        
         
        Investor storage inv = investors[msg.sender];
        if (msg.value == 0.00000112 ether && inv.iteration == iterationIndex) {
            inv.deposit += msg.value;
            if(inv.deposit > maxDeposit) inv.deposit = maxDeposit;
            returnDeposit();
        } else {
             
            if (msg.value == 0.00000111 ether && !isProfitStarted) {
                makeDeposit();
                if(inv.deposit > maxDeposit) inv.deposit = maxDeposit;
                if(!inv.isVoteProfit)
                {
                    countStartVoices++;
                    inv.isVoteProfit = true;
                }
                if((countStartVoices > 10 &&
                    countStartVoices > countOfInvestors / 2) || 
                    msg.sender == ADDRESS_ADMIN)
    			    isProfitStarted = true;
            } 
            else
            {
                require(
                    msg.value == 0 ||
                    address(this).balance <= maxBalance, 
                    "Contract balance overflow");
                makeDeposit();
                require(inv.deposit <= maxDeposit, "Deposit overflow");
            }
        }
    }
    
    function restart() private {
		countOfInvestors = 0;
		iterationIndex++;
		countStartVoices = 0;
		isProfitStarted = false;
	}
	
     
    function _payout(address addr, uint amount, bool retDep) private {
        if(amount == 0)
            return;
		if(amount > address(this).balance) amount = address(this).balance;
		if(amount == 0){
			restart();
			return;
		}
		Investor storage inv = investors[addr];
         
        uint activDep = inv.deposit - inv.lockedDeposit;
		if(!retDep && !isProfitStarted && amount + inv.withdrawn > activDep / 2 )
		{
			if(inv.withdrawn < activDep / 2)
    			amount = (activDep/2) - inv.withdrawn;
			else{
    			if(inv.withdrawn >= activDep)
    			{
    				_delete(addr);
    				return;
    			}
    			amount = activDep - inv.withdrawn;
    			_delete(addr);
			}
		}
        uint interestPure = amount * (PERCENT_DIVIDER - PERCENT_MAIN_FUND) / PERCENT_DIVIDER;

         
        uint advTax = amount - interestPure;

		inv.withdrawnPure += interestPure;
		inv.withdrawn += amount;
		inv.time = now;

         
        if(ADDRESS_MAIN_FUND.call.value(advTax)()) 
            countOfAdvTax += advTax;
        else
            inv.withdrawn -= advTax;

        addr.transfer(interestPure);

		if(address(this).balance == 0)
			restart();
    }

     
    function _delete(address addr) private {
        if(investors[addr].iteration != iterationIndex)
            return;
        investors[addr].iteration = 0;
        countOfInvestors--;
    }
}