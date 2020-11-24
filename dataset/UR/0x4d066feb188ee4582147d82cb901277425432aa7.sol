 

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


contract DOWToken is BasicToken {

using SafeMath for uint256;

string public name = "DOW";                         
string public symbol = "dow";                       
uint8 public decimals = 18;                         
uint256 public initialSupply = 2000000000 * 10**18;   

 
uint256 public foundersAllocation;                   
uint256 public devAllocation;                        
uint256 public totalAllocatedTokens;                 
uint256 public tokensAllocatedToCrowdFund;           
 

address public founderMultiSigAddress;               
address public devTeamAddress;                       
address public crowdFundAddress;                     



 

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

  
    
   function DOWToken (address _crowdFundAddress, address _founderMultiSigAddress, address _devTeamAddress) {
    crowdFundAddress = _crowdFundAddress;
    founderMultiSigAddress = _founderMultiSigAddress;
    devTeamAddress = _devTeamAddress;

     
    foundersAllocation = 50 * 10 ** 25;                
    devAllocation = 30 * 10 ** 25;                     
    tokensAllocatedToCrowdFund = 120 * 10 ** 25;       
   
     
    balances[founderMultiSigAddress] = foundersAllocation;
    balances[devTeamAddress] = devAllocation;
    balances[crowdFundAddress] = tokensAllocatedToCrowdFund;

    totalAllocatedTokens = balances[founderMultiSigAddress] + balances[devTeamAddress];
  }


 
  function addToAllocation(uint256 _amount) onlyCrowdFundAddress {
    totalAllocatedTokens = totalAllocatedTokens.add(_amount);
  }

 
  function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
    founderMultiSigAddress = _newFounderMultiSigAddress;
    ChangeFoundersWalletAddress(now, founderMultiSigAddress);
  }

 
  function () {
    revert();
  }

}


contract DOWCrowdfund {

    using SafeMath for uint256;
    
    DOWToken public token;                                  

     
    uint256 public crowdfundStartTime;                      
    uint256 public crowdfundEndTime;                        
    uint256 public totalWeiRaised;                          
    uint256 public weekOneRate = 3000;                      
    uint256 public weekTwoRate = 2000;                      
    uint256 public weekThreeRate = 1500;                    
    uint256 public weekFourthRate = 1200;                   
    uint256 minimumFundingGoal = 5000 * 1 ether;            
    uint256 MAX_FUNDING_GOAL = 400000 * 1 ether;            
    uint256 public totalDowSold = 0;
    address public owner = 0x0;                             

    bool  internal isTokenDeployed = false;                 

     
    address public founderMultiSigAddress;                  
    address public remainingTokenHolder;                    
     
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

    modifier onlyPublic() {
        require(msg.sender != founderMultiSigAddress);
        _;
    }

    modifier isBetween() {
        require(now >= crowdfundStartTime && now <= crowdfundEndTime);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function DOWCrowdfund (address _founderWalletAddress, address _remainingTokenHolder) {
        founderMultiSigAddress = _founderWalletAddress;
        remainingTokenHolder = _remainingTokenHolder;
        owner = msg.sender;
        crowdfundStartTime = 1510272001;   
        crowdfundEndTime = 1512950399;     
    }


     
    function ChangeFounderMultiSigAddress(address _newFounderAddress) onlyFounders nonZeroAddress(_newFounderAddress) {
        founderMultiSigAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

     
    function setTokenAddress(address _tokenAddress) external onlyOwner nonZeroAddress(_tokenAddress) {
        require(isTokenDeployed == false);
        token = DOWToken(_tokenAddress);
        isTokenDeployed = true;
    }


     
     
    function endCrowdfund() onlyFounders returns (bool) {
        require(now > crowdfundEndTime);
        uint256 remainingToken = token.balanceOf(this);   

        if (remainingToken != 0) {
          token.transfer(remainingTokenHolder, remainingToken); 
          CrowdFundClosed(now);
          return true; 
        } 
        CrowdFundClosed(now);
        return false;
       
    }

     
    function buyTokens(address beneficiary) 
    nonZeroEth 
    tokenIsDeployed 
    onlyPublic
    isBetween 
    nonZeroAddress(beneficiary) 
    payable 
    returns(bool) 
    {
        if (totalWeiRaised.add(msg.value) > MAX_FUNDING_GOAL) 
            revert();

            fundTransfer(msg.value);
            uint256 amount = getNoOfTokens(msg.value);
            
            if (token.transfer(beneficiary, amount)) {
                token.addToAllocation(amount); 
                totalDowSold = totalDowSold.add(amount);
                totalWeiRaised = totalWeiRaised.add(msg.value);
                TokenPurchase(beneficiary, msg.value, amount);
                return true;
            } 
            return false;
        }

     
    function fundTransfer(uint256 weiAmount) internal {
        founderMultiSigAddress.transfer(weiAmount);
    }

 

     
    function getNoOfTokens(uint256 investedAmount) internal returns (uint256) {
        
        if ( now > crowdfundStartTime + 3 weeks && now < crowdfundEndTime) {
            return  investedAmount.mul(weekFourthRate);
        }
        if (now > crowdfundStartTime + 2 weeks) {
            return investedAmount.mul(weekThreeRate);
        }
        if (now > crowdfundStartTime + 1 weeks) {
            return investedAmount.mul(weekTwoRate);
        }
        if (now > crowdfundStartTime) {
            return investedAmount.mul(weekOneRate);
        }
    }

    
     
     
     
    function() public payable {
        buyTokens(msg.sender);
    }
}