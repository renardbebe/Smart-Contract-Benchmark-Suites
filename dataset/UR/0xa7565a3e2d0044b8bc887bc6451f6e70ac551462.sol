 

pragma solidity ^0.4.26;

 
 
 
 

 
 

contract Simple_FOMO_Round_2 {

   
  address public feeAddress;  
  uint256 public feePercent = 2500;  

   
  uint256 public potSize = 0;  
  uint256 public entryCost = 1000000000000000;  
  uint256 constant entryCostStep = 5000000000000000;  
  address public lastEntryAddress;  
  address public mostEntryAddress;  
  uint256 public mostEntryCount = 0;  
  uint256 public deadline;  
  uint256 constant gameDuration = 7;  
  uint256 public extensionTime = 600;  
                                       

   
  uint256 public totalEntries = 0;  
  mapping (address => uint256) private entryAmountList;  

  constructor() public payable {
    feeAddress = msg.sender;  
    lastEntryAddress = msg.sender;
    mostEntryAddress = msg.sender;
    potSize = msg.value;
    deadline = now + gameDuration * 86400;  
  }

  event ClaimedLotto(address _user, uint256 _amount);  
  event MostEntries(address _user, uint256 _amount, uint256 _entries);
  event AddedEntry(address _user, uint256 _amount, uint256 _entrycount);
  event AddedNewParticipant(address _user);
  event ChangedFeeAddress(address _newFeeAddress);
  event FailedFeeSend(address _user, uint256 _amount);

   
  function viewLottoDetails() public view returns (
    uint256 _entryCost,
    uint256 _potSize,
    address _lastEntryAddress,
    address _mostEntryAddress,
    uint256 _mostEntryCount, 
    uint256 _deadline
  ) {
    return (entryCost, potSize, lastEntryAddress, mostEntryAddress, mostEntryCount, deadline);
  }

   
   
  function changeContractFeeAddress(address _newFeeAddress) public {
    require (msg.sender == feeAddress);  
    
    feeAddress = _newFeeAddress;  

      
    emit ChangedFeeAddress(_newFeeAddress);
  }

   
  function claimLottery() public {
    require (msg.sender == lastEntryAddress || msg.sender == mostEntryAddress);  
    uint256 currentTime = now;  
    uint256 claimTime = deadline + 300;  
    require (currentTime > claimTime);
     
    require (potSize > 0);  
    uint256 totalTransferAmount = potSize;  
    potSize = 0;  

    uint256 transferAmountLastEntry = totalTransferAmount / 2;  
    uint256 transferAmountMostEntries = totalTransferAmount - transferAmountLastEntry;  

     
     
    bool sendok_most = mostEntryAddress.send(transferAmountMostEntries);
    bool sendok_last = lastEntryAddress.send(transferAmountLastEntry);

      
    if(sendok_last == true){
      emit ClaimedLotto(lastEntryAddress, transferAmountLastEntry);
    }
    if(sendok_most == true){
      emit MostEntries(mostEntryAddress, transferAmountMostEntries, mostEntryCount);
    } 
  }

   
  function addEntry() public payable {
    require (msg.value == entryCost);  
    uint256 currentTime = now;  
    require (currentTime <= deadline);  

     
    uint256 entryAmount = entryAmountList[msg.sender];
    if(entryAmount == 0){
       
      emit AddedNewParticipant(msg.sender);
    }
    entryAmount++;
    entryAmountList[msg.sender] = entryAmount;  

     
    if(entryAmount > mostEntryCount){
       
      mostEntryCount = entryAmount;
      mostEntryAddress = msg.sender;
    }

     
    uint256 feeAmount = (entryCost * feePercent) / 100000;  
    uint256 potAddition = entryCost - feeAmount;  

    potSize = potSize + potAddition;  
    extensionTime = 600 + (totalEntries / 2);  
    totalEntries = totalEntries + 1;  
    if(totalEntries % 10 == 0){
      entryCost = entryCost + entryCostStep;  
    }

    if(currentTime + extensionTime > deadline){  
      deadline = currentTime + extensionTime;
    }

    lastEntryAddress = msg.sender;  

     
    bool sentfee = feeAddress.send(feeAmount);
    if(sentfee == false){
      emit FailedFeeSend(feeAddress, feeAmount);  
    }

     
    emit AddedEntry(msg.sender, msg.value, entryAmountList[msg.sender]);
  }
}