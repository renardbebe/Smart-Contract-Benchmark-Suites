 

pragma solidity 0.4 .24;

 

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
        return c;
    }
}
contract SmartRocket {
    using SafeMath
    for uint;

    mapping(address => uint) public TimeOfInvestments;
    mapping(address => uint) public CalculatedProfit;
    mapping(address => uint) public SumOfInvestments;
    uint public WithdrawPeriod = 1 minutes;
    uint public HappyInvestors = 0;
    address public constant PromotionBank = 0x3B2CCc7B82f18eCAB670FA4802cFAE8e8957661d;
    address public constant BackUpBank = 0x0674D98b3f6f3045981029FDCD8adE493071ba37;

    modifier AreYouGreedy() {
        require(now >= TimeOfInvestments[msg.sender].add(WithdrawPeriod), "Don’t hurry, dude, not yet");
        _;
    }

    modifier AreYouLucky() {
        require(SumOfInvestments[msg.sender] > 0, "You are not with us, yet");
        _;
    }

    function() external payable {
        if (msg.value > 0) {
            if (SumOfInvestments[msg.sender] == 0) {
                HappyInvestors += 1;
            }
            if (SumOfInvestments[msg.sender] > 0 && now > TimeOfInvestments[msg.sender].add(WithdrawPeriod)) {
                PrepareToBeRich();
            }
            SumOfInvestments[msg.sender] = SumOfInvestments[msg.sender].add(msg.value);
            TimeOfInvestments[msg.sender] = now;
            PromotionBank.transfer(msg.value.mul(6).div(100));
            BackUpBank.transfer(msg.value.mul(3).div(100));
        } else {
            PrepareToBeRich();
        }
    }

    function PrepareToBeRich() AreYouGreedy AreYouLucky internal {
        if ((SumOfInvestments[msg.sender].mul(217).div(100)) <= CalculatedProfit[msg.sender]) {
            SumOfInvestments[msg.sender] = 0;
            CalculatedProfit[msg.sender] = 0;
            TimeOfInvestments[msg.sender] = 0;
        } else {
            uint GetYourMoney = YourPercent();
            CalculatedProfit[msg.sender] += GetYourMoney;
            TimeOfInvestments[msg.sender] = now;
            msg.sender.transfer(GetYourMoney);
        }
    }
 
    function YourPercent() public view returns(uint) {
        uint withdrawalAmount = ((SumOfInvestments[msg.sender].mul(1).div(36000)).mul(now.sub(TimeOfInvestments[msg.sender]).div(WithdrawPeriod)));
        return (withdrawalAmount);
    }
}