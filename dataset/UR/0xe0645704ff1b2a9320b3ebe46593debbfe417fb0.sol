 

pragma solidity ^0.4.17;

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

contract ITestekToken {
  function mintTokens(address _to, uint256 _amount);
  function totalSupply() constant returns (uint256 totalSupply);
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

contract TestekCrowdsale is owned {
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public minEthToRaise;
    uint256 public maxEthToRaise;
    uint256 public totalEthRaised;
    address public multisigAddress;
    
    ITestekToken TestekTokenContract; 

    uint256 nextFreeParticipantIndex;
    mapping (uint => address) participantIndex;
    mapping (address => uint256) participantContribution;
    
    bool crowdsaleHasStarted;
    bool softCapReached;
    bool hardCapReached;
    bool crowdsaleHasSucessfulyEnded;
    uint256 blocksInADay;
    bool ownerHasClaimedTokens;
    
    uint256 lastEthReturnIndex;
    mapping (address => bool) hasClaimedEthWhenFail;
    
    event CrowdsaleStarted(uint256 _blockNumber);
    event CrowdsaleSoftCapReached(uint256 _blockNumber);
    event CrowdsaleHardCapReached(uint256 _blockNumber);
    event CrowdsaleEndedSuccessfuly(uint256 _blockNumber, uint256 _amountRaised);
    event Crowdsale(uint256 _blockNumber, uint256 _ammountRaised);
    event ErrorSendingETH(address _from, uint256 _amount);
    
    function TestekCrowdsale(uint256 _startBlock, address _multisigAddress){
        
        blocksInADay = 300;
        startBlock = _startBlock;
        endBlock = _startBlock + blocksInADay * 29;      
        minEthToRaise = 3 * 10**18;                     
        maxEthToRaise = 33 * 10**18;                 
        multisigAddress = _multisigAddress;
    }
    
   
      
   
    
    function () payable{
      if(msg.value == 0) throw;
      if (crowdsaleHasSucessfulyEnded || block.number > endBlock) throw;         
      if (!crowdsaleHasStarted){                                                 
        if (block.number >= startBlock){                                         
          crowdsaleHasStarted = true;                                            
          CrowdsaleStarted(block.number);                                        
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
        TestekTokenContract.mintTokens(msg.sender, getTestekTokenIssuance(block.number, msg.value));
        if (!softCapReached && totalEthRaised >= minEthToRaise){                 
          CrowdsaleSoftCapReached(block.number);                                 
          softCapReached = true;                                                 
        }     
      }else{                                                                     
        uint maxContribution = maxEthToRaise - totalEthRaised;                   
        participantContribution[msg.sender] += maxContribution;                  
        totalEthRaised += maxContribution;  
        TestekTokenContract.mintTokens(msg.sender, getTestekTokenIssuance(block.number, maxContribution));
        uint toReturn = msg.value - maxContribution;                             
        crowdsaleHasSucessfulyEnded = true;                                      
        CrowdsaleHardCapReached(block.number);
        hardCapReached = true;
        CrowdsaleEndedSuccessfuly(block.number, totalEthRaised);      
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
    
     
    function participantCount() constant returns(uint){
      return nextFreeParticipantIndex;
    }

       
    function claimTeamTokens(address _to) onlyOwner{     
      if (!crowdsaleHasSucessfulyEnded) throw; 
      if (ownerHasClaimedTokens) throw;
        
      TestekTokenContract.mintTokens(_to, TestekTokenContract.totalSupply() * 49/51);  
      ownerHasClaimedTokens = true;
    } 
      
       
    function setTokenContract(address _TestekTokenContractAddress) onlyOwner {     
      TestekTokenContract = ITestekToken(_TestekTokenContractAddress);   
    }   
       
    function getTestekTokenIssuance(uint256 _blockNumber, uint256 _ethSent) constant returns(uint){
      if (_blockNumber >= startBlock && _blockNumber < startBlock + blocksInADay * 2) return _ethSent * 3540;
      if (_blockNumber >= startBlock + blocksInADay * 2 && _blockNumber < startBlock + blocksInADay * 7) return _ethSent * 3289; 
      if (_blockNumber >= startBlock + blocksInADay * 7 && _blockNumber < startBlock + blocksInADay * 14) return _ethSent * 3184; 
      if (_blockNumber >= startBlock + blocksInADay * 14 && _blockNumber < startBlock + blocksInADay * 21) return _ethSent * 3097; 
      if (_blockNumber >= startBlock + blocksInADay * 21 ) return _ethSent * 3009;
    }
    
       
    function withdrawEther() onlyOwner{     
      if (this.balance == 0) throw;                                             
      if (totalEthRaised < minEthToRaise) throw;                                
          
      if(multisigAddress.send(this.balance)){}                                  
    }

    function endCrowdsale() onlyOwner{
      if (totalEthRaised < minEthToRaise) throw;
      if (block.number < endBlock) throw;
      crowdsaleHasSucessfulyEnded = true;
      CrowdsaleEndedSuccessfuly(block.number, totalEthRaised);
    }
    
    
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner{
    IERC20Token(_tokenAddress).transfer(_to, _amount);
    }
          
    
    function getTSTTokenAddress() constant returns(address _tokenAddress){    
      return address(TestekTokenContract);   
    }   
    
    function crowdsaleInProgress() constant returns (bool answer){    
      return crowdsaleHasStarted && !crowdsaleHasSucessfulyEnded;   
    }   
    
    function participantContributionInEth(address _querryAddress) constant returns (uint256 answer){    
      return participantContribution[_querryAddress];   
    }
    
       
    function withdrawRemainingBalanceForManualRecovery() onlyOwner{     
      if (this.balance == 0) throw;                                          
      if (block.number < endBlock) throw;                                    
      if (participantIndex[lastEthReturnIndex] != 0x0) throw;                
      if (multisigAddress.send(this.balance)){}                              
    }
}