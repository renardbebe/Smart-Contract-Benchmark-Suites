 

pragma solidity ^0.4.21;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

 
contract Ownable {
    
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract RateSetter {
  
    address public rateSetter;
    event RateSetterChanged(address indexed previousRateSetter, address indexed newRateSetter);

    function RateSetter() public {
        rateSetter = msg.sender;
    }

    modifier onlyRateSetter() {
        require(msg.sender == rateSetter);
        _;
    }

    function changeRateSetter(address newRateSetter) onlyRateSetter public {
        require(newRateSetter != address(0));
        emit RateSetterChanged(rateSetter, newRateSetter);
        rateSetter = newRateSetter;
    }

}

 
 
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract CCWhitelist {
    function isWhitelisted(address addr) public constant returns (bool);
}

 
contract Crowdsale is Ownable, RateSetter {
    using SafeMath for uint256;

     
    ERC20 public token;
     
    CCWhitelist public whitelist;
     
    uint256 public startTimeIco;
     
    uint256 public endTimeIco;
     
    address public wallet;
     
    uint32 public ethEurRate;
     
    uint32 public btcEthRate;
     
    uint256 public tokensSoldPre;
     
    uint256 public tokensSoldIco;
     
    uint256 public weiRaised;
     
    uint256 public eurRaised;
     
    uint256 public contributions;

     
    uint256 public icoPhase1Start;
    uint256 public icoPhase1End;
    uint256 public icoPhase2Start;
    uint256 public icoPhase2End;
    uint256 public icoPhase3Start;
    uint256 public icoPhase3End;
    uint256 public icoPhase4Start;
    uint256 public icoPhase4End;
  

     
    uint8 public icoPhaseDiscountPercentage1;
    uint8 public icoPhaseDiscountPercentage2;
    uint8 public icoPhaseDiscountPercentage3;
    uint8 public icoPhaseDiscountPercentage4;

     
    uint32 public HARD_CAP_EUR = 19170000;  
     
    uint32 public SOFT_CAP_EUR = 2000000;  
     
    uint256 public HARD_CAP_IN_TOKENS = 810 * 10**24;  

     
    mapping (address => uint) public contributors;

    function Crowdsale(uint256 _startTimeIco, uint256 _endTimeIco, uint32 _ethEurRate, uint32 _btcEthRate, address _wallet, address _tokenAddress, address _whitelistAddress, uint256 _tokensSoldPre, uint256 _contributions, uint256 _weiRaised, uint256 _eurRaised, uint256 _tokensSoldIco) public {
        require(_endTimeIco >= _startTimeIco);
        require(_ethEurRate > 0 && _btcEthRate > 0);
        require(_wallet != address(0));
        require(_tokenAddress != address(0));
        require(_whitelistAddress != address(0));
        require(_tokensSoldPre > 0);

        startTimeIco = _startTimeIco;
        endTimeIco = _endTimeIco;
        ethEurRate = _ethEurRate;
        btcEthRate = _btcEthRate;
        wallet = _wallet;
        token = ERC20(_tokenAddress);
        whitelist = CCWhitelist(_whitelistAddress);
        tokensSoldPre = _tokensSoldPre;
        contributions = _contributions;
        weiRaised = _weiRaised;
        eurRaised = _eurRaised;
        tokensSoldIco = _tokensSoldIco;
         
        icoPhase1Start = 1520208000;
        icoPhase1End = 1520812799;
        icoPhase2Start = 1520812800;
        icoPhase2End = 1526255999;
        icoPhase3Start = 1526256000;
        icoPhase3End = 1527465599;
        icoPhase4Start = 1527465600;
        icoPhase4End = 1528113600;
        icoPhaseDiscountPercentage1 = 40;  
        icoPhaseDiscountPercentage2 = 30;  
        icoPhaseDiscountPercentage3 = 20;  
        icoPhaseDiscountPercentage4 = 0;   
    }


     
     
     
    function setRates(uint32 _ethEurRate, uint32 _btcEthRate) public onlyRateSetter {
        require(_ethEurRate > 0 && _btcEthRate > 0);
        ethEurRate = _ethEurRate;
        btcEthRate = _btcEthRate;
        emit RatesChanged(rateSetter, ethEurRate, btcEthRate);
    }


     
     
     
    function setICOtime(uint256 _start, uint256 _end) external onlyOwner {
        require(_start < _end);
        startTimeIco = _start;
        endTimeIco = _end;
        emit ChangeIcoPhase(0, _start, _end);
    }


     
     
     
    function setIcoPhase1(uint256 _start, uint256 _end) external onlyOwner {
        require(_start < _end);
        icoPhase1Start = _start;
        icoPhase1End = _end;
        emit ChangeIcoPhase(1, _start, _end);
    }

     
     
     
    function setIcoPhase2(uint256 _start, uint256 _end) external onlyOwner {
        require(_start < _end);
        icoPhase2Start = _start;
        icoPhase2End = _end;
        emit ChangeIcoPhase(2, _start, _end);
    }

       
       
       
    function setIcoPhase3(uint256 _start, uint256 _end) external onlyOwner {
        require(_start < _end);
        icoPhase3Start = _start;
        icoPhase3End = _end;
        emit ChangeIcoPhase(3, _start, _end);
    }

     
     
     
    function setIcoPhase4(uint256 _start, uint256 _end) external onlyOwner {
        require(_start < _end);
        icoPhase4Start = _start;
        icoPhase4End = _end;
        emit ChangeIcoPhase(4, _start, _end);
    }

    function setIcoDiscountPercentages(uint8 _icoPhaseDiscountPercentage1, uint8 _icoPhaseDiscountPercentage2, uint8 _icoPhaseDiscountPercentage3, uint8 _icoPhaseDiscountPercentage4) external onlyOwner {
        icoPhaseDiscountPercentage1 = _icoPhaseDiscountPercentage1;
        icoPhaseDiscountPercentage2 = _icoPhaseDiscountPercentage2;
        icoPhaseDiscountPercentage3 = _icoPhaseDiscountPercentage3;
        icoPhaseDiscountPercentage4 = _icoPhaseDiscountPercentage4;
        emit DiscountPercentagesChanged(_icoPhaseDiscountPercentage1, _icoPhaseDiscountPercentage2, _icoPhaseDiscountPercentage3, _icoPhaseDiscountPercentage4);

    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

     
     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(whitelist.isWhitelisted(beneficiary));
        uint256 weiAmount = msg.value;
        require(weiAmount > 0);
        require(contributors[beneficiary].add(weiAmount) <= 200 ether);
        uint256 tokenAmount = 0;
        if (isIco()) {
            uint8 discountPercentage = getIcoDiscountPercentage();
            tokenAmount = getTokenAmount(weiAmount, discountPercentage);
             
            require(tokenAmount >= 10**18); 
            uint256 newTokensSoldIco = tokensSoldIco.add(tokenAmount); 
            require(newTokensSoldIco <= HARD_CAP_IN_TOKENS);
            tokensSoldIco = newTokensSoldIco;
        } else {
             
            require(false);
        }
        executeTransaction(beneficiary, weiAmount, tokenAmount);
    }

     
    function getIcoDiscountPercentage() internal constant returns (uint8) {
        if (icoPhase1Start >= now && now < icoPhase1End) {
            return icoPhaseDiscountPercentage1;
        }
        else if (icoPhase2Start >= now && now < icoPhase2End) {
            return icoPhaseDiscountPercentage2;
        } else if (icoPhase3Start >= now && now < icoPhase3End) {
            return icoPhaseDiscountPercentage3;
        } else {
            return icoPhaseDiscountPercentage4;
        }
    }

     
    function getTokenAmount(uint256 weiAmount, uint8 discountPercentage) internal constant returns (uint256) {
         
        require(discountPercentage >= 0 && discountPercentage < 100); 
        uint256 baseTokenAmount = weiAmount.mul(ethEurRate);
        uint256 denominator = 3 * (100 - discountPercentage);
        uint256 tokenAmount = baseTokenAmount.mul(10000).div(denominator);
        return tokenAmount;
    }

   
     
     
     
    function getCurrentTokenAmountForOneEth() public constant returns (uint256) {
        if (isIco()) {
            uint8 discountPercentage = getIcoDiscountPercentage();
            return getTokenAmount(1 ether, discountPercentage);
        } 
        return 0;
    }
  
     
     
    function getCurrentTokenAmountForOneBtc() public constant returns (uint256) {
        uint256 amountForOneEth = getCurrentTokenAmountForOneEth();
        return amountForOneEth.mul(btcEthRate).div(100);
    }

     
    function executeTransaction(address beneficiary, uint256 weiAmount, uint256 tokenAmount) internal {
        weiRaised = weiRaised.add(weiAmount);
        uint256 eurAmount = weiAmount.mul(ethEurRate).div(10**18);
        eurRaised = eurRaised.add(eurAmount);
        token.transfer(beneficiary, tokenAmount);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
        contributions = contributions.add(1);
        contributors[beneficiary] = contributors[beneficiary].add(weiAmount);
        wallet.transfer(weiAmount);
    }

     
    function isIco() public constant returns (bool) {
        return now >= startTimeIco && now <= endTimeIco;
    }

     
    function hasIcoEnded() public constant returns (bool) {
        return now > endTimeIco;
    }

     
    function cummulativeTokensSold() public constant returns (uint256) {
        return tokensSoldPre + tokensSoldIco;
    }

     
     
    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) { 
            owner.transfer(this.balance);
            return;
        }

        ERC20 erc20Token = ERC20(_token);
        uint balance = erc20Token.balanceOf(this);
        erc20Token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }

     
    event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount);
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
    event IcoPhaseAmountsChanged(uint256 _icoPhaseAmount1, uint256 _icoPhaseAmount2, uint256 _icoPhaseAmount3, uint256 _icoPhaseAmount4);
    event RatesChanged(address indexed _rateSetter, uint32 _ethEurRate, uint32 _btcEthRate);
    event DiscountPercentagesChanged(uint8 _icoPhaseDiscountPercentage1, uint8 _icoPhaseDiscountPercentage2, uint8 _icoPhaseDiscountPercentage3, uint8 _icoPhaseDiscountPercentage4);
     
    event ChangeIcoPhase(uint8 _phase, uint256 _start, uint256 _end);

}

 
contract CulturalCoinCrowdsale is Crowdsale {

    function CulturalCoinCrowdsale(uint256 _startTimeIco, uint256 _endTimeIco, uint32 _ethEurRate, uint32 _btcEthRate, address _wallet, address _tokenAddress, address _whitelistAddress, uint256 _tokensSoldPre, uint256 _contributions, uint256 _weiRaised, uint256 _eurRaised, uint256 _tokensSoldIco) 
    Crowdsale(_startTimeIco, _endTimeIco, _ethEurRate, _btcEthRate, _wallet, _tokenAddress, _whitelistAddress, _tokensSoldPre, _contributions, _weiRaised, _eurRaised, _tokensSoldIco) public {

    }

}