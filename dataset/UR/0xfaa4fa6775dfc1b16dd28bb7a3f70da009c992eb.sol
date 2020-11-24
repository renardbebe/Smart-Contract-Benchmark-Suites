 

pragma solidity ^0.4.18;

contract ownerOnly {
    
    function ownerOnly() public { owner = msg.sender; }
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract Game is ownerOnly {
    
     
    uint cow_code;
    
    struct cows {
        uint cow;
        bool place;
        uint date_buy;
        bool cow_live;
        uint milk;
        uint date_milk;
    } 
    
     
    mapping (address => uint) users_cows;
     
    mapping (bytes32 => cows) user;
     
    mapping (address => bool) telega;
     
    address multisig;
     
    address rico;
    
    
     
    uint volume_milk;
     
    uint time_to_milk;
     
    uint time_to_live;   
        
     
    uint milkcost;
    

     
    function Game() public {
        
         
    	multisig = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
         
    	rico = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
    	
    	 
    	cow_code = 0;
    	
         
        volume_milk = 20;
         
        time_to_milk = 60;
         
        time_to_live = 1800;  
        
         
        milkcost = 0.001083333333333 ether;
    }
    
    function pay(uint cor) public payable {
       
        if (cor==0) {
            payCow();    
        }
        else {
            payPlace(cor);
        }
    }        
    
     
    function payCow() private {
       
        uint time= now;
        uint cows_count = users_cows[msg.sender];
        
        uint index = msg.value/0.09 ether;
        
        for (uint i = 1; i <= index; i++) {
            
            cow_code++;
            cows_count++;
            user[keccak256(msg.sender) & keccak256(i)]=cows(cow_code,false,time,true,0,time);
        }
        users_cows[msg.sender] = cows_count;
    }    
    
     
    function payPlace(uint cor) private {

        uint index = msg.value/0.01 ether;
        user[keccak256(msg.sender) & keccak256(cor)].place=true;
        rico.transfer(msg.value);
    }        
    
    
    
     
    function MilkCow(address gamer) private {
       
        uint time= now;
        uint time_milk;
        
         
        uint cows_count = users_cows[gamer];
        
        for (uint i=1; i<=cows_count; i++) {
            
             
            cows tmp = user[keccak256(gamer) & keccak256(i)];
            
             
            if (tmp.cow_live==true && tmp.place) {
                
                 
                uint datedeadcow=tmp.date_buy+time_to_live;
               
                 
                if (time>=datedeadcow) {
                    
                     
                    time_milk=(time-tmp.date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                         
                        tmp.milk+=(volume_milk*time_milk);
                         
                        tmp.cow_live=false;
                         
                        tmp.date_milk+=time_milk*time_to_milk;
                    }
                    
                } else {
                    
                    time_milk=(time-tmp.date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                        tmp.milk+=volume_milk*time_milk;
                        tmp.date_milk+=time_milk*time_to_milk;
                    }
                }
           
                 
                user[keccak256(gamer) & keccak256(i)] = tmp;
            }
        }
    }    
  
     
    function saleMilk(uint vol, uint num_cow) public {
        
         
        uint milk_to_sale;
        
         
        if (telega[msg.sender]==true) {
            
            MilkCow(msg.sender);
            
             
            uint cows_count = users_cows[msg.sender];            
        
             
            milk_to_sale=0;
            
             
            if (num_cow==0) {
                
                for (uint i=1; i<=cows_count; i++) {
                    
                    if (user[keccak256(msg.sender) & keccak256(i)].place) {
                        
                        milk_to_sale += user[keccak256(msg.sender) & keccak256(i)].milk;
                         
                        user[keccak256(msg.sender) & keccak256(i)].milk = 0;
                    }
                }
            }
             
            else {
                
                 
                cows tmp = user[keccak256(msg.sender) & keccak256(num_cow)];
                            
                 
                if (vol==0) {
                
                     
                    milk_to_sale = tmp.milk;
                     
                    tmp.milk = 0;    
                } 
                 
                else {
                        
                     
                    if (tmp.milk>vol) {
                    
                        milk_to_sale = vol;
                        tmp.milk -= milk_to_sale;
                    } 
                    
                     
                    else {
                        
                        milk_to_sale = tmp.milk;
                        tmp.milk = 0;
                    }                        
                } 
                
                user[keccak256(msg.sender) & keccak256(num_cow)] = tmp;
            }
            
             
            msg.sender.transfer(milkcost*milk_to_sale);
        }            
    }
            
     
    function TransferCow(address gamer, uint num_cow) public {
       
         
        cows cow= user[keccak256(msg.sender) & keccak256(num_cow)];
        
         
        if (cow.cow_live == true && cow.place==true) {
            
             
            uint cows_count = users_cows[gamer];
            
             
            cows_count++;
            
             
            user[keccak256(gamer) & keccak256(cows_count)]=cows(cow.cow,true,cow.date_buy,cow.cow_live,0,now);
            
             
            cow.cow_live= false;
             
            user[keccak256(msg.sender) & keccak256(num_cow)] = cow;
            
            users_cows[gamer] = cows_count;
        }
    }
    
     
    function DeadCow(address gamer, uint num_cow) public onlyOwner {
       
         
        user[keccak256(gamer) & keccak256(num_cow)].cow_live = false;
    }  
    
     
    function TelegaSend(address gamer) public onlyOwner {
       
         
        telega[gamer] = true;
       
    }  
    
     
    function SendOwner() public onlyOwner {
        msg.sender.transfer(this.balance);
    }      
    
     
    function TelegaOut(address gamer) public onlyOwner {
       
         
        telega[gamer] = false;
       
    }  
    
     
    function CountCow(address gamer) public view returns (uint) {
        return users_cows[gamer];   
    }

     
    function StatusCow(address gamer, uint num_cow) public view returns (uint,bool,uint,bool,uint,uint) {
        return (user[keccak256(gamer) & keccak256(num_cow)].cow,
        user[keccak256(gamer) & keccak256(num_cow)].place,
        user[keccak256(gamer) & keccak256(num_cow)].date_buy,
        user[keccak256(gamer) & keccak256(num_cow)].cow_live,
        user[keccak256(gamer) & keccak256(num_cow)].milk,
        user[keccak256(gamer) & keccak256(num_cow)].date_milk);   
    }
    
     
    function Statustelega(address gamer) public view returns (bool) {
        return telega[gamer];   
    }    
    
}