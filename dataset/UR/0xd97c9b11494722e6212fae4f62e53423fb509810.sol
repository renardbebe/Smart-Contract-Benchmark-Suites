 

pragma solidity >=0.4.25 <0.6.0;

 

interface token {
    function transfer(address receiver, uint amount) external;
}

contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract LightCrowdsale1 is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeMath for uint;

    address payable public beneficiary;  
    uint public fundingGoal;  
    uint public amountRaised;  
    uint public minAmountWei;  
    uint public deadline;  
    uint public price;  
    token public tokenReward;  
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    constructor(
        address payable ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint finneyCostOfEachToken,
        address addressOfTokenUsedAsReward,
        uint minAmountFinney
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = finneyCostOfEachToken * 1 finney;
        minAmountWei = minAmountFinney * 1 finney;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function() payable external {
        buyTokens(msg.sender);
    }

    function buyTokens(address sender) public nonReentrant payable {
        checkGoalReached();
        require(!crowdsaleClosed);
        require(sender != address(0));
        uint amount = msg.value;
        require(balanceOf[sender] >= amount);
        require(amount != 0);
        require(amount >= minAmountWei);

        uint senderBalance = balanceOf[sender];
        balanceOf[sender] = senderBalance.add(amount);
        amountRaised = amountRaised.add(amount);
        uint tokenToSend = amount.div(price) * 1 ether;
        tokenReward.transfer(sender, tokenToSend);
        emit FundTransfer(sender, amount, true);

        if (beneficiary.send(amount)) {
            emit FundTransfer(beneficiary, amount, false);
        }

        checkGoalReached();
    }

    modifier afterDeadline() {if (now >= deadline) _;}

     
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            crowdsaleClosed = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        if (now > deadline) {
            crowdsaleClosed = true;
            emit GoalReached(beneficiary, amountRaised);
        }
    }
}