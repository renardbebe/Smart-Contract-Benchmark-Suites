 

contract SafeMath {
    
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
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
contract Lockable is Owned {

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


    function lockUntil(uint256 _untilBlock, string _reason) onlyOwner public {
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
contract tokenRecipientInterface {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}
contract ERC20TokenInterface {
  function totalSupply() public constant returns (uint256 _totalSupply);
  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract SportifyTokenInterface {
    function mint(address _to, uint256 _amount) public;
}

contract Crowdsale is ReentrancyHandlingContract, Owned {

  struct ContributorData {
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

  uint crowdsaleTokenCap =          134000000 * 10**decimals;
  uint foundersAndTeamTokens =       36000000 * 10**decimals;
  uint advisorAndAmbassadorTokens =  20000000 * 10**decimals;
  uint futurePromoEventTokens =      10000000 * 10**decimals;
  bool foundersAndTeamTokensClaimed = false;
  bool advisorAndAmbassadorTokensClaimed = false;
  bool futurePromoEventTokensClaimed = false;

   
   
   
  function() noReentrancy payable public {
    require(msg.value != 0);                         
    require(crowdsaleState != state.crowdsaleEnded); 

    bool stateChanged = checkCrowdsaleState();       

    if (crowdsaleState == state.crowdsale) {
      processTransaction(msg.sender, msg.value);     
    } else {
      refundTransaction(stateChanged);               
    }
  }

   
   
   
  function checkCrowdsaleState() internal returns (bool) {
    if (ethRaised == maxCap && crowdsaleState != state.crowdsaleEnded) {                         
      crowdsaleState = state.crowdsaleEnded;
      CrowdsaleEnded(block.number);                                                              
      return true;
    }

    if (block.number > crowdsaleStartBlock && block.number <= crowdsaleEndedBlock) {             
      if (crowdsaleState != state.crowdsale) {                                                   
        crowdsaleState = state.crowdsale;                                                        
        CrowdsaleStarted(block.number);                                                          
        return true;
      }
    } else {
      if (crowdsaleState != state.crowdsaleEnded && block.number > crowdsaleEndedBlock) {        
        crowdsaleState = state.crowdsaleEnded;                                                   
        CrowdsaleEnded(block.number);                                                            
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

  function calculateEthToToken(uint _eth, uint _blockNumber) constant public returns(uint) {
    if (_blockNumber < crowdsaleStartBlock + blocksInADay * 3) {
      return _eth * 3298;
    }
    if (_eth >= 100*10**decimals) {
      return _eth * 3298;
    }
    if (_blockNumber > crowdsaleStartBlock) {
      return _eth * 2998;
    }
  }

   
   
   
  function processTransaction(address _contributor, uint _amount) internal{
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

    if (contributorList[_contributor].contributionAmount == 0) {
        contributorIndexes[nextContributorIndex] = _contributor;
        nextContributorIndex += 1;
    }

    contributorList[_contributor].contributionAmount += contributionAmount;
    ethRaised += contributionAmount;                                               

    uint tokenAmount = calculateEthToToken(contributionAmount, block.number);      
    if (tokenAmount > 0) {
      SportifyTokenInterface(tokenAddress).mint(_contributor, tokenAmount);        
      contributorList[_contributor].tokensIssued += tokenAmount;                   
    }
    if (returnAmount != 0) {
      _contributor.transfer(returnAmount);
    } 
  }

  function pushAngelInvestmentData(address _address, uint _ethContributed) onlyOwner public {
      assert(ethRaised + _ethContributed <= maxCap);
      processTransaction(_address, _ethContributed);
  }
  function depositAngelInvestmentEth() payable onlyOwner public {}
  

   
   
   
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
    ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
  }

   
   
   
  function withdrawEth() onlyOwner public {
    require(this.balance != 0);
    require(ethRaised >= minCap);

    multisigAddress.transfer(this.balance);
  }

   
   
   
  function claimEthIfFailed() public {
    require(block.number > crowdsaleEndedBlock && ethRaised < minCap);     
    require(contributorList[msg.sender].contributionAmount > 0);           
    require(!hasClaimedEthWhenFail[msg.sender]);                           

    uint ethContributed = contributorList[msg.sender].contributionAmount;  
    hasClaimedEthWhenFail[msg.sender] = true;                              
    if (!msg.sender.send(ethContributed)) {                                 
      ErrorSendingETH(msg.sender, ethContributed);                         
    }
  }

   
   
   
  function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner public {
    require(block.number > crowdsaleEndedBlock && ethRaised < minCap);                 
    address currentParticipantAddress;
    uint contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
      currentParticipantAddress = contributorIndexes[nextContributorToClaim];          
      if (currentParticipantAddress == 0x0) {
        return;                                                                        
      }
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                         
        contribution = contributorList[currentParticipantAddress].contributionAmount;  
        hasClaimedEthWhenFail[currentParticipantAddress] = true;                       
        if (!currentParticipantAddress.send(contribution)) {                           
          ErrorSendingETH(currentParticipantAddress, contribution);                    
        }
      }
      nextContributorToClaim += 1;                                                     
    }
  }

   
   
   
  function withdrawRemainingBalanceForManualRecovery() onlyOwner public {
    require(this.balance != 0);                                   
    require(block.number > crowdsaleEndedBlock);                  
    require(contributorIndexes[nextContributorToClaim] == 0x0);   
    multisigAddress.transfer(this.balance);                       
  }

  function claimTeamTokens(address _to, uint _choice) onlyOwner public {
    require(crowdsaleState == state.crowdsaleEnded);
    require(ethRaised >= minCap);

    uint mintAmount;
    if (_choice == 1) {
      assert(!advisorAndAmbassadorTokensClaimed);
      mintAmount = advisorAndAmbassadorTokens;
      advisorAndAmbassadorTokensClaimed = true;
    } else if (_choice == 2) {
      assert(!futurePromoEventTokensClaimed);
      mintAmount = futurePromoEventTokens;
      futurePromoEventTokensClaimed = true;
    } else if (_choice == 3) {
      assert(!foundersAndTeamTokensClaimed);
      assert(advisorAndAmbassadorTokensClaimed);
      assert(futurePromoEventTokensClaimed);
      assert(tokenTotalSupply > ERC20TokenInterface(tokenAddress).totalSupply());
      mintAmount = tokenTotalSupply - ERC20TokenInterface(tokenAddress).totalSupply();
      foundersAndTeamTokensClaimed = true;
    } else {
      revert();
    }
    SportifyTokenInterface(tokenAddress).mint(_to, mintAmount);
  }


   
   
   
  function setMultisigAddress(address _newAddress) onlyOwner public {
    multisigAddress = _newAddress;
  }

   
   
   
  function setToken(address _newAddress) onlyOwner public {
    tokenAddress = _newAddress;
  }

  function getTokenAddress() constant public returns(address) {
    return tokenAddress;
  }

  function investorCount() constant public returns(uint) {
    return nextContributorIndex;
  }
}

contract SportifyCrowdsale is Crowdsale {
  
  function SportifyCrowdsale() { 

    crowdsaleStartBlock = 4595138;
    crowdsaleEndedBlock = 4708120;

    minCap = 4190000000000000000000;
    maxCap = 40629000000000000000000;

    blocksInADay = 6646;
  }
}