 

pragma solidity ^0.4.6;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract TheGreatEtherRace {

   mapping(uint256 => address) public racers;  
   mapping(address => uint256) public racer_index;  
   
   mapping(address => uint256) public distance_driven;  
   
   string public sponsor;
   
   uint256 public total_racers;       
   uint256 public registered_racers;  
   uint256 public registration_fee;   
   uint256 public additional_price_money;
   uint256 public race_start_block;   
   
   address public winner;
   
   address developer_address;  
   address creator;

   enum EvtStatus { SignUp, ReadyToStart, Started, Finished }
   EvtStatus public eventStatus;
   
   function getStatus() constant returns (string) {
       if (eventStatus == EvtStatus.SignUp) return "SignUp";
       if (eventStatus == EvtStatus.ReadyToStart) return "ReadyToStart";
       if (eventStatus == EvtStatus.Started) return "Started";
       if (eventStatus == EvtStatus.Finished) return "Finished";
   }
   
   function additional_incentive() public payable {  
       additional_price_money += msg.value;
   }
   
   function TheGreatEtherRace(string p_sponsor){  
       sponsor = p_sponsor;
       total_racers = 20;
       registered_racers = 0;
       registration_fee = 50 ether;
       eventStatus = EvtStatus.SignUp;
       developer_address = 0x6d5719Ff464c6624C30225931393F842E3A4A41a;
       creator = msg.sender;
   }
   
    
   
   function() payable {  
        uint store;
        if ( msg.value < registration_fee ) throw;     
        if ( racer_index[msg.sender] > 0  ) throw;     
        if ( eventStatus != EvtStatus.SignUp ) throw;  
        
        registered_racers++;
        racer_index[msg.sender] = registered_racers;   
        racers[registered_racers] = msg.sender;        
        if ( registered_racers >= total_racers){       
            eventStatus = EvtStatus.ReadyToStart;      
            race_start_block = block.number + 42;   
        }
   }
   
    
   
   function start_the_race() public {
       if ( eventStatus != EvtStatus.ReadyToStart ) throw;  
       if (block.number < race_start_block) throw;             
       eventStatus = EvtStatus.Started;
   }
   
    
   function drive() public {
       if ( eventStatus != EvtStatus.Started ) throw;
       
       if ( block.number > race_start_block + 126 ){ 
           
           eventStatus = EvtStatus.Finished;
           
            
           winner = racers[1];
           for (uint256 idx = 2; idx <= registered_racers; idx++){
               if ( distance_driven[racers[idx]] > distance_driven[winner]  )  
                    winner = racers[idx];
           }
           return;
       }
       distance_driven[msg.sender]++;  
   }
   
    
   
   function claim_price_money() public {
       
       if  (eventStatus == EvtStatus.Finished){
                uint winning_amount = this.balance - 5 ether;   
                if (!winner.send(winning_amount)) throw;        
                if (!developer_address.send(5 ether)) throw;    
       }
       
   }

   
    
   function cleanup() public {
       if (msg.sender != creator) throw;
       if (
             registered_racers == 0 ||     
             eventStatus == EvtStatus.Finished && block.number > race_start_block + 18514  
          ){
           selfdestruct(creator);
       } 
       else throw;
   }
    
}