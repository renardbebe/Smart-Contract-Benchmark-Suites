 

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

contract IToken {
  function totalSupply() constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) {}
}
contract IMintableToken {
  function mintTokens(address _to, uint256 _amount){}
}
contract IERC20Token {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ItokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

contract Owned {
    address public owner;
    address public newOwner;

    function Owned() {
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
contract ReentrnacyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

contract Lockable is Owned{

  uint256 public lockedUntilBlock;

  event ContractLocked(uint256 _untilBlock, string _reason);

  modifier lockAffected {
      require(block.number > lockedUntilBlock);
      _;
  }

  function lockFromSelf(uint256 _untilBlock, string _reason) internal {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }


  function lockUntil(uint256 _untilBlock, string _reason) onlyOwner {
    lockedUntilBlock = _untilBlock;
    ContractLocked(_untilBlock, _reason);
  }
}

contract Crowdsale is ReentrnacyHandlingContract, Owned{

  struct ContributorData{
    uint priorityPassAllowance;
    bool isActive;
    uint contributionAmount;
    uint tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;
  uint nextContributorIndex;
  mapping(uint => address) contributorIndexes;

  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, priorityPass, openedPriorityPass, crowdsale, crowdsaleEnded }

  uint public presaleStartBlock;
  uint public presaleUnlimitedStartBlock;
  uint public crowdsaleStartBlock;
  uint public crowdsaleEndedBlock;

  event PresaleStarted(uint blockNumber);
  event PresaleUnlimitedStarted(uint blockNumber);
  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockNumber);
  event MaxCapReached(uint blockNumber);

  IToken token = IToken(0x0);
  uint ethToTokenConversion;

  uint public minCap;
  uint public maxP1Cap;
  uint public maxCap;
  uint public ethRaised;

  address public multisigAddress;

  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  uint maxTokenSupply;
  bool ownerHasClaimedTokens;
  uint cofounditReward;
  address cofounditAddress;
  bool cofounditHasClaimedTokens;

   
   
   
  function() noReentrancy payable{
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
      MaxCapReached(block.number);                                                               
      CrowdsaleEnded(block.number);                                                              
      return true;
    }

    if (block.number > presaleStartBlock && block.number <= presaleUnlimitedStartBlock){   
      if (crowdsaleState != state.priorityPass){                                           
        crowdsaleState = state.priorityPass;                                               
        PresaleStarted(block.number);                                                      
        return true;
      }
    }else if(block.number > presaleUnlimitedStartBlock && block.number <= crowdsaleStartBlock){  
      if (crowdsaleState != state.openedPriorityPass){                                           
        crowdsaleState = state.openedPriorityPass;                                               
        PresaleUnlimitedStarted(block.number);                                                   
        return true;
      }
    }else if(block.number > crowdsaleStartBlock && block.number <= crowdsaleEndedBlock){         
      if (crowdsaleState != state.crowdsale){                                                    
        crowdsaleState = state.crowdsale;                                                        
        CrowdsaleStarted(block.number);                                                          
        return true;
      }
    }else{
      if (crowdsaleState != state.crowdsaleEnded && block.number > crowdsaleEndedBlock){         
        crowdsaleState = state.crowdsaleEnded;                                                   
        CrowdsaleEnded(block.number);                                                            
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

    if (ethRaised + contributionAmount > minCap && minCap > ethRaised) MinCapReached(block.number);

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

    uint tokenAmount = contributionAmount * ethToTokenConversion;                
    if (tokenAmount > 0){
      token.mintTokens(_contributor, tokenAmount);                                 
      contributorList[_contributor].tokensIssued += tokenAmount;                   
    }
    if (returnAmount != 0) _contributor.transfer(returnAmount);                  
  }

   
   
   
  function editContributors(address[] _contributorAddresses, uint[] _contributorPPAllowances) onlyOwner{
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

   
   
   
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }

   
   
   
  function withdrawEth() onlyOwner{
    require(this.balance != 0);
    require(ethRaised >= minCap);

    pendingEthWithdrawal = this.balance;
  }
  uint pendingEthWithdrawal;
  function sanityCheck(){
    require(msg.sender == multisigAddress);
    require(pendingEthWithdrawal > 0);

    multisigAddress.transfer(pendingEthWithdrawal);
    pendingEthWithdrawal = 0;
  }

   
   
   
  function claimEthIfFailed(){
    require(block.number > crowdsaleEndedBlock && ethRaised < minCap);     
    require(contributorList[msg.sender].contributionAmount > 0);           
    require(!hasClaimedEthWhenFail[msg.sender]);                           

    uint ethContributed = contributorList[msg.sender].contributionAmount;  
    hasClaimedEthWhenFail[msg.sender] = true;                              
    if (!msg.sender.send(ethContributed)){                                 
      ErrorSendingETH(msg.sender, ethContributed);                         
    }
  }

   
   
   
  function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner{
    require(block.number > crowdsaleEndedBlock && ethRaised < minCap);                 
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

   
   
   
  function withdrawRemainingBalanceForManualRecovery() onlyOwner{
    require(this.balance != 0);                                   
    require(block.number > crowdsaleEndedBlock);                  
    require(contributorIndexes[nextContributorToClaim] == 0x0);   
    multisigAddress.transfer(this.balance);                       
  }

   
   
   
  function setMultisigAddress(address _newAddress) onlyOwner{
    multisigAddress = _newAddress;
  }

   
   
   
  function setToken(address _newAddress) onlyOwner{
    token = IToken(_newAddress);
  }

   
   
   
  function claimCoreTeamsTokens(address _to) onlyOwner{
    require(crowdsaleState == state.crowdsaleEnded);               
    require(!ownerHasClaimedTokens);                               

    uint devReward = maxTokenSupply - token.totalSupply();
    if (!cofounditHasClaimedTokens) devReward -= cofounditReward;  
    token.mintTokens(_to, devReward);                              
    ownerHasClaimedTokens = true;                                  
  }

   
   
   
  function claimCofounditTokens(address _to){
    require(msg.sender == cofounditAddress);             
    require(crowdsaleState == state.crowdsaleEnded);     
    require(!cofounditHasClaimedTokens);                 

    token.mintTokens(_to, cofounditReward);              
    cofounditHasClaimedTokens = true;                    
  }

  function getTokenAddress() constant returns(address){
    return address(token);
  }
}



contract MaecenasCrowdsale is Crowdsale {
  function MaecenasCrowdsale(){
    presaleStartBlock = 4241483;
    presaleUnlimitedStartBlock = 4245055;
    crowdsaleStartBlock = 4248627;
    crowdsaleEndedBlock = 4348635;

    minCap = 9375 * 10**18;
    maxP1Cap = 31250 * 10**18;
    maxCap = 62500 * 10**18;

    ethToTokenConversion = 480;

    maxTokenSupply = 100000000 * 10**18;
    cofounditReward = 4000000 * 10**18;
    cofounditAddress = 0x988c3eA5554f3D2fB5ECB4dC5c35126eEf3B8a5D;
  }
}