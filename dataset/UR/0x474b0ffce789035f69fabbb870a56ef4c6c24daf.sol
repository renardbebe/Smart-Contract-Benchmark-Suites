 

pragma solidity ^0.5.0;

interface IReferrals {

    function getSplit(address user) external view returns (uint8 discount, uint8 referrer);
        
}

 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address payable _owner) public onlyOwner {
        owner = _owner;
    }

    function getOwner() public view returns (address payable) {
        return owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "must be owner to call this function");
        _;
    }

}


contract Referrals is Ownable {

    using SafeMath for uint;

    uint public discountLimit;
    uint public defaultDiscount;
    uint public defaultRefer;

    mapping(address => Split) public splits;

    struct Split {
        bool set;
        uint8 discountPercentage;
        uint8 referrerPercentage;
    }

    event SplitChanged(address user, uint8 discount, uint8 referrer);

    constructor(uint _discountLimit, uint _defaultDiscount, uint _defaultRefer) public {   
        setDiscountLimit(_discountLimit);
        setDefaults(_defaultDiscount, _defaultRefer);
    }

     
     
    function setSplit(uint8 discount, uint8 referrer) public {
        require(discountLimit >= discount + referrer, "can't give more than the limit");
        require(discount + referrer >= discount, "can't overflow");
        splits[msg.sender] = Split({
            discountPercentage: discount,
            referrerPercentage: referrer,
            set: true
        });
        emit SplitChanged(msg.sender, discount, referrer);
    }

     
    function overrideSplit(address user, uint8 discount, uint8 referrer) public onlyOwner {
        require(discountLimit >= discount + referrer, "can't give more than the limit");
        require(discount + referrer >= discount, "can't overflow");
        splits[user] = Split({
            discountPercentage: discount,
            referrerPercentage: referrer,
            set: true
        });
        emit SplitChanged(user, discount, referrer);
    }

     
    function setDiscountLimit(uint _limit) public onlyOwner {
        require(_limit <= 100, "discount limit must be <= 100");
        discountLimit = _limit;
    }

     
    function setDefaults(uint _discount, uint _refer) public onlyOwner {
        require(discountLimit >= _discount + _refer, "can't be more than the limit");
        require(_discount + _refer >= _discount, "can't overflow");
        defaultDiscount = _discount;
        defaultRefer = _refer;
    }

     
    function getSplit(address user) public view returns (uint8 discount, uint8 referrer) {
        if (user == address(0)) {
            return (0, 0);
        }
        Split memory s = splits[user];
        if (!s.set) {
            return (uint8(defaultDiscount), uint8(defaultRefer));
        }
        return (s.discountPercentage, s.referrerPercentage);
    }

}




contract Processor is Ownable {

    using SafeMath for uint256;

    IReferrals public referrals;
    address payable public vault;
    uint public count;
    mapping(address => bool) public approvedSellers;

    event PaymentProcessed(uint id, address user, uint cost, uint items, address referrer, uint toVault, uint toReferrer);
    event SellerApprovalChanged(address seller, bool approved);

    constructor(address payable _vault, IReferrals _referrals) public {
        referrals = _referrals;
        vault = _vault;
    }

    function setCanSell(address seller, bool approved) public onlyOwner {
        approvedSellers[seller] = approved;
        emit SellerApprovalChanged(seller, approved);
    }

    function processPayment(address payable user, uint cost, uint items, address payable referrer) public payable returns (uint) {

        require(approvedSellers[msg.sender]);
        require(user != referrer, "can't refer yourself");
        require(items != 0, "have to purchase at least one item");
        require(cost > 0, "items must cost something");
         
        require(cost >= 100, "items must cost at least 100 wei");
        require(cost % 100 == 0, "costs must be multiples of 100");

        uint toVault;
        uint toReferrer;
        
        (toVault, toReferrer) = getAllocations(cost, items, referrer);

        uint total = toVault.add(toReferrer);

         
        require(msg.value >= total, "not enough value sent to contract");
        if (msg.value > total) {
            uint change = msg.value.sub(total);
            user.transfer(change);
        }

        vault.transfer(toVault);

         
        if (toReferrer > 0 && referrer != address(0)) {
            referrer.transfer(toReferrer);
        }

         
        uint id = count++;
        emit PaymentProcessed(id, user, cost, items, referrer, toVault, toReferrer);

        return id;
    }

     
     
    function getAllocations(uint cost, uint items, address referrer) public view returns (uint toVault, uint toReferrer) {
        uint8 discount;
        uint8 refer;
        (discount, refer) = referrals.getSplit(referrer);
        require(discount + refer <= 100 && discount + refer >= discount, "invalid referral split");
         
        uint total = cost.mul(items);
        uint8 vaultPercentage = 100 - discount - refer;
        toVault = getPercentage(total, vaultPercentage);
        toReferrer = getPercentage(total, refer);
        uint discountedTotal = getPercentage(total, 100 - discount);
        require(discountedTotal == toVault.add(toReferrer), "not all funds allocated");
        return (toVault, toReferrer);
    }

     
    function getPrice(uint cost, uint items, address referrer) public view returns (uint) {

        uint8 discount;
        (discount, ) = referrals.getSplit(referrer);

        return getPercentage(cost.mul(items), 100 - discount);
    }

    function getPercentage(uint amount, uint8 percentage) public pure returns (uint) {
        
         
        require(amount >= 100, "items must cost at least 100 wei");
        require(amount % 100 == 0, "costs must be multiples of 100 wei");
    
        return amount.mul(percentage).div(100);
    }

}