 

pragma solidity ^0.4.18;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract token {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function setStartTime(uint _startTime) external;
}

 
contract ObirumCrowdsale{
    using SafeMath for uint256;

     
    uint256 public constant kRate = 20000;
    uint256 public constant kMinStake = 0.1 ether;
    uint256 public constant kMaxStake = 200 ether;

    uint256[9] internal stageLimits = [
        100 ether,
        300 ether,
        1050 ether,
        3050 ether,
        8050 ether,
        18050 ether,
        28050 ether,
        38050 ether,
        48050 ether
    ];
    uint128[9] internal stageDiscounts = [
        300,
        250,
        200,
        150,
        135,
        125,
        115,
        110,
        105
    ];

     
    mapping(address => uint256) balances;

    uint256 public weiRaised;
    uint8 public currentStage = 0;

     
    token public reward;

     
    address public owner;

     
    uint public startTime;
    uint public endTime;

     
    address public wallet;

     
    uint256 public tokensSold;

     
    uint256 constant public softCap = 106000000 * (10**18);

     
    uint256 constant public hardCap = 1151000000 * (10**18);

     
    bool private isStartTimeSet = false;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event Refund(address indexed receiver, uint256 amount);

     
    function ObirumCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, address _token, address _owner)  public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_owner != address(0));

        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
        owner = _owner;
        reward = token(_token);
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function () external payable {
        if(msg.sender == wallet) {
            require(hasEnded() && tokensSold < softCap);
        } else {
            buyTokens(msg.sender);
        }
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
        require(currentStage < getStageCount());
        
        uint256 value = msg.value;
        weiRaised = weiRaised.add(value);
        uint256 limit = getStageLimit(currentStage);
        uint256 dif = 0;
        uint256 returnToSender = 0;
    
        if(weiRaised > limit){
            dif = weiRaised.sub(limit);
            value = value.sub(dif);
            
            if(currentStage == getStageCount() - 1){
                returnToSender = dif;
                weiRaised = weiRaised.sub(dif);
                dif = 0;
            }
        }
        
        mintTokens(value, beneficiary);
        
        if(dif > 0){
            currentStage = currentStage + 1;
            mintTokens(dif, beneficiary);
        }

         
        if(tokensSold == hardCap) {
            reward.setStartTime(now + 2 weeks);
        }

         
        if(returnToSender > 0) {
            msg.sender.transfer(returnToSender);
        }
    }
    
    function mintTokens(uint256 value, address sender) private{
        uint256 tokens = value.mul(kRate).mul(getStageDiscount(currentStage)).div(100);
        
         
        tokensSold = tokensSold.add(tokens);
        
         
        balances[sender] = balances[sender].add(value);
        reward.transferFrom(owner, sender, tokens);
        
        TokenPurchase(msg.sender, sender, value, tokens);
        
         
        wallet.transfer(value);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0 && msg.value >= kMinStake && msg.value <= kMaxStake;
        bool hardCapNotReached = tokensSold < hardCap;
        return withinPeriod && nonZeroPurchase && hardCapNotReached;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime || tokensSold >= hardCap;
    }

     
    function claimRefund() external {
        require(hasEnded());
        require(tokensSold < softCap);

        uint256 amount = balances[msg.sender];

        if(address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                Refund(msg.sender, amount);
            }
        }
    }

     
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

    function getStageLimit(uint8 _stage) public view returns (uint256) {
        return stageLimits[_stage];
    }

    function getStageDiscount(uint8 _stage) public view returns (uint128) {
        return stageDiscounts[_stage];
    }

    function getStageCount() public view returns (uint8) {
        return uint8(stageLimits.length);
    }
}