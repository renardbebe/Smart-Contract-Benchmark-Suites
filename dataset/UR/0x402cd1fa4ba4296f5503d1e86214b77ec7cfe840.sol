 

pragma solidity ^0.4.21;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    uint public starttime;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint weiCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiCostOfEachToken;
        tokenReward = token(addressOfTokenUsedAsReward);
        starttime = now;
    }

     
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        if (now < (starttime + 1440 * 1 minutes))
        {
            tokenReward.transfer(msg.sender, (amount * 1000000000000000000) / (price * 65 / 100));
        }
        else if (now < (starttime + 4320 * 1 minutes))
        {
            tokenReward.transfer(msg.sender, (amount * 1000000000000000000) / (price * 75 / 100));
        }
        else if (now < (starttime + 10080 * 1 minutes))
        {
            tokenReward.transfer(msg.sender, (amount * 1000000000000000000) / (price * 85 / 100));
        }
        else if (now < (starttime + 30240 * 1 minutes))
        {
            tokenReward.transfer(msg.sender, (amount * 1000000000000000000) / (price * 90 / 100));
        }
        else
        {
            tokenReward.transfer(msg.sender, (amount * 1000000000000000000) / price);
        }
       emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
    }
}