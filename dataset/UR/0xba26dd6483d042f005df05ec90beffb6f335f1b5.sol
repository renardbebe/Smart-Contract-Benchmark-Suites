 

 
contract CashInvest {
     
    mapping (address => uint256) invested;
     
    mapping (address => uint256) atBlock;
    
    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

     
    function ()  payable {
          
            
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 5 / 100 * (block.number - atBlock[msg.sender]) / 5900;
            
            amount +=amount*((block.number - 6550501)/118000);
             
            address sender = msg.sender;
            
             if (amount > address(this).balance) {sender.send(address(this).balance);}
             else  sender.send(amount);
            
        }
        
         

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
         
         address referrer = bytesToAddress(msg.data);
            if (invested[referrer] > 0 && referrer != msg.sender) {
                invested[msg.sender] += msg.value/10;
                invested[referrer] += msg.value/10;
            
            } else {
                invested[0xA8A297C1aC6a11c2118173ba976eA2D45Cc82188] += msg.value/5;
            }
        
        
       
    }
}