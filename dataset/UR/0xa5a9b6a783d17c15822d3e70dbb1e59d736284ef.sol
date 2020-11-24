 

pragma solidity ^0.4.26;

 
 
 
 

contract Simple_FOMO_Round_1 {

   
  address public feeAddress;  
  uint256 public feePercent = 2500;  

   
  uint256 public potSize = 0;  
  uint256 public entryCost = 1000000000000000;  
  uint256 constant entryCostStep = 2000000000000000;  
  address public lastEntryAddress;  
  uint256 public deadline;  
  uint256 constant gameDuration = 7;  
  uint256 public extensionTime = 600;  
                                       
  uint256 public totalEntries = 0;  

  constructor() public payable {
    feeAddress = msg.sender;  
    lastEntryAddress = msg.sender;
    potSize = msg.value;
    deadline = now + gameDuration * 86400;  
  }

  event ClaimedLotto(address _user, uint256 _amount);  
  event AddedEntry(address _user, uint256 _amount);
  event ChangedFeeAddress(address _newFeeAddress);

   
  function viewLottoDetails() public view returns (
    uint256 _entryCost,
    uint256 _potSize,
    address _lastEntryAddress,
    uint256 _deadline
  ) {
    return (entryCost, potSize, lastEntryAddress, deadline);
  }

   
   
  function changeContractFeeAddress(address _newFeeAddress) public {
    require (msg.sender == feeAddress);  
    
    feeAddress = _newFeeAddress;  

      
    emit ChangedFeeAddress(_newFeeAddress);
  }

   
  function claimLottery() public {
    require (msg.sender == lastEntryAddress);  
    uint256 currentTime = now;  
    uint256 claimTime = deadline + 300;  
    require (currentTime > claimTime);
     
    require (potSize > 0);  
    uint256 transferAmount = potSize;  
    potSize = 0;  
    lastEntryAddress.transfer(transferAmount);

      
    emit ClaimedLotto(lastEntryAddress, transferAmount);
  }

   
  function addEntry() public payable {
    require (msg.value == entryCost);  
    uint256 currentTime = now;  
    require (currentTime <= deadline);  

     
    uint256 feeAmount = (entryCost * feePercent) / 100000;  
    uint256 potAddition = entryCost - feeAmount;  

    potSize = potSize + potAddition;  
    extensionTime = 600 + (totalEntries / 2);  
    totalEntries = totalEntries + 1;  
    if(totalEntries % 25 == 0){
      entryCost = entryCost + entryCostStep;  
    }

    if(currentTime + extensionTime > deadline){  
      deadline = currentTime + extensionTime;
    }

    lastEntryAddress = msg.sender;  

     
    feeAddress.transfer(feeAmount);

     
    emit AddedEntry(msg.sender, msg.value);
  }
}