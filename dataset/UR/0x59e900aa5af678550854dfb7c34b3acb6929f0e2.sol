 

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract CrowdsaleCryptoMindPreICO {
    address public beneficiary;
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

     
    function CrowdsaleCryptoMindPreICO() {
        beneficiary = 0x41A2fe9687Ae815176166616D222B48DA6a36546;
        MaxToken = 800 * 1 ether;
        StartCrowdsale = 1510358400;
        deadline = 1512086400;
        price = 5000;
        tokenReward = token(0xa7b67b22E0504D151E40d2782C8DB4a48DC202f6);
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
        fundingGoalReached = true;
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() afterDeadline {

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
    }
}