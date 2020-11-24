 

contract Honestgamble {
    
     
    uint private deposit = 10 ether;  
    uint private feeFrac = 10;  
    uint constant time_max = 12 * 60 * 60;  
    uint private first_prize = 130;
    uint private second_prize = 110;
    uint private third_prize = 60;
    
     
    uint private Balance = 0;
    uint private fees = 0;  
    uint private Payout_id = 0;
    uint private number_of_players = 0;
    
    uint private last_time ;
    
    address private admin;
    
    function Honestgamble() {
        admin = msg.sender;
        last_time = block.timestamp;
    }

    modifier onlyowner {if (msg.sender == admin) _  }

    struct Player {
        address addr;
        uint payout;  
        bool paid;
    }

    Player[] private players;

     
    function() {
        init();
    }

     
    function init() private {
         
        if (msg.value < deposit) { 
            msg.sender.send(msg.value);
            return;
        }
        if(msg.value > deposit){
            msg.sender.send(msg.value-deposit);
        }
        
         
        Balance += (deposit * (1000 - feeFrac )) / 1000;  
        fees += (deposit * feeFrac) / 1000;           

    
        last_time = block.timestamp;
        players.push(Player(msg.sender,  0 , false));
        number_of_players++;
        
         
        if(number_of_players == 3){  
            Pay();
        }
    }
    
    function  Pay() private{
          
        uint256 toss = uint256(sha3(msg.gas)) + uint256(sha3(block.timestamp)); 
         
        uint i_13;
        uint i_11;
        uint i_6;
        
        if( toss % 3 == 0 ){
            i_13=Payout_id;
            i_11=Payout_id+1;
            i_6 =Payout_id+2;
        }
        else if( toss % 3 == 1){
            i_13=Payout_id+2;
            i_11=Payout_id;
            i_6 =Payout_id+1;
        }
        else{
            i_13=Payout_id+1;
            i_11=Payout_id+2;
            i_6 =Payout_id;
        }
        uint256 bet=(deposit * (1000 - feeFrac )) / 1000;
        players[i_13].addr.send(bet*first_prize/100);  
        players[i_11].addr.send(bet*second_prize/100);  
        players[i_6].addr.send(bet*third_prize/100);  
        
         
        players[i_13].payout=bet*first_prize/100;
        players[i_11].payout=bet*second_prize/100;
        players[i_6].payout=bet*third_prize/100;
        players[Payout_id].paid=true;
        players[Payout_id+1].paid=true;
        players[Payout_id+2].paid=true;
        Balance=0;
        number_of_players=0;
        Payout_id += 3;
    }

    
    function CancelRoundAndRefundAll() {  
        if(number_of_players==0) return;
        
        if (last_time + time_max < block.timestamp) {
            for(uint i=Payout_id; i<(Payout_id+number_of_players); i++){
                players[i].addr.send((deposit * (1000 - feeFrac )) / 1000 );
                players[i].paid=true;
                players[i].payout=(deposit * (1000 - feeFrac )) / 1000;  
            }
            Payout_id += number_of_players;
            number_of_players=0;
        }
    }
    
     
    
    
    function WatchBalance() constant returns(uint TotalBalance, string info) {
        TotalBalance = Balance /  1 finney;
        info ='Balance in finney';
    }
    
    function PlayerInfo(uint id) constant returns(address Address, uint Payout, bool UserPaid) {
        if (id <= players.length) {
            Address = players[id].addr;
            Payout = (players[id].payout) / 1 finney;
            UserPaid=players[id].paid;
        }
    }
    
    function WatchLastTime() constant returns(uint LastTimestamp) {
        LastTimestamp = last_time;
    }

    function WatchCollectedFeesInSzabo() constant returns(uint Fees) {
        Fees = fees / 1 szabo;
    }
    
    function WatchAppliedFeePercentage() constant returns(uint FeePercent) {
        FeePercent = feeFrac/10;
    }
    

    function WatchNumberOfPlayerInCurrentRound() constant returns(uint N) {
        N = number_of_players;
    }
     
    
    function ChangeOwnership(address _owner) onlyowner {
        admin = _owner;
    }
    
    function CollectAllFees() onlyowner {
        if (fees == 0) throw;
        admin.send(fees);
        fees = 0;
    }
    
    function CollectAndReduceFees(uint p) onlyowner {
        if (fees == 0) feeFrac=feeFrac*50/100;  
        admin.send(fees / 1000 * p); 
        fees -= fees / 1000 * p;
    }
}