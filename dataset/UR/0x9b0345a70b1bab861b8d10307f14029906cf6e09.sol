 

pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount) public;
}

contract Presale {
    address public beneficiary;
    address public burner;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;

    uint public pricePresale = 10000;

     
     
     
    uint public presaleSupply = 6120000 * 1 ether;
    uint public availableSupply = 4000000 * 1 ether;

     
    uint public erotixFundMultiplier = 50;
    uint public foundersFundMultiplier = 3;

     
    uint public requestedTokens;
    uint public amountAvailable;

    address public erotixFund = 0x1a0cc2B7F7Cb6fFFd3194A2AEBd78A4a072915Be;
    
     
    address public foundersFund = 0xaefe05643b613823dBAF6245AFb819Fd56fBdd22; 

    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool presaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function Presale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint endOfPresale,
        address addressOfTokenUsedAsReward,
        address burnAddress
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = endOfPresale;
        tokenReward = token(addressOfTokenUsedAsReward);
        burner = burnAddress;
    }

     
    function () payable public {
        require(!presaleClosed);
        uint amount = msg.value;

         
        requestedTokens = amount * pricePresale;

         
        if (requestedTokens <= availableSupply) {
            balanceOf[msg.sender] += amount;
            amountRaised += amount;

             
            tokenReward.transfer(msg.sender, amount * pricePresale);
             
            tokenReward.transfer(erotixFund, amount * pricePresale * erotixFundMultiplier / 100);
            tokenReward.transfer(foundersFund, amount * pricePresale * foundersFundMultiplier / 100);

            FundTransfer(msg.sender, amount, true);

             
            availableSupply -= requestedTokens;
        } else {
             
            amountAvailable = availableSupply / pricePresale;
            balanceOf[msg.sender] += amountAvailable;
            amountRaised += amountAvailable;

             
            tokenReward.transfer(msg.sender, amountAvailable * pricePresale);
             
            tokenReward.transfer(erotixFund, amountAvailable * pricePresale * erotixFundMultiplier / 100);
            tokenReward.transfer(foundersFund, amountAvailable * pricePresale * foundersFundMultiplier / 100);

            FundTransfer(msg.sender, amountAvailable, true);

             
            availableSupply = 0;

             
            amount -= amountAvailable;
            msg.sender.send(amount);

             
            presaleClosed = true;
        }
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() afterDeadline public {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        presaleClosed = true;

        if (availableSupply > 0) {
            tokenReward.transfer(burner, availableSupply);
            tokenReward.transfer(burner, availableSupply * erotixFundMultiplier / 100);
            tokenReward.transfer(burner, availableSupply * foundersFundMultiplier / 100);
        }
    }


     
    function safeWithdrawal() public {
        if (now >= deadline) {
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
        }
        
        if (presaleClosed) {
            if (fundingGoalReached && beneficiary == msg.sender) {
                if (beneficiary.send(amountRaised)) {
                    FundTransfer(beneficiary, amountRaised, false);
                } else {
                     
                    fundingGoalReached = false;
                }
            }
        }
    }
}