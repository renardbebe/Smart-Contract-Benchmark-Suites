 

pragma solidity ^0.4.18;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public;
}

contract CrowdSale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public startTime;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool public crowdsaleClosed = false ;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event CrowdsaleClose(uint totalAmountRaised, bool fundingGoalReached);

     
    function CrowdSale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint startTimeInSeconds,
        uint durationInMinutes,
        uint szaboCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        startTime = startTimeInSeconds;
        deadline = startTimeInSeconds + durationInMinutes * 1 minutes;
        price = szaboCostOfEachToken * 1 finney;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function purchase() internal {
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transferFrom(beneficiary, msg.sender, (amount * price) / 1 ether);
        checkGoalReached();
        FundTransfer(msg.sender, amount, true);
    }

     
    function()
    payable
    isOpen
    afterStart
    public {
        purchase();
    }

     
    function shiftSalePurchase() payable public returns(bool success) {
        purchase();
        return true;
    }

    modifier afterStart() {
        require(now >= startTime);
        _;
    }

    modifier afterDeadline() {
        require(now >= deadline);
        _;
    }

    modifier previousDeadline() {
        require(now <= deadline);
        _;
    }

    modifier isOwner() {
        require (msg.sender == beneficiary);
        _;
    }

    modifier isClosed() {
        require(crowdsaleClosed);
        _;
    }

    modifier isOpen() {
        require(!crowdsaleClosed);
        _;
    }

     
    function checkGoalReached() internal {
        if (amountRaised >= fundingGoal && !fundingGoalReached) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
    }

     
    function closeCrowdsale()
    isOwner
    public {
        crowdsaleClosed = true;
        CrowdsaleClose(amountRaised, fundingGoalReached);
    }


     
    function safeWithdrawal()
    afterDeadline
    isClosed
    public {
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