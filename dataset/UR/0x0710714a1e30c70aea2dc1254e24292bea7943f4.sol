 

 
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

contract Token {
    function issue(address _recipient, uint256 _value) returns (bool success) {}
    function issueAtIco(address _recipient, uint256 _value, uint256 _icoNumber) returns (bool success) {}
    function totalSupply() constant returns (uint256 supply) {}
    function unlock() returns (bool success) {}
}

contract RICHCrowdsale {

    using SafeMath for uint256;

     
    address public creator;  
    address public buyBackFund;  
    address public humanityFund;  

     
    uint256 public creatorWithdraw = 0;  
    uint256 public maxCreatorWithdraw = 5 * 10 ** 3 * 10**18;  
    uint256 public percentageHumanityFund = 51;  
    uint256 public percentageBuyBackFund = 49;  

     
    uint256 public currentMarketRate = 1;  
    uint256 public minimumIcoRate = 240;  
    uint256 public minAcceptedEthAmount = 4 finney;  

     
    uint256 public maxTotalSupply = 1000000000 * 10**8;  

    mapping (uint256 => uint256) icoTokenIssued;  
    uint256 public totalTokenIssued;  

    uint256 public icoPeriod = 10 days;
    uint256 public noIcoPeriod = 10 days;
    uint256 public maxIssuedTokensPerIco = 10**6 * 10**8;  
    uint256 public preIcoPeriod = 30 days;

    uint256 public bonusPreIco = 50;
    uint256 public bonusFirstIco = 30;
    uint256 public bonusSecondIco = 10;

    uint256 public bonusSubscription = 5;
    mapping (address => uint256) subsriptionBonusTokensIssued;

     
    mapping (address => uint256) balances;
    mapping (address => uint256) tokenBalances;
    mapping (address => mapping (uint256 => uint256)) tokenBalancesPerIco;

    enum Stages {
        Countdown,
        PreIco,
        PriorityIco,
        OpenIco,
        Ico,  
        NoIco,
        Ended
    }

    Stages public stage = Stages.Countdown;

     
    uint public start;
    uint public preIcoStart;

     
    Token public richToken;

     
    modifier atStage(Stages _stage) {
        updateState();

        if (stage != _stage && _stage != Stages.Ico) {
            throw;
        }

        if (stage != Stages.PriorityIco && stage != Stages.OpenIco && stage != Stages.PreIco) {
            throw;
        }
        _;
    }


     
    modifier onlyCreator() {
        if (creator != msg.sender) {
            throw;
        }
        _;
    }

     
    function getPercentageBonusForIco(uint256 _currentIco) returns (uint256 percentage) {
        updateState();

        if (stage == Stages.PreIco) {
            return bonusPreIco;
        }

        if (_currentIco == 1) {
            return bonusFirstIco;
        }

        if (_currentIco == 2) {
            return bonusSecondIco;
        }

        return 0;
    }

     
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }

     
    function RICHCrowdsale(address _tokenAddress, address _creator, uint256 _start, uint256 _preIcoStart) {
        richToken = Token(_tokenAddress);
        creator = _creator;
        start = _start;
        preIcoStart = _preIcoStart;
    }

     
    function setCurrentMarketRate(uint256 _currentMarketRate) onlyCreator returns (uint256) {
        currentMarketRate = _currentMarketRate;
    }

     
    function setMinimumIcoRate(uint256 _minimumIcoRate) onlyCreator returns (uint256) {
        minimumIcoRate = _minimumIcoRate;
    }

     
    function setHumanityFund(address _humanityFund) onlyCreator {
        humanityFund = _humanityFund;
    }

     
    function setBuyBackFund(address _buyBackFund) onlyCreator {
        buyBackFund = _buyBackFund;
    }

     
    function getRate() returns (uint256 rate) {
        if (currentMarketRate * 12 / 10 < minimumIcoRate) {
            return minimumIcoRate;
        }

        return currentMarketRate * 12 / 10;
    }

     
    function getInvestorTokenPercentage(address _investor, uint256 exeptInIco) returns (uint256 percentage) {
        uint256 deductionInvestor = 0;
        uint256 deductionIco = 0;

        if (exeptInIco >= 0) {
            deductionInvestor = tokenBalancesPerIco[_investor][exeptInIco];
            deductionIco = icoTokenIssued[exeptInIco];
        }

        if (totalTokenIssued - deductionIco == 0) {
            return 0;
        }

        return 1000000 * (tokenBalances[_investor] - deductionInvestor) / (totalTokenIssued - deductionIco);
    }

     
    function toRICH(uint256 _wei) returns (uint256 amount) {
        uint256 rate = getRate();

        return _wei * rate * 10**8 / 1 ether;  
    }

     
    function getCurrentIcoNumber() returns (uint256 amount) {
        uint256 timeBehind = now - start;
        if (now < start) {
            return 0;
        }

        return 1 + ((timeBehind - (timeBehind % (icoPeriod + noIcoPeriod))) / (icoPeriod + noIcoPeriod));
    }

     
    function updateState() {
        uint256 timeBehind = now - start;
        uint256 currentIcoNumber = getCurrentIcoNumber();

        if (icoTokenIssued[currentIcoNumber] >= maxIssuedTokensPerIco) {
            stage = Stages.NoIco;
            return;
        }

        if (totalTokenIssued >= maxTotalSupply) {
            stage = Stages.Ended;
            return;
        }

        if (now >= preIcoStart && now <= preIcoStart + preIcoPeriod) {
            stage = Stages.PreIco;
            return;
        }

        if (now < start) {
            stage = Stages.Countdown;
            return;
        }

        uint256 timeFromIcoStart = timeBehind - (currentIcoNumber - 1) * (icoPeriod + noIcoPeriod);

        if (timeFromIcoStart > icoPeriod) {
            stage = Stages.NoIco;
            return;
        }

        if (timeFromIcoStart > icoPeriod / 2) {
            stage = Stages.OpenIco;
            return;
        }

        stage = Stages.PriorityIco;
    }


     
    function withdraw() onlyCreator {
        uint256 ethBalance = this.balance;
        uint256 amountToSend = ethBalance - 100000000;

        if (creatorWithdraw < maxCreatorWithdraw) {
            if (amountToSend > maxCreatorWithdraw - creatorWithdraw) {
                amountToSend = maxCreatorWithdraw - creatorWithdraw;
            }

            if (!creator.send(amountToSend)) {
                throw;
            }

            creatorWithdraw += amountToSend;
            return;
        }

        uint256 ethForHumanityFund = amountToSend * percentageHumanityFund / 100;
        uint256 ethForBuyBackFund = amountToSend * percentageBuyBackFund / 100;

        if (!humanityFund.send(ethForHumanityFund)) {
            throw;
        }

        if (!buyBackFund.send(ethForBuyBackFund)) {
            throw;
        }
    }

     
    function sendSubscriptionBonus(address investorAddress) onlyCreator {
        uint256 subscriptionBonus = tokenBalances[investorAddress] * bonusSubscription / 100;

        if (subsriptionBonusTokensIssued[investorAddress] < subscriptionBonus) {
            uint256 toBeIssued = subscriptionBonus - subsriptionBonusTokensIssued[investorAddress];
            if (!richToken.issue(investorAddress, toBeIssued)) {
                throw;
            }

            subsriptionBonusTokensIssued[investorAddress] += toBeIssued;
        }
    }

     
    function () payable atStage(Stages.Ico) {
        uint256 receivedEth = msg.value;

        if (receivedEth < minAcceptedEthAmount) {
            throw;
        }

        uint256 tokensToBeIssued = toRICH(receivedEth);
        uint256 currentIco = getCurrentIcoNumber();

         
        tokensToBeIssued = tokensToBeIssued + (tokensToBeIssued * getPercentageBonusForIco(currentIco) / 100);

        if (tokensToBeIssued == 0 || icoTokenIssued[currentIco] + tokensToBeIssued > maxIssuedTokensPerIco) {
            throw;
        }

        if (stage == Stages.PriorityIco) {
            uint256 alreadyBoughtInIco = tokenBalancesPerIco[msg.sender][currentIco];
            uint256 canBuyTokensInThisIco = maxIssuedTokensPerIco * getInvestorTokenPercentage(msg.sender, currentIco) / 1000000;

            if (tokensToBeIssued > canBuyTokensInThisIco - alreadyBoughtInIco) {
                throw;
            }
        }

        if (!richToken.issue(msg.sender, tokensToBeIssued)) {
            throw;
        }

        icoTokenIssued[currentIco] += tokensToBeIssued;
        totalTokenIssued += tokensToBeIssued;
        balances[msg.sender] += receivedEth;
        tokenBalances[msg.sender] += tokensToBeIssued;
        tokenBalancesPerIco[msg.sender][currentIco] += tokensToBeIssued;
    }
}