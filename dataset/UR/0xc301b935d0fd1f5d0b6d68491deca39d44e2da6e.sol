 

pragma solidity ^0.4.13;

 
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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

contract AbstractStarbaseCrowdsale {
    function startDate() constant returns (uint256) {}
    function endedAt() constant returns (uint256) {}
    function isEnded() constant returns (bool);
    function totalRaisedAmountInCny() constant returns (uint256);
    function numOfPurchasedTokensOnCsBy(address purchaser) constant returns (uint256);
    function numOfPurchasedTokensOnEpBy(address purchaser) constant returns (uint256);
}

contract AbstractStarbaseMarketingCampaign {}

 
 
contract StarbaseToken is StandardToken {
     
    event PublicOfferingPlanDeclared(uint256 tokenCount, uint256 unlockCompanysTokensAt);
    event MvpLaunched(uint256 launchedAt);
    event LogNewFundraiser (address indexed fundraiserAddress, bool isBonaFide);
    event LogUpdateFundraiser(address indexed fundraiserAddress, bool isBonaFide);

     
    struct PublicOfferingPlan {
        uint256 tokenCount;
        uint256 unlockCompanysTokensAt;
        uint256 declaredAt;
    }

     
    AbstractStarbaseCrowdsale public starbaseCrowdsale;
    AbstractStarbaseMarketingCampaign public starbaseMarketingCampaign;

     
    address public company;
    PublicOfferingPlan[] public publicOfferingPlans;   
    mapping(address => uint256) public initialEcTokenAllocation;     
    uint256 public mvpLaunchedAt;   
    mapping(address => bool) private fundraisers;  

     
    string constant public name = "Starbase";   
    string constant public symbol = "STAR";   
    uint8 constant public decimals = 18;
    uint256 constant public initialSupply = 1000000000e18;  
    uint256 constant public initialCompanysTokenAllocation = 750000000e18;   
    uint256 constant public initialBalanceForCrowdsale = 175000000e18;   
    uint256 constant public initialBalanceForMarketingCampaign = 12500000e18;    

     
    modifier onlyCrowdsaleContract() {
        assert(msg.sender == address(starbaseCrowdsale));
        _;
    }

    modifier onlyMarketingCampaignContract() {
        assert(msg.sender == address(starbaseMarketingCampaign));
        _;
    }

    modifier onlyFundraiser() {
         
        assert(isFundraiser(msg.sender));
        _;
    }

    modifier onlyBeforeCrowdsale() {
        require(starbaseCrowdsale.startDate() == 0);
        _;
    }

    modifier onlyAfterCrowdsale() {
        require(starbaseCrowdsale.isEnded());
        _;
    }

     

     

    function StarbaseToken(
        address starbaseCompanyAddr,
        address starbaseCrowdsaleAddr,
        address starbaseMarketingCampaignAddr
    ) {
        assert(
            starbaseCompanyAddr != 0 &&
            starbaseCrowdsaleAddr != 0 &&
            starbaseMarketingCampaignAddr != 0);

        starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddr);
        starbaseMarketingCampaign = AbstractStarbaseMarketingCampaign(starbaseMarketingCampaignAddr);
        company = starbaseCompanyAddr;

         
        fundraisers[msg.sender] = true;
        LogNewFundraiser(msg.sender, true);

         
        balances[address(starbaseCrowdsale)] = initialBalanceForCrowdsale;

         
        balances[address(starbaseMarketingCampaign)] = initialBalanceForMarketingCampaign;

         
        balances[0] = 62500000e18;  

         
        balances[starbaseCompanyAddr] = initialCompanysTokenAllocation;  

        totalSupply = initialSupply;     
    }

     
    function setup(address starbaseCrowdsaleAddr, address starbaseMarketingCampaignAddr)
        external
        onlyFundraiser
        onlyBeforeCrowdsale
        returns (bool)
    {
        require(starbaseCrowdsaleAddr != 0 && starbaseMarketingCampaignAddr != 0);
        assert(balances[address(starbaseCrowdsale)] == initialBalanceForCrowdsale);
        assert(balances[address(starbaseMarketingCampaign)] == initialBalanceForMarketingCampaign);

         
        balances[address(starbaseCrowdsale)] = 0;
        balances[address(starbaseMarketingCampaign)] = 0;
        balances[starbaseCrowdsaleAddr] = initialBalanceForCrowdsale;
        balances[starbaseMarketingCampaignAddr] = initialBalanceForMarketingCampaign;

         
        starbaseCrowdsale = AbstractStarbaseCrowdsale(starbaseCrowdsaleAddr);
        starbaseMarketingCampaign = AbstractStarbaseMarketingCampaign(starbaseMarketingCampaignAddr);
        return true;
    }

     

     
    function numOfDeclaredPublicOfferingPlans()
        external
        constant
        returns (uint256)
    {
        return publicOfferingPlans.length;
    }

     
    function declarePublicOfferingPlan(uint256 tokenCount, uint256 unlockCompanysTokensAt)
        external
        onlyFundraiser
        onlyAfterCrowdsale
        returns (bool)
    {
        assert(tokenCount <= 100000000e18);     
        assert(SafeMath.sub(now, starbaseCrowdsale.endedAt()) >= 180 days);    
        assert(SafeMath.sub(unlockCompanysTokensAt, now) >= 60 days);    

         
        if (publicOfferingPlans.length > 0) {
            uint256 lastDeclaredAt =
                publicOfferingPlans[publicOfferingPlans.length - 1].declaredAt;
            assert(SafeMath.sub(now, lastDeclaredAt) >= 180 days);
        }

        uint256 totalDeclaredTokenCount = tokenCount;
        for (uint8 i; i < publicOfferingPlans.length; i++) {
            totalDeclaredTokenCount = SafeMath.add(totalDeclaredTokenCount, publicOfferingPlans[i].tokenCount);
        }
        assert(totalDeclaredTokenCount <= initialCompanysTokenAllocation);    

        publicOfferingPlans.push(
            PublicOfferingPlan(tokenCount, unlockCompanysTokensAt, now));

        PublicOfferingPlanDeclared(tokenCount, unlockCompanysTokensAt);
    }

     
    function allocateToMarketingSupporter(address to, uint256 value)
        external
        onlyMarketingCampaignContract
        returns (bool)
    {
        return allocateFrom(address(starbaseMarketingCampaign), to, value);
    }

     
    function allocateToEarlyContributor(address to, uint256 value)
        external
        onlyFundraiser
        returns (bool)
    {
        initialEcTokenAllocation[to] =
            SafeMath.add(initialEcTokenAllocation[to], value);
        return allocateFrom(0, to, value);
    }

     
    function issueTokens(address _for, uint256 value)
        external
        onlyFundraiser
        onlyAfterCrowdsale
        returns (bool)
    {
         
        assert(value <= numOfInflatableTokens());

        totalSupply = SafeMath.add(totalSupply, value);
        balances[_for] = SafeMath.add(balances[_for], value);
        return true;
    }

     
    function declareMvpLaunched(uint256 launchedAt)
        external
        onlyFundraiser
        onlyAfterCrowdsale
        returns (bool)
    {
        require(mvpLaunchedAt == 0);  
        require(launchedAt <= now);
        require(starbaseCrowdsale.isEnded());

        mvpLaunchedAt = launchedAt;
        MvpLaunched(launchedAt);
        return true;
    }

     
    function allocateToCrowdsalePurchaser(address to, uint256 value)
        external
        onlyCrowdsaleContract
        onlyAfterCrowdsale
        returns (bool)
    {
        return allocateFrom(address(starbaseCrowdsale), to, value);
    }

     

     
    function transfer(address to, uint256 value) public returns (bool) {
        assert(isTransferable(msg.sender, value));
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        assert(isTransferable(from, value));
        return super.transferFrom(from, to, value);
    }

     
    function addFundraiser(address fundraiserAddress) public onlyFundraiser {
        assert(!isFundraiser(fundraiserAddress));

        fundraisers[fundraiserAddress] = true;
        LogNewFundraiser(fundraiserAddress, true);
    }

     
    function updateFundraiser(address fundraiserAddress, bool isBonaFide)
       public
       onlyFundraiser
       returns(bool)
    {
        assert(isFundraiser(fundraiserAddress));

        fundraisers[fundraiserAddress] = isBonaFide;
        LogUpdateFundraiser(fundraiserAddress, isBonaFide);
        return true;
    }

     
    function isFundraiser(address fundraiserAddress) constant public returns(bool) {
        return fundraisers[fundraiserAddress];
    }

     
    function isTransferable(address from, uint256 tokenCount)
        constant
        public
        returns (bool)
    {
        if (tokenCount == 0 || balances[from] < tokenCount) {
            return false;
        }

         
        if (from == company) {
            if (tokenCount > numOfTransferableCompanysTokens()) {
                return false;
            }
        }

        uint256 untransferableTokenCount = 0;

         
        if (initialEcTokenAllocation[from] > 0) {
            untransferableTokenCount = SafeMath.add(
                untransferableTokenCount,
                numOfUntransferableEcTokens(from));
        }

         
        if (starbaseCrowdsale.isEnded()) {
            uint256 passedDays =
                SafeMath.sub(now, starbaseCrowdsale.endedAt()) / 86400;  
            if (passedDays < 7) {   
                 
                untransferableTokenCount = SafeMath.add(
                    untransferableTokenCount,
                    starbaseCrowdsale.numOfPurchasedTokensOnCsBy(from));
            }
            if (passedDays < 14) {   
                 
                untransferableTokenCount = SafeMath.add(
                    untransferableTokenCount,
                    starbaseCrowdsale.numOfPurchasedTokensOnEpBy(from));
            }
        }

        uint256 transferableTokenCount =
            SafeMath.sub(balances[from], untransferableTokenCount);

        if (transferableTokenCount < tokenCount) {
            return false;
        } else {
            return true;
        }
    }

     
    function numOfTransferableCompanysTokens() constant public returns (uint256) {
        uint256 unlockedTokens = 0;
        for (uint8 i; i < publicOfferingPlans.length; i++) {
            PublicOfferingPlan memory plan = publicOfferingPlans[i];
            if (plan.unlockCompanysTokensAt <= now) {
                unlockedTokens = SafeMath.add(unlockedTokens, plan.tokenCount);
            }
        }
        return SafeMath.sub(
            balances[company],
            initialCompanysTokenAllocation - unlockedTokens);
    }

     
    function numOfUntransferableEcTokens(address _for) constant public returns (uint256) {
        uint256 initialCount = initialEcTokenAllocation[_for];
        if (mvpLaunchedAt == 0) {
            return initialCount;
        }

        uint256 passedWeeks = SafeMath.sub(now, mvpLaunchedAt) / 7 days;
        if (passedWeeks <= 52) {     
             
            return initialCount;
        }

         
        uint256 transferableTokenCount = initialCount / 52 * (passedWeeks - 52);
        if (transferableTokenCount >= initialCount) {
            return 0;
        } else {
            return SafeMath.sub(initialCount, transferableTokenCount);
        }
    }

     
    function numOfInflatableTokens() constant public returns (uint256) {
        if (starbaseCrowdsale.endedAt() == 0) {
            return 0;
        }
        uint256 passedDays = SafeMath.sub(now, starbaseCrowdsale.endedAt()) / 86400;   
        uint256 passedYears = passedDays * 100 / 36525;     
        uint256 inflatedSupply = initialSupply;
        for (uint256 i; i < passedYears; i++) {
            inflatedSupply = SafeMath.add(inflatedSupply, SafeMath.mul(inflatedSupply, 25) / 1000);  
        }

        uint256 remainderedDays = passedDays * 100 % 36525 / 100;
        if (remainderedDays > 0) {
            uint256 inflatableTokensOfNextYear =
                SafeMath.mul(inflatedSupply, 25) / 1000;
            inflatedSupply = SafeMath.add(inflatedSupply, SafeMath.mul(
                inflatableTokensOfNextYear, remainderedDays * 100) / 36525);
        }

        return SafeMath.sub(inflatedSupply, totalSupply);
    }

     

     
    function allocateFrom(address from, address to, uint256 value) internal returns (bool) {
        assert(value > 0 && balances[from] >= value);
        balances[from] = SafeMath.sub(balances[from], value);
        balances[to] = SafeMath.add(balances[to], value);
        Transfer(from, to, value);
        return true;
    }
}