 

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


 
contract ERC20Basic {
  uint256 public totalSupply = 800000000 * 10**18;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract Ownable {

  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

 
contract AfterSchoolCrowdsaleToken is StandardToken, Ownable {
    
  string public standard = "AfterSchool Token v1.1";
  string public name = "AfterSchool Token";
  string public symbol = "AST";
  uint public decimals = 18;
  address public multisig = 0x8Dab59292A76114776B4933aD6F1246Bf647aB90;
  
   
  uint PRICE = 5800;
  
  struct ContributorData {
    uint contributionAmount;
    uint tokensIssued;
  }

  function AfterSchoolCrowdsaleToken() {
    balances[msg.sender] = totalSupply;
  }

  mapping(address => ContributorData) public contributorList;
  uint nextContributorIndex;
  mapping(uint => address) contributorIndexes;
  
  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, crowdsale, crowdsaleEnded }
  
  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockNumber);
  event MaxCapReached(uint blockNumber);
  
  uint public constant BEGIN_TIME = 1506420000;
  
  uint public constant END_TIME = 1509012000;

  uint public minCap = 3500 ether;
  uint public maxCap = 50000 ether;
  uint public ethRaised = 0;
  uint public tokenTotalSupply = 800000000 * 10**decimals;
  
  uint crowdsaleTokenCap =            480000000 * 10**decimals;  
  uint foundersAndTeamTokens =        120000000 * 10**decimals;  
  uint advisorAndAmbassadorTokens =    56000000 * 10**decimals;  
  uint investorTokens =                8000000 * 10**decimals;  
  uint afterschoolContributorTokens = 56000000 * 10**decimals;  
  uint futurePartnerTokens =          64000000 * 10**decimals;  
  
  bool foundersAndTeamTokensClaimed = false;
  bool advisorAndAmbassadorTokensClaimed = false;
  bool investorTokensClaimed = false;
  bool afterschoolContributorTokensClaimed = false;
  bool futurePartnerTokensClaimed = false;
  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  function() payable {
  require(msg.value != 0);
  require(crowdsaleState != state.crowdsaleEnded); 
  
  bool stateChanged = checkCrowdsaleState();       
  
  if(crowdsaleState == state.crowdsale) {
      createTokens(msg.sender);              
    } else {
      refundTransaction(stateChanged);               
    }
  }
  
   
   
   
  function checkCrowdsaleState() internal returns (bool) {
    if (ethRaised >= maxCap && crowdsaleState != state.crowdsaleEnded) {  
      crowdsaleState = state.crowdsaleEnded;
      CrowdsaleEnded(block.number);  
      return true;
    }
    
    if(now >= END_TIME) {   
      crowdsaleState = state.crowdsaleEnded;
      CrowdsaleEnded(block.number);  
      return true;
    }

    if(now >= BEGIN_TIME && now < END_TIME) {         
      if (crowdsaleState != state.crowdsale) {                                                    
        crowdsaleState = state.crowdsale;                                                        
        CrowdsaleStarted(block.number);                                                          
        return true;
      }
    }
    
    return false;
  }
  
   
   
   
  function refundTransaction(bool _stateChanged) internal {
    if (_stateChanged) {
      msg.sender.transfer(msg.value);
    } else {
      revert();
    }
  }
  
  function createTokens(address _contributor) payable {
  
    uint _amount = msg.value;
  
    uint contributionAmount = _amount;
    uint returnAmount = 0;
    
    if (_amount > (maxCap - ethRaised)) {                                           
      contributionAmount = maxCap - ethRaised;                                      
      returnAmount = _amount - contributionAmount;                                  
    }

    if (ethRaised + contributionAmount > minCap && minCap > ethRaised) {
      MinCapReached(block.number);
    }

    if (ethRaised + contributionAmount == maxCap && ethRaised < maxCap) {
      MaxCapReached(block.number);
    }

    if (contributorList[_contributor].contributionAmount == 0){
        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex += 1;
    }
  
    contributorList[_contributor].contributionAmount += contributionAmount;
    ethRaised += contributionAmount;                                               

    uint256 tokenAmount = calculateEthToAfterschool(contributionAmount);       
    if (tokenAmount > 0) {
      transferToContributor(_contributor, tokenAmount);
      contributorList[_contributor].tokensIssued += tokenAmount;                   
    }

    if (!multisig.send(msg.value)) {
        revert();
    }
  }


    function transferToContributor(address _to, uint256 _value)  {
    balances[owner] = balances[owner].sub(_value);
    balances[_to] = balances[_to].add(_value);
  }
  
  function calculateEthToAfterschool(uint _eth) constant returns(uint256) {
  
    uint tokens = _eth.mul(getPrice());
    uint percentage = 0;
    
    if (ethRaised > 0)
    {
        percentage = ethRaised * 100 / maxCap;
    }
    
    return tokens + getStageBonus(percentage, tokens) + getAmountBonus(_eth, tokens);
  }

  function getStageBonus(uint percentage, uint tokens) constant returns (uint) {
    uint stageBonus = 0;
      
    if (percentage <= 10) stageBonus = tokens * 60 / 100;  
    else if (percentage <= 50) stageBonus = tokens * 30 / 100;
    else if (percentage <= 70) stageBonus = tokens * 20 / 100;
    else if (percentage <= 90) stageBonus = tokens * 15 / 100;
    else if (percentage <= 100) stageBonus = tokens * 10 / 100;

    return stageBonus;
  }

  function getAmountBonus(uint _eth, uint tokens) constant returns (uint) {
    uint amountBonus = 0;  
      
    if (_eth >= 3000 ether) amountBonus = tokens * 13 / 100;
    else if (_eth >= 2000 ether) amountBonus = tokens * 12 / 100;
    else if (_eth >= 1500 ether) amountBonus = tokens * 11 / 100;
    else if (_eth >= 1000 ether) amountBonus = tokens * 10 / 100;
    else if (_eth >= 750 ether) amountBonus = tokens * 9 / 100;
    else if (_eth >= 500 ether) amountBonus = tokens * 8 / 100;
    else if (_eth >= 300 ether) amountBonus = tokens * 75 / 1000;
    else if (_eth >= 200 ether) amountBonus = tokens * 7 / 100;
    else if (_eth >= 150 ether) amountBonus = tokens * 6 / 100;
    else if (_eth >= 100 ether) amountBonus = tokens * 55 / 1000;
    else if (_eth >= 75 ether) amountBonus = tokens * 5 / 100;
    else if (_eth >= 50 ether) amountBonus = tokens * 45 / 1000;
    else if (_eth >= 30 ether) amountBonus = tokens * 4 / 100;
    else if (_eth >= 20 ether) amountBonus = tokens * 35 / 1000;
    else if (_eth >= 15 ether) amountBonus = tokens * 3 / 100;
    else if (_eth >= 10 ether) amountBonus = tokens * 25 / 1000;
    else if (_eth >= 7 ether) amountBonus = tokens * 2 / 100;
    else if (_eth >= 5 ether) amountBonus = tokens * 15 / 1000;
    else if (_eth >= 3 ether) amountBonus = tokens * 1 / 100;
    else if (_eth >= 2 ether) amountBonus = tokens * 5 / 1000;
    
    return amountBonus;
  }
  
   
  function getPrice() constant returns (uint result) {
    return PRICE;
  }
  
   
   
   
  function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner {
    require(crowdsaleState != state.crowdsaleEnded);                 
    require(ethRaised < minCap);                 
    address currentParticipantAddress;
    uint contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++){
      currentParticipantAddress = contributorIndexes[nextContributorToClaim];          
      if (currentParticipantAddress == 0x0) return;                                    
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                         
        contribution = contributorList[currentParticipantAddress].contributionAmount;  
        hasClaimedEthWhenFail[currentParticipantAddress] = true;                       
        balances[currentParticipantAddress] = 0;
        if (!currentParticipantAddress.send(contribution)){                            
          ErrorSendingETH(currentParticipantAddress, contribution);                    
        }
      }
      nextContributorToClaim += 1;                                                     
    }
  }
  
     
   
   
  function setMultisigAddress(address _newAddress) onlyOwner {
    multisig = _newAddress;
  }
  
}