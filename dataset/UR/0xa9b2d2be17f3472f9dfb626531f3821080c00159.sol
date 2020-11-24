 

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

 
contract BitDegreeCrowdsale {
    using SafeMath for uint256;

     
    mapping(address => uint256) balances;

     
    token public reward;

     
    address public owner;

     
    uint public startTime;
    uint public endTime;

     
    address public wallet;

     
    uint256 public tokensSold;

     
    uint256 constant public softCap = 6250000 * (10**18);

     
    uint256 constant public hardCap = 336600000 * (10**18);

     
    bool private isStartTimeSet = false;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event Refund(address indexed receiver, uint256 amount);

     
    function BitDegreeCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, address _token, address _owner)  public {
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

        uint256 weiAmount = msg.value;
        uint256 returnToSender = 0;

         
        uint256 rate = getRate();

         
        uint256 tokens = weiAmount.mul(rate);

         
        if(tokensSold.add(tokens) > hardCap) {
            tokens = hardCap.sub(tokensSold);
            weiAmount = tokens.div(rate);
            returnToSender = msg.value.sub(weiAmount);
        }

         
        tokensSold = tokensSold.add(tokens);

         
        balances[beneficiary] = balances[beneficiary].add(weiAmount);

        assert(reward.transferFrom(owner, beneficiary, tokens));
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

         
        wallet.transfer(weiAmount);

         
        if(tokensSold == hardCap) {
            reward.setStartTime(now + 2 weeks);
        }

         
        if(!isStartTimeSet) {
            isStartTimeSet = true;
            reward.setStartTime(endTime + 2 weeks);
        }

         
        if(returnToSender > 0) {
            msg.sender.transfer(returnToSender);
        }
    }

     
    function getRate() internal constant returns (uint256) {
        if(now < (startTime + 1 weeks)) {
            return 11500;
        }

        if(now < (startTime + 2 weeks)) {
            return 11000;
        }

        if(now < (startTime + 3 weeks)) {
            return 10500;
        }

        return 10000;
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
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

}