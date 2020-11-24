 

pragma solidity ^0.4.15;

contract ERC20 {
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract EPTToken is BasicToken {

    using SafeMath for uint256;

    string public name = "e-Pocket Token";                       
    string public symbol = "EPT";                                
    uint8 public decimals = 18;                                  
    uint256 public initialSupply = 64000000 * 10**18;            

     
    uint256 public totalAllocatedTokens;                          
    uint256 public tokensAllocatedToCrowdFund;                    
    uint256 public foundersAllocation;                            

     
    address public founderMultiSigAddress;                        
    address public crowdFundAddress;                              

     
    event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
    
     

    modifier nonZeroAddress(address _to){
        require(_to != 0x0);
        _;
    }

    modifier onlyFounders(){
        require(msg.sender == founderMultiSigAddress);
        _;
    }

    modifier onlyCrowdfund(){
        require(msg.sender == crowdFundAddress);
        _;
    }

     
    
    function EPTToken(address _crowdFundAddress, address _founderMultiSigAddress) {
        crowdFundAddress = _crowdFundAddress;
        founderMultiSigAddress = _founderMultiSigAddress;
    
         
        tokensAllocatedToCrowdFund = 32 * 10**24;
        foundersAllocation = 32 * 10**24;

         
        balances[crowdFundAddress] = tokensAllocatedToCrowdFund;
        balances[founderMultiSigAddress] = foundersAllocation;

        totalAllocatedTokens = balances[founderMultiSigAddress];
    }

     

    function changeTotalSupply(uint256 _amount) onlyCrowdfund {
        totalAllocatedTokens += _amount;
    }


     
    
    function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
        founderMultiSigAddress = _newFounderMultiSigAddress;
        ChangeFoundersWalletAddress(now, founderMultiSigAddress);
    }

  
}


contract EPTCrowdfund {
    
    using SafeMath for uint256;

    EPTToken public token;                                       
    
    address public beneficiaryAddress;                           
    address public founderAddress;                               
    uint256 public crowdfundStartTime = 1516579201;              
    uint256 public crowdfundEndTime = 1518998399;                
    uint256 public presaleStartTime = 1513123201;                
    uint256 public presaleEndTime = 1516579199;                  
    uint256 public ethRaised;                                    
    bool private tokenDeployed = false;                          
    uint256 public tokenSold;                                    
    uint256 private ethRate;
    
    
     
    event ChangeFounderAddress(address indexed _newFounderAddress , uint256 _timestamp);
    event TokenPurchase(address indexed _beneficiary, uint256 _value, uint256 _amount);
    event CrowdFundClosed(uint256 _timestamp);
    
    enum State {PreSale, CrowdSale, Finish}
    
     
    modifier onlyfounder() {
        require(msg.sender == founderAddress);
        _;
    }

    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier onlyPublic() {
        require(msg.sender != founderAddress);
        _;
    }

    modifier nonZeroEth() {
        require(msg.value != 0);
        _;
    }

    modifier isTokenDeployed() {
        require(tokenDeployed == true);
        _;
    }

    modifier isBetween() {
        require(now >= presaleStartTime && now <= crowdfundEndTime);
        _;
    }

     

    function EPTCrowdfund(address _founderAddress, address _beneficiaryAddress, uint256 _ethRate) {
        beneficiaryAddress = _beneficiaryAddress;
        founderAddress = _founderAddress;
        ethRate = uint256(_ethRate);
    }
   
     

    function setToken(address _tokenAddress) nonZeroAddress(_tokenAddress) onlyfounder {
         require(tokenDeployed == false);
         token = EPTToken(_tokenAddress);
         tokenDeployed = true;
    }
    
    
     

    function changeFounderWalletAddress(address _newAddress) onlyfounder nonZeroAddress(_newAddress) {
         founderAddress = _newAddress;
         ChangeFounderAddress(founderAddress,now);
    }

    
     

    function buyTokens (address _beneficiary)
    isBetween
    onlyPublic
    nonZeroAddress(_beneficiary)
    nonZeroEth
    isTokenDeployed
    payable
    public
    returns (bool)
    {
         uint256 amount = msg.value.mul(((ethRate.mul(100)).div(getRate())));
    
        if (token.transfer(_beneficiary, amount)) {
            fundTransfer(msg.value);
            
            ethRaised = ethRaised.add(msg.value);
            tokenSold = tokenSold.add(amount);
            token.changeTotalSupply(amount); 
            TokenPurchase(_beneficiary, msg.value, amount);
            return true;
        }
        return false;
    }

     

    function setEthRate(uint256 _newEthRate) onlyfounder returns (bool) {
        require(_newEthRate > 0);
        ethRate = _newEthRate;
        return true;
    }

     

    function getRate() internal returns(uint256) {

        if (getState() == State.PreSale) {
            return 10;
        } 
        if(getState() == State.CrowdSale) {
            if (now >= crowdfundStartTime + 3 weeks && now <= crowdfundEndTime) {
                return 30;
             }
            if (now >= crowdfundStartTime + 2 weeks) {
                return 25;
            }
            if (now >= crowdfundStartTime + 1 weeks) {
                return 20;
            }
            if (now >= crowdfundStartTime) {
                return 15;
            }  
        } else {
            return 0;
        }
              
    }  

     

    function getState() private returns(State) {
        if (now >= crowdfundStartTime && now <= crowdfundEndTime) {
            return State.CrowdSale;
        }
        if (now >= presaleStartTime && now <= presaleEndTime) {
            return State.PreSale;
        } else {
            return State.Finish;
        }

    }

     

    function endCrowdFund() onlyfounder returns(bool) {
        require(now > crowdfundEndTime);
        uint256 remainingtoken = token.balanceOf(this);

        if (remainingtoken != 0) {
            token.transfer(founderAddress,remainingtoken);
            CrowdFundClosed(now);
            return true;
        }
        CrowdFundClosed(now);
        return false;    
 } 

     

    function fundTransfer(uint256 _funds) private {
        beneficiaryAddress.transfer(_funds);
    }

     
     
     
    function () payable {
        buyTokens(msg.sender);
    }

}