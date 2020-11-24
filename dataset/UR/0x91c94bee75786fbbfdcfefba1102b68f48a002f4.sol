 

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

contract ReentrancyHandlingContract{

    bool locked;

    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
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
contract IToken {
  function totalSupply() constant returns (uint256 totalSupply);
  function mintTokens(address _to, uint256 _amount) {}
}






contract Crowdsale is ReentrancyHandlingContract, Owned{

  struct ContributorData{
    uint contributionAmount;
    uint tokensIssued;
  }

  mapping(address => ContributorData) public contributorList;
  uint nextContributorIndex;
  mapping(uint => address) contributorIndexes;

  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, crowdsale, crowdsaleEnded }

  uint public crowdsaleStartBlock;
  uint public crowdsaleEndedBlock;

  event CrowdsaleStarted(uint blockNumber);
  event CrowdsaleEnded(uint blockNumber);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blockNumber);
  event MaxCapReached(uint blockNumber);

  address tokenAddress = 0x0;
  uint decimals = 18;

  uint ethToTokenConversion;

  uint public minCap;
  uint public maxCap;
  uint public ethRaised;
  uint public tokenTotalSupply = 200000000 * 10**decimals;

  address public multisigAddress;
  uint blocksInADay;

  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

  uint crowdsaleTokenCap =          120000000 * 10**decimals;
  uint foundersAndTeamTokens =       32000000 * 10**decimals;
  uint advisorAndAmbassadorTokens =  16000000 * 10**decimals;
  uint investorTokens =               8000000 * 10**decimals;
  uint viberateContributorTokens =   10000000 * 10**decimals;
  uint futurePartnerTokens =         14000000 * 10**decimals;
  bool foundersAndTeamTokensClaimed = false;
  bool advisorAndAmbassadorTokensClaimed = false;
  bool investorTokensClaimed = false;
  bool viberateContributorTokensClaimed = false;
  bool futurePartnerTokensClaimed = false;

   
   
   
  function() noReentrancy payable{
    require(msg.value != 0);                         
    require(crowdsaleState != state.crowdsaleEnded); 

    bool stateChanged = checkCrowdsaleState();       

    if(crowdsaleState == state.crowdsale){
      processTransaction(msg.sender, msg.value);     
    }
    else{
      refundTransaction(stateChanged);               
    }
  }

   
   
   
  function checkCrowdsaleState() internal returns (bool){
    if (ethRaised == maxCap && crowdsaleState != state.crowdsaleEnded){                          
      crowdsaleState = state.crowdsaleEnded;
      CrowdsaleEnded(block.number);                                                              
      return true;
    }

    if(block.number > crowdsaleStartBlock && block.number <= crowdsaleEndedBlock){         
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

   
   
   
  function calculateEthToVibe(uint _eth, uint _blockNumber) constant returns(uint) {
    if (_blockNumber < crowdsaleStartBlock) return _eth * 3158;
    if (_blockNumber >= crowdsaleStartBlock && _blockNumber < crowdsaleStartBlock + blocksInADay * 2) return _eth * 3158;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 2 && _blockNumber < crowdsaleStartBlock + blocksInADay * 7) return _eth * 3074;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 7 && _blockNumber < crowdsaleStartBlock + blocksInADay * 14) return _eth * 2989;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 14 && _blockNumber < crowdsaleStartBlock + blocksInADay * 21) return _eth * 2905;
    if (_blockNumber >= crowdsaleStartBlock + blocksInADay * 21 ) return _eth * 2820;
  }

   
   
   
  function processTransaction(address _contributor, uint _amount) internal{
    uint contributionAmount = _amount;
    uint returnAmount = 0;

    if (_amount > (maxCap - ethRaised)){                                            
      contributionAmount = maxCap - ethRaised;                                      
      returnAmount = _amount - contributionAmount;                                  
    }

    if (ethRaised + contributionAmount > minCap && minCap > ethRaised){
      MinCapReached(block.number);
    }

    if (ethRaised + contributionAmount == maxCap && ethRaised < maxCap){
      MaxCapReached(block.number);
    }

    if (contributorList[_contributor].contributionAmount == 0){
        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex += 1;
    }

    contributorList[_contributor].contributionAmount += contributionAmount;
    contributorList[_contributor].tokensIssued += contributionAmount;
    ethRaised += contributionAmount;                                               

    uint tokenAmount = calculateEthToVibe(contributionAmount, block.number);       
    if (tokenAmount > 0){
      IToken(tokenAddress).mintTokens(_contributor, tokenAmount);                  
      contributorList[_contributor].tokensIssued += tokenAmount;                   
    }
    if (returnAmount != 0) _contributor.transfer(returnAmount);
  }

  function pushAngelInvestmentData(address _address, uint _ethContributed) onlyOwner{
      assert(ethRaised + _ethContributed <= maxCap);
      processTransaction(_address, _ethContributed);
  }
  function depositAngelInvestmentEth() payable onlyOwner {}
  

   
   
   
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
  }

   
   
   
  function withdrawEth() onlyOwner{
    require(this.balance != 0);
    require(ethRaised >= minCap);

    multisigAddress.transfer(this.balance);
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

  function claimTeamTokens(address _to, uint _choice) onlyOwner{
    require(crowdsaleState == state.crowdsaleEnded);
    require(ethRaised >= minCap);

    uint mintAmount;
    if(_choice == 1){
      assert(!advisorAndAmbassadorTokensClaimed);
      mintAmount = advisorAndAmbassadorTokens;
      advisorAndAmbassadorTokensClaimed = true;
    }else if(_choice == 2){
      assert(!investorTokensClaimed);
      mintAmount = investorTokens;
      investorTokensClaimed = true;
    }else if(_choice == 3){
      assert(!viberateContributorTokensClaimed);
      mintAmount = viberateContributorTokens;
      viberateContributorTokensClaimed = true;
    }else if(_choice == 4){
      assert(!futurePartnerTokensClaimed);
      mintAmount = futurePartnerTokens;
      futurePartnerTokensClaimed = true;
    }else if(_choice == 5){
      assert(!foundersAndTeamTokensClaimed);
      assert(advisorAndAmbassadorTokensClaimed);
      assert(investorTokensClaimed);
      assert(viberateContributorTokensClaimed);
      assert(futurePartnerTokensClaimed);
      assert(tokenTotalSupply > IERC20Token(tokenAddress).totalSupply());
      mintAmount = tokenTotalSupply - IERC20Token(tokenAddress).totalSupply();
      foundersAndTeamTokensClaimed = true;
    }
    else{
      revert();
    }
    IToken(tokenAddress).mintTokens(_to, mintAmount);
  }


   
   
   
  function setMultisigAddress(address _newAddress) onlyOwner{
    multisigAddress = _newAddress;
  }

   
   
   
  function setToken(address _newAddress) onlyOwner{
    tokenAddress = _newAddress;
  }

  function getTokenAddress() constant returns(address){
    return tokenAddress;
  }

  function investorCount() constant returns(uint){
    return nextContributorIndex;
  }
}









contract ViberateCrowdsale is Crowdsale {
  function ViberateCrowdsale(){

    crowdsaleStartBlock = 4240935;
    crowdsaleEndedBlock = 4348935;

    minCap = 3546099290780000000000;
    maxCap = 37993920972640000000000;

    blocksInADay = 3600;

  }
}