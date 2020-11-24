 

pragma solidity ^0.4.15;

 
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
    function transferOwnership(address _newOwner) {}
}


contract CryptoCopyCrowdsale {

    using SafeMath for uint256;

     
    address public creator;
    address public buyBackFund;
    address public bountyPool;
    address public advisoryPool;

    uint256 public minAcceptedEthAmount = 100 finney;  

     
    uint256 public maxTotalSupply = 1000000 * 10**8;  
    uint256 public tokensForInvestors = 900000 * 10**8;  
    uint256 public tokensForBounty = 50000 * 10**8;  
    uint256 public tokensForAdvisory = 50000 * 10**8;  

    uint256 public totalTokenIssued;  

    uint256 public bonusFirstTwoDaysPeriod = 2 days;
    uint256 public bonusFirstWeekPeriod = 9 days;
    uint256 public bonusSecondWeekPeriod = 16 days;
    uint256 public bonusThirdWeekPeriod = 23 days;
    uint256 public bonusFourthWeekPeriod = 30 days;
    
    uint256 public bonusFirstTwoDays = 20;
    uint256 public bonusFirstWeek = 15;
    uint256 public bonusSecondWeek = 10;
    uint256 public bonusThirdWeek = 5;
    uint256 public bonusFourthWeek = 5;
    uint256 public bonusSubscription = 5;
    
    uint256 public bonusOver3ETH = 10;
    uint256 public bonusOver10ETH = 20;
    uint256 public bonusOver30ETH = 30;
    uint256 public bonusOver100ETH = 40;

     
    mapping (address => uint256) balancesETH;
    mapping (address => uint256) balancesETHWithBonuses;
    mapping (address => uint256) balancesETHForSubscriptionBonus;
    mapping (address => uint256) tokenBalances;
    
    uint256 public totalInvested;
    uint256 public totalInvestedWithBonuses;

    uint256 public hardCap = 100000 ether;  
    uint256 public softCap = 175 ether;  
    
    enum Stages {
        Countdown,
        Ico,
        Ended
    }

    Stages public stage = Stages.Countdown;

     
    uint public start;
    uint public end;

     
    Token public CryptoCopyToken;
    
    function setToken(address newToken) public onlyCreator {
        CryptoCopyToken = Token(newToken);
    }
    
    function returnOwnershipOfToken() public onlyCreator {
        CryptoCopyToken.transferOwnership(creator);
    }
    
     
    function setCreator(address _creator) public onlyCreator {
        creator = _creator;
    }

     
    modifier atStage(Stages _stage) {
        updateState();

        if (stage != _stage) {
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

     
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balancesETH[_investor];
    }

     
    function CryptoCopyCrowdsale(address _tokenAddress, uint256 _start, uint256 _end) {
        CryptoCopyToken = Token(_tokenAddress);
        creator = msg.sender;
        start = _start;
        end = _end;
    }
    
     
    function withdrawBountyAndAdvisory() onlyCreator {
        if (!CryptoCopyToken.issue(bountyPool, tokensForBounty)) {
            throw;
        }
        
        if (!CryptoCopyToken.issue(advisoryPool, tokensForAdvisory)) {
            throw;
        }
    }
    
     
    function setEnd(uint256 _end) onlyCreator {
        end = _end;
    }
    
     
    function setBountyPool(address _bountyPool) onlyCreator {
        bountyPool = _bountyPool;
    }
    
     
    function setAdvisoryPool(address _advisoryPool) onlyCreator {
        advisoryPool = _advisoryPool;
    }
    
     
    function setBuyBackFund(address _buyBackFund) onlyCreator {
        buyBackFund = _buyBackFund;
    }

     
    function updateState() {
        uint256 timeBehind = now - start;

        if (totalInvested >= hardCap || now > end) {
            stage = Stages.Ended;
            return;
        }
        
        if (now < start) {
            stage = Stages.Countdown;
            return;
        }

        stage = Stages.Ico;
    }

     
    function releaseTokens(address investorAddress) onlyCreator {
        if (stage != Stages.Ended) {
            return;
        }
        
        uint256 tokensToBeReleased = tokensForInvestors * balancesETHWithBonuses[investorAddress] / totalInvestedWithBonuses;

        if (tokenBalances[investorAddress] == tokensToBeReleased) {
            return;
        }
        
        if (!CryptoCopyToken.issue(investorAddress, tokensToBeReleased - tokenBalances[investorAddress])) {
            throw;
        }
        
        tokenBalances[investorAddress] = tokensToBeReleased;
    }

     
    function withdraw() onlyCreator {
        uint256 ethBalance = this.balance;
        
        if (stage != Stages.Ended) {
            throw;
        }
        
        if (!creator.send(ethBalance)) {
            throw;
        }
    }
    

     
    function addSubscriptionBonus(address investorAddress) onlyCreator {
        uint256 alreadyIncludedSubscriptionBonus = balancesETHForSubscriptionBonus[investorAddress];
        
        uint256 subscriptionBonus = balancesETH[investorAddress] * bonusSubscription / 100;
        
        balancesETHForSubscriptionBonus[investorAddress] = subscriptionBonus;
        
        totalInvestedWithBonuses = totalInvestedWithBonuses.add(subscriptionBonus - alreadyIncludedSubscriptionBonus);
        balancesETHWithBonuses[investorAddress] = balancesETHWithBonuses[investorAddress].add(subscriptionBonus - alreadyIncludedSubscriptionBonus);
    }

     
    function () payable atStage(Stages.Ico) {
        uint256 receivedEth = msg.value;
        uint256 totalBonuses = 0;

        if (receivedEth < minAcceptedEthAmount) {
            throw;
        }
        
        if (now < start + bonusFirstTwoDaysPeriod) {
            totalBonuses += bonusFirstTwoDays;
        } else if (now < start + bonusFirstWeekPeriod) {
            totalBonuses += bonusFirstWeek;
        } else if (now < start + bonusSecondWeekPeriod) {
            totalBonuses += bonusSecondWeek;
        } else if (now < start + bonusThirdWeekPeriod) {
            totalBonuses += bonusThirdWeek;
        } else if (now < start + bonusFourthWeekPeriod) {
            totalBonuses += bonusFourthWeek;
        }
        
        if (receivedEth >= 100 ether) {
            totalBonuses += bonusOver100ETH;
        } else if (receivedEth >= 30 ether) {
            totalBonuses += bonusOver30ETH;
        } else if (receivedEth >= 10 ether) {
            totalBonuses += bonusOver10ETH;
        } else if (receivedEth >= 3 ether) {
            totalBonuses += bonusOver3ETH;
        }
        
        uint256 receivedEthWithBonuses = receivedEth + (receivedEth * totalBonuses / 100);
        
        totalInvested = totalInvested.add(receivedEth);
        totalInvestedWithBonuses = totalInvestedWithBonuses.add(receivedEthWithBonuses);
        balancesETH[msg.sender] = balancesETH[msg.sender].add(receivedEth);
        balancesETHWithBonuses[msg.sender] = balancesETHWithBonuses[msg.sender].add(receivedEthWithBonuses);
    }
}