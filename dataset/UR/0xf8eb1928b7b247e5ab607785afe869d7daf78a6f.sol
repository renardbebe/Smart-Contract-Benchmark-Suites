 

pragma solidity ^0.4.8;

contract token {function transfer(address receiver, uint amount){ }}

contract Crowdsale {
    mapping(address => uint256) public balanceOf;

    uint public amountRaised; uint public tokensCounter; uint tokensForSending;

    token public tokenReward = token(0x9bB7Eb467eB11193966e726f3397d27136E79eb2);
    address public beneficiary = 0xA4047af02a2Fd8e6BB43Cfe8Ab25292aC52c73f4;
    bool public crowdsaleClosed = true;
    bool public admin = false;
    uint public price = 0.0000000333 ether;

    event FundTransfer(address backer, uint amount, bool isContribution);


    function () payable {
        uint amount = msg.value;
        if (crowdsaleClosed || amount < 0.1 ether) throw;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokensForSending = amount / price;
        tokenReward.transfer(msg.sender, tokensForSending);
        tokensCounter += tokensForSending;
        FundTransfer(msg.sender, amount, true);
        if (beneficiary.send(amount)) {
            FundTransfer(beneficiary, amount, false);
        }
    }

    function closeCrowdsale(bool closeType){
        if (beneficiary == msg.sender) {
            crowdsaleClosed = closeType;
        }
        else {
            throw;
        }
    }

    function getUnsoldTokensVal(uint val_) {
        if (beneficiary == msg.sender) {
            tokenReward.transfer(beneficiary, val_);
        }
        else {
            throw;
        }
    }
    
    function checkAdmin() {
        if (beneficiary == msg.sender) {
            admin =  true;
        }
        else {
            throw;
        }
    }
}