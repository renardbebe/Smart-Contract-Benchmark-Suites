 

pragma solidity ^0.4.11;

contract token { function transfer(address, uint){  } }

contract CrowdsaleWatch {
    address public beneficiary;
    uint public fundingGoal; uint public amountRaised; uint public deadline; uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    event GoalReached(address beneficiary, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    bool crowdsaleClosed = false;

     

     
    function CrowdsaleWatch(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        token addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 5000 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 5000000 wei;
        tokenReward = token(addressOfTokenUsedAsReward);
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
        if(amountRaised >= fundingGoal && !fundingGoalReached){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }
function safeWithdrawal() afterDeadline {
        checkGoalReached();
        if (!fundingGoalReached) {
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
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
    }
    
    function tokenWithdraw(uint256 amount) afterDeadline {
        if(beneficiary == msg.sender){
            tokenReward.transfer(msg.sender, amount);
        }
    }
}