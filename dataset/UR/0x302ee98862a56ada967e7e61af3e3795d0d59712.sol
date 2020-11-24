 

pragma solidity ^0.4.2;

contract SOCToken {
     
    mapping (address => uint256) public balanceOf;

     
    function SOCToken(
        uint256 initialSupply
        ) {
        balanceOf[msg.sender] = initialSupply;               
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
    }
}


contract SOCTokenSale {
    address public beneficiary;
    uint public fundingGoal; 
	uint public amountRaised; 
	uint public deadline; 
	uint public price;
    SOCToken public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    uint softMarketingLimit = 25 * 1 ether;	
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool crowdsaleClosed = false;

     

     
    function SOCTokenSale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint pricePerEther,
        SOCToken addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = 1 ether / pricePerEther;
        tokenReward = SOCToken(addressOfTokenUsedAsReward);
    }

     
    function () payable {
        if (crowdsaleClosed) throw;
        uint amount = msg.value;
        balanceOf[msg.sender] = amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


    function withdrawal(uint amount) {
        if (msg.sender == beneficiary) {
            if (beneficiary.send(amount * 1 finney)) {
    			FundTransfer(beneficiary, amount * 1 finney, false);
            }
        }
    }	
	
    function safeWithdrawal() afterDeadline {
        if (amountRaised < softMarketingLimit) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(this.balance)) {
                FundTransfer(beneficiary, this.balance, false);
            } else {
                fundingGoalReached = false;
            }
        }
    }
}