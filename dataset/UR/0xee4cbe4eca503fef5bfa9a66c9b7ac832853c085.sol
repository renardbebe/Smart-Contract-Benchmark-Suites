 

pragma solidity ^0.4.21;
contract BLInterface {
    function setPrimaryAccount(address newMainAddress) public;
    function withdraw() public;
}
contract CSInterface {
    function goalReached() public;
    function goal() public returns (uint);
    function hasClosed() public returns(bool);
    function weiRaised() public returns (uint);
}
contract StorageInterface {
    function getUInt(bytes32 record) public constant returns (uint);
}
contract Interim {
     
    address public owner;  
    address public bubbled;  
    BLInterface internal BL;  
    CSInterface internal CS;  
    StorageInterface internal s;  
    uint public rate;  
    function Interim() public {
         
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyBubbled() {
        require(msg.sender == bubbled);
        _;
    }
    modifier onlyMembers() {
        require(msg.sender == owner || msg.sender == bubbled);
        _;
    }
     
    function setBLInterface(address newAddress) public onlyOwner {
        BL = BLInterface(newAddress);
    }
     
    function setStorageInterface(address newAddress) public onlyOwner {
        s = StorageInterface(newAddress);
    }
     
    function setCSInterface(address newAddress) public onlyOwner {
        CS = CSInterface(newAddress);
    }
     
    function setBubbled(address newAddress) public onlyMembers {
        bubbled = newAddress;
    }
     
    function setDS(address newAddress) public onlyOwner {
        owner = newAddress;
    }

    function setRate(uint _rate) public onlyOwner {
      rate = _rate;
    }

     
    function checkStatus () public returns(uint raisedBL, uint raisedCS, uint total, uint required, bool goalReached){
      raisedBL = s.getUInt(keccak256(address(this), "balance"));
      raisedCS = CS.weiRaised();
      total = raisedBL + raisedCS;
      required = CS.goal();
      goalReached = total >= required;
    }

    function completeContract (bool toSplit) public payable {
     
    bool goalReached;
    (,,,goalReached) = checkStatus();
    if (goalReached) require(toSplit == false);
      uint feeDue;
      if (toSplit == false) {
        feeDue = 20000 / rate * 1000000000000000000;  
        require(msg.value >= feeDue);
      }
      BL.withdraw();  
       if (goalReached) {  
         BL.setPrimaryAccount(bubbled);  
         owner.transfer(feeDue);
         bubbled.transfer(this.balance);
       } else {  
         if (toSplit) {  
           BL.setPrimaryAccount(owner);  
           uint balance = this.balance;
           bubbled.transfer(balance / 2);
           owner.transfer(balance / 2);
         } else {
            
           BL.setPrimaryAccount(bubbled);
           owner.transfer(feeDue);
           bubbled.transfer(this.balance);
         }
       }
    }
     
    function () public payable {
    }
}