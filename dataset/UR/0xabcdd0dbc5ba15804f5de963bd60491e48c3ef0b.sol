 

pragma solidity ^0.4.7;
contract Investment{
     
    address owner;
     
    address[] public investors;
     
    mapping(address => uint) public balances;
     
    uint public amountRaised;
     
    uint public investorIndex;
     
    uint[] public rates;
    uint[] public limits;
     
    bool public closed;
     
    event NewInvestment(address investor, uint amount);
     
    event Returned(uint amount);

    
    function Investment(){
        owner = msg.sender;
        limits= [0, 1000000000000000000000, 4000000000000000000000, 10000000000000000000000];
        rates= [15, 14, 13,12]; 
    }
    
     
     function invest() payable{
        if (closed) throw;
        if (msg.value < 1 ether) throw;
        if (balances[msg.sender]==0){ 
            investors.push(msg.sender);
        }
        balances[msg.sender] += calcReturnValue(msg.value, amountRaised); 
        amountRaised += msg.value;
        NewInvestment(msg.sender, msg.value);
     }
     
      
     function() payable{
         invest();
     }
     
      
     function calcReturnValue(uint value, uint amRa) internal returns (uint){
         if(amRa >= limits[limits.length-1]) return value/10*rates[limits.length-1];
         for(uint i = limits.length-2; i >= 0; i--){
             if(amRa>=limits[i]){
                uint newAmountRaised = amRa+value;
                if(newAmountRaised>limits[i+1]){
                    uint remainingVal=newAmountRaised-limits[i+1];
                    return (value-remainingVal)/10 * rates[i] + calcReturnValue(remainingVal, limits[i+1]);
                }  
                else
                    return value/10*rates[i];
             }
         }
     }
     
      
     function withdraw(){
         if(msg.sender==owner){
             msg.sender.send(this.balance);
         }
     }
     
      
     function returnInvestment() payable{
        returnInvestmentRecursive(msg.value);
        Returned(msg.value);
     }
     
      
     function returnInvestmentRecursive(uint value) internal{
        if (investorIndex>=investors.length || value==0) return;
        else if(value<=balances[investors[investorIndex]]){
            balances[investors[investorIndex]]-=value;
            if(!investors[investorIndex].send(value)) throw; 
        } 
        else if(balances[investors[investorIndex]]>0){
            uint val = balances[investors[investorIndex]];
            balances[investors[investorIndex]]=0;
            if(!investors[investorIndex].send(val)) throw;
            investorIndex++;
            returnInvestmentRecursive(value-val);
        } 
        else{
            investorIndex++;
            returnInvestmentRecursive(value);
        }
     }
     
     function getNumInvestors() constant returns(uint){
         return investors.length;
     }
     
      
     function close(){
         if(msg.sender==owner)
            closed=true;
     }
     
      
     function open(){
         if(msg.sender==owner)
            closed=false;
     }
}