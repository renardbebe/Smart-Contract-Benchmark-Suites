 

pragma solidity ^0.4.13;
library SafeMath {    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed burner, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  
  using SafeMath for uint256;
  bool public teamStakesFrozen = true;
  bool public fundariaStakesFrozen = true;
  mapping(address => uint256) balances;
  address public owner;
  address public fundaria = 0x1882464533072e9fCd8C6D3c5c5b588548B95296;  
  
  function BasicToken() public {
    owner = msg.sender;
  }
  
  modifier notFrozen() {
    require(msg.sender != owner || (msg.sender == owner && !teamStakesFrozen) || (msg.sender == fundaria && !fundariaStakesFrozen));
    _;
  }

   
  function transfer(address _to, uint256 _value) public notFrozen returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public notFrozen returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public notFrozen returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract SAUR is StandardToken {
  string public constant name = "Cardosaur Stake";
  string public constant symbol = "SAUR";
  uint8 public constant decimals = 0;
}

contract Sale is SAUR {

    using SafeMath for uint;

 

     
    uint public poolCapUSD = 70000;  
     
    uint public usdPerEther = 800;
    uint public supplyCap;  
    uint public businessPlannedPeriodDuration = 183 days;  
    uint public businessPlannedPeriodEndTimestamp;
    uint public teamCap;  
    uint8 public teamShare = 55;  
    uint public distributedTeamStakes;  
    uint public fundariaCap;  
    uint8 public fundariaShare = 20;  
    uint public distributedFundariaStakes;  
    uint public contractCreatedTimestamp;  
    address public pool = 0x28C19cEb598fdb171048C624DB8b91C56Af29aA2;  
    mapping (address=>bool) public rejectedInvestmentWithdrawals;
    uint public allowedAmountToTransferToPool;  
    uint public allowedAmountTransferedToPoolTotal;  
    uint public investmentGuidesRewardsWithdrawn;  

 
 
    uint public distributedBountyStakes;  
    uint public bountyCap;  
    uint8 public bountyShare = 4;  
    
 
    address supplier = 0x0000000000000000000000000000000000000000;  
     
    struct saleData {
      uint stakes;  
      uint invested;  
      uint bonusStakes;  
      uint guideReward;  
      address guide;  
    }
    mapping (address=>saleData) public saleStat;  
    uint public saleStartTimestamp = 1524852000;  
    uint public saleEndTimestamp = 1527444000; 
    uint public distributedSaleStakes;  
    uint public totalInvested;  
    uint public totalWithdrawn;  
    uint public saleCap;  
    uint8 public saleShare = 20;  
    uint public lastStakePriceUSCents;  
    uint[] public targetPrice;    
    bool public priceIsFrozen = false;  
    
     
     
    struct guideData {
      bool registered;  
      uint accumulatedPotentialReward;  
      uint rewardToWithdraw;  
      uint periodicallyWithdrawnReward;  
    }
    mapping (address=>guideData) public guidesStat;  
    uint public bonusCap;  
    uint public distributedBonusStakes;  
    uint public bonusShare = 1;  
    uint8 public guideInvestmentAttractedShareToPay = 10;  

     

 

    uint8 public financePeriodsCount = 6;  
    uint[] public financePeriodsTimestamps;  
    uint public transferedToPool;  

 

    event StakesSale(address to, uint weiInvested, uint stakesRecieved, uint teamStakesRecieved, uint stake_price_us_cents);
    event BountyDistributed(address to, uint bountyStakes);
    event TransferedToPool(uint weiAmount, uint8 currentFinancialPeriodNo);
    event InvestmentWithdrawn(address to, uint withdrawnWeiAmount, uint stakesBurned, uint8 remainedFullFinancialPeriods);
    event UsdPerEtherChanged(uint oldUsdPerEther, uint newUsdPerEther);
    event BonusDistributed(address to, uint bonusStakes, address guide, uint accumulatedPotentialReward);
    event PoolCapChanged(uint oldCapUSD, uint newCapUSD);
    event RegisterGuide(address investmentGuide);
    event TargetPriceChanged(uint8 N, uint oldTargetPrice, uint newTargetPrice);
    event InvestmentGuideWithdrawReward(address investmentGuide, uint withdrawnRewardWei);
    
    modifier onlyOwner() {
      require(msg.sender==owner);
      _;
    }
         
    function Sale() public {     
      uint financePeriodDuration = businessPlannedPeriodDuration/financePeriodsCount;  
       
      financePeriodsTimestamps.push(saleEndTimestamp);  
      for(uint8 i=1; i<=financePeriodsCount; i++) {
        financePeriodsTimestamps.push(saleEndTimestamp+financePeriodDuration*i);  
      }
      businessPlannedPeriodEndTimestamp = saleEndTimestamp+businessPlannedPeriodDuration; 
      contractCreatedTimestamp = now;
      targetPrice.push(1);  
      targetPrice.push(10);  
      targetPrice.push(100);  
      targetPrice.push(1000);  
      balances[supplier] = 0;  
    }
        
    function remainingInvestment() public view returns(uint) {
      return poolCapUSD.div(usdPerEther).mul(1 ether).sub(totalInvested);  
    }
          
    function setCaps() internal {
       
      saleCap = distributedSaleStakes+stakeForWei(remainingInvestment());  
      supplyCap = saleCap.mul(100).div(saleShare);  
      teamCap = supplyCap.mul(teamShare).div(100);  
      fundariaCap = supplyCap.mul(fundariaShare).div(100);  
      bonusCap = supplyCap.mul(bonusShare).div(100);  
      bountyCap = supplyCap.sub(saleCap).sub(teamCap).sub(bonusCap);  
    }
          
    function setStakePriceUSCents() internal {
        uint targetPriceFrom;
        uint targetPriceTo;
        uint startTimestamp;
        uint endTimestamp;
       
      if(now < saleStartTimestamp) {
        targetPriceFrom = targetPrice[0];
        targetPriceTo = targetPrice[1];
        startTimestamp = contractCreatedTimestamp;
        endTimestamp = saleStartTimestamp;        
       
      } else if(now >= saleStartTimestamp && now < saleEndTimestamp) {
        targetPriceFrom = targetPrice[1];
        targetPriceTo = targetPrice[2];
        startTimestamp = saleStartTimestamp;
        endTimestamp = saleEndTimestamp;    
       
      } else if(now >= saleEndTimestamp && now < businessPlannedPeriodEndTimestamp) {
        targetPriceFrom = targetPrice[2];
        targetPriceTo = targetPrice[3];
        startTimestamp = saleEndTimestamp;
        endTimestamp = businessPlannedPeriodEndTimestamp;    
      }     
      lastStakePriceUSCents = targetPriceFrom + ((now-startTimestamp)*(targetPriceTo-targetPriceFrom))/(endTimestamp-startTimestamp);       
    }  
       
    function() payable public {
      require(msg.sender != address(0));
      require(msg.value > 0);  
      require(now < businessPlannedPeriodEndTimestamp);  
      processSale();       
    }
          
    function processSale() internal {
      if(!priceIsFrozen) {  
        setStakePriceUSCents();
      }
      setCaps();    

        uint teamStakes;  
        uint fundariaStakes;  
        uint saleStakes;  
        uint weiInvested;  
        uint trySaleStakes = stakeForWei(msg.value);  

      if(trySaleStakes > 1) {
        uint tryDistribute = distributedSaleStakes+trySaleStakes;  
        if(tryDistribute <= saleCap) {  
          saleStakes = trySaleStakes;  
          weiInvested = msg.value;  
        } else {
          saleStakes = saleCap-distributedSaleStakes;  
          weiInvested = weiForStake(saleStakes);  
        }
        teamStakes = (saleStakes*teamShare).div(saleShare);  
        fundariaStakes = (saleStakes*fundariaShare).div(saleShare);  
        if(saleStakes > 0) {          
          balances[owner] += teamStakes;  
          totalSupply += teamStakes;  
          distributedTeamStakes += teamStakes;  
          Transfer(supplier, owner, teamStakes);         
          balances[fundaria] += fundariaStakes;  
          totalSupply += fundariaStakes;  
          distributedFundariaStakes += fundariaStakes;  
          Transfer(supplier, fundaria, fundariaStakes);                     
          saleSupply(msg.sender, saleStakes, weiInvested);  
          if(saleStat[msg.sender].guide != address(0)) {  
            distributeBonusStakes(msg.sender, saleStakes, weiInvested);  
          }          
        }        
        if(tryDistribute > saleCap) {
          msg.sender.transfer(msg.value-weiInvested);  
        }        
      } else {
        msg.sender.transfer(msg.value);  
      }
    }
    
    function saleSupply(address _to, uint _stakes, uint _wei) internal {
      require(_stakes > 0);  
      balances[_to] += _stakes;  
      totalSupply += _stakes;
      distributedSaleStakes += _stakes;
      totalInvested = totalInvested.add(_wei);  
       
      saleStat[_to].stakes += _stakes;  
      saleStat[_to].invested = saleStat[_to].invested.add(_wei);  
      Transfer(supplier, _to, _stakes);
    }      
       
    function setNewOwner(address new_owner) public onlyOwner {
      owner = new_owner; 
    }
       
    function setNewFundaria(address new_fundaria) public onlyOwner {
      fundaria = new_fundaria; 
    }    
       
    function setUsdPerEther(uint new_usd_per_ether) public onlyOwner {
      UsdPerEtherChanged(usdPerEther, new_usd_per_ether);
      usdPerEther = new_usd_per_ether; 
    }
            
    function setPoolAddress(address _pool) public onlyOwner {
      pool = _pool;  
    }
       
    function setPoolCapUSD(uint new_pool_cap_usd) public onlyOwner {
      PoolCapChanged(poolCapUSD, new_pool_cap_usd);
      poolCapUSD = new_pool_cap_usd; 
    }
        
    function registerGuide(address investment_guide) public onlyOwner {
      guidesStat[investment_guide].registered = true;
      RegisterGuide(investment_guide);
    }
      
    function freezePrice() public onlyOwner {
      priceIsFrozen = true; 
    }
          
    function unfreezePrice() public onlyOwner {
      priceIsFrozen = false;  
    }
          
    function setTargetPrice(uint8 n, uint stake_price_us_cents) public onlyOwner {
      TargetPriceChanged(n, targetPrice[n], stake_price_us_cents);
      targetPrice[n] = stake_price_us_cents;
    }  
        
    function getBonusStakesPermanently(address key) public {
      require(guidesStat[key].registered);
      require(saleStat[msg.sender].guide == address(0));  
      saleStat[msg.sender].guide = key;  
      if(saleStat[msg.sender].invested > 0) {  
        distributeBonusStakes(msg.sender, saleStat[msg.sender].stakes, saleStat[msg.sender].invested);
      }
    }
          
    function distributeBonusStakes(address _to, uint added_stakes, uint added_wei) internal {
      uint added_bonus_stakes = (added_stakes*((bonusShare*100).div(saleShare)))/100;  
      require(distributedBonusStakes+added_bonus_stakes <= bonusCap);  
      uint added_potential_reward = (added_wei*guideInvestmentAttractedShareToPay)/100;  
      if(!rejectedInvestmentWithdrawals[_to]) {
        guidesStat[saleStat[_to].guide].accumulatedPotentialReward += added_potential_reward;  
      } else {
        guidesStat[saleStat[_to].guide].rewardToWithdraw += added_potential_reward;  
      }      
      saleStat[_to].guideReward += added_potential_reward;  
      saleStat[_to].bonusStakes += added_bonus_stakes;  
      balances[_to] += added_bonus_stakes;  
      distributedBonusStakes += added_bonus_stakes;  
      totalSupply += added_bonus_stakes;  
      BonusDistributed(_to, added_bonus_stakes, saleStat[_to].guide, added_potential_reward);
      Transfer(supplier, _to, added_bonus_stakes);          
    }
  
     
  
    
    function stakeForWei(uint input_wei) public view returns(uint) {
      return ((input_wei*usdPerEther*100)/1 ether)/lastStakePriceUSCents;    
    }  
    
    function weiForStake(uint input_stake) public view returns(uint) {
      return (input_stake*lastStakePriceUSCents*1 ether)/(usdPerEther*100);    
    } 
       
    function transferToPool() public onlyOwner {      
      uint max_available;  
      uint amountToTransfer;  
         
        for(uint8 i=0; i <= financePeriodsCount; i++) {
           
          if(now < financePeriodsTimestamps[i] || (i == financePeriodsCount && now > financePeriodsTimestamps[i])) {   
             
            max_available = ((i+1)*(totalInvested+totalWithdrawn-allowedAmountTransferedToPoolTotal))/(financePeriodsCount+1); 
             
            if(max_available > transferedToPool-allowedAmountTransferedToPoolTotal || allowedAmountToTransferToPool > 0) {
              if(allowedAmountToTransferToPool > 0) {  
                amountToTransfer = allowedAmountToTransferToPool;  
                allowedAmountTransferedToPoolTotal += allowedAmountToTransferToPool;  
                allowedAmountToTransferToPool = 0;                  
              } else {
                amountToTransfer = max_available-transferedToPool;  
              }
              if(amountToTransfer > this.balance || now > financePeriodsTimestamps[i]) {  
                amountToTransfer = this.balance;  
              }
              transferedToPool += amountToTransfer;  
              pool.transfer(amountToTransfer);                        
              TransferedToPool(amountToTransfer, i+1);
            }
            allowedAmountToTransferToPool=0;
            break;    
          }
        }     
    }  
          
    function withdrawInvestment() public {
      require(!rejectedInvestmentWithdrawals[msg.sender]);  
      require(saleStat[msg.sender].stakes > 0);
      require(balances[msg.sender] >= saleStat[msg.sender].stakes+saleStat[msg.sender].bonusStakes);  
      uint remained;  
      uint to_withdraw;  
      for(uint8 i=0; i < financePeriodsCount; i++) {  
        if(now<financePeriodsTimestamps[i]) {  
          remained = totalInvested - ((i+1)*totalInvested)/(financePeriodsCount+1);  
          to_withdraw = (saleStat[msg.sender].invested*remained)/totalInvested;  
          uint sale_stakes_to_burn = saleStat[msg.sender].stakes+saleStat[msg.sender].bonusStakes;  
          uint team_stakes_to_burn = (saleStat[msg.sender].stakes*teamShare)/saleShare;  
          uint fundaria_stakes_to_burn = (saleStat[msg.sender].stakes*fundariaShare)/saleShare;  
          balances[owner] = balances[owner].sub(team_stakes_to_burn);  
          balances[fundaria] = balances[fundaria].sub(fundaria_stakes_to_burn);  
          Burn(owner,team_stakes_to_burn);
          Burn(fundaria,fundaria_stakes_to_burn);
          distributedTeamStakes -= team_stakes_to_burn;  
          distributedFundariaStakes -= fundaria_stakes_to_burn;  
          balances[msg.sender] = balances[msg.sender].sub(sale_stakes_to_burn);  
          distributedSaleStakes -= saleStat[msg.sender].stakes;  
          Burn(msg.sender,sale_stakes_to_burn);
          totalInvested = totalInvested.sub(to_withdraw);  
          totalSupply = totalSupply.sub(sale_stakes_to_burn).sub(team_stakes_to_burn).sub(fundaria_stakes_to_burn);  
          if(saleStat[msg.sender].guide != address(0)) {  
             
            guidesStat[saleStat[msg.sender].guide].accumulatedPotentialReward -= (saleStat[msg.sender].guideReward - ((i+1)*saleStat[msg.sender].guideReward)/(financePeriodsCount+1)); 
            distributedBonusStakes -= saleStat[msg.sender].bonusStakes;
            saleStat[msg.sender].bonusStakes = 0;
            saleStat[msg.sender].guideReward = 0;          
          }
          saleStat[msg.sender].stakes = 0;  
          saleStat[msg.sender].invested = 0;  
          totalWithdrawn += to_withdraw;
          msg.sender.transfer(to_withdraw);  
          InvestmentWithdrawn(msg.sender, to_withdraw, sale_stakes_to_burn, financePeriodsCount-i);          
          break;  
        }
      }      
    }
        
    function rejectInvestmentWithdrawal() public {
      rejectedInvestmentWithdrawals[msg.sender] = true;
      address guide = saleStat[msg.sender].guide;
      if(guide != address(0)) {  
        if(saleStat[msg.sender].guideReward >= guidesStat[guide].periodicallyWithdrawnReward) {  
          uint remainedRewardToWithdraw = saleStat[msg.sender].guideReward-guidesStat[guide].periodicallyWithdrawnReward;
          guidesStat[guide].periodicallyWithdrawnReward = 0;  
          if(guidesStat[guide].accumulatedPotentialReward >= remainedRewardToWithdraw) {  
            guidesStat[guide].accumulatedPotentialReward -= remainedRewardToWithdraw;  
            guidesStat[guide].rewardToWithdraw += remainedRewardToWithdraw;   
          } else {
            guidesStat[guide].accumulatedPotentialReward = 0;  
          }
        } else {
           
          guidesStat[guide].periodicallyWithdrawnReward -= saleStat[msg.sender].guideReward;
           
          if(guidesStat[guide].accumulatedPotentialReward >= saleStat[msg.sender].guideReward) {
             
            guidesStat[guide].accumulatedPotentialReward -= saleStat[msg.sender].guideReward;
            guidesStat[guide].rewardToWithdraw += saleStat[msg.sender].guideReward;   
          } else {
            guidesStat[guide].accumulatedPotentialReward = 0;  
          }   
        }
      }
      allowedAmountToTransferToPool += saleStat[msg.sender].invested;
    }
  
        
    function distributeBounty(address _to, uint _stakes) public onlyOwner {
      require(distributedBountyStakes+_stakes <= bountyCap);  
      balances[_to] = balances[_to].add(_stakes);  
      totalSupply += _stakes; 
      distributedBountyStakes += _stakes;  
      BountyDistributed(_to, _stakes);
      Transfer(supplier, _to, _stakes);    
    } 
         
    function unFreeze() public onlyOwner {
       
      if(now > businessPlannedPeriodEndTimestamp) {
        teamStakesFrozen = false;  
        fundariaStakesFrozen = false;  
      }  
    }     
}