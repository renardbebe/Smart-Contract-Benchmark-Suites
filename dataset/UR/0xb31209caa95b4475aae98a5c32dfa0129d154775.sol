 

pragma solidity ^0.4.18;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public;
}

contract RetailSale {
    address public beneficiary;
    uint public actualPrice;
    uint public nextPrice;
    uint public nextPriceDate = 0;
    uint public periodStart;
    uint public periodEnd;
    uint public bonus = 0;
    uint public bonusStart = 0;
    uint public bonusEnd = 0;
    uint public milestone = 0;
    uint public milestoneBonus = 0;
    bool public milestoneReached = true;
    uint public minPurchase;
    token public tokenReward;

    event FundTransfer(address backer, uint amount, uint bonus, uint tokens);

     
    function RetailSale(
        address _beneficiary,
        address addressOfTokenUsedAsReward,
        uint ethPriceInWei,
        uint _minPurchase,
        uint start,
        uint end
    ) public {
        beneficiary = _beneficiary;
        tokenReward = token(addressOfTokenUsedAsReward);
        actualPrice = ethPriceInWei;
        nextPrice = ethPriceInWei;
        minPurchase = _minPurchase;
        periodStart = start;
        periodEnd = end;
    }

     
    function()
    payable
    isOpen
    aboveMinValue
    public {
        uint price = actualPrice;
        if (now >= nextPriceDate) {
            price = nextPrice;
        }
        uint vp = (msg.value * 1 ether) / price;
        uint b = 0;
        uint tokens = 0;
        if (now >= bonusStart && now <= bonusEnd) {
            b = bonus;
        }
        if (this.balance >= milestone && !milestoneReached) {
            b = milestoneBonus;
            milestoneReached = true;
        }
        if (b == 0) {
            tokens = vp;
        } else {
            tokens = (vp + ((vp * b) / 100));
        }
        tokenReward.transferFrom(beneficiary, msg.sender, tokens);
        FundTransfer(msg.sender, msg.value, b, tokens);
    }

    modifier aboveMinValue() {
        require(msg.value >= minPurchase);
        _;
    }

    modifier isOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    modifier isClosed() {
        require(!(now >= periodStart && now <= periodEnd));
        _;
    }

    modifier isOpen() {
        require(now >= periodStart && now <= periodEnd);
        _;
    }

    modifier validPeriod(uint start, uint end){
        require(start < end);
        _;
    }

     
    function setNextPeriod(uint _start, uint _end)
    isOwner
    validPeriod(_start, _end)
    public {
        periodStart = _start;
        periodEnd = _end;
    }

     
    function setMinPurchase(uint _minPurchase)
    isOwner
    public {
        minPurchase = _minPurchase;
    }

     
    function changeBonus(uint _bonus, uint _bonusStart, uint _bonusEnd)
    isOwner
    public {
        bonus = _bonus;
        bonusStart = _bonusStart;
        bonusEnd = _bonusEnd;
    }

     
    function setNextMilestone(uint _milestone, uint _milestoneBonus)
    isOwner
    public {
        milestone = _milestone;
        milestoneBonus = _milestoneBonus;
        milestoneReached = false;
    }

     
    function setNextPrice(uint _price, uint _priceDate)
    isOwner
    public {
        actualPrice = nextPrice;
        nextPrice = _price;
        nextPriceDate = _priceDate;
    }


     
    function safeWithdrawal()
    isClosed
    isOwner
    public {

        beneficiary.transfer(this.balance);

    }

    function open() view public returns (bool) {
        return (now >= periodStart && now <= periodEnd);
    }

}