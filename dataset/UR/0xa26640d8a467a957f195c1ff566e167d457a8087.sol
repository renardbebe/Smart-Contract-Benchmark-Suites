 

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
        uint date_buy;
        bool cow_live;
        uint milk;
        uint date_milk;
    } 
    
     
    mapping (address => uint) users_cows;
     
    mapping (bytes32 => cows) user;
     
    mapping (address => bool) telega;
     
    address rico;
    
     
    uint volume_milk;
     
    uint time_to_milk;
     
    uint time_to_live;   
        
     
    uint milkcost;
    
     
    function Game() public {
        
         
    	rico = 0xb5F60D78F15b73DC2D2083571d0EEa70d35b9D28;
    	
    	 
    	cow_code = 0;
    	
         
        volume_milk = 1;
         
        time_to_milk = 60;
         
        time_to_live = 600;  
        
         
        milkcost = 0.0013 ether;
    }
    
    function pay() public payable {
        payCow();
    }        
    
     
    function payCow() private {
       
        uint time= now;
        uint cows_count = users_cows[msg.sender];
        
        uint index = msg.value/0.01 ether;
        
        for (uint i = 1; i <= index; i++) {
            
            cow_code++;
            cows_count++;
            user[keccak256(msg.sender) & keccak256(i)]=cows(cow_code,time,true,0,time);
        }
        users_cows[msg.sender] = cows_count;
        rico.transfer(0.001 ether);
    }    
    
     
    function MilkCow(address gamer) private {
       
        uint time= now;
        uint time_milk;
        
        for (uint i=1; i<=users_cows[gamer]; i++) {
            
             
            if (user[keccak256(gamer) & keccak256(i)].cow_live==true) {
                
                 
                uint datedeadcow=user[keccak256(gamer) & keccak256(i)].date_buy+time_to_live;
               
                 
                if (time>=datedeadcow) {
                    
                     
                    time_milk=(time-user[keccak256(gamer) & keccak256(i)].date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                         
                        user[keccak256(gamer) & keccak256(i)].milk+=(volume_milk*time_milk);
                         
                        user[keccak256(gamer) & keccak256(i)].cow_live=false;
                         
                        user[keccak256(gamer) & keccak256(i)].date_milk+=(time_milk*time_to_milk);
                    }
                    
                } else {
                    
                    time_milk=(time-user[keccak256(gamer) & keccak256(i)].date_milk)/time_to_milk;
                    
                    if (time_milk>=1) {
                        user[keccak256(gamer) & keccak256(i)].milk+=(volume_milk*time_milk);
                        user[keccak256(gamer) & keccak256(i)].date_milk+=(time_milk*time_to_milk);
                    }
                }
            }
        }
    }    
  
     
    function saleMilk() public {
        
         
        uint milk_to_sale;
        
         
        if (telega[msg.sender]==true) {
            
            MilkCow(msg.sender);
            
             
            uint cows_count = users_cows[msg.sender];            
        
             
            milk_to_sale=0;

            for (uint i=1; i<=cows_count; i++) {

                milk_to_sale += user[keccak256(msg.sender) & keccak256(i)].milk;
                 
                user[keccak256(msg.sender) & keccak256(i)].milk = 0;
            }
             
            uint a=milkcost*milk_to_sale;
            msg.sender.transfer(milkcost*milk_to_sale);
        }            
    }
            
     
    function TransferCow(address gamer, uint num_cow) public {
        
         
        if (user[keccak256(msg.sender) & keccak256(num_cow)].cow_live == true) {
            
             
            uint cows_count = users_cows[gamer];
            
             
            user[keccak256(gamer) & keccak256(cows_count)]=cows(user[keccak256(msg.sender) & keccak256(num_cow)].cow,
            user[keccak256(msg.sender) & keccak256(num_cow)].date_buy,
            user[keccak256(msg.sender) & keccak256(num_cow)].cow_live,0,now);
            
             
            user[keccak256(msg.sender) & keccak256(num_cow)].cow_live= false;
            
            users_cows[gamer] ++;
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

     
    function StatusCow(address gamer, uint num_cow) public view returns (uint,uint,bool,uint,uint) {
        return (user[keccak256(gamer) & keccak256(num_cow)].cow,
        user[keccak256(gamer) & keccak256(num_cow)].date_buy,
        user[keccak256(gamer) & keccak256(num_cow)].cow_live,
        user[keccak256(gamer) & keccak256(num_cow)].milk,
        user[keccak256(gamer) & keccak256(num_cow)].date_milk);   
    }
    
     
    function Statustelega(address gamer) public view returns (bool) {
        return telega[gamer];   
    }    
    
}