 

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract TestCrowdsaleCryptoMind {
    address public beneficiary;
    uint public fundingGoal;
    uint public MaxToken;
    uint public amountRaised;
    uint public deadline;
    uint public StartCrowdsale;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    

     
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function TestCrowdsaleCryptoMind() {
        beneficiary = 0x41A2fe9687Ae815176166616D222B48DA6a36546;
        fundingGoal = 0.01 * 1 ether;
        MaxToken = 300 * 1 ether;
        StartCrowdsale = 1507766400;
        deadline = 1508536800;
        price = 1000;
        tokenReward = token(0xbCBD4c956E765fEEce4F44ea6909A9301C6c4703);
    }

     
    function () payable {
        require(!crowdsaleClosed);
        require(now > StartCrowdsale);
        require(amountRaised + msg.value > amountRaised);
        require(amountRaised + msg.value < MaxToken);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * price);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
             
        }
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() afterDeadline {
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
}