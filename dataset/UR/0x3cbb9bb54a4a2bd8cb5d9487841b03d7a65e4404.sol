 

pragma solidity ^0.4.15;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract DNNTDE {

    using SafeMath for uint256;

     
     
     
    DNNToken public dnnToken;

     
     
     
    address public cofounderA;
    address public cofounderB;

     
     
     
    address public dnnHoldingMultisig;

     
     
     
    uint256 public TDEStartDate;   

     
     
     
    uint256 public TDEEndDate;   

     
     
     
    uint256 public tokenExchangeRateBase = 3000;  

     
     
     
    uint256 public tokensDistributed = 0;

     
     
     
    uint256 public minimumTDEContributionInWei = 0.001 ether;
    uint256 public minimumPRETDEContributionInWei = 5 ether;

     
     
     
    uint256 public maximumFundingGoalInETH;

     
     
     
    uint256 public fundsRaisedInWei = 0;
    uint256 public presaleFundsRaisedInWei = 0;

     
     
     
    mapping(address => uint256) ETHContributions;


     
     
     
    mapping(address => uint256) PRETDEContributorTokensPendingRelease;
    uint256 PRETDEContributorsTokensPendingCount = 0;  
    uint256 TokensPurchasedDuringPRETDE = 0;  

     
     
     
    modifier NoPRETDEContributorsAwaitingTokens() {

         
        require(PRETDEContributorsTokensPendingCount == 0);

        _;
    }

     
     
     
    modifier PRETDEContributorsAwaitingTokens() {

         
        require(PRETDEContributorsTokensPendingCount > 0);

        _;
    }

     
     
     
    modifier onlyCofounders() {
        require (msg.sender == cofounderA || msg.sender == cofounderB);
        _;
    }

     
     
     
    modifier onlyCofounderA() {
        require (msg.sender == cofounderA);
        _;
    }

     
     
     
    modifier onlyCofounderB() {
        require (msg.sender == cofounderB);
        _;
    }

     
     
     
    modifier PRETDEHasNotEnded() {
       require (now < TDEStartDate);
       _;
    }

     
     
     
    modifier TDEHasEnded() {
       require (now >= TDEEndDate || fundsRaisedInWei >= maximumFundingGoalInETH);
       _;
    }

     
     
     
    modifier ContributionIsAtLeastMinimum() {
        require (msg.value >= minimumTDEContributionInWei);
        _;
    }

     
     
     
    modifier ContributionDoesNotCauseGoalExceedance() {
       uint256 newFundsRaised = msg.value+fundsRaisedInWei;
       require (newFundsRaised <= maximumFundingGoalInETH);
       _;
    }

     
     
     
    modifier HasPendingPRETDETokens(address _contributor) {
        require (PRETDEContributorTokensPendingRelease[_contributor] !=  0);
        _;
    }

     
     
     
    modifier IsNotAwaitingPRETDETokens(address _contributor) {
        require (PRETDEContributorTokensPendingRelease[_contributor] ==  0);
        _;
    }

     
     
     
     
    function changeCofounderA(address newAddress)
        onlyCofounderA
    {
        cofounderA = newAddress;
    }

     
     
     
     
    function changeCofounderB(address newAddress)
        onlyCofounderB
    {
        cofounderB = newAddress;
    }

     
     
     
     
    function extendPRETDE(uint256 startDate)
        onlyCofounders
        PRETDEHasNotEnded
        returns (bool)
    {
         
         
        if (startDate > now && startDate > TDEStartDate) {
            TDEEndDate = TDEEndDate + (startDate-TDEStartDate);  
            TDEStartDate = startDate;  
            return true;
        }

        return false;
    }

     
     
     
     
    function changeDNNHoldingMultisig(address newAddress)
        onlyCofounders
    {
        dnnHoldingMultisig = newAddress;
    }

     
     
     
    function contributorETHBalance(address _owner)
      constant
      returns (uint256 balance)
    {
        return ETHContributions[_owner];
    }

     
     
     
    function isAwaitingPRETDETokens(address _contributorAddress)
       internal
       returns (bool)
    {
        return PRETDEContributorTokensPendingRelease[_contributorAddress] > 0;
    }

     
     
     
    function getPendingPresaleTokens(address _contributor)
        constant
        returns (uint256)
    {
        return PRETDEContributorTokensPendingRelease[_contributor];
    }

     
     
     
    function getCurrentTDEBonus()
        constant
        returns (uint256)
    {
        return getTDETokenExchangeRate(now);
    }


     
     
     
    function getCurrentPRETDEBonus()
        constant
        returns (uint256)
    {
        return getPRETDETokenExchangeRate(now);
    }

     
     
     
     
    function getTDETokenExchangeRate(uint256 timestamp)
        constant
        returns (uint256)
    {
         
        if (timestamp > TDEEndDate) {
            return uint256(0);
        }

         
        if (TDEStartDate > timestamp) {
            return uint256(0);
        }

         
        if (fundsRaisedInWei <= maximumFundingGoalInETH.mul(20).div(100)) {
            return tokenExchangeRateBase.mul(120).div(100);

         
        } else if (fundsRaisedInWei > maximumFundingGoalInETH.mul(20).div(100) && fundsRaisedInWei <= maximumFundingGoalInETH.mul(60).div(100)) {
            return tokenExchangeRateBase.mul(115).div(100);

         
        } else if (fundsRaisedInWei > maximumFundingGoalInETH.mul(60).div(100) && fundsRaisedInWei <= maximumFundingGoalInETH) {
            return tokenExchangeRateBase.mul(110).div(100);

         
        } else {
            return tokenExchangeRateBase;
        }
    }

     
     
     
     
    function getPRETDETokenExchangeRate(uint256 weiamount)
        constant
        returns (uint256)
    {
         
        if (weiamount < minimumPRETDEContributionInWei) {
            return uint256(0);
        }

         
        if (weiamount >= minimumPRETDEContributionInWei && weiamount <= 199 ether) {
            return tokenExchangeRateBase + tokenExchangeRateBase.mul(25).div(100);

         
        } else if (weiamount >= 200 ether && weiamount <= 300 ether) {
            return tokenExchangeRateBase + tokenExchangeRateBase.mul(30).div(100);

         
        } else if (weiamount >= 301 ether && weiamount <= 2665 ether) {
            return tokenExchangeRateBase + tokenExchangeRateBase.mul(35).div(100);

         
        } else {
            return tokenExchangeRateBase + tokenExchangeRateBase.mul(50).div(100);
        }
    }

     
     
     
    function calculateTokens(uint256 weiamount, uint256 timestamp)
        constant
        returns (uint256)
    {

         
        uint256 computedTokensForPurchase = weiamount.mul(timestamp >= TDEStartDate ? getTDETokenExchangeRate(timestamp) : getPRETDETokenExchangeRate(weiamount));

         
        return computedTokensForPurchase;
     }


     
     
     
     
     
     
    function buyTokens()
        internal
        ContributionIsAtLeastMinimum
        ContributionDoesNotCauseGoalExceedance
        returns (bool)
    {

         
        uint256 tokenCount = calculateTokens(msg.value, now);

         
        tokensDistributed = tokensDistributed.add(tokenCount);

         
        ETHContributions[msg.sender] = ETHContributions[msg.sender].add(msg.value);

         
        fundsRaisedInWei = fundsRaisedInWei.add(msg.value);

         
        DNNToken.DNNSupplyAllocations allocationType = DNNToken.DNNSupplyAllocations.TDESupplyAllocation;

         
        if (!dnnToken.issueTokens(msg.sender, tokenCount, allocationType)) {
            revert();
        }

         
        dnnHoldingMultisig.transfer(msg.value);

        return true;
    }

     
     
     
     
     
    function buyPRETDETokensWithoutETH(address beneficiary, uint256 weiamount, uint256 tokenCount)
        onlyCofounders
        PRETDEHasNotEnded
        IsNotAwaitingPRETDETokens(beneficiary)
        returns (bool)
    {
           
          ETHContributions[beneficiary] = ETHContributions[beneficiary].add(weiamount);

           
          fundsRaisedInWei = fundsRaisedInWei.add(weiamount);

           
          presaleFundsRaisedInWei = presaleFundsRaisedInWei.add(weiamount);

           
          PRETDEContributorTokensPendingRelease[beneficiary] = PRETDEContributorTokensPendingRelease[beneficiary].add(tokenCount);

           
          PRETDEContributorsTokensPendingCount += 1;

           
          return issuePRETDETokens(beneficiary);
      }

     
     
     
     
    function issuePRETDETokens(address beneficiary)
        onlyCofounders
        PRETDEContributorsAwaitingTokens
        HasPendingPRETDETokens(beneficiary)
        returns (bool)
    {

         
        uint256 tokenCount = PRETDEContributorTokensPendingRelease[beneficiary];

         
        tokensDistributed = tokensDistributed.add(tokenCount);

         
        DNNToken.DNNSupplyAllocations allocationType = DNNToken.DNNSupplyAllocations.PRETDESupplyAllocation;

         
        if (!dnnToken.issueTokens(beneficiary, tokenCount, allocationType)) {
            revert();
        }

         
        PRETDEContributorsTokensPendingCount -= 1;

         
        PRETDEContributorTokensPendingRelease[beneficiary] = 0;

        return true;
    }


     
     
     
    function finalizeTDE()
       onlyCofounders
       TDEHasEnded
    {
         
         
        require(dnnToken.tokensLocked() == true && dnnToken.PRETDESupplyRemaining() == 0);

         
        dnnToken.unlockTokens();

         
        tokensDistributed += dnnToken.TDESupplyRemaining();

         
        dnnToken.sendUnsoldTDETokensToPlatform();
    }


     
     
     
    function finalizePRETDE()
       onlyCofounders
       NoPRETDEContributorsAwaitingTokens
    {
         
        require(dnnToken.PRETDESupplyRemaining() > 0);

         
        dnnToken.sendUnsoldPRETDETokensToTDE();
    }


     
     
     
    function DNNTDE(address tokenAddress, address founderA, address founderB, address dnnHolding, uint256 hardCap, uint256 startDate, uint256 endDate)
    {

         
        dnnToken = DNNToken(tokenAddress);

         
        cofounderA = founderA;
        cofounderB = founderB;

         
        dnnHoldingMultisig = dnnHolding;

         
        maximumFundingGoalInETH = hardCap * 1 ether;

         
        TDEStartDate = startDate >= now ? startDate : now;

         
         
        TDEEndDate = endDate > TDEStartDate && (endDate-TDEStartDate) >= 30 days ? endDate : (TDEStartDate + 30 days);
    }

     
     
     
    function () payable {

         
         
         
        if (now < TDEStartDate && msg.value >= minimumPRETDEContributionInWei && PRETDEContributorTokensPendingRelease[msg.sender] == 0) {

             
            ETHContributions[msg.sender] = ETHContributions[msg.sender].add(msg.value);

             
            fundsRaisedInWei = fundsRaisedInWei.add(msg.value);

             
            presaleFundsRaisedInWei = presaleFundsRaisedInWei.add(msg.value);

             
            PRETDEContributorTokensPendingRelease[msg.sender] = PRETDEContributorTokensPendingRelease[msg.sender].add(calculateTokens(msg.value, now));

             
            TokensPurchasedDuringPRETDE += calculateTokens(msg.value, now);

             
            PRETDEContributorsTokensPendingCount += 1;

             
            if (TokensPurchasedDuringPRETDE > dnnToken.TDESupplyRemaining()+dnnToken.PRETDESupplyRemaining()) {
                revert();
            }

             
            dnnHoldingMultisig.transfer(msg.value);
        }

         
        else if (now >= TDEStartDate && now < TDEEndDate) buyTokens();

         
        else revert();
    }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract DNNToken is StandardToken {

    using SafeMath for uint256;

     
     
     
    enum DNNSupplyAllocations {
        EarlyBackerSupplyAllocation,
        PRETDESupplyAllocation,
        TDESupplyAllocation,
        BountySupplyAllocation,
        WriterAccountSupplyAllocation,
        AdvisorySupplyAllocation,
        PlatformSupplyAllocation
    }

     
     
     
    address public allocatorAddress;
    address public crowdfundContract;

     
     
     
    string constant public name = "DNN";
    string constant public symbol = "DNN";
    uint8 constant public decimals = 18;  

     
     
     
    address public cofounderA;
    address public cofounderB;

     
     
     
    address public platform;

     
     
     
    uint256 public earlyBackerSupply;  
    uint256 public PRETDESupply;  
    uint256 public TDESupply;  
    uint256 public bountySupply;  
    uint256 public writerAccountSupply;  
    uint256 public advisorySupply;  
    uint256 public cofoundersSupply;  
    uint256 public platformSupply;  

    uint256 public earlyBackerSupplyRemaining;  
    uint256 public PRETDESupplyRemaining;  
    uint256 public TDESupplyRemaining;  
    uint256 public bountySupplyRemaining;  
    uint256 public writerAccountSupplyRemaining;  
    uint256 public advisorySupplyRemaining;  
    uint256 public cofoundersSupplyRemaining;  
    uint256 public platformSupplyRemaining;  

     
     
     
    uint256 public cofoundersSupplyVestingTranches = 10;
    uint256 public cofoundersSupplyVestingTranchesIssued = 0;
    uint256 public cofoundersSupplyVestingStartDate;  
    uint256 public cofoundersSupplyDistributed = 0;   

     
     
     
    bool public tokensLocked = true;

     
     
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
     
     
    modifier CofoundersTokensVested()
    {
         
        require (cofoundersSupplyVestingStartDate != 0 && (now-cofoundersSupplyVestingStartDate) >= 4 weeks);

         
        uint256 currentTranche = now.sub(cofoundersSupplyVestingStartDate) / 4 weeks;

         
        uint256 issuedTranches = cofoundersSupplyVestingTranchesIssued;

         
        uint256 maxTranches = cofoundersSupplyVestingTranches;

         
         
        require (issuedTranches != maxTranches && currentTranche > issuedTranches);

        _;
    }

     
     
     
    modifier TokensUnlocked()
    {
        require (tokensLocked == false);
        _;
    }

     
     
     
    modifier TokensLocked()
    {
       require (tokensLocked == true);
       _;
    }

     
     
     
    modifier onlyCofounders()
    {
        require (msg.sender == cofounderA || msg.sender == cofounderB);
        _;
    }

     
     
     
    modifier onlyCofounderA()
    {
        require (msg.sender == cofounderA);
        _;
    }

     
     
     
    modifier onlyCofounderB()
    {
        require (msg.sender == cofounderB);
        _;
    }

     
     
     
    modifier CanSetAllocator()
    {
       require (allocatorAddress == address(0x0) || tokensLocked == false);
       _;
    }

     
     
     
    modifier CanSetCrowdfundContract()
    {
       require (crowdfundContract == address(0x0));
       _;
    }

     
     
     
    modifier onlyAllocator()
    {
        require (msg.sender == allocatorAddress && tokensLocked == false);
        _;
    }

     
     
     
    modifier onlyCrowdfundContract()
    {
        require (msg.sender == crowdfundContract);
        _;
    }

     
     
     
    modifier onlyAllocatorOrCrowdfundContractOrPlatform()
    {
        require (msg.sender == allocatorAddress || msg.sender == crowdfundContract || msg.sender == platform);
        _;
    }

     
     
     
     
    function changePlatform(address newAddress)
        onlyCofounders
    {
        platform = newAddress;
    }

     
     
     
     
    function changeCrowdfundContract(address newAddress)
        onlyCofounders
        CanSetCrowdfundContract
    {
        crowdfundContract = newAddress;
    }

     
     
     
     
    function changeAllocator(address newAddress)
        onlyCofounders
        CanSetAllocator
    {
        allocatorAddress = newAddress;
    }

     
     
     
     
    function changeCofounderA(address newAddress)
        onlyCofounderA
    {
        cofounderA = newAddress;
    }

     
     
     
     
    function changeCofounderB(address newAddress)
        onlyCofounderB
    {
        cofounderB = newAddress;
    }


     
     
     
    function transfer(address _to, uint256 _value)
      TokensUnlocked
      returns (bool)
    {
          Transfer(msg.sender, _to, _value);
          return BasicToken.transfer(_to, _value);
    }

     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
      TokensUnlocked
      returns (bool)
    {
          Transfer(_from, _to, _value);
          return StandardToken.transferFrom(_from, _to, _value);
    }


     
     
     
     
     
    function issueCofoundersTokensIfPossible()
        onlyCofounders
        CofoundersTokensVested
        returns (bool)
    {
         
        uint256 tokenCount = cofoundersSupply.div(cofoundersSupplyVestingTranches);

         
        if (tokenCount > cofoundersSupplyRemaining) {
           return false;
        }

         
        cofoundersSupplyRemaining = cofoundersSupplyRemaining.sub(tokenCount);

         
        cofoundersSupplyDistributed = cofoundersSupplyDistributed.add(tokenCount);

         
        balances[cofounderA] = balances[cofounderA].add(tokenCount.div(2));
        balances[cofounderB] = balances[cofounderB].add(tokenCount.div(2));

         
        cofoundersSupplyVestingTranchesIssued += 1;

        return true;
    }


     
     
     
    function issueTokens(address beneficiary, uint256 tokenCount, DNNSupplyAllocations allocationType)
      onlyAllocatorOrCrowdfundContractOrPlatform
      returns (bool)
    {
         
         
        bool canAllocatorPerform = msg.sender == allocatorAddress && tokensLocked == false;
        bool canCrowdfundContractPerform = msg.sender == crowdfundContract;
        bool canPlatformPerform = msg.sender == platform && tokensLocked == false;

         
        if (canAllocatorPerform && allocationType == DNNSupplyAllocations.EarlyBackerSupplyAllocation && tokenCount <= earlyBackerSupplyRemaining) {
            earlyBackerSupplyRemaining = earlyBackerSupplyRemaining.sub(tokenCount);
        }

         
        else if (canCrowdfundContractPerform && msg.sender == crowdfundContract && allocationType == DNNSupplyAllocations.PRETDESupplyAllocation) {

               
               
              if (PRETDESupplyRemaining >= tokenCount) {

                     
                    PRETDESupplyRemaining = PRETDESupplyRemaining.sub(tokenCount);
              }

               
              else if (PRETDESupplyRemaining+TDESupplyRemaining >= tokenCount) {

                     
                    TDESupplyRemaining = TDESupplyRemaining.sub(tokenCount-PRETDESupplyRemaining);

                     
                    PRETDESupplyRemaining = 0;
              }

               
              else {
                  return false;
              }
        }

         
        else if (canCrowdfundContractPerform && allocationType == DNNSupplyAllocations.TDESupplyAllocation && tokenCount <= TDESupplyRemaining) {
            TDESupplyRemaining = TDESupplyRemaining.sub(tokenCount);
        }

         
        else if (canAllocatorPerform && allocationType == DNNSupplyAllocations.BountySupplyAllocation && tokenCount <= bountySupplyRemaining) {
            bountySupplyRemaining = bountySupplyRemaining.sub(tokenCount);
        }

         
        else if (canAllocatorPerform && allocationType == DNNSupplyAllocations.WriterAccountSupplyAllocation && tokenCount <= writerAccountSupplyRemaining) {
            writerAccountSupplyRemaining = writerAccountSupplyRemaining.sub(tokenCount);
        }

         
        else if (canAllocatorPerform && allocationType == DNNSupplyAllocations.AdvisorySupplyAllocation && tokenCount <= advisorySupplyRemaining) {
            advisorySupplyRemaining = advisorySupplyRemaining.sub(tokenCount);
        }

         
        else if (canPlatformPerform && allocationType == DNNSupplyAllocations.PlatformSupplyAllocation && tokenCount <= platformSupplyRemaining) {
            platformSupplyRemaining = platformSupplyRemaining.sub(tokenCount);
        }

        else {
            return false;
        }

         
        balances[beneficiary] = balances[beneficiary].add(tokenCount);

        return true;
    }

     
     
     
    function sendUnsoldTDETokensToPlatform()
      external
      onlyCrowdfundContract
    {
         
        if (TDESupplyRemaining > 0) {

             
            platformSupplyRemaining = platformSupplyRemaining.add(TDESupplyRemaining);

             
            TDESupplyRemaining = 0;
        }
    }

     
     
     
    function sendUnsoldPRETDETokensToTDE()
      external
      onlyCrowdfundContract
    {
           
          if (PRETDESupplyRemaining > 0) {

               
              TDESupplyRemaining = TDESupplyRemaining.add(PRETDESupplyRemaining);

               
              PRETDESupplyRemaining = 0;
        }
    }

     
     
     
    function unlockTokens()
        external
        onlyCrowdfundContract
    {
         
        require(tokensLocked == true);

        tokensLocked = false;
    }

     
     
     
    function DNNToken(address founderA, address founderB, address platformAddress, uint256 vestingStartDate)
    {
           
          cofounderA = founderA;
          cofounderB = founderB;

           
          platform = platformAddress;

           
           
          totalSupply = uint256(1000000000).mul(uint256(10)**decimals);

           
          earlyBackerSupply = totalSupply.mul(10).div(100);  
          PRETDESupply = totalSupply.mul(10).div(100);  
          TDESupply = totalSupply.mul(40).div(100);  
          bountySupply = totalSupply.mul(1).div(100);  
          writerAccountSupply = totalSupply.mul(4).div(100);  
          advisorySupply = totalSupply.mul(14).div(100);  
          cofoundersSupply = totalSupply.mul(10).div(100);  
          platformSupply = totalSupply.mul(11).div(100);  

           
          earlyBackerSupplyRemaining = earlyBackerSupply;
          PRETDESupplyRemaining = PRETDESupply;
          TDESupplyRemaining = TDESupply;
          bountySupplyRemaining = bountySupply;
          writerAccountSupplyRemaining = writerAccountSupply;
          advisorySupplyRemaining = advisorySupply;
          cofoundersSupplyRemaining = cofoundersSupply;
          platformSupplyRemaining = platformSupply;

           
          cofoundersSupplyVestingStartDate = vestingStartDate >= now ? vestingStartDate : now;
    }
}