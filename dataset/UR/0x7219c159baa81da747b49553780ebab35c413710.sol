 

pragma solidity ^0.5.1;

 
 
contract X3ProfitInMonthV4 {

	struct Investor {
	       
		int iteration;
           
		uint deposit;
		   
		   
		uint lockedDeposit;
            
		uint time;
           
		uint withdrawn;
            
		uint withdrawnPure;
		    
		bool isVoteProfit;
		    
		bool isVoteRestart;
            
        bool isWeHaveDebt;
	}

    mapping(address => Investor) public investors;
	
     
    address payable public constant ADDRESS_MAIN_FUND = 0x3Bd33FF04e1F2BF01C8BF15C395D607100b7E116;
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
	int  public iterationIndex = 1;
	int  private undoDecreaseIteration = 0;
	uint public countOfReturnDebt = 0;

	uint public amountDebt = 0;
	uint public amountReturnDebt = 0;
	uint public amountOfCharity = 0;

     
     
	uint public constant maxBalance = 340282366920938463463374607431768211456 wei;  
	uint public constant maxDeposit = maxBalance / 1000; 
	
	 
    bool public isProfitStarted = false; 
    bool public isContractSealed = false;

    modifier isUserExists() {
        require(investors[msg.sender].iteration == iterationIndex, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(isContractSealed || now >= investors[msg.sender].time + TIME_QUANT, "Too fast payout request");
        _;
    }

     
    function collectPercent() isUserExists timePayment internal {
        uint payout = payoutAmount(msg.sender);
        _payout(msg.sender, payout, false);
    }
    function dailyPercent() public view returns(uint) {
        uint percent = PERCENT_DAY;
		int delta = 1 + undoDecreaseIteration;
		if (delta > iterationIndex) delta = iterationIndex;
        uint decrease = PERCENT_DECREASE_PER_ITERATION * (uint)(iterationIndex - delta);
        if(decrease > percent - PERCENT_DECREASE_MINIMUM)
            decrease = percent - PERCENT_DECREASE_MINIMUM;
        percent -= decrease;
        return percent;
    }

     
    function payoutAmount(address addr) public view returns(uint) {
        Investor storage inv = investors[addr];
        if(inv.iteration != iterationIndex)
            return 0;
        if (isContractSealed)
        {
            if(inv.withdrawnPure >= inv.deposit) {
                uint delta = 0;
                if(amountReturnDebt < amountDebt) delta = amountDebt - amountReturnDebt;
                
                 
                if(address(this).balance > delta) 
                    return address(this).balance - delta;
                return 0;
            }
            uint amount = inv.deposit - inv.withdrawnPure;
            return PERCENT_DIVIDER * amount / (PERCENT_DIVIDER - PERCENT_MAIN_FUND) + 1;
        }
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
        if (msg.value > 0.000000001 ether) {
            Investor storage inv = investors[msg.sender];
            if (inv.iteration != iterationIndex) {
			    inv.iteration = iterationIndex;
                countOfInvestors ++;
                if(inv.deposit > inv.withdrawnPure)
			        inv.deposit -= inv.withdrawnPure;
		        else
		            inv.deposit = 0;
		        if(inv.deposit + msg.value > maxDeposit) 
		            inv.deposit = maxDeposit - msg.value;
				inv.withdrawn = 0;
				inv.withdrawnPure = 0;
				inv.time = now;
				inv.lockedDeposit = inv.deposit;
			    amountDebt += inv.lockedDeposit;
				
				inv.isVoteProfit = false;
				inv.isVoteRestart = false;
                inv.isWeHaveDebt = true;
            }
            if (!isContractSealed && now >= inv.time + TIME_QUANT) {
                collectPercent();
            }
            if (!inv.isWeHaveDebt)
            {
                inv.isWeHaveDebt = true;
                countOfReturnDebt--;
                amountReturnDebt -= inv.deposit;
            }
            inv.deposit += msg.value;
            amountDebt += msg.value;
            
        } else {
            collectPercent();
        }
    }

     
    function returnDeposit() isUserExists private {
        if(isContractSealed)return;
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
    function charityToContract() external payable {
	    amountOfCharity += msg.value;
    }    
    function() external payable {
        if(msg.data.length > 0){
    	    amountOfCharity += msg.value;
            return;        
        }
        require(msg.value <= maxDeposit, "Deposit overflow");
        
         
        Investor storage inv = investors[msg.sender];
        if (!isContractSealed &&
            msg.value == 0.00000112 ether && inv.iteration == iterationIndex) {
            inv.deposit += msg.value;
            if(inv.deposit > maxDeposit) inv.deposit = maxDeposit;
            returnDeposit();
        } else {
             
            if ((!isContractSealed &&
                (msg.value == 0.00000111 ether || msg.value == 0.00000101 ether)) ||
                (msg.value == 0.00000102 ether&&msg.sender == ADDRESS_ADMIN)) 
            {
                if(inv.iteration != iterationIndex)
                    makeDeposit();
                else
                    inv.deposit += msg.value;
                if(inv.deposit > maxDeposit) inv.deposit = maxDeposit;
                if(msg.value == 0.00000102 ether){
                    isContractSealed = !isContractSealed;
                    if (!isContractSealed)
                    {
                        undoDecreaseIteration++;
                        restart();
                    }
                }
                else
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
        			    undoDecreaseIteration++;
        			    restart();
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
                    msg.value <= 0.000000001 ether ||
                    address(this).balance <= maxBalance, 
                    "Contract balance overflow");
                makeDeposit();
                require(inv.deposit <= maxDeposit, "Deposit overflow");
            }
        }
    }
    
    function start(address payable addr) private {
        if (isContractSealed) return;
	    isProfitStarted = true;
        uint payout = payoutAmount(ADDRESS_ADMIN);
        _payout(ADDRESS_ADMIN, payout, false);
        if(addr != ADDRESS_ADMIN){
            payout = payoutAmount(addr);
            _payout(addr, payout, false);
        }
    }
    
    function restart() private {
        if (isContractSealed) return;
        if(dailyPercent() == PERCENT_DECREASE_MINIMUM)
        {
            isContractSealed = true;
            return;
        }
		countOfInvestors = 0;
		iterationIndex++;
		countStartVoices = 0;
		countReStartVoices = 0;
		isProfitStarted = false;
		amountDebt = 0;
		amountReturnDebt = 0;
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
        bool isDeleteNeed = false;
		if(!isContractSealed && !retDep && !isProfitStarted && amount + inv.withdrawn > activDep / 2 )
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
    			isDeleteNeed = true;
			}
		}
        uint interestPure = amount * (PERCENT_DIVIDER - PERCENT_MAIN_FUND) / PERCENT_DIVIDER;

         
        uint advTax = amount - interestPure;
        
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
        if(interestPure > 0) addr.transfer(interestPure);
        
        if(inv.isWeHaveDebt && inv.withdrawnPure >= inv.deposit)
        {
            amountReturnDebt += inv.deposit;
            countOfReturnDebt++;
            inv.isWeHaveDebt = false;
        }
        
        if(isDeleteNeed)
			_delete(addr);

		if(address(this).balance == 0)
			restart();
    }

     
    function _delete(address addr) private {
        Investor storage inv = investors[addr];
        if(inv.iteration != iterationIndex)
            return;
        amountDebt -= inv.deposit;
        if(!inv.isWeHaveDebt){
            countOfReturnDebt--;
            amountReturnDebt-=inv.deposit;
            inv.isWeHaveDebt = true;
        }
        inv.iteration = -1;
        countOfInvestors--;
    }
}