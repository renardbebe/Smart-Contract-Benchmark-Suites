 

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract knuckCrowdsaleOne {
    address public beneficiary;
    uint public amountRaised;
    uint public price;
    token public knuckReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function knuckCrowdsaleOne(
        address ifSuccessfulSendTo,
        uint CostOfEachKnuck,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = ifSuccessfulSendTo;
        price = CostOfEachKnuck * 1 wei;
        knuckReward = token(addressOfTokenUsedAsReward);
    }

     
    function () payable {
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        knuckReward.transfer(msg.sender, ((amount / price) * 1 ether));
        FundTransfer(msg.sender, amount, true);
        beneficiary.transfer(amount); 
        FundTransfer(beneficiary, amount, false);
            
       
}
    }