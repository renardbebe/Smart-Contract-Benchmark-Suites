 

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

 
contract ERC20 {
  uint256 public totalSupply;
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function transfer(address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  function allowance(address owner, address spender) constant returns (uint256);
  function balanceOf(address who) constant returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
 
    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    

   
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      }
      return false;
}


   
    function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
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


}

 
contract BiQToken is BasicToken {

  using SafeMath for uint256;

  string public name = "BurstIQ Token";               
  string public symbol = "BiQ";                       
  uint8 public decimals = 18;                         
  uint256 public totalSupply = 1000000000 * 10**18;   

   
  uint256 public keyEmployeesAllocatedFund;            
  uint256 public advisorsAllocation;                   
  uint256 public marketIncentivesAllocation;           
  uint256 public vestingFounderAllocation;             
  uint256 public totalAllocatedTokens;                 
  uint256 public tokensAllocatedToCrowdFund;           
  uint256 public saftInvestorAllocation;               

  bool public isPublicTokenReleased = false;           

   

  address public founderMultiSigAddress;               
  address public advisorAddress;                       
  address public vestingFounderAddress;                
  address public crowdFundAddress;                     

   

  uint256 public preAllocatedTokensVestingTime;        

   

  event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);
  event TransferPreAllocatedFunds(uint256  _blockTimeStamp , address _to , uint256 _value);
  event PublicTokenReleased(uint256 _blockTimeStamp);

   

  modifier onlyCrowdFundAddress() {
    require(msg.sender == crowdFundAddress);
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

  modifier onlyFounders() {
    require(msg.sender == founderMultiSigAddress);
    _;
  }

  modifier onlyVestingFounderAddress() {
    require(msg.sender == vestingFounderAddress);
    _;
  }

  modifier onlyAdvisorAddress() {
    require(msg.sender == advisorAddress);
    _;
  }

  modifier isPublicTokenNotReleased() {
    require(isPublicTokenReleased == false);
    _;
  }


   
  function BiQToken (address _crowdFundAddress, address _founderMultiSigAddress, address _advisorAddress, address _vestingFounderAddress) {
    crowdFundAddress = _crowdFundAddress;
    founderMultiSigAddress = _founderMultiSigAddress;
    vestingFounderAddress = _vestingFounderAddress;
    advisorAddress = _advisorAddress;

     
    vestingFounderAllocation = 18 * 10 ** 25 ;         
    keyEmployeesAllocatedFund = 2 * 10 ** 25 ;         
    advisorsAllocation = 5 * 10 ** 25 ;                
    tokensAllocatedToCrowdFund = 60 * 10 ** 25 ;       
    marketIncentivesAllocation = 5 * 10 ** 25 ;        
    saftInvestorAllocation = 10 * 10 ** 25 ;           

     
    balances[founderMultiSigAddress] = keyEmployeesAllocatedFund + saftInvestorAllocation;
    balances[crowdFundAddress] = tokensAllocatedToCrowdFund;

    totalAllocatedTokens = balances[founderMultiSigAddress];
    preAllocatedTokensVestingTime = now + 180 * 1 days;                 
  }

   
  function changeTotalSupply(uint256 _amount) onlyCrowdFundAddress {
    totalAllocatedTokens = totalAllocatedTokens.add(_amount);
    tokensAllocatedToCrowdFund = tokensAllocatedToCrowdFund.sub(_amount);
  }

   
  function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
    founderMultiSigAddress = _newFounderMultiSigAddress;
    ChangeFoundersWalletAddress(now, founderMultiSigAddress);
  }

   
  function releaseToken() onlyFounders isPublicTokenNotReleased {
    isPublicTokenReleased = !isPublicTokenReleased;
    PublicTokenReleased(now);
  }

   
  function transferMarketIncentivesFund(address _to, uint _value) onlyFounders nonZeroAddress(_to)  returns (bool) {
    if (marketIncentivesAllocation >= _value) {
      marketIncentivesAllocation = marketIncentivesAllocation.sub(_value);
      balances[_to] = balances[_to].add(_value);
      totalAllocatedTokens = totalAllocatedTokens.add(_value);
      TransferPreAllocatedFunds(now, _to, _value);
      return true;
    }
    return false;
  }


   
  function getVestedFounderTokens() onlyVestingFounderAddress returns (bool) {
    if (now >= preAllocatedTokensVestingTime && vestingFounderAllocation > 0) {
      balances[vestingFounderAddress] = balances[vestingFounderAddress].add(vestingFounderAllocation);
      totalAllocatedTokens = totalAllocatedTokens.add(vestingFounderAllocation);
      vestingFounderAllocation = 0;
      TransferPreAllocatedFunds(now, vestingFounderAddress, vestingFounderAllocation);
      return true;
    }
    return false;
  }

   
  function getVestedAdvisorTokens() onlyAdvisorAddress returns (bool) {
    if (now >= preAllocatedTokensVestingTime && advisorsAllocation > 0) {
      balances[advisorAddress] = balances[advisorAddress].add(advisorsAllocation);
      totalAllocatedTokens = totalAllocatedTokens.add(advisorsAllocation);
      advisorsAllocation = 0;
      TransferPreAllocatedFunds(now, advisorAddress, advisorsAllocation);
      return true;
    } else {
      return false;
    }
  }

   
  function transfer(address _to, uint256 _value) returns (bool) {
    if (msg.sender == crowdFundAddress) {
      return super.transfer(_to,_value);
    } else {
      if (isPublicTokenReleased) {
        return super.transfer(_to,_value);
      }
      return false;
    }
  }

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    if (msg.sender == crowdFundAddress) {
      return super.transferFrom(_from, _to, _value);
    } else {
      if (isPublicTokenReleased) {
        return super.transferFrom(_from, _to, _value);
      }
      return false;
    }
  }

   
  function () {
    revert();
  }

}

contract BiQCrowdFund {

    using SafeMath for uint256;

    BiQToken public token;                                  

     
    uint256 public crowdfundStartTime;                      
    uint256 public crowdfundEndTime;                        
    uint256 public totalWeiRaised = 0;                      
    uint256 public exchangeRate = 2307;                     
    uint256 internal minAmount = 36.1219 * 10 ** 18;        

    bool public isCrowdFundActive = false;                  
    bool internal isTokenDeployed = false;                  
    bool internal hasCrowdFundStarted = false;              

     
    address public founderMultiSigAddress;                  
    address public remainingTokenHolder;                    
    address public authorizerAddress;                       

     
    mapping (address => uint256) auth;                      

    enum State { PreSale, CrowdFund }

     
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event CrowdFundClosed(uint256 _blockTimeStamp);
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);

     
    modifier tokenIsDeployed() {
        require(isTokenDeployed == true);
        _;
    }
     modifier nonZeroEth() {
        require(msg.value > 0);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier checkCrowdFundActive() {
        require(isCrowdFundActive == true);
        _;
    }

    modifier onlyFounders() {
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderMultiSigAddress);
        _;
    }

    modifier onlyAuthorizer() {
        require(msg.sender == authorizerAddress);
        _;
    }


    modifier inState(State state) {
        require(getState() == state);
        _;
    }

     
    function BiQCrowdFund (address _founderWalletAddress, address _remainingTokenHolder, address _authorizerAddress) {
        founderMultiSigAddress = _founderWalletAddress;
        remainingTokenHolder = _remainingTokenHolder;
        authorizerAddress = _authorizerAddress;
    }

     
    function setFounderMultiSigAddress(address _newFounderAddress) onlyFounders nonZeroAddress(_newFounderAddress) {
        founderMultiSigAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

     function setAuthorizerAddress(address _newAuthorizerAddress) onlyFounders nonZeroAddress(_newAuthorizerAddress) {
        authorizerAddress = _newAuthorizerAddress;
    }

     function setRemainingTokenHolder(address _newRemainingTokenHolder) onlyFounders nonZeroAddress(_newRemainingTokenHolder) {
        remainingTokenHolder = _newRemainingTokenHolder;
    }

     
    function setTokenAddress(address _tokenAddress) onlyFounders nonZeroAddress(_tokenAddress) {
        require(isTokenDeployed == false);
        token = BiQToken(_tokenAddress);
        isTokenDeployed = true;
    }

     
    function changeCrowdfundState() tokenIsDeployed onlyFounders inState(State.CrowdFund) {
        isCrowdFundActive = !isCrowdFundActive;
    }

     
    function authorize(address _to, uint256 max_amount) onlyAuthorizer {
        auth[_to] = max_amount * 1 ether;
    }

     
    function buyTokens(address beneficiary) nonZeroEth tokenIsDeployed onlyPublic nonZeroAddress(beneficiary) payable returns(bool) {
         
        if (auth[beneficiary] < msg.value) {
            revert();
        }
        auth[beneficiary] = auth[beneficiary].sub(msg.value);

        if (getState() == State.PreSale) {
            if (buyPreSaleTokens(beneficiary)) {
                return true;
            }
            revert();
        } else {
            require(now < crowdfundEndTime && isCrowdFundActive);
            fundTransfer(msg.value);

            uint256 amount = getNoOfTokens(exchangeRate, msg.value);

            if (token.transfer(beneficiary, amount)) {
                token.changeTotalSupply(amount);
                totalWeiRaised = totalWeiRaised.add(msg.value);
                TokenPurchase(beneficiary, msg.value, amount);
                return true;
            }
            revert();
        }

    }

     
    function fundTransfer(uint256 weiAmount) internal {
        founderMultiSigAddress.transfer(weiAmount);
    }

     

     
   function getState() public constant returns(State) {
        if (!isCrowdFundActive && !hasCrowdFundStarted) {
            return State.PreSale;
        }
        return State.CrowdFund;
   }

     
   function getPreAuthorizedAmount(address _address) constant returns(uint256) {
        return auth[_address];
   }

    
   function calculateTotalTokenPerContribution(uint256 _totalETHContribution) public constant returns(uint256) {
       if (getState() == State.PreSale) {
           return getTokensForPreSale(exchangeRate, _totalETHContribution * 1 ether).div(10 ** 18);
       }
       return getNoOfTokens(exchangeRate, _totalETHContribution);
   }

     
    function currentBonus(uint256 _ethContribution) public constant returns (uint8) {
        if (getState() == State.PreSale) {
            return getPreSaleBonusRate(_ethContribution * 1 ether);
        }
        return getCurrentBonusRate();
    }


 
     
    function buyPreSaleTokens(address beneficiary) internal returns(bool) {
        
        if (msg.value < minAmount) {
          revert();
        } else {
            fundTransfer(msg.value);
            uint256 amount = getTokensForPreSale(exchangeRate, msg.value);

            if (token.transfer(beneficiary, amount)) {
                token.changeTotalSupply(amount);
                totalWeiRaised = totalWeiRaised.add(msg.value);
                TokenPurchase(beneficiary, msg.value, amount);
                return true;
            }
            return false;
        }
    }

     
    function getTokensForPreSale(uint256 _exchangeRate, uint256 _amount) internal returns (uint256) {
        uint256 noOfToken = _amount.mul(_exchangeRate);
        uint256 preSaleTokenQuantity = ((100 + getPreSaleBonusRate(_amount)) * noOfToken ).div(100);
        return preSaleTokenQuantity;
    }

    function getPreSaleBonusRate(uint256 _ethAmount) internal returns (uint8) {
        if ( _ethAmount >= minAmount.mul(5) && _ethAmount < minAmount.mul(10)) {
            return 30;
        }
        if (_ethAmount >= minAmount.mul(10)) {
            return 35;
        }
        if (_ethAmount >= minAmount) {
            return 25;
        }
    }
 

     
    function startCrowdfund(uint256 _exchangeRate) onlyFounders tokenIsDeployed inState(State.PreSale) {
        if (_exchangeRate > 0 && !hasCrowdFundStarted) {
            exchangeRate = _exchangeRate;
            crowdfundStartTime = now;
            crowdfundEndTime = crowdfundStartTime + 5 * 1 weeks;  
            isCrowdFundActive = !isCrowdFundActive;
            hasCrowdFundStarted = !hasCrowdFundStarted;
        } else {
            revert();
        }
    }

     
     
    function endCrowdfund() onlyFounders returns (bool) {
        require(now > crowdfundEndTime);
        uint256 remainingToken = token.balanceOf(this);   

        if (remainingToken != 0 && token.transfer(remainingTokenHolder, remainingToken)) {
          return true;
        } else {
            return false;
        }
        CrowdFundClosed(now);
    }

    
    function getNoOfTokens(uint256 _exchangeRate, uint256 _amount) internal returns (uint256) {
         uint256 noOfToken = _amount.mul(_exchangeRate);
         uint256 noOfTokenWithBonus = ((100 + getCurrentBonusRate()) * noOfToken).div(100);
         return noOfTokenWithBonus;
    }

     
    function getCurrentBonusRate() internal returns (uint8) {
        if (now > crowdfundStartTime + 4 weeks) {
            return 0;
        }
        if (now > crowdfundStartTime + 3 weeks) {
            return 5;
        }
        if (now > crowdfundStartTime + 2 weeks) {
            return 10;
        }
        if (now > crowdfundStartTime + 1 weeks) {
            return 15;
        }
        if (now > crowdfundStartTime) {
            return 20;
        }
    }

     
     
     
    function() public payable {
        buyTokens(msg.sender);
    }
}