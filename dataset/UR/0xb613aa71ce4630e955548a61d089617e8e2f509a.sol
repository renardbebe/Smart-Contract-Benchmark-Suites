 

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


contract MomsAvenueToken {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}


contract MomsAvenueCrowdsale {

    using SafeMath for uint256;

    MomsAvenueToken public token;

     
    uint256 constant public rate = 10000;
    
    uint256 constant public goal = 20000000 * (10 ** 18);
    uint256 public startTime;
    uint256 public endTime;
    uint256 public weiRaised;
    uint256 public tokensSold;

    bool public crowdsaleActive = true;

    address public wallet;
    address public tokenOwner;

    mapping(address => uint256) balances;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function MomsAvenueCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, address _token, address _tokenOwner) public {
        require(_startTime < _endTime);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_tokenOwner != address(0));

        startTime = _startTime;
        endTime = _endTime;

        wallet = _wallet;
        tokenOwner = _tokenOwner;
        token = MomsAvenueToken(_token);
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address investor) public payable {
        require(investor != address(0));
        require(now >= startTime && now <= endTime);
        require(crowdsaleActive);
        require(msg.value != 0);

        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

        require(tokensSold.add(tokens) <= goal);

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);
        balances[investor] = balances[investor].add(weiAmount);

        assert(token.transferFrom(tokenOwner, investor, tokens));
        TokenPurchase(msg.sender, investor, weiAmount, tokens);

        wallet.transfer(msg.value);
    }

    function setCrowdsaleActive(bool _crowdsaleActive) public {
        require(msg.sender == tokenOwner);
        crowdsaleActive = _crowdsaleActive;
    }

     
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }
}