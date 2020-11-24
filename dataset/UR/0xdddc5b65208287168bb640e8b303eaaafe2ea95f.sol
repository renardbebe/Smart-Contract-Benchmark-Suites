 

pragma solidity >=0.4.22 <0.6.0;
contract FiveForty {
    
 
 
 
 
 
 
 
 
 
 
 
 
 

using ToAddress for *;
mapping (address => uint256) invested;  
mapping (address => uint256) lastPaymentBlock;  
mapping (address => uint256) dailyPayment;  
mapping (address => uint256) totalPaid;  
address payable constant fundAddress = 0x27FE767C1da8a69731c64F15d6Ee98eE8af62E72;  

function () external payable {
    if (msg.value >= 1000) {  
        
        fundAddress.transfer(msg.value / 10);  
        if (invested[msg.sender] == 0) {lastPaymentBlock[msg.sender] = block.number;}  
        invested[msg.sender] += msg.value;  
        
        address refAddress = msg.data.toAddr();
        if (invested[refAddress] != 0 && refAddress != msg.sender) { invested[refAddress] += msg.value/20; }  
        invested[msg.sender] += msg.value/20;  
        
        dailyPayment[msg.sender] = (invested[msg.sender] * 2 - totalPaid[msg.sender]) / 40;  
        
    } else {  
        
        if (invested[msg.sender] * 2 > totalPaid[msg.sender] &&  
            block.number - lastPaymentBlock[msg.sender] > 5900) {  
                totalPaid[msg.sender] += dailyPayment[msg.sender];  
                address payable sender = msg.sender; sender.transfer(dailyPayment[msg.sender]);  
            }
    }
}
}

library ToAddress {
  function toAddr(bytes memory source) internal pure returns(address payable addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}