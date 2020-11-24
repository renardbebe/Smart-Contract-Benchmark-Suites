 

contract owned {

  address public owner;

  function owned() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    if (msg.sender != owner) throw;
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    owner = newOwner;
  }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract ISncToken {
  function mintTokens(address _to, uint256 _amount);
  function totalSupply() constant returns (uint256 totalSupply);
}

contract SunContractIco is owned{

  uint256 public startBlock;
  uint256 public endBlock;
  uint256 public minEthToRaise;
  uint256 public maxEthToRaise;
  uint256 public totalEthRaised;
  address public multisigAddress;


  ISncToken sncTokenContract; 
  mapping (address => bool) presaleContributorAllowance;
  uint256 nextFreeParticipantIndex;
  mapping (uint => address) participantIndex;
  mapping (address => uint256) participantContribution;

  bool icoHasStarted;
  bool minTresholdReached;
  bool icoHasSucessfulyEnded;
  uint256 blocksInWeek;
    bool ownerHasClaimedTokens;

  uint256 lastEthReturnIndex;
  mapping (address => bool) hasClaimedEthWhenFail;

  event ICOStarted(uint256 _blockNumber);
  event ICOMinTresholdReached(uint256 _blockNumber);
  event ICOEndedSuccessfuly(uint256 _blockNumber, uint256 _amountRaised);
  event ICOFailed(uint256 _blockNumber, uint256 _ammountRaised);
  event ErrorSendingETH(address _from, uint256 _amount);

  function SunContractIco(uint256 _startBlock, address _multisigAddress) {
    blocksInWeek = 4 * 60 * 24 * 7;
    startBlock = _startBlock;
    endBlock = _startBlock + blocksInWeek * 4;
    minEthToRaise = 5000 * 10**18;
    maxEthToRaise = 100000 * 10**18;
    multisigAddress = _multisigAddress;
  }

   
      
   

     
  function () payable {
    if (msg.value == 0) throw;                                           
    if (icoHasSucessfulyEnded || block.number > endBlock) throw;         
    if (!icoHasStarted){                                                 
      if (block.number >= startBlock){                                   
        icoHasStarted = true;                                            
        ICOStarted(block.number);                                        
      } else{
        throw;
      }
    }     
    if (participantContribution[msg.sender] == 0){                      
      participantIndex[nextFreeParticipantIndex] = msg.sender;          
      nextFreeParticipantIndex += 1;
    }     
    if (maxEthToRaise > (totalEthRaised + msg.value)){                  
      participantContribution[msg.sender] += msg.value;                 
      totalEthRaised += msg.value; 
      sncTokenContract.mintTokens(msg.sender, getSncTokenIssuance(block.number, msg.value));
      if (!minTresholdReached && totalEthRaised >= minEthToRaise){       
        ICOMinTresholdReached(block.number);                             
        minTresholdReached = true;                                       
      }     
    }else{                                                               
      uint maxContribution = maxEthToRaise - totalEthRaised;             
      participantContribution[msg.sender] += maxContribution;            
      totalEthRaised += maxContribution;  
      sncTokenContract.mintTokens(msg.sender, getSncTokenIssuance(block.number, maxContribution));
      uint toReturn = msg.value - maxContribution;                        
      icoHasSucessfulyEnded = true;                                       
      ICOEndedSuccessfuly(block.number, totalEthRaised);      
      if(!msg.sender.send(toReturn)){                                     
        ErrorSendingETH(msg.sender, toReturn);                            
      }     
    }
  }   

      
  function claimEthIfFailed(){    
    if (block.number <= endBlock || totalEthRaised >= minEthToRaise) throw;  
    if (participantContribution[msg.sender] == 0) throw;                     
    if (hasClaimedEthWhenFail[msg.sender]) throw;                            
    uint256 ethContributed = participantContribution[msg.sender];            
    hasClaimedEthWhenFail[msg.sender] = true;     
    if (!msg.sender.send(ethContributed)){      
      ErrorSendingETH(msg.sender, ethContributed);                           
    }   
  }   

   
     
   

      
  function addPresaleContributors(address[] _presaleContributors) onlyOwner {     
    for (uint cnt = 0; cnt < _presaleContributors.length; cnt++){       
      presaleContributorAllowance[_presaleContributors[cnt]] = true;    
    }   
  }   

     
  function batchReturnEthIfFailed(uint256 _numberOfReturns) onlyOwner{    
    if (block.number < endBlock || totalEthRaised >= minEthToRaise) throw;     
    address currentParticipantAddress;    
    uint256 contribution;
    for (uint cnt = 0; cnt < _numberOfReturns; cnt++){      
      currentParticipantAddress = participantIndex[lastEthReturnIndex];        
      if (currentParticipantAddress == 0x0) return;                            
      if (!hasClaimedEthWhenFail[currentParticipantAddress]) {                 
        contribution = participantContribution[currentParticipantAddress];     
        hasClaimedEthWhenFail[msg.sender] = true;                              
        if (!currentParticipantAddress.send(contribution)){                    
          ErrorSendingETH(currentParticipantAddress, contribution);            
        }       
      }       
      lastEthReturnIndex += 1;    
    }   
  }   

   
  function changeMultisigAddress(address _newAddress) onlyOwner {     
    multisigAddress = _newAddress;
  }   

     
  function claimCoreTeamsTokens(address _to) onlyOwner{     
    if (!icoHasSucessfulyEnded) throw; 
    if (ownerHasClaimedTokens) throw;
    
    sncTokenContract.mintTokens(_to, sncTokenContract.totalSupply() * 25 / 100);
    ownerHasClaimedTokens = true;
  }   

     
  function removePresaleContributor(address _presaleContributor) onlyOwner {    
    presaleContributorAllowance[_presaleContributor] = false;   
  }   

     
  function setTokenContract(address _sncTokenContractAddress) onlyOwner {     
    sncTokenContract = ISncToken(_sncTokenContractAddress);   
  }   

     
  function withdrawEth() onlyOwner{     
    if (this.balance == 0) throw;                                             
    if (totalEthRaised < minEthToRaise) throw;                                
      
    if(multisigAddress.send(this.balance)){}                                  
  }
  
  function endIco() onlyOwner {
      if (totalEthRaised < minEthToRaise) throw;
      if (block.number < endBlock) throw;
  
    icoHasSucessfulyEnded = true;
    ICOEndedSuccessfuly(block.number, totalEthRaised);
  }

     
  function withdrawRemainingBalanceForManualRecovery() onlyOwner{     
    if (this.balance == 0) throw;                                          
    if (block.number < endBlock) throw;                                    
    if (participantIndex[lastEthReturnIndex] != 0x0) throw;                
    if (multisigAddress.send(this.balance)){}                              
  }

   
      
   

  function getSncTokenAddress() constant returns(address _tokenAddress){    
    return address(sncTokenContract);   
  }   

  function icoInProgress() constant returns (bool answer){    
    return icoHasStarted && !icoHasSucessfulyEnded;   
  }   

  function isAddressAllowedInPresale(address _querryAddress) constant returns (bool answer){    
    return presaleContributorAllowance[_querryAddress];   
  }   

  function participantContributionInEth(address _querryAddress) constant returns (uint256 answer){    
    return participantContribution[_querryAddress];   
  }
  
  function getSncTokenIssuance(uint256 _blockNumber, uint256 _ethSent) constant returns(uint){
        if (_blockNumber >= startBlock && _blockNumber < blocksInWeek + startBlock) {
          if (presaleContributorAllowance[msg.sender]) return _ethSent * 11600;
          else return _ethSent * 11500;
        }
        if (_blockNumber >= blocksInWeek + startBlock && _blockNumber < blocksInWeek * 2 + startBlock) return _ethSent * 11000;
        if (_blockNumber >= blocksInWeek * 2 + startBlock && _blockNumber < blocksInWeek * 3 + startBlock) return _ethSent * 10500;
        if (_blockNumber >= blocksInWeek * 3 + startBlock && _blockNumber <= blocksInWeek * 4 + startBlock) return _ethSent * 10000;
    }

   
   
   
   
   
   
}