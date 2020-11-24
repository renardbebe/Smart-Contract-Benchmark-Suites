 

 

pragma solidity ^0.4.13;

contract ReentrnacyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract IToken {
  function totalSupply() public constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) public {}
}

contract IERC20Token {
  function totalSupply() public constant returns (uint256 totalSupply);
  function balanceOf(address _owner) public constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) public returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
  function approve(address _spender, uint256 _value) public returns (bool success) {}
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Crowdsale is ReentrnacyHandlingContract, Owned{

  struct ContributorData{
    uint priorityPassAllowance;
    bool isActive;
    uint contributionAmount;
    uint tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;
  uint public nextContributorIndex;
  mapping(uint => address) public contributorIndexes;

  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, priorityPass, openedPriorityPass, crowdsale, crowdsaleEnded }

  uint public presaleStartTime;
  uint public presaleUnlimitedStartTime;
  uint public crowdsaleStartTime;
  uint public crowdsaleEndedTime;

  event PresaleStarted(uint blockTime);
  event PresaleUnlimitedStarted(uint blockTime);
  event CrowdsaleStarted(uint blockTime);
  event CrowdsaleEnded(uint blockTime);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockTime);
  event MaxCapReached(uint blockTime);
  event ContributionMade(address indexed contributor, uint amount);


  IToken token = IToken(0x0);
  uint ethToTokenConversion;

  uint public minCap;
  uint public maxP1Cap;
  uint public maxCap;
  uint public ethRaised;

  address public multisigAddress;

  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  uint public maxTokenSupply;
  bool public ownerHasClaimedTokens;
  uint public presaleBonusTokens;
  address public presaleBonusAddress;
  address public presaleBonusAddressColdStorage;
  bool public presaleBonusTokensClaimed;

   
   
   
   
  function() public noReentrancy payable{
    require(msg.value != 0);                         
    require(crowdsaleState != state.crowdsaleEnded); 

    bool stateChanged = checkCrowdsaleState();       

    if (crowdsaleState == state.priorityPass){
      if (contributorList[msg.sender].isActive){     
        processTransaction(msg.sender, msg.value);   
      }else{
        refundTransaction(stateChanged);             
      }
    }
    else if(crowdsaleState == state.openedPriorityPass){
      if (contributorList[msg.sender].isActive){     
        processTransaction(msg.sender, msg.value);   
      }else{
        refundTransaction(stateChanged);             
      }
    }
    else if(crowdsaleState == state.crowdsale){
      processTransaction(msg.sender, msg.value);     
    }
    else{
      refundTransaction(stateChanged);               
    }
  }

   
   
   
  function checkCrowdsaleState() internal returns (bool){
    if (ethRaised == maxCap && crowdsaleState != state.crowdsaleEnded){                          
      crowdsaleState = state.crowdsaleEnded;
      MaxCapReached(block.timestamp);                                                               
      CrowdsaleEnded(block.timestamp);                                                              
      return true;
    }

    if (block.timestamp > presaleStartTime && block.timestamp <= presaleUnlimitedStartTime){   
      if (crowdsaleState != state.priorityPass){                                           
        crowdsaleState = state.priorityPass;                                               
        PresaleStarted(block.timestamp);                                                      
        return true;
      }
    }else if(block.timestamp > presaleUnlimitedStartTime && block.timestamp <= crowdsaleStartTime){  
      if (crowdsaleState != state.openedPriorityPass){                                           
        crowdsaleState = state.openedPriorityPass;                                               
        PresaleUnlimitedStarted(block.timestamp);                                                   
        return true;
      }
    }else if(block.timestamp > crowdsaleStartTime && block.timestamp <= crowdsaleEndedTime){         
      if (crowdsaleState != state.crowdsale){                                                    
        crowdsaleState = state.crowdsale;                                                        
        CrowdsaleStarted(block.timestamp);                                                          
        return true;
      }
    }else{
      if (crowdsaleState != state.crowdsaleEnded && block.timestamp > crowdsaleEndedTime){         
        crowdsaleState = state.crowdsaleEnded;                                                   
        CrowdsaleEnded(block.timestamp);                                                            
        return true;
      }
    }
    return false;
  }

   
   
   
  function refundTransaction(bool _stateChanged) internal{
    if (_stateChanged){
      msg.sender.transfer(msg.value);
    }else{
      revert();
    }
  }

   
   
   
  function calculateMaxContribution(address _contributor) constant returns (uint maxContribution){
    uint maxContrib;
    if (crowdsaleState == state.priorityPass){     
      maxContrib = contributorList[_contributor].priorityPassAllowance - contributorList[_contributor].contributionAmount;
      if (maxContrib > (maxP1Cap - ethRaised)){    
        maxContrib = maxP1Cap - ethRaised;         
      }
    }
    else{
      maxContrib = maxCap - ethRaised;             
    }
    return maxContrib;
  }

   
   
   
  function processTransaction(address _contributor, uint _amount) internal{
    uint maxContribution = calculateMaxContribution(_contributor);               
    uint contributionAmount = _amount;
    uint returnAmount = 0;
    if (maxContribution < _amount){                                              
      contributionAmount = maxContribution;                                      
      returnAmount = _amount - maxContribution;                                  
    }

    if (ethRaised + contributionAmount > minCap && minCap > ethRaised) MinCapReached(block.timestamp);

    if (contributorList[_contributor].isActive == false){                        
      contributorList[_contributor].isActive = true;                             
      contributorList[_contributor].contributionAmount = contributionAmount;     
      contributorIndexes[nextContributorIndex] = _contributor;                   
      nextContributorIndex++;
    }
    else{
      contributorList[_contributor].contributionAmount += contributionAmount;    
    }
    ethRaised += contributionAmount;                                             

    ContributionMade(msg.sender, contributionAmount);

    uint tokenAmount = contributionAmount * ethToTokenConversion;                
    if (tokenAmount > 0){
      token.mintTokens(_contributor, tokenAmount);                                 
      contributorList[_contributor].tokensIssued += tokenAmount;                   
    }
    if (returnAmount != 0) _contributor.transfer(returnAmount);                  
  }

   
   
   
  function editContributors(address[] _contributorAddresses, uint[] _contributorPPAllowances) public onlyOwner{
    require(_contributorAddresses.length == _contributorPPAllowances.length);  

    for(uint cnt = 0; cnt < _contributorAddresses.length; cnt++){
      if (contributorList[_contributorAddresses[cnt]].isActive){
        contributorList[_contributorAddresses[cnt]].priorityPassAllowance = _contributorPPAllowances[cnt];
      }
      else{
        contributorList[_contributorAddresses[cnt]].isActive = true;
        contributorList[_contributorAddresses[cnt]].priorityPassAllowance = _contributorPPAllowances[cnt];
        contributorIndexes[nextContributorIndex] = _contributorAddresses[cnt];
        nextContributorIndex++;
      }
    }
  }

   
   
   
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) public onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }

   
   
   
   
  function withdrawEth() onlyOwner public {
    require(this.balance != 0);
    require(ethRaised >= minCap);

    pendingEthWithdrawal = this.balance;
  }


  uint public pendingEthWithdrawal;
   
   
   
   
   
  function pullBalance() public {
    require(msg.sender == multisigAddress);
    require(pendingEthWithdrawal > 0);

    multisigAddress.transfer(pendingEthWithdrawal);
    pendingEthWithdrawal = 0;
  }

   
   
   
  function claimEthIfFailed() public {
    require(block.timestamp > crowdsaleEndedTime && ethRaised < minCap);     
    require(contributorList[msg.sender].contributionAmount > 0);           
    require(!hasClaimedEthWhenFail[msg.sender]);                           

    uint ethContributed = contributorList[msg.sender].contributionAmount;  
    hasClaimedEthWhenFail[msg.sender] = true;                              
    if (!msg.sender.send(ethContributed)){                                 
      ErrorSendingETH(msg.sender, ethContributed);                         
    }
  }

   
   
   
  function batchReturnEthIfFailed(uint _numberOfReturns) public onlyOwner{
    require(block.timestamp > crowdsaleEndedTime && ethRaised < minCap);                 
    address currentParticipantAddress;
    uint contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++){
      currentParticipantAddress = contributorIndexes[nextContributorToClaim];          
      if (currentParticipantAddress == 0x0) return;                                    
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                         
        contribution = contributorList[currentParticipantAddress].contributionAmount;  
        hasClaimedEthWhenFail[currentParticipantAddress] = true;                       
        if (!currentParticipantAddress.send(contribution)){                            
          ErrorSendingETH(currentParticipantAddress, contribution);                    
        }
      }
      nextContributorToClaim += 1;                                                     
    }
  }

   
   
   
  function withdrawRemainingBalanceForManualRecovery() public onlyOwner{
    require(this.balance != 0);                                   
    require(block.timestamp > crowdsaleEndedTime);                  
    require(contributorIndexes[nextContributorToClaim] == 0x0);   
    multisigAddress.transfer(this.balance);                       
  }

   
   
   
  function setMultisigAddress(address _newAddress) public onlyOwner{
    multisigAddress = _newAddress;
  }

   
   
   
  function setToken(address _newAddress) public onlyOwner{
    token = IToken(_newAddress);
  }

   
   
   
  function claimCoreTeamsTokens(address _to) public onlyOwner{
    require(crowdsaleState == state.crowdsaleEnded);               
    require(!ownerHasClaimedTokens);                               

    uint devReward = maxTokenSupply - token.totalSupply();
    if (!presaleBonusTokensClaimed) devReward -= presaleBonusTokens;  
    token.mintTokens(_to, devReward);                              
    ownerHasClaimedTokens = true;                                  
  }

   
   
   
  function claimPresaleTokens() public {
    require(msg.sender == presaleBonusAddress);          
    require(crowdsaleState == state.crowdsaleEnded);     
    require(!presaleBonusTokensClaimed);                 

    token.mintTokens(presaleBonusAddressColdStorage, presaleBonusTokens);              
    presaleBonusTokensClaimed = true;                    
  }

  function getTokenAddress() public constant returns(address){
    return address(token);
  }

}


contract FutouristCrowdsale is Crowdsale {
  function FutouristCrowdsale() public {
     
    presaleStartTime = 1519142400;  
    presaleUnlimitedStartTime = 1519315200;  
    crowdsaleStartTime = 1519747200;  
    crowdsaleEndedTime = 1521561600;  

    minCap = 1 ether;
    maxCap = 4979 ether;
    maxP1Cap = 4979 ether;

    ethToTokenConversion = 47000;

    maxTokenSupply = 1000000000 * 10**18;
    presaleBonusTokens = 115996000  * 10**18;
    presaleBonusAddress = 0xd7C4af0e30EC62a01036e45b6ed37BC6D0a3bd53;
    presaleBonusAddressColdStorage = 0x47D634Ce50170a156ec4300d35BE3b48E17CAaf6;
     
  }
}