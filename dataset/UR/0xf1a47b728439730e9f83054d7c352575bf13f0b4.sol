 

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
    
    modifier nonZeroEth(uint _value) {
      require(_value > 0);
      _;
    }

    modifier onlyPayloadSize() {
      require(msg.data.length >= 68);
      _;
    }
     

    function transfer(address _to, uint256 _value) nonZeroEth(_value) onlyPayloadSize returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]){
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else{
            return false;
        }
    }
    

     

    function transferFrom(address _from, address _to, uint256 _value) nonZeroEth(_value) onlyPayloadSize returns (bool) {
      if(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]){
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      }else{
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


contract RPTToken is BasicToken {

using SafeMath for uint256;

string public name = "RPT Token";                   
string public symbol = "RPT";                       
uint8 public decimals = 18;                         
uint256 public totalSupply = 1000000000 * 10**18;   

 
uint256 public keyEmployeeAllocation;                
uint256 public totalAllocatedTokens;                 
uint256 public tokensAllocatedToCrowdFund;           

 
address public founderMultiSigAddress = 0xf96E905091d38ca25e06C014fE67b5CA939eE83D;     
address public crowdFundAddress;                     

 
event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);
event TransferPreAllocatedFunds(uint256  _blockTimeStamp , address _to , uint256 _value);

 
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

    
   function RPTToken (address _crowdFundAddress) {
    crowdFundAddress = _crowdFundAddress;

     
    tokensAllocatedToCrowdFund = 70 * 10 ** 25;         
    keyEmployeeAllocation = 30 * 10 ** 25;              

     
    balances[founderMultiSigAddress] = keyEmployeeAllocation;
    balances[crowdFundAddress] = tokensAllocatedToCrowdFund;

    totalAllocatedTokens = balances[founderMultiSigAddress];
  }

 
  function changeTotalSupply(uint256 _amount) onlyCrowdFundAddress {
    totalAllocatedTokens = totalAllocatedTokens.add(_amount);
  }

 
  function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
    founderMultiSigAddress = _newFounderMultiSigAddress;
    ChangeFoundersWalletAddress(now, founderMultiSigAddress);
  }
 

}


contract RPTCrowdsale {

    using SafeMath for uint256;
    
    RPTToken public token;                                           
     
   
    uint256 public totalWeiRaised;                                   
    uint32 public exchangeRate = 3000;                               
    uint256 public preDistriToAcquiantancesStartTime = 1510876801;   
    uint256 public preDistriToAcquiantancesEndTime = 1511827199;     
    uint256 public presaleStartTime = 1511827200;                    
    uint256 public presaleEndTime = 1513036799;                      
    uint256 public crowdfundStartTime = 1513036800;                  
    uint256 public crowdfundEndTime = 1515628799;                    
    bool internal isTokenDeployed = false;                           
    
     
    address public founderMultiSigAddress;                           
    address public remainingTokenHolder;                             
    address public beneficiaryAddress;                               
    

    enum State { Acquiantances, PreSale, CrowdFund, Closed }

     
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

    modifier inState(State state) {
        require(getState() == state); 
        _;
    }

    modifier inBetween() {
        require(now >= preDistriToAcquiantancesStartTime && now <= crowdfundEndTime);
        _;
    }

     
    function RPTCrowdsale (address _founderWalletAddress, address _remainingTokenHolder, address _beneficiaryAddress) {
        founderMultiSigAddress = _founderWalletAddress;
        remainingTokenHolder = _remainingTokenHolder;
        beneficiaryAddress = _beneficiaryAddress;
    }

     
     function setFounderMultiSigAddress(address _newFounderAddress) onlyFounders  nonZeroAddress(_newFounderAddress) {
        founderMultiSigAddress = _newFounderAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }
    
     
    function setTokenAddress(address _tokenAddress) external onlyFounders nonZeroAddress(_tokenAddress) {
        require(isTokenDeployed == false);
        token = RPTToken(_tokenAddress);
        isTokenDeployed = true;
    }


     
    function endCrowdfund() onlyFounders returns (bool) {
        require(now > crowdfundEndTime);
        uint256 remainingToken = token.balanceOf(this);   

        if (remainingToken != 0) {
          token.transfer(remainingTokenHolder, remainingToken); 
          CrowdFundClosed(now);
          return true; 
        } else {
            CrowdFundClosed(now);
            return false;
        }
       
    }

     
    function buyTokens(address beneficiary)
    nonZeroEth 
    tokenIsDeployed 
    onlyPublic 
    nonZeroAddress(beneficiary) 
    inBetween
    payable 
    public 
    returns(bool) 
    {
            fundTransfer(msg.value);

            uint256 amount = getNoOfTokens(exchangeRate, msg.value);
            
            if (token.transfer(beneficiary, amount)) {
                token.changeTotalSupply(amount); 
                totalWeiRaised = totalWeiRaised.add(msg.value);
                TokenPurchase(beneficiary, msg.value, amount);
                return true;
            } 
            return false;
        
    }


     
    function fundTransfer(uint256 weiAmount) internal {
        beneficiaryAddress.transfer(weiAmount);
    }

 

     
    function getState() internal constant returns(State) {
        if (now >= preDistriToAcquiantancesStartTime && now <= preDistriToAcquiantancesEndTime) {
            return State.Acquiantances;
        } if (now >= presaleStartTime && now <= presaleEndTime) {
            return State.PreSale;
        } if (now >= crowdfundStartTime && now <= crowdfundEndTime) {
            return State.CrowdFund;
        } else {
            return State.Closed;
        }
        
    }


    
    function getNoOfTokens(uint32 _exchangeRate, uint256 _amount) internal returns (uint256) {
         uint256 noOfToken = _amount.mul(uint256(_exchangeRate));
         uint256 noOfTokenWithBonus = ((uint256(100 + getCurrentBonusRate())).mul(noOfToken)).div(100);
         return noOfTokenWithBonus;
    }

    

     
    function getCurrentBonusRate() internal returns (uint8) {
        
        if (getState() == State.Acquiantances) {
            return 40;
        }
        if (getState() == State.PreSale) {
            return 20;
        }
        if (getState() == State.CrowdFund) {
            return 0;
        } else {
            return 0;
        }
    }

     
    function getBonus() constant returns (uint8) {
        return getCurrentBonusRate();
    }

     
     
    function() public payable {
        buyTokens(msg.sender);
    }
}