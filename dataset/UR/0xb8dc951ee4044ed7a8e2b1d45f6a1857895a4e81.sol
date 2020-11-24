 

 

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
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}

 
contract FastInvestTokenCrowdsale {
    using SafeMath for uint256;

    address public owner;

     
    token public tokenReward;

     
    address internal tokenOwner;

     
    address internal wallet;

     
    uint256 public startTime;
    uint256 public endTime;

     
    uint256 public tokensSold = 0;

     
    uint256 public weiRaised = 0;

     
    uint256 constant public SOFT_CAP        = 38850000000000000000000000;
    uint256 constant public FUNDING_GOAL    = 388500000000000000000000000;

     
    uint256 constant public RATE = 1000;
    uint256 constant public RATE_SOFT = 1200;

     
    mapping (address => uint256) public balanceOf;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function FastInvestTokenCrowdsale(address _tokenAddress, address _wallet, uint256 _start, uint256 _end) public {
        require(_tokenAddress != address(0));
        require(_wallet != address(0));

        owner = msg.sender;
        tokenOwner = msg.sender;
        wallet = _wallet;

        tokenReward = token(_tokenAddress);

        require(_start < _end);
        startTime = _start;
        endTime = _end;

    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 tokens = 0;

         
        if (tokensSold < SOFT_CAP) {
            tokens = weiAmount.mul(RATE_SOFT);

            if (tokensSold.add(tokens) > SOFT_CAP) {
                uint256 softTokens = SOFT_CAP.sub(tokensSold);
                uint256 amountLeft = weiAmount.sub(softTokens.div(RATE_SOFT));

                tokens = softTokens.add(amountLeft.mul(RATE));
            }

        } else  {
            tokens = weiAmount.mul(RATE);
        }

        require(tokens > 0);
        require(tokensSold.add(tokens) <= FUNDING_GOAL);

        forwardFunds();
        assert(tokenReward.transferFrom(tokenOwner, beneficiary, tokens));

        balanceOf[beneficiary] = balanceOf[beneficiary].add(weiAmount);

         
        weiRaised  = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool hasTokens = tokensSold < FUNDING_GOAL;

        return withinPeriod && nonZeroPurchase && hasTokens;
    }

    function setStart(uint256 _start) public onlyOwner {
        startTime = _start;
    }

    function setEnd(uint256 _end) public onlyOwner {
        require(startTime < _end);
        endTime = _end;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

}