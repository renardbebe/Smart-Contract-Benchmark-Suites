 

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