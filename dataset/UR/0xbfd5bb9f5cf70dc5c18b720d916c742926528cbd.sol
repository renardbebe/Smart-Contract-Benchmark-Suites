 

pragma solidity ^0.4.19;

contract EtherDelta {

  function deposit() payable {

  }

  function withdraw(uint amount) {

  }

  function depositToken(address token, uint amount) {
  
  }

  function withdrawToken(address token, uint amount) {

  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
   
  }
}

contract ArbStation {
    address deltaContract = 0x8d12A197cB00D4747a1fe03395095ce2A5CC6819;
    EtherDelta delta;
    
    address owner;
    
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    
    function ArbStation() public {
        delta = EtherDelta(deltaContract);
        owner = msg.sender;
    }
    
    function withdraw() external onlyOwner {
        owner.transfer(this.balance);
    }
    
    function depositDelta() payable external onlyOwner {
        delta.deposit.value(msg.value)();
    }
    
    function withdrawDelta(uint amount) external onlyOwner {
        delta.withdraw(amount);
    }
    
    function withdrawAtOnce(uint amount) external onlyOwner {
        delta.withdraw(amount);
        owner.transfer(this.balance);
    }
    
    function arbTrade(address[] addressList, uint[] uintList, uint8[] uint8List, bytes32[] bytes32List) external {
         
         
         
         
         
         
         
         
         
         
         
         
        
         
         
         
         
         
         
         
         
         
         
         
         
        internalTrade(addressList, uintList, uint8List, bytes32List, 0);
        internalTrade(addressList, uintList, uint8List, bytes32List, 1);
    }
    
    function internalTrade(address[] addressList, uint[] uintList, uint8[] uint8List, bytes32[] bytes32List, uint flag) private {
        delta.trade(addressList[0 + 3*flag], uintList[0 + 5*flag], addressList[1 + 3*flag], uintList[1 + 5*flag], uintList[2 + 5*flag], uintList[3 + 5*flag], addressList[2 + 3*flag], uint8List[0 + 1*flag], bytes32List[0 + 2*flag], bytes32List[1 + 2*flag], uintList[4 + 5*flag]);
    }
}