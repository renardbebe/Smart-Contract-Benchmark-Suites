 

pragma solidity ^0.4.11;


 
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract BlockvPublicLedger is Ownable {

  struct logEntry{
        string txType;
        string txId;
        address to;
        uint256 amountContributed;
        uint8 discount;
        uint256 blockTimestamp;
  }
  struct distributionEntry{
        string txId;
        address to;
        uint256 amountContributed;    
        uint8 discount;
        uint256 tokenAmount;
  }
  struct index {
    uint256 index;
    bool set;
  }
  uint256 public txCount = 0;
  uint256 public distributionEntryCount = 0;
  mapping (string => index) distributionIndex;
  logEntry[] public transactionLog;
  distributionEntry[] public distributionList;
  bool public distributionFixed = false;


   
  function BlockvPublicLedger() {
  }

   
  function appendToDistributionList(string _tx_id, address _to, uint256 _amount, uint8 _discount)  onlyOwner returns (bool) {
        index memory idx = distributionIndex[_tx_id];
        bool ret;
        logEntry memory le;
        distributionEntry memory de;

        if(distributionFixed) {  
          revert();
        }

        if ( _discount > 100 ) {
          revert();
        }
         
        if ( !idx.set ) {
            ret = false;
            le.txType = "INSERT";
        } else {
            ret = true;
            le.txType = "UPDATE";          
        }
        le.to = _to;
        le.amountContributed = _amount;
        le.blockTimestamp = block.timestamp;
        le.txId = _tx_id;
        le.discount = _discount;
        transactionLog.push(le);
        txCount++;

         
        de.txId = _tx_id;
        de.to = _to;
        de.amountContributed = _amount;
        de.discount = _discount;
        de.tokenAmount = 0;
        if (!idx.set) {
          idx.index = distributionEntryCount;
          idx.set = true;
          distributionIndex[_tx_id] = idx;
          distributionList.push(de);
          distributionEntryCount++;
        } else {
          distributionList[idx.index] = de;
        }
        return ret;
  }


   
  function fixDistribution(uint8 _tokenPrice, uint256 _usdToEthConversionRate) onlyOwner {

    distributionEntry memory de;
    logEntry memory le;
    uint256 i = 0;

    if(distributionFixed) {  
      revert();
    }

    for(i = 0; i < distributionEntryCount; i++) {
      de = distributionList[i];
      de.tokenAmount = (de.amountContributed * _usdToEthConversionRate * 100) / (_tokenPrice  * de.discount / 100);
      distributionList[i] = de;
    }
    distributionFixed = true;
  
    le.txType = "FIXED";
    le.blockTimestamp = block.timestamp;
    le.txId = "__FIXED__DISTRIBUTION__";
    transactionLog.push(le);
    txCount++;

  }

}