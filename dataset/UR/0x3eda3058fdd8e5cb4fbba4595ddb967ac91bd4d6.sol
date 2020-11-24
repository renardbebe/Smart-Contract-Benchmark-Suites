 

pragma solidity ^0.4.24;

contract Lottery3{
    using SafeMathLib for *;
     
     
     
    mapping(uint64 => address) public id_addr;

    mapping(address => mapping(uint16 => JackpotLib.Ticket3)) public ticketRecs;
     
    mapping(address => JackpotLib.Player) public players;
    mapping(uint16 => JackpotLib.Round3) public rounds;

    uint64 constant private noticePeriod = 10 minutes; 
    uint64 constant private claimPeriod = 30 days; 
    uint16 constant private ticketPrice = 20;  
    uint16 constant private prize0 = 18600; 
    uint16 constant private prize1 = 3100; 
    uint16 constant private prize2 = 6200; 
    uint256 constant private unitSize=1e14; 

    uint32 constant private mask0 = 0xC0000000; 
    uint32 constant private mask1 = 0x3FF00000; 
    uint32 constant private mask2 = 0xFFC00; 
    uint32 constant private mask3 = 0x3FF; 
    
    uint64 constant private roundInterval = 1 days;

    JackpotLib.Status public gameState;

    
    
     

    address adminAddr=0xdf68C2236bB7e5ac40f4b809CD41C5ab73958643;
    



    modifier adminOnly(){
        require(msg.sender == adminAddr,'Who are you?');
        _;        
    }
    modifier humanOnly() { 
    require(msg.sender == tx.origin, "Humans only");
        _;
    } 
    constructor() public{          
         
         
        gameState.baseRound=324;
        gameState.baseRoundEndTime=1543320000;  
        gameState.numPlayers=0;
        gameState.currRound=gameState.baseRound;
        rounds[gameState.baseRound].endTime=gameState.baseRoundEndTime;

    }
    function setBaseRound(uint16 baseRound,uint64 baseRoundEndTime)
        adminOnly()
        public
    {
        gameState.baseRound=baseRound;
        gameState.baseRoundEndTime=baseRoundEndTime;   
    }

    function getBal()
        public
        view
        returns(uint256 balance)
    {
        return address(this).balance;
    }


    function startRound() 
        public 
    {
        require(gameState.baseRound>0,'cannot start round now');
        uint64 endTime;
        endTime=(uint64(now)-gameState.baseRoundEndTime+roundInterval-1)/roundInterval*roundInterval+gameState.baseRoundEndTime;
        uint16 round;
        round=uint16((endTime-gameState.baseRoundEndTime)/roundInterval+gameState.baseRound);
        rounds[round].endTime=endTime;
        gameState.currRound=round;
    }
     
     
     
     
     
     
     
     
     
     
     
     
    function announceWinningNum(uint16 round,uint16 winningNum0,uint16 winningNum1,uint16 winningNum2) 
        adminOnly() 
        public
    {
        require( uint64(now) > rounds[round].endTime,'round not ended yet, where did you get the numbers?');
        require( rounds[round].claimStartTime==0 || uint64(now) < rounds[round].claimStartTime, 'claim started, cannot change number');                
        rounds[round].winningNum0   =winningNum0;
        rounds[round].winningNum1   =winningNum1;
        rounds[round].winningNum2   =winningNum2;
        rounds[round].claimStartTime    =uint64(now)+noticePeriod;
        rounds[round].claimDeadline     =uint64(now)+noticePeriod+claimPeriod;
        gameState.lastRound=round;
    }    
    function sweep()    
        adminOnly()
        public
    {
        require(gameState.baseRound==0,'game not ended');
        require(rounds[gameState.currRound].claimDeadline>0 && rounds[gameState.currRound].claimDeadline < uint64(now),'claim not ended');
        adminAddr.transfer(address(this).balance);
    }
    function checkTicket(address playerAddr,uint16 id)
        public
        view
        returns(
            uint16 status, 
            uint16 winningNum0,
            uint256 prize            
        )
    {
        uint16 winningNum;
        winningNum0=rounds[ticketRecs[playerAddr][id].round].winningNum0;
        if(rounds[ticketRecs[playerAddr][id].round].claimStartTime==0 || uint64(now) < rounds[ticketRecs[playerAddr][id].round].claimStartTime){
            status=0;
            winningNum=1000;
            prize=0;            
        }else{
            if(ticketRecs[playerAddr][id].ticketType==0){
                winningNum=rounds[ticketRecs[playerAddr][id].round].winningNum0;
                prize=prize0;
            }else if(ticketRecs[playerAddr][id].ticketType==1){
                winningNum=rounds[ticketRecs[playerAddr][id].round].winningNum1;
                prize=prize1;
            }else if(ticketRecs[playerAddr][id].ticketType==2){
                winningNum=rounds[ticketRecs[playerAddr][id].round].winningNum2;
                prize=prize2;
            }else{ 
                winningNum=rounds[ticketRecs[playerAddr][id].round].winningNum0;
                prize=prize0;
            }
            if(ticketRecs[playerAddr][id].claimed){ 
                status=2;
            }else if( ticketRecs[playerAddr][id].ticketType==3 ?  
            !checkCombo(ticketRecs[playerAddr][id].numbers,winningNum) :
             ticketRecs[playerAddr][id].numbers != winningNum){ 
                status=1;
            }else if(rounds[ticketRecs[playerAddr][id].round].claimDeadline<=now){ 
                status=3;            
            }else{ 
                status=4;
            }
            if(status==4 || status==2){
                prize=unitSize.mul(prize).mul(ticketRecs[playerAddr][id].multiple);
            }else{
                prize=0;
            }
            return (status,winningNum0,prize);
        }        
    }

    function claimPrize(uint16 id)        
        public
    {        
        uint16 winningNum;
        uint16 prize;

        if(ticketRecs[msg.sender][id].ticketType==0){
            winningNum=rounds[ticketRecs[msg.sender][id].round].winningNum0;
            prize=prize0;
        }else if(ticketRecs[msg.sender][id].ticketType==1){
            winningNum=rounds[ticketRecs[msg.sender][id].round].winningNum1;
            prize=prize1;
        }else if(ticketRecs[msg.sender][id].ticketType==2){
            winningNum=rounds[ticketRecs[msg.sender][id].round].winningNum2;
            prize=prize2;
        }else{ 
            winningNum=rounds[ticketRecs[msg.sender][id].round].winningNum0;
            prize=prize0;
        }

        require(rounds[ticketRecs[msg.sender][id].round].claimStartTime>0,'not announced yet');
        require(rounds[ticketRecs[msg.sender][id].round].claimStartTime<=now,'claim not started');  
        require(rounds[ticketRecs[msg.sender][id].round].claimDeadline>now,'claim already ended');  
        if(ticketRecs[msg.sender][id].ticketType==3){ 
            require(checkCombo(ticketRecs[msg.sender][id].numbers,winningNum),"you combo didn't cover the lucky number");
        }else{ 
            require(ticketRecs[msg.sender][id].numbers == winningNum,"you didn't win");  
        }
        
        require(!ticketRecs[msg.sender][id].claimed,'ticket already claimed');   
            
        ticketRecs[msg.sender][id].claimed=true;            
        msg.sender.transfer(unitSize.mul(prize).mul(ticketRecs[msg.sender][id].multiple));
        
    }
    function checkCombo(uint32 ticketNumber,uint32 winningNum)
        public 
        pure
        returns(bool win)
    {
         
         
         
         
         
         
         

        uint32 num3=winningNum % 10; 
        winningNum = winningNum /10;
        uint32 num2=winningNum % 10; 
        winningNum = winningNum /10;
        uint32 num1=winningNum % 10; 
         

        return (ticketNumber & (uint32(1)<<(num1+20))!=0) && 
            (ticketNumber & (uint32(1)<<(num2+10))!=0) && 
            (ticketNumber & (uint32(1)<<num3)!=0);
    }
    function register(address playerAddr)
        private
    {   
        if(players[playerAddr].id==0){
            players[playerAddr].id=++gameState.numPlayers;
            players[playerAddr].registerOn=uint64(now);
            id_addr[gameState.numPlayers]=playerAddr;        
        }
    }
    
    function buyTicket(address owner,uint8 ticketType,uint32 numbers,uint16 multiple) 
        humanOnly()
        public
        payable
    {
        address player;
        if(owner==address(0))
            player=msg.sender;
        else
            player=owner;
        register(player);
        if(ticketType>2) 
            ticketType=2;
         
         
        if(rounds[gameState.currRound].endTime<=uint64(now))
             
            startRound();

        uint256 amt=unitSize.mul(ticketPrice).mul(multiple);
        require(msg.value >= amt,'insufficient fund');
        amt=msg.value-amt; 
        uint16 numTickets=(players[player].numTickets)+1;
        require(numTickets > players[player].numTickets,'you played too much');
        require(numbers <= 999,'wrong number');

        ticketRecs[player][numTickets]=JackpotLib.Ticket3(false,ticketType,gameState.currRound,multiple,numbers,uint64(now));
         
         
        players[player].numTickets=numTickets;
                        
        if(amt>0){ 
            (msg.sender).transfer(amt); 
        }
    }   
    function countChoice(uint32 number) 
        public 
        pure
        returns(uint16 count)
    {
        count=0;
        uint8 i;
        for(i=0;i<10;i++){
            if(number%2 == 1)
                count++;
            number=number/2;
        }
        return count;
    }

    function buyCombo(address owner,uint32 numbers,uint16 multiple) 
        humanOnly()
        public
        payable
    {
        address player;
        if(owner==address(0))
            player=msg.sender;
        else
            player=owner;
        register(player);
         
        
        if(rounds[gameState.currRound].endTime<=uint64(now))            
            startRound();

         
        require(mask0 & numbers == 0,'wrong num: first 2 bits should be empty');
        uint16 combos=countChoice(numbers); 
        require(combos !=0, 'wrong num: select numbers for slot 3');
        combos*=countChoice(numbers>>10); 
        require(combos !=0, 'wrong num: select numbers for slot 2');
        combos*=countChoice(numbers>>20); 
        require(combos !=0, 'wrong num: select numbers for slot 1');
        
        uint256 amt=unitSize.mul(ticketPrice).mul(multiple).mul(combos);
        require(msg.value >= amt,'insufficient fund');
        amt=msg.value-amt; 
        uint16 numTickets=(players[player].numTickets)+1;
        require(numTickets > players[player].numTickets,'you played too much');        

        ticketRecs[player][numTickets]=JackpotLib.Ticket3(false,3,gameState.currRound,multiple,numbers,uint64(now));        
        players[player].numTickets=numTickets;
                        
        if(amt>0){ 
            (msg.sender).transfer(amt); 
        }
    }       
     
     
     
}

library JackpotLib{
	struct Ticket3{		
		bool claimed; 
		uint8 ticketType; 
		uint16 round;		
		uint16 multiple;
		uint32 numbers;
		uint64 soldOn; 
	}
	 
	 
	 
	 
	 
	 
	 
	struct Player{
		uint16 id;
		uint16 numTickets;
		uint64 registerOn; 
	}
	struct Status{
		uint16 lastRound;
		uint16 currRound;
		uint16 numPlayers;
		uint16 baseRound;
		uint64 baseRoundEndTime;
		uint64 reserve;
	}

	struct Round3{
		uint64 endTime;		 
		uint64 claimStartTime; 
		uint64 claimDeadline; 
		uint16 winningNum0;
		uint16 winningNum1;
		uint16 winningNum2;
	}
	 
	 
	 
	 
	 
	 

	
}

library SafeMathLib {
    
   
  function mul(uint256 a, uint256 b) 
      internal 
      pure 
      returns (uint256 c) 
  {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
  }

   
  function sub(uint256 a, uint256 b)
      internal
      pure
      returns (uint256) 
  {
    require(b <= a, "SafeMath sub failed");
    return a - b;
  }

   
  function add(uint256 a, uint256 b)
      internal
      pure
      returns (uint256 c) 
  {
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
  }
  
   
  function sqrt(uint256 x)
      internal
      pure
      returns (uint256 y) 
  {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y) 
    {
      y = z;
      z = ((add((x / z),z)) / 2);
    }
  }
  
   
  function sq(uint256 x)
      internal
      pure
      returns (uint256)
  {
    return (mul(x,x));
  }
  
   
  function pwr(uint256 x, uint256 y)
      internal 
      pure 
      returns (uint256)
  {
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else 
    {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}