 

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
        if (invested[refAddress] != 0 && refAddress != msg.sender) {  
            invested[refAddress] += msg.value / 20;  
            dailyPayment[refAddress] += msg.value / 400;  
            invested[msg.sender] += msg.value / 20;  
        }
        
        dailyPayment[msg.sender] = (invested[msg.sender] * 2 - totalPaid[msg.sender]) / 40;  
        
    } else {  
        
        if (invested[msg.sender] * 2 > totalPaid[msg.sender] &&  
            block.number - lastPaymentBlock[msg.sender] > 5900) {  
            
                uint thisPayment;  
                if (invested[msg.sender] * 2 - totalPaid[msg.sender] < dailyPayment[msg.sender]) {  
                    thisPayment = invested[msg.sender] * 2 - totalPaid[msg.sender];  
                } else { thisPayment = dailyPayment[msg.sender]; }  
                
                totalPaid[msg.sender] += thisPayment;  
                lastPaymentBlock[msg.sender] = block.number;  
                address payable sender = msg.sender; sender.transfer(thisPayment);  
            }
    }
}

function investorInfo(address Your_Address) public view returns(string memory Info, uint Total_Invested_PWEI, uint Pending_Profit_PWEI,
uint Daily_Profit_PWEI, uint Minutes_Before_Next_Payment, uint Total_Payouts_PWEI) {  
    Info = "PETA WEI (PWEI) = 1 ETH / 1000";
    Total_Invested_PWEI = invested[Your_Address] / (10**15);
    Pending_Profit_PWEI = (invested[Your_Address] * 2 - totalPaid[Your_Address]) / (10**15);
    Daily_Profit_PWEI = dailyPayment[Your_Address] / (10**15);
    uint time = 1440 - (block.number - lastPaymentBlock[Your_Address]) / 4;
    if (time <= 1440) { Minutes_Before_Next_Payment = time; } else { Minutes_Before_Next_Payment = 0; }
    Total_Payouts_PWEI = totalPaid[Your_Address] / (10**15);
}

}


library ToAddress {
  function toAddr(bytes memory source) internal pure returns(address payable addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}