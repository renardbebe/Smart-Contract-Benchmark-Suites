 

pragma solidity ^0.4.18;

contract GenericCrowdsale {
    address public icoBackend;
    address public icoManager;
    address public emergencyManager;

     
    bool paused = false;

     
    event TokensAllocated(address _beneficiary, uint _contribution, uint _tokensIssued);

     
    event BonusIssued(address _beneficiary, uint _bonusTokensIssued);

     
    event FoundersAndPartnersTokensIssued(address foundersWallet, uint tokensForFounders,
                                          address partnersWallet, uint tokensForPartners);

    event Paused();
    event Unpaused();

     
    function issueTokens(address _beneficiary, uint _contribution) onlyBackend onlyUnpaused external;

     
    function issueTokensWithCustomBonus(address _beneficiary, uint _contribution, uint _tokens, uint _bonus) onlyBackend onlyUnpaused external;

     
    function pause() external onlyManager onlyUnpaused {
        paused = true;
        Paused();
    }

     
    function unpause() external onlyManager onlyPaused {
        paused = false;
        Unpaused();
    }

     
    function changeicoBackend(address _icoBackend) external onlyManager {
        icoBackend = _icoBackend;
    }

     
    modifier onlyManager() {
        require(msg.sender == icoManager);
        _;
    }

    modifier onlyBackend() {
        require(msg.sender == icoBackend);
        _;
    }

    modifier onlyEmergency() {
        require(msg.sender == emergencyManager);
        _;
    }

    modifier onlyPaused() {
        require(paused == true);
        _;
    }

    modifier onlyUnpaused() {
        require(paused == false);
        _;
    }
}

 
contract ERC20 {
  uint public totalSupply;

  function balanceOf(address _owner) constant public returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) constant public returns (uint remaining);

  event Transfer(address indexed _from, address indexed _to, uint value);
  event Approval(address indexed _owner, address indexed _spender, uint value);
}

library SafeMath {
   function mul(uint a, uint b) internal pure returns (uint) {
     if (a == 0) {
        return 0;
      }

      uint c = a * b;
      assert(c / a == b);
      return c;
   }

   function sub(uint a, uint b) internal pure returns (uint) {
      assert(b <= a);
      return a - b;
   }

   function add(uint a, uint b) internal pure returns (uint) {
      uint c = a + b;
      assert(c >= a);
      return c;
   }

  function div(uint a, uint b) internal pure returns (uint256) {
     
    uint c = a / b;
     
    return c;
  }
}

contract StandardToken is ERC20 {
    using SafeMath for uint;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if (balances[msg.sender] >= _value
            && _value > 0
            && _to != msg.sender
            && _to != address(0)
          ) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);

            Transfer(msg.sender, _to, _value);
            return true;
        }

        return false;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && _from != _to
          ) {
            balances[_to]   = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        }

        return false;
    }

    function balanceOf(address _owner) constant public returns (uint) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) constant public returns (uint) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != address(0));
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
         
        require(_spender != address(0));

         
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
         
        require(_spender != address(0));

        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    modifier onlyPayloadSize(uint _size) {
        require(msg.data.length >= _size + 4);
        _;
    }
}

contract Cappasity is StandardToken {

     
     
    string public constant name = "Cappasity";
    string public constant symbol = "CAPP";
    uint8 public constant decimals = 2;
    uint public constant TOKEN_LIMIT = 10 * 1e9 * 1e2;  

     
     
    address public manager;

     
    bool public tokensAreFrozen = true;

     
    bool public mintingIsAllowed = true;

     
    event MintingAllowed();
    event MintingDisabled();

     
    event TokensFrozen();
    event TokensUnfrozen();

     
     
    function Cappasity(address _manager) public {
        manager = _manager;
    }

     
     
    function() payable public {
        revert();
    }

     
     
    function transfer(address _to, uint _value) public returns (bool) {
        require(!tokensAreFrozen);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(!tokensAreFrozen);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        require(!tokensAreFrozen);
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        require(!tokensAreFrozen);
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        require(!tokensAreFrozen);
        return super.decreaseApproval(_spender, _subtractedValue);
    }

     
     
    modifier onlyByManager() {
        require(msg.sender == manager);
        _;
    }

     
    function mint(address _beneficiary, uint _value) external onlyByManager {
        require(_value != 0);
        require(totalSupply.add(_value) <= TOKEN_LIMIT);
        require(mintingIsAllowed == true);

        balances[_beneficiary] = balances[_beneficiary].add(_value);
        totalSupply = totalSupply.add(_value);
    }

     
    function endMinting() external onlyByManager {
        require(mintingIsAllowed == true);
        mintingIsAllowed = false;
        MintingDisabled();
    }

     
    function startMinting() external onlyByManager {
        require(mintingIsAllowed == false);
        mintingIsAllowed = true;
        MintingAllowed();
    }

     
    function freeze() external onlyByManager {
        require(tokensAreFrozen == false);
        tokensAreFrozen = true;
        TokensFrozen();
    }

     
    function unfreeze() external onlyByManager {
        require(tokensAreFrozen == true);
        tokensAreFrozen = false;
        TokensUnfrozen();
    }
}

 
contract VestingWallet {
    using SafeMath for uint;

    event TokensReleased(uint _tokensReleased, uint _tokensRemaining, uint _nextPeriod);

    address public foundersWallet;
    address public crowdsaleContract;
    ERC20 public tokenContract;

     
    bool public vestingStarted = false;
    uint constant cliffPeriod = 30 days;
    uint constant totalPeriods = 24;

    uint public periodsPassed = 0;
    uint public nextPeriod;
    uint public tokensRemaining;
    uint public tokensPerBatch;

     
     
    function VestingWallet(address _foundersWallet, address _tokenContract) public {
        require(_foundersWallet != address(0));
        require(_tokenContract != address(0));

        foundersWallet    = _foundersWallet;
        tokenContract     = ERC20(_tokenContract);
        crowdsaleContract = msg.sender;
    }

     
     
    function releaseBatch() external onlyFounders {
        require(true == vestingStarted);
        require(now > nextPeriod);
        require(periodsPassed < totalPeriods);

        uint tokensToRelease = 0;
        do {
            periodsPassed   = periodsPassed.add(1);
            nextPeriod      = nextPeriod.add(cliffPeriod);
            tokensToRelease = tokensToRelease.add(tokensPerBatch);
        } while (now > nextPeriod);

         
        if (periodsPassed >= totalPeriods) {
            tokensToRelease = tokenContract.balanceOf(this);
            nextPeriod = 0x0;
        }

        tokensRemaining = tokensRemaining.sub(tokensToRelease);
        tokenContract.transfer(foundersWallet, tokensToRelease);

        TokensReleased(tokensToRelease, tokensRemaining, nextPeriod);
    }

    function launchVesting() public onlyCrowdsale {
        require(false == vestingStarted);

        vestingStarted  = true;
        tokensRemaining = tokenContract.balanceOf(this);
        nextPeriod      = now.add(cliffPeriod);
        tokensPerBatch  = tokensRemaining / totalPeriods;
    }

     
     
    modifier onlyFounders() {
        require(msg.sender == foundersWallet);
        _;
    }

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleContract);
        _;
    }
}

 
contract TokenAllocation is GenericCrowdsale {
    using SafeMath for uint;

     
    event TokensAllocated(address _beneficiary, uint _contribution, uint _tokensIssued);
    event BonusIssued(address _beneficiary, uint _bonusTokensIssued);
    event FoundersAndPartnersTokensIssued(address _foundersWallet, uint _tokensForFounders,
                                          address _partnersWallet, uint _tokensForPartners);

     
    uint public tokenRate = 125;  
                                  
    Cappasity public tokenContract;

    address public foundersWallet;  
    address public partnersWallet;  

     
    uint constant public hardCap     = 5 * 1e7 * 1e2;  
    uint constant public phaseOneCap = 3 * 1e7 * 1e2;  
    uint public totalCentsGathered = 0;

     
     
    uint public centsInPhaseOne = 0;
    uint public totalTokenSupply = 0;      

     
     
    uint public tokensDuringPhaseOne = 0;
    VestingWallet public vestingWallet;

    enum CrowdsalePhase { PhaseOne, BetweenPhases, PhaseTwo, Finished }
    enum BonusPhase { TenPercent, FivePercent, None }

    uint public constant bonusTierSize = 1 * 1e7 * 1e2;  
    uint public constant bigContributionBound  = 1 * 1e5 * 1e2;  
    uint public constant hugeContributionBound = 3 * 1e5 * 1e2;  
    CrowdsalePhase public crowdsalePhase = CrowdsalePhase.PhaseOne;
    BonusPhase public bonusPhase = BonusPhase.TenPercent;

     
    function TokenAllocation(address _icoManager,
                             address _icoBackend,
                             address _foundersWallet,
                             address _partnersWallet,
                             address _emergencyManager
                             ) public {
        require(_icoManager != address(0));
        require(_icoBackend != address(0));
        require(_foundersWallet != address(0));
        require(_partnersWallet != address(0));
        require(_emergencyManager != address(0));

        tokenContract = new Cappasity(address(this));

        icoManager       = _icoManager;
        icoBackend       = _icoBackend;
        foundersWallet   = _foundersWallet;
        partnersWallet   = _partnersWallet;
        emergencyManager = _emergencyManager;
    }

     
     
     
    function issueTokens(address _beneficiary, uint _contribution) external onlyBackend onlyValidPhase onlyUnpaused {
         
        if (crowdsalePhase == CrowdsalePhase.PhaseOne) {
            require(totalCentsGathered.add(_contribution) <= phaseOneCap);
        } else {
            require(totalCentsGathered.add(_contribution) <= hardCap);
        }

        uint remainingContribution = _contribution;

         
         
        do {
             
            uint centsLeftInPhase = calculateCentsLeftInPhase(remainingContribution);
            uint contributionPart = min(remainingContribution, centsLeftInPhase);

             
            uint tokensToMint = tokenRate.mul(contributionPart);
            mintAndUpdate(_beneficiary, tokensToMint);
            TokensAllocated(_beneficiary, contributionPart, tokensToMint);

             
            uint tierBonus = calculateTierBonus(contributionPart);
            if (tierBonus > 0) {
                mintAndUpdate(_beneficiary, tierBonus);
                BonusIssued(_beneficiary, tierBonus);
            }

             
            if ((bonusPhase != BonusPhase.None) && (contributionPart == centsLeftInPhase)) {
                advanceBonusPhase();
            }

             
            totalCentsGathered = totalCentsGathered.add(contributionPart);
            remainingContribution = remainingContribution.sub(contributionPart);

             
        } while (remainingContribution > 0);

         
        uint sizeBonus = calculateSizeBonus(_contribution);
        if (sizeBonus > 0) {
            mintAndUpdate(_beneficiary, sizeBonus);
            BonusIssued(_beneficiary, sizeBonus);
        }
    }

     
    function issueTokensWithCustomBonus(address _beneficiary, uint _contribution, uint _tokens, uint _bonus)
                                            external onlyBackend onlyValidPhase onlyUnpaused {

         
        require(_tokens > 0);
         
        require(_tokens >= _bonus);
         
        if (crowdsalePhase == CrowdsalePhase.PhaseOne) {
             
            require(totalCentsGathered.add(_contribution) <= phaseOneCap);
        } else {
             
            require(totalCentsGathered.add(_contribution) <= hardCap);
        }

        uint remainingContribution = _contribution;

         
         
        do {
           
          uint centsLeftInPhase = calculateCentsLeftInPhase(remainingContribution);
          uint contributionPart = min(remainingContribution, centsLeftInPhase);

           
          totalCentsGathered = totalCentsGathered.add(contributionPart);
          remainingContribution = remainingContribution.sub(contributionPart);

           
          if ((remainingContribution == centsLeftInPhase) && (bonusPhase != BonusPhase.None)) {
              advanceBonusPhase();
          }

        } while (remainingContribution > 0);

         
        mintAndUpdate(_beneficiary, _tokens);

         
        if (_tokens > _bonus) {
          TokensAllocated(_beneficiary, _contribution, _tokens.sub(_bonus));
        }

         
        if (_bonus > 0) {
          BonusIssued(_beneficiary, _bonus);
        }
    }

     
    function rewardFoundersAndPartners() external onlyManager onlyValidPhase onlyUnpaused {
        uint tokensDuringThisPhase;
        if (crowdsalePhase == CrowdsalePhase.PhaseOne) {
            tokensDuringThisPhase = totalTokenSupply;
        } else {
            tokensDuringThisPhase = totalTokenSupply - tokensDuringPhaseOne;
        }

         
         
        uint tokensForFounders = tokensDuringThisPhase.mul(257).div(1000);  
        uint tokensForPartners = tokensDuringThisPhase.mul(171).div(1000);  

        tokenContract.mint(partnersWallet, tokensForPartners);

        if (crowdsalePhase == CrowdsalePhase.PhaseOne) {
            vestingWallet = new VestingWallet(foundersWallet, address(tokenContract));
            tokenContract.mint(address(vestingWallet), tokensForFounders);
            FoundersAndPartnersTokensIssued(address(vestingWallet), tokensForFounders,
                                            partnersWallet,         tokensForPartners);

             
            centsInPhaseOne = totalCentsGathered;
            tokensDuringPhaseOne = totalTokenSupply;

             
            tokenContract.unfreeze();
            crowdsalePhase = CrowdsalePhase.BetweenPhases;
        } else {
            tokenContract.mint(address(vestingWallet), tokensForFounders);
            vestingWallet.launchVesting();

            FoundersAndPartnersTokensIssued(address(vestingWallet), tokensForFounders,
                                            partnersWallet,         tokensForPartners);
            crowdsalePhase = CrowdsalePhase.Finished;
        }

        tokenContract.endMinting();
   }

     
    function beginPhaseTwo(uint _tokenRate) external onlyManager onlyUnpaused {
        require(crowdsalePhase == CrowdsalePhase.BetweenPhases);
        require(_tokenRate != 0);

        tokenRate = _tokenRate;
        crowdsalePhase = CrowdsalePhase.PhaseTwo;
        bonusPhase = BonusPhase.TenPercent;
        tokenContract.startMinting();
    }

     
    function freeze() external onlyUnpaused onlyEmergency {
        require(crowdsalePhase != CrowdsalePhase.PhaseOne);
        tokenContract.freeze();
    }

    function unfreeze() external onlyUnpaused onlyEmergency {
        require(crowdsalePhase != CrowdsalePhase.PhaseOne);
        tokenContract.unfreeze();
    }

     
     
    function calculateCentsLeftInPhase(uint _remainingContribution) internal view returns(uint) {
         
         
        if (bonusPhase == BonusPhase.TenPercent) {
            return bonusTierSize.sub(totalCentsGathered.sub(centsInPhaseOne));
        }

        if (bonusPhase == BonusPhase.FivePercent) {
           
           
          return bonusTierSize.mul(2).sub(totalCentsGathered);
        }

        return _remainingContribution;
    }

    function mintAndUpdate(address _beneficiary, uint _tokensToMint) internal {
        tokenContract.mint(_beneficiary, _tokensToMint);
        totalTokenSupply = totalTokenSupply.add(_tokensToMint);
    }

    function calculateTierBonus(uint _contribution) constant internal returns (uint) {
         
         
        uint tierBonus = 0;

         
         
        if (bonusPhase == BonusPhase.TenPercent) {
            tierBonus = _contribution.div(10);  
        } else if (bonusPhase == BonusPhase.FivePercent) {
            tierBonus = _contribution.div(20);  
        }

        tierBonus = tierBonus.mul(tokenRate);
        return tierBonus;
    }

    function calculateSizeBonus(uint _contribution) constant internal returns (uint) {
        uint sizeBonus = 0;
        if (crowdsalePhase == CrowdsalePhase.PhaseOne) {
             
            if (_contribution >= hugeContributionBound) {
                sizeBonus = _contribution.div(10);  
             
            } else if (_contribution >= bigContributionBound) {
                sizeBonus = _contribution.div(20);  
            }

            sizeBonus = sizeBonus.mul(tokenRate);
        }
        return sizeBonus;
    }


     
    function advanceBonusPhase() internal onlyValidPhase {
        if (crowdsalePhase == CrowdsalePhase.PhaseOne) {
            if (bonusPhase == BonusPhase.TenPercent) {
                bonusPhase = BonusPhase.FivePercent;
            } else if (bonusPhase == BonusPhase.FivePercent) {
                bonusPhase = BonusPhase.None;
            }
        } else if (bonusPhase == BonusPhase.TenPercent) {
            bonusPhase = BonusPhase.None;
        }
    }

    function min(uint _a, uint _b) internal pure returns (uint result) {
        return _a < _b ? _a : _b;
    }

     
    modifier onlyValidPhase() {
        require( crowdsalePhase == CrowdsalePhase.PhaseOne
                 || crowdsalePhase == CrowdsalePhase.PhaseTwo );
        _;
    }

     
    function() payable public {
        revert();
    }
}