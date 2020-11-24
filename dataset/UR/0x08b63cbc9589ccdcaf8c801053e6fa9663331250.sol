 

 

pragma solidity ^0.4.13;

contract ReentrancyHandlingContract {

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

    function Owned() public {
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
contract PriorityPassInterface {
    function getAccountLimit(address _accountAddress) public constant returns (uint);
    function getAccountActivity(address _accountAddress) public constant returns (bool);
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

contract SeedCrowdsaleContract is ReentrancyHandlingContract, Owned {

  struct ContributorData {
    uint contributionAmount;
  }

  mapping(address => ContributorData) public contributorList;
  uint public nextContributorIndex;
  mapping(uint => address) public contributorIndexes;

  state public crowdsaleState = state.pendingStart;
  enum state { pendingStart, priorityPass, openedPriorityPass, crowdsaleEnded }

  uint public presaleStartTime;
  uint public presaleUnlimitedStartTime;
  uint public crowdsaleEndedTime;

  event PresaleStarted(uint blocktime);
  event PresaleUnlimitedStarted(uint blocktime);
  event CrowdsaleEnded(uint blocktime);
  event ErrorSendingETH(address to, uint amount);
  event MinCapReached(uint blocktime);
  event MaxCapReached(uint blocktime);
  event ContributionMade(address indexed contributor, uint amount);

  PriorityPassInterface priorityPassContract = PriorityPassInterface(0x0);

  uint public minCap;
  uint public maxP1Cap;
  uint public maxCap;
  uint public ethRaised;

  address public multisigAddress;

  uint nextContributorToClaim;
  mapping(address => bool) hasClaimedEthWhenFail;

   
   
   
   
  function() noReentrancy payable public {
    require(msg.value != 0);                                                     
    require(crowdsaleState != state.crowdsaleEnded);                             

    bool stateChanged = checkCrowdsaleState();                                   

    if (crowdsaleState == state.priorityPass) {
      if (priorityPassContract.getAccountActivity(msg.sender)) {                 
        processTransaction(msg.sender, msg.value);                               
      } else {
        refundTransaction(stateChanged);                                         
      }
    } else if (crowdsaleState == state.openedPriorityPass) {
      if (priorityPassContract.getAccountActivity(msg.sender)) {                 
        processTransaction(msg.sender, msg.value);                               
      } else {
        refundTransaction(stateChanged);                                         
      }
    } else {
      refundTransaction(stateChanged);                                           
    }
  }

   
   
   
   
  function checkCrowdsaleState() internal returns (bool) {
    if (ethRaised == maxCap && crowdsaleState != state.crowdsaleEnded) {         
      crowdsaleState = state.crowdsaleEnded;
      MaxCapReached(block.timestamp);                                            
      CrowdsaleEnded(block.timestamp);                                           
      return true;
    }

    if (block.timestamp > presaleStartTime && block.timestamp <= presaleUnlimitedStartTime) {  
      if (crowdsaleState != state.priorityPass) {                                
        crowdsaleState = state.priorityPass;                                     
        PresaleStarted(block.timestamp);                                         
        return true;
      }
    } else if (block.timestamp > presaleUnlimitedStartTime && block.timestamp <= crowdsaleEndedTime) {   
      if (crowdsaleState != state.openedPriorityPass) {                          
        crowdsaleState = state.openedPriorityPass;                               
        PresaleUnlimitedStarted(block.timestamp);                                
        return true;
      }
    } else {
      if (crowdsaleState != state.crowdsaleEnded && block.timestamp > crowdsaleEndedTime) { 
        crowdsaleState = state.crowdsaleEnded;                                   
        CrowdsaleEnded(block.timestamp);                                         
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

   
   
   
   
  function calculateMaxContribution(address _contributor) constant public returns (uint maxContribution) {
    uint maxContrib;

    if (crowdsaleState == state.priorityPass) {                                  
      maxContrib = priorityPassContract.getAccountLimit(_contributor) - contributorList[_contributor].contributionAmount;

	    if (maxContrib > (maxP1Cap - ethRaised)) {                                 
        maxContrib = maxP1Cap - ethRaised;                                       
      }

    } else {
      maxContrib = maxCap - ethRaised;                                           
    }
    return maxContrib;
  }

   
   
   
   
   
   
  function processTransaction(address _contributor, uint _amount) internal {
    uint maxContribution = calculateMaxContribution(_contributor);               
    uint contributionAmount = _amount;
    uint returnAmount = 0;

	  if (maxContribution < _amount) {                                             
      contributionAmount = maxContribution;                                      
      returnAmount = _amount - maxContribution;                                  
    }

    if (ethRaised + contributionAmount >= minCap && minCap > ethRaised) {
      MinCapReached(block.timestamp);
    } 

    if (contributorList[_contributor].contributionAmount == 0) {                 
      contributorList[_contributor].contributionAmount = contributionAmount;     
      contributorIndexes[nextContributorIndex] = _contributor;                   
      nextContributorIndex++;
    } else {
      contributorList[_contributor].contributionAmount += contributionAmount;    
    }
    ethRaised += contributionAmount;                                             

    ContributionMade(msg.sender, contributionAmount);                            

	  if (returnAmount != 0) {
      _contributor.transfer(returnAmount);                                       
    } 
  }

   
   
   
   
   
   
   
  function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
    ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
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

   
   
   
   
   
  function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner public {
    require(block.timestamp > crowdsaleEndedTime && ethRaised < minCap);         

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
    require(block.timestamp > crowdsaleEndedTime);                               
    require(contributorIndexes[nextContributorToClaim] == 0x0);                  
    multisigAddress.transfer(this.balance);                                      
  }

   
   
   
   
   
  function setMultisigAddress(address _newAddress) onlyOwner public {
    multisigAddress = _newAddress;
  }

   
   
   
   
   
  function setPriorityPassContract(address _newAddress) onlyOwner public {
    priorityPassContract = PriorityPassInterface(_newAddress);
  }

   
   
   
   
  function priorityPassContractAddress() constant public returns (address) {
    return address(priorityPassContract);
  }

   
   
   
   
   
   
   
  function setCrowdsaleTimes(uint _presaleStartTime, uint _presaleUnlimitedStartTime, uint _crowdsaleEndedTime) onlyOwner public {
    require(crowdsaleState == state.pendingStart);                               
    require(_presaleStartTime != 0);                                             
    require(_presaleStartTime < _presaleUnlimitedStartTime);                     
    require(_presaleUnlimitedStartTime != 0);                                    
    require(_presaleUnlimitedStartTime < _crowdsaleEndedTime);                   
    require(_crowdsaleEndedTime != 0);                                           
    presaleStartTime = _presaleStartTime;
    presaleUnlimitedStartTime = _presaleUnlimitedStartTime;
    crowdsaleEndedTime = _crowdsaleEndedTime;
  }
}

contract DataFundSeedCrowdsale is SeedCrowdsaleContract {
  
  function DataFundSeedCrowdsale() {

    presaleStartTime = 1512032400;
    presaleUnlimitedStartTime = 1512063000;
    crowdsaleEndedTime = 1512140400;

    minCap = 356 ether;
    maxP1Cap = 534 ether;
    maxCap = 594 ether;
  }
}