 

 
pragma solidity ^0.4.24;
contract RESERVED {
   
    address owner;  
    address investor;  
    mapping (address => uint256) balances;  
    mapping (address => uint256) timestamp;  
    mapping (address => uint16) rate;  
    mapping (address => uint256) referrers;  
    uint16 default_rate = 300;  
    uint16 max_rate = 1000;  
    uint256 eth = 1000000000000000000;  
    uint256 jackpot = 0;  
    uint256 random_number;  
    uint256 referrer_bonus;  
    uint256 deposit;  
    uint256 day = 86400;  
    bytes msg_data;  
    
     
    constructor() public { owner = msg.sender;}
    
     
    function() external payable{
        
        deposit = msg.value;  
        
        investor = msg.sender;  
        
        msg_data = bytes(msg.data);  
        
        owner.transfer(deposit / 10);  
        
        tryToWin();  
        
        sendPayment();  
        
        updateRate();  
        
        upgradeReferrer();  
        
        
    }
    
     
    function tryToWin() internal{
        random_number = uint(blockhash(block.number-1))%100 + 1;
        if (deposit >= (eth / 10) && random_number<(deposit/(eth / 10) + 1) && jackpot>0) {
            investor.transfer(jackpot);
            jackpot = deposit / 20;
        }
        else jackpot += deposit / 20;
    }
    
     
    function sendPayment() internal{
        if (balances[investor] != 0){
            uint256 paymentAmount = balances[investor]*rate[investor]/10000*(now-timestamp[investor])/day;
            investor.transfer(paymentAmount);
        }
        timestamp[investor] = now;
        balances[investor] += deposit;
    }
    
     
    function updateRate() internal{
        require (balances[investor]>0);
        if (balances[investor]>=(10*eth) && rate[investor]<default_rate+75){
                    rate[investor]=default_rate+75;
                }
                else if (balances[investor]>=(5*eth) && rate[investor]<default_rate+50){
                        rate[investor]=default_rate+50;
                    }
                    else if (balances[investor]>=eth && rate[investor]<default_rate+25){
                            rate[investor]=default_rate+25;
                        }
                        else if (rate[investor]<default_rate){
                                rate[investor]=default_rate;
                            }
    }
    
     
    function upgradeReferrer() internal{
        if(msg_data.length == 20 && referrers[investor] == 0) {
            address referrer = bytesToAddress(msg_data);
            if(referrer != investor && balances[referrer]>0){
                referrers[investor] = 1;
                rate[investor] += 50; 
                referrer_bonus = deposit * rate[referrer] / 10000;
                referrer.transfer(referrer_bonus); 
                if(rate[referrer]<max_rate){
                    if (deposit >= 10*eth){
                        rate[referrer] = rate[referrer] + 100;
                    }
                    else if (deposit >= 3*eth){
                            rate[referrer] = rate[referrer] + 50;
                        }
                        else if (deposit >= eth / 2){
                                rate[referrer] = rate[referrer] + 25;
                            }
                            else if (deposit >= eth / 10){
                                    rate[referrer] = rate[referrer] + 10;
                                }
                }
            }
        }    
        referrers[investor] = 1;  
    }
    
     
    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }
    
}