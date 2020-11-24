 

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract NyronChain_Crowdsale {
    address public beneficiary;
    uint public amountRaised;
    uint public rate;
    uint public softcap;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function NyronChain_Crowdsale() {
        beneficiary = 0x618a6e3DA0A159937917DC600D49cAd9d0054A70;
        rate = 1800;
        softcap = 5560 * 1 ether;
        tokenReward = token(0xE65a20195d53DD00f915d2bE49e55ffDB46380D7);
    }
    
     
    function () payable {
        require(msg.value > 0);
            uint amount = msg.value;
            balanceOf[msg.sender] += amount;
            amountRaised += amount;
            if(!crowdsaleClosed){ 
            if(amountRaised >= softcap){
                tokenReward.transfer(msg.sender, amount * rate);
            }else {
                tokenReward.transfer(msg.sender, amount * rate + amount * rate * 20 / 100);
            }}
            FundTransfer(msg.sender, amount, true);
    }
     
      
    function openCrowdsale() {
        if(beneficiary == msg.sender){
            crowdsaleClosed = false;
        }
    }
    
    
     
    function endCrowdsale() {
        if(beneficiary == msg.sender){
            crowdsaleClosed = true;
        }
    }

     
    function safeWithdrawal() {
        if(beneficiary == msg.sender){
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            }
        }
    }
}