 

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
    uint public endFirstBonus;
    uint public endSecondBonus;
    uint public endThirdBonus;
    uint public hardCap;
    uint public price;
    uint public minPurchase;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event CrowdsaleClose(uint totalAmountRaised, bool fundingGoalReached);

     
    function CrowdSale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward,
        uint tokensPerEth,
        uint _minPurchase,
        uint fundingGoalInWei,
        uint hardCapInWei,
        uint startTimeInSeconds,
        uint durationInMinutes,
        uint _endFirstBonus,
        uint _endSecondBonus,
        uint _endThirdBonus
    ) public {
        beneficiary = ifSuccessfulSendTo;
        tokenReward = token(addressOfTokenUsedAsReward);
        price = tokensPerEth;
        minPurchase = _minPurchase;
        fundingGoal = fundingGoalInWei;
        hardCap = hardCapInWei;
        startTime = startTimeInSeconds;
        deadline = startTimeInSeconds + durationInMinutes * 1 minutes;
        endFirstBonus = _endFirstBonus;
        endSecondBonus = _endSecondBonus;
        endThirdBonus = _endThirdBonus;
    }

     
    function purchase() internal {
        uint amount = msg.value;
        uint vp = amount * price;
        uint tokens = ((vp + ((vp * getBonus()) / 100))) / 1 ether;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transferFrom(beneficiary, msg.sender, tokens);
        checkGoalReached();
        FundTransfer(msg.sender, amount, true);
    }

     
    function()
    payable
    isOpen
    afterStart
    hardCapNotReached
    aboveMinValue
    public {
        purchase();
    }

     
    function shiftSalePurchase()
    payable
    isOpen
    afterStart
    hardCapNotReached
    aboveMinValue
    public returns (bool success) {
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
        require(msg.sender == beneficiary);
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

    modifier hardCapNotReached() {
        require(amountRaised < hardCap);
        _;
    }

    modifier aboveMinValue() {
        require(msg.value >= minPurchase);
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

     
    function setMinPurchaseValue(uint _minPurchase)
    isOwner
    public {
        minPurchase = _minPurchase;
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

    function getBonus() view public returns (uint) {
        if (startTime <= now) {
            if (now <= endFirstBonus) {
                return 50;
            } else if (now <= endSecondBonus) {
                return 40;
            } else if (now <= endThirdBonus) {
                return 30;
            } else {
                return 20;
            }
        }
        return 0;
    }
}