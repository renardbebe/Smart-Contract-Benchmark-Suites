 

pragma solidity ^0.4.16;

interface token {
    function transfer (address receiver, uint amount) public;
}

contract Crowdsale {
    address public beneficiary;
    uint public amountRaised;
	uint public amountLeft;
    uint public deadline;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function Crowdsale(
        address teamMultisig,
        uint durationInMinutes,
        address addressOfTokenUsedAsReward
    ) public{
        beneficiary = teamMultisig;
        deadline = now + durationInMinutes * 1 minutes;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function () payable public{
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount*10000);
        FundTransfer(msg.sender, amount, true);
		if(beneficiary.send(amount)) 
		{
		    FundTransfer(beneficiary, amount, false);
		}
		else
		{
		    amountLeft += amountLeft;
		}
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function closeCrowdSale() afterDeadline public{
	    if(beneficiary == msg.sender)
	    {
            crowdsaleClosed = true;
		}
    }


     
    function safeWithdrawal() afterDeadline public{       
        if (beneficiary == msg.sender&& amountLeft > 0) {
            if (beneficiary.send(amountLeft)) {
                FundTransfer(beneficiary, amountLeft, false);
            } else {
            }
        }
    }
}