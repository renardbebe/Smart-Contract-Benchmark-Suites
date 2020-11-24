 

pragma solidity ^0.4.21;

 
 
 
 
 
 
 

 
 
 
 
 

contract EtherWild{
     
    uint8 constant MaxOffersPerADDR = 16;  
    uint16 CFee = 500;  
    uint16 HFeePart = 5000;  
    
    address Owner;
    address HelpOwner = 0x30B3E09d9A81D6B265A573edC7Cc4C4fBc0B0586;
    
     
     
     

     
     
     
     
    
     
     


    struct SimpleGame{
        address Owner;    
        uint8 setting;   

    }
    
    struct OfferGame{
	    uint256 amount;     
	    uint8 setting;      
        bool SimpleGame;  
    }
    
     
    mapping(uint256 => SimpleGame) public SimpleGameList;

     
    mapping(address => OfferGame[MaxOffersPerADDR]) public OfferGameList;
    

     
    event SimpleGamePlayed(address creator, address target, bool blue, bool cwon, uint256 amount);
    event SimpleGameCreated(address creator, uint256 fee, uint8 setting);
    event SimpleGameCancelled(uint256 fee);
    
         
    event OfferGameCreated(address creator, uint8 setting, uint256 amount, uint8 id);
    event OfferGameCancelled(address creator, uint8 id);
    event OfferGamePlayed(address creator, address target, bool blue, bool cwon, uint256 amount, uint8 id);
    
     
    modifier OnlyOwner(){
        if (msg.sender == Owner){
            _;
        }
        else{
            revert();
        }
    }
    
    function EtherWild() public{
        Owner = msg.sender;

    }
    
     
    function SetDevFee(uint16 tfee) public OnlyOwner{
        require(tfee <= 500);
        CFee = tfee;
    }
    
     
    function SetHFee(uint16 hfee) public OnlyOwner {
        require(hfee <= 10000);
        require(hfee >= 1000);
        HFeePart = hfee;
    
    }
    

     
    function UserOffers(address who) public view returns(uint8){
        uint8 ids = 0;
        for (uint8 i=0; i<MaxOffersPerADDR; i++){
            if ((OfferGameList[who][i].setting & 3) == 0){
                ids++ ;
            }
        }
        return ids;
    }
    
     
    function ViewOffer(address who, uint8 id) public view returns (uint256 amt, uint8 setting, bool sgame){
        var Game = OfferGameList[who][id];
        return (Game.amount, Game.setting,Game.SimpleGame);
    }
    
     
     
    function CreateOffer(uint8 setting) public payable{
        require(msg.value>0);
        require(setting>0);
        CreateOffer_internal(setting, false);
    }
    

     
    function CreateOffer_internal(uint8 setting, bool Sgame) internal returns (uint8 id){
         
        require(setting <= 3);

        bool found = false;
        id = 0;
         
        for (uint8 i=0; i<MaxOffersPerADDR; i++){
            if (OfferGameList[msg.sender][i].setting == 0){
                id = i;
                found = true;
                break;
            }
        }
         
         
        require(found);
        OfferGameList[msg.sender][id] = OfferGame(msg.value, setting, Sgame);

        emit OfferGameCreated(msg.sender, setting, msg.value, id);
         
        return id;
    }
    
     
     
    function OfferCancel(uint8 id) public {
        OfferCancel_internal(id, false);
    }
    
    
    function OfferCancel_internal(uint8 id, bool skipSimple) internal {
        var game = OfferGameList[msg.sender][id];
        if (game.setting != 0){
            uint8 setting; 
            bool sgame; 
            uint8 _notn;
            (setting, sgame, _notn) = DataFromSetting(game.setting);
             
            game.setting = 0;
            
            emit OfferGameCancelled(msg.sender, id);
            
             
             
            if ((!skipSimple) && game.SimpleGame){
                CancelSimpleOffer_internal(game.amount,true);
            }
            
             
            if (!skipSimple){
                msg.sender.transfer(game.amount);  
            }
        }
        else{
            return;
        }
    }
    
     
    function OfferPlay(address target, uint8 id, uint8 setting) public payable {
        var Game = OfferGameList[target][id];
        require(Game.setting != 0);
        require(msg.value >= Game.amount);
        
        uint256 excess = msg.value - Game.amount;
        if (excess > 0){
            msg.sender.transfer(excess);  
        }
        
        uint8 cset;
        bool sgame; 
        uint8 _id;
        
        (cset, sgame, id) = DataFromSetting(Game.setting);
        
        bool creatorChoosesBlue = GetSetting(Game.setting, setting);
        bool blue;
        bool creatorwins;
        (blue, creatorwins) = ProcessGame(target, msg.sender, creatorChoosesBlue, Game.amount);

        
         
        emit OfferGamePlayed(target, msg.sender, blue, creatorwins, Game.amount, id);
         
        Game.setting = 0;  
        
         
         
        if(sgame){
             
            CancelSimpleOffer_internal(Game.amount, true);
        }
        
    }
    
     
    function CancelSimpleOffer_internal(uint256 fee, bool SkipOffer) internal {
        uint8 setting = SimpleGameList[fee].setting;
        if (setting == 0){
            return;
        }
        if (!(SimpleGameList[fee].Owner == msg.sender)){
            return;
        }
      
        
        bool offer;
        uint8 id;
        
        (setting, offer, id) = DataFromSetting(setting);
        SimpleGameList[fee].setting = 0;  
         
         
        if ((!SkipOffer) && offer){
            OfferCancel_internal(id, true);
        }
        

         
       if (!SkipOffer){
            msg.sender.transfer(fee);  
       }
        
        emit SimpleGameCancelled( fee);
    }
    
     
     
    function CancelSimpleOffer(uint256 fee) public {
        
       CancelSimpleOffer_internal(fee, false);
    }
    
     
     
    function GetSetting(uint8 setting1, uint8 setting2) pure internal returns (bool creatorChoosesBlue){
        if (setting1 == 1){
            return true;
        }
        else if (setting1 == 2){
            return false;
        }
        else{
            if (setting2 == 1){
                return false;
            }
        }
        return true;
    }
    
     
     
    function PlaySimpleGame(uint8 setting, bool WantInOffer) payable public {
        require(msg.value > 0);
        require(setting > 0);  

        var game = (SimpleGameList[msg.value]);
        uint8 id;
        if (game.setting != 0){
             
             
            require(game.Owner != msg.sender);  
            
             
            uint8 cset; 
            bool ogame;
            id; 
            (cset, ogame, id) = DataFromSetting(game.setting);
            
            bool creatorChoosesBlue = GetSetting(cset, setting);
            bool blue;
            bool creatorwins;
             
            (blue, creatorwins) = ProcessGame(game.Owner, msg.sender, creatorChoosesBlue, msg.value);
            emit SimpleGamePlayed(game.Owner, msg.sender, blue, creatorwins, msg.value);
             
            game.setting = 0;
            
             
             
            if (ogame){
                OfferCancel_internal(id, true);
            }
        }
        else {
             
             
            id = 0;
            if (WantInOffer){
                 
                id = CreateOffer_internal(setting, true);  
            }
            
             
             
            
            setting = DataToSetting(setting, WantInOffer, id);
            
             
            var myGame = SimpleGame(msg.sender, setting);
            SimpleGameList[msg.value] = myGame;
            emit SimpleGameCreated(msg.sender, msg.value, setting);
        }
    }
    
         
         
         
         
    function ProcessGame(address creator, address target, bool creatorWantsBlue, uint256 fee) internal returns (bool blue, bool cWon) {
        uint random = rand(1, creator);
        blue = (random==0);
       
        cWon = (creatorWantsBlue == blue);  
        if (cWon){
            creator.transfer(DoFee(fee*2));  
        }
        else{
            target.transfer(DoFee(fee*2));
        }
    }
     
    function rand(uint max, address other) constant internal returns (uint result){
        uint add = uint (msg.sender) + uint(other) + uint(block.timestamp);
        uint random_number = addmod(uint (block.blockhash(block.number-1)), add, uint (max + 1)) ;
        return random_number;   
    }
    
    
    
     
     
    function DoFee(uint256 amt) internal returns (uint256 left){
        uint256 totalFee = (amt*CFee)/10000;  
        uint256 cFee = (totalFee*HFeePart)/10000;  
        uint256 dFee = totalFee - cFee;  
        
        Owner.transfer(dFee);  
        HelpOwner.transfer(cFee);
        
        return amt-totalFee;  
    }
     
     

     
    
     
     function DataToSetting(uint8 setting, bool offer, uint8 id) pure internal returns (uint8 output){
        require(setting <= 3);

        if (!offer){
            return setting;  
        }
        require(id <= 15);
        uint8 out=setting;
        if (offer){
            out = out + 4;  
        }
         
        uint8 conv_id = id << 4;
         
        out = out + conv_id; 
        return out;
    }
    
     
    function DataFromSetting(uint8 n) pure internal returns(uint8 set, bool offer, uint8 id){
         
        set = (n & 3); 
         
        offer = (bool) ((n & 4)==4); 
         
        id = (n) >> 4;
        
    }
    
    
}