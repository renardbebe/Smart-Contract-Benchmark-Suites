 

pragma solidity ^0.5.0;

 
 
contract X3ProfitInMonthV2 {

	struct Investor {
	       
		uint iteration;
           
		uint deposit;
		   
		   
		uint lockedDeposit;
            
		uint time;
           
		uint withdrawn;
            
		uint withdrawnPure;
		    
		bool isVoteProfit;
		    
		bool isVoteRestart;
	}

    mapping(address => Investor) public investors;
	
     
    address payable public constant ADDRESS_MAIN_FUND = 0x20C476Bb4c7aA64F919278fB9c09e880583beb4c;
    address payable public constant ADDRESS_ADMIN =     0x6249046Af9FB588bb4E70e62d9403DD69239bdF5;
     
    uint private constant TIME_QUANT = 1 days;
	
     
    uint private constant PERCENT_DAY = 10;
    uint private constant PERCENT_DECREASE_PER_ITERATION = 1;
    uint private constant PERCENT_DECREASE_MINIMUM = 1;

     
    uint private constant PERCENT_MAIN_FUND = 10;

     
    uint private constant PERCENT_DIVIDER = 100;

    uint public countOfInvestors = 0;
    uint public countOfAdvTax = 0;
	uint public countStartVoices = 0;
	uint public countReStartVoices = 0;
	uint public iterationIndex = 1;
	uint private undoDecreaseIteration = 0;
	uint public countOfDebt = 0;
	uint public countOfReturnDebt = 0;

	uint public amountDebt = 0;
	uint public amountReturnDebt = 0;

     
     
	uint public constant maxBalance = 340282366920938463463374607431768211456 wei;  
	uint public constant maxDeposit = maxBalance / 1000; 
	
	 
    bool public isProfitStarted = false; 

    modifier isUserExists() {
        require(investors[msg.sender].iteration == iterationIndex, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= investors[msg.sender].time + TIME_QUANT, "Too fast payout request");
        _;
    }

     
    function collectPercent() isUserExists timePayment internal {
        uint payout = payoutAmount(msg.sender);
        _payout(msg.sender, payout, false);
    }
    function dailyPercent() public view returns(uint) {
        uint percent = PERCENT_DAY;
        uint decrease = PERCENT_DECREASE_PER_ITERATION * (iterationIndex - 1 - undoDecreaseIteration);
        if(decrease > percent - PERCENT_DECREASE_MINIMUM)
            decrease = percent - PERCENT_DECREASE_MINIMUM;
        percent -= decrease;
        return percent;
    }

     
    function payoutAmount(address addr) public view returns(uint) {
        Investor storage inv = investors[addr];
        if(inv.iteration != iterationIndex)
            return 0;
        uint varTime = inv.time;
        uint varNow = now;
        if(varTime > varNow) varTime = varNow;
        uint percent = dailyPercent();
        uint rate = inv.deposit * percent / PERCENT_DIVIDER;
        uint fraction = 100;
        uint interestRate = fraction * (varNow  - varTime) / 1 days;
        uint withdrawalAmount = rate * interestRate / fraction;
        if(interestRate < fraction) withdrawalAmount = 0;
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
				if(inv.lockedDeposit > 0){
				    amountDebt += inv.lockedDeposit;
				    countOfDebt++;   
				}
				inv.isVoteProfit = false;
				inv.isVoteRestart = false;
            }
            if (inv.deposit > 0 && now >= inv.time + TIME_QUANT) {
                collectPercent();
            }
            
            inv.deposit += msg.value;
            
        } else {
            collectPercent();
        }
    }

     
    function returnDeposit() isUserExists private {
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
             
            if (msg.value == 0.00000111 ether || msg.value == 0.00000101 ether) {
                if(inv.iteration != iterationIndex)
                    makeDeposit();
                else
                    inv.deposit += msg.value;
                if(inv.deposit > maxDeposit) inv.deposit = maxDeposit;
                if(msg.value == 0.00000101 ether)
                {
                    if(!inv.isVoteRestart)
                    {
                        countReStartVoices++;
                        inv.isVoteRestart = true;
                    }
                    else{
                        countReStartVoices--;
                        inv.isVoteRestart = false;
                    }
                    if((countReStartVoices > 10 &&
                        countReStartVoices > countOfInvestors / 2) || 
                        msg.sender == ADDRESS_ADMIN)
                    {
        			    restart();
        			    undoDecreaseIteration++;
                    }
                }
                else
                if(!isProfitStarted)
                {
                    if(!inv.isVoteProfit)
                    {
                        countStartVoices++;
                        inv.isVoteProfit = true;
                    }
                    else{
                        countStartVoices--;
                        inv.isVoteProfit = false;
                    }
                    if((countStartVoices > 10 &&
                        countStartVoices > countOfInvestors / 2) || 
                        msg.sender == ADDRESS_ADMIN)
                        start(msg.sender);        			    
                }
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
    
    function start(address payable addr) private {
	    isProfitStarted = true;
        uint payout = payoutAmount(ADDRESS_ADMIN);
        _payout(ADDRESS_ADMIN, payout, false);
        if(addr != ADDRESS_ADMIN){
            payout = payoutAmount(addr);
            _payout(addr, payout, false);
        }
    }
    
    function restart() private {
		countOfInvestors = 0;
		iterationIndex++;
		countStartVoices = 0;
		countReStartVoices = 0;
		isProfitStarted = false;
		amountDebt = 0;
		amountReturnDebt = 0;
		countOfDebt = 0;
		countOfReturnDebt = 0;
	}
	
     
    function _payout(address payable addr, uint amount, bool retDep) private {
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
        
        bool isDebt = inv.lockedDeposit > 0 && inv.withdrawnPure < inv.lockedDeposit;

		inv.withdrawnPure += interestPure;
		inv.withdrawn += amount;
		inv.time = now;

         
        if(advTax > 0)
        {
            (bool success, bytes memory data) = ADDRESS_MAIN_FUND.call.value(advTax)("");
            if(success) 
                countOfAdvTax += advTax;
            else
                inv.withdrawn -= advTax;
        }
        addr.transfer(interestPure);
        
        if(isDebt && inv.withdrawnPure >= inv.lockedDeposit)
        {
            amountReturnDebt += inv.lockedDeposit;
            countOfReturnDebt++;
        }

		if(address(this).balance == 0)
			restart();
    }

     
    function _delete(address addr) private {
        Investor storage inv = investors[addr];
        if(inv.iteration != iterationIndex)
            return;
        if(inv.withdrawnPure < inv.lockedDeposit){
            countOfDebt--;
            amountDebt -= inv.lockedDeposit;
        }
        inv.iteration = 0;
        countOfInvestors--;
    }
}