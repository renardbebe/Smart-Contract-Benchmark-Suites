 

 
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
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
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
        }else {
            return false;
        }
    }
    

     

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
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


contract SPCToken is BasicToken {

using SafeMath for uint256;

string public name = "SecurityPlusCloud Token";               
string public symbol = "SPC";                                 
uint8 public decimals = 18;                                   
uint256 public totalSupply = 500000000 * 10**18;              

 
uint256 public keyEmployeesAllocation;               
uint256 public bountiesAllocation;                   
uint256 public longTermBudgetAllocation;             
uint256 public bonusAllocation;                      
uint256 public totalAllocatedTokens;                 
uint256 public tokensAllocatedToCrowdFund;           

 
 
address public founderMultiSigAddress = 0x70b0ea058aee845342B09f1769a2bE8deB46aA86;     
address public crowdFundAddress;                     
address public owner;                                
 
address public bonusAllocAddress = 0x95817119B58D195C10a935De6fA4141c2647Aa56;
 
address public bountiesAllocAddress = 0x6272A7521c60dE62aBc048f7B40F61f775B32d78;
 
address public longTermbudgetAllocAddress = 0x00a6858fe26c326c664a6B6499e47D72e98402Bb;

 

event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);

 

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


  
    
   function SPCToken (address _crowdFundAddress) {
    owner = msg.sender;
    crowdFundAddress = _crowdFundAddress;

     
    keyEmployeesAllocation = 50 * 10 ** 24;            
    bountiesAllocation = 35 * 10 ** 24;                
    tokensAllocatedToCrowdFund = 25 * 10 ** 25;        
    longTermBudgetAllocation = 10 * 10 ** 25;          
    bonusAllocation = 65 * 10 ** 24;                   

     
    balances[founderMultiSigAddress] = keyEmployeesAllocation;
    balances[crowdFundAddress] = tokensAllocatedToCrowdFund;
    balances[bonusAllocAddress] = bonusAllocation;
    balances[bountiesAllocAddress] = bountiesAllocation;
    balances[longTermbudgetAllocAddress] = longTermBudgetAllocation;

    totalAllocatedTokens = balances[founderMultiSigAddress] + balances[bonusAllocAddress] + balances[bountiesAllocAddress] + balances[longTermbudgetAllocAddress];
  }

 
  function changeTotalSupply(uint256 _amount) onlyCrowdFundAddress {
    totalAllocatedTokens += _amount;
  }

 
  function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
    founderMultiSigAddress = _newFounderMultiSigAddress;
    ChangeFoundersWalletAddress(now, founderMultiSigAddress);
  }


 
  function () {
    revert();
  }

}



contract SPCCrowdFund {

    using SafeMath for uint256;
    
    SPCToken public token;                                     

     
    uint256 public preSaleStartTime = 1509494401;              
    uint256 public preSaleEndTime = 1510531199;                
    uint256 public crowdfundStartDate = 1511308801;            
    uint256 public crowdfundEndDate = 1515283199;              
    uint256 public totalWeiRaised;                             
    uint256 public exchangeRateForETH = 300;                   
    uint256 public exchangeRateForBTC = 4500;                  
    uint256 internal tokenSoldInPresale = 0;
    uint256 internal tokenSoldInCrowdsale = 0;
    uint256 internal minAmount = 1 * 10 ** 17;                 

    bool internal isTokenDeployed = false;                     
 

      
     
    address public founderMultiSigAddress = 0xF50aCE12e0537111be782899Fd5c4f5f638340d5;                            
     
    address public owner;                                              
    
    enum State { PreSale, Crowdfund, Finish }

     
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

    modifier onlyFounders() {
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderMultiSigAddress);
        _;
    }

    modifier inState(State state) {
        require(getState() == state); 
        _;
    }

      
    function SPCCrowdFund () {
        owner = msg.sender;
    }

     
     function setFounderMultiSigAddress(address _newFounderAddress) onlyFounders  nonZeroAddress(_newFounderAddress) {
        founderMultiSigAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

     
    function setTokenAddress(address _tokenAddress) external onlyOwner nonZeroAddress(_tokenAddress) {
        require(isTokenDeployed == false);
        token = SPCToken(_tokenAddress);
        isTokenDeployed = true;
    }

     
     
    function endCrowdfund() onlyFounders inState(State.Finish) returns (bool) {
        require(now > crowdfundEndDate);
        uint256 remainingToken = token.balanceOf(this);   

        if (remainingToken != 0) 
          token.transfer(founderMultiSigAddress, remainingToken); 
        CrowdFundClosed(now);
        return true; 
    }

     
    function buyTokens(address beneficiary) 
    nonZeroEth 
    tokenIsDeployed 
    onlyPublic 
    nonZeroAddress(beneficiary) 
    payable 
    returns(bool) 
    {
        require(msg.value >= minAmount);

        if (getState() == State.PreSale) {
            if (buyPreSaleTokens(beneficiary)) {
                return true;
            }
            return false;
        } else {
            require(now >= crowdfundStartDate && now <= crowdfundEndDate);
            fundTransfer(msg.value);

            uint256 amount = getNoOfTokens(exchangeRateForETH, msg.value);
            
            if (token.transfer(beneficiary, amount)) {
                tokenSoldInCrowdsale = tokenSoldInCrowdsale.add(amount);
                token.changeTotalSupply(amount); 
                totalWeiRaised = totalWeiRaised.add(msg.value);
                TokenPurchase(beneficiary, msg.value, amount);
                return true;
            } 
            return false;
        }
       
    }
        
     
    function buyPreSaleTokens(address beneficiary) internal returns(bool) {
            
            uint256 amount = getTokensForPreSale(exchangeRateForETH, msg.value);
            fundTransfer(msg.value);

            if (token.transfer(beneficiary, amount)) {
                tokenSoldInPresale = tokenSoldInPresale.add(amount);
                token.changeTotalSupply(amount); 
                totalWeiRaised = totalWeiRaised.add(msg.value);
                TokenPurchase(beneficiary, msg.value, amount);
                return true;
            }
            return false;
    }    

 
    function getNoOfTokens(uint256 _exchangeRate, uint256 _amount) internal constant returns (uint256) {
         uint256 noOfToken = _amount.mul(_exchangeRate);
         uint256 noOfTokenWithBonus = ((100 + getCurrentBonusRate()) * noOfToken ).div(100);
         return noOfTokenWithBonus;
    }

    function getTokensForPreSale(uint256 _exchangeRate, uint256 _amount) internal constant returns (uint256) {
        uint256 noOfToken = _amount.mul(_exchangeRate);
        uint256 noOfTokenWithBonus = ((100 + getCurrentBonusRate()) * noOfToken ).div(100);
        if (noOfTokenWithBonus + tokenSoldInPresale > (50000000 * 10 ** 18) ) {
            revert();
        }
        return noOfTokenWithBonus;
    }

     
    function fundTransfer(uint256 weiAmount) internal {
        founderMultiSigAddress.transfer(weiAmount);
    }


 

     
    function getState() public constant returns(State) {
        if (now >= preSaleStartTime && now <= preSaleEndTime) {
            return State.PreSale;
        }
        if (now >= crowdfundStartDate && now <= crowdfundEndDate) {
            return State.Crowdfund;
        } 
        return State.Finish;
    }


     
    function getCurrentBonusRate() internal returns (uint8) {
        
        if (getState() == State.PreSale) {
           return 50;
        } 
        if (getState() == State.Crowdfund) {
           if (tokenSoldInCrowdsale <= (100000000 * 10 ** 18) ) {
               return 30;
           }
           if (tokenSoldInCrowdsale > (100000000 * 10 ** 18) && tokenSoldInCrowdsale <= (175000000 * 10 ** 18)) {
               return 10;
           } else {
               return 0;
           }
        }
    }


     
    function currentBonus() public constant returns (uint8) {
        return getCurrentBonusRate();
    }

     

    function getContractTimestamp() public constant returns ( 
        uint256 _presaleStartDate, 
        uint256 _presaleEndDate, 
        uint256 _crowdsaleStartDate, 
        uint256 _crowdsaleEndDate) 
    {
        return (preSaleStartTime, preSaleEndTime, crowdfundStartDate, crowdfundEndDate);
    }

    function getExchangeRate() public constant returns (uint256 _exchangeRateForETH, uint256 _exchangeRateForBTC) {
        return (exchangeRateForETH, exchangeRateForBTC);
    }

    function getNoOfSoldToken() public constant returns (uint256 _tokenSoldInPresale , uint256 _tokenSoldInCrowdsale) {
        return (tokenSoldInPresale, tokenSoldInCrowdsale);
    }

    function getWeiRaised() public constant returns (uint256 _totalWeiRaised) {
        return totalWeiRaised;
    }

     
     
     
    function() public payable {
        buyTokens(msg.sender);
    }
}