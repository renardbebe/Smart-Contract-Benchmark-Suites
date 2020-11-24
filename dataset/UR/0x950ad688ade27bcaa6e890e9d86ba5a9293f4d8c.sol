 

pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public amountRemaining;
    uint public deadline;
    uint public price;
    token public tokenReward;
    bool crowdsaleClosed = false;
    
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function Crowdsale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = 5000 * 1 ether;
        deadline = 1532361600;
        price = 10 szabo;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        amountRaised += amount;
        amountRemaining+= amount;
        tokenReward.transfer(msg.sender, amount / price);
       emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            emit GoalReached(beneficiary, amountRaised);
        }
        else
        {
	        tokenReward.transfer(beneficiary, (fundingGoal-amountRaised) / price);
        }
        crowdsaleClosed = true;
    }
     
    function safeWithdrawal() public afterDeadline {
        if (beneficiary == msg.sender) {
            if (beneficiary.send(amountRemaining)) {
               amountRemaining =0;
               emit FundTransfer(beneficiary, amountRemaining, false);
           }
        }
    }
}