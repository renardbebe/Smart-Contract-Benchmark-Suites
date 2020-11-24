 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract Rouleth
{

     
    address developer;
    uint8 blockDelay;  
    uint8 blockExpiration;  
    uint256 maxGamble;  
    uint maxBetsPerBlock;  
    uint nbBetsCurrentBlock;  
    uint casinoStatisticalLimit;
     
    uint256 currentMaxGamble; 
     
    struct Gamble
    {
	address player;
        bool spinned;  
	bool win;
	BetTypes betType;  
	uint8 input;  
	uint256 wager;
	uint256 blockNumber;  
        uint8 wheelResult;
    }
    Gamble[] private gambles;
    uint firstActiveGamble;  
     
    mapping (address=>uint) gambleIndex;  
    enum Status {waitingForBet, waitingForSpin} Status status;  
    mapping (address=>Status) playerStatus;  

     
     
     
	function  Rouleth() private  
    { 
        developer = msg.sender;
        blockDelay=6;  
	blockExpiration=200;  
        maxGamble=50 finney;  
        maxBetsPerBlock=2;  
        casinoStatisticalLimit=20;
    }
	
    modifier onlyDeveloper() {
	    if (msg.sender!=developer) throw;
	    _
    }
	
	function changeDeveloper(address new_dev)
        noEthSent
	    onlyDeveloper
	{
		developer=new_dev;
	}


     
    enum States{active, inactive} States private state;
	function disableBetting()
    noEthSent
	onlyDeveloper
	{
            state=States.inactive;
	}
	function enableBetting()
	onlyDeveloper
        noEthSent
	{
            state=States.active;
	}
    
	modifier onlyActive
    {
        if (state==States.inactive) throw;
        _
    }

          
	function changeSettings(uint newCasinoStatLimit, uint newMaxBetsBlock, uint256 newMaxGamble, uint8 newMaxInvestor, uint256 newMinInvestment, uint256 newLockPeriod, uint8 newBlockDelay, uint8 newBlockExpiration)
	noEthSent
	onlyDeveloper
	{
	         
	        if (newCasinoStatLimit<20) throw;
	        casinoStatisticalLimit=newCasinoStatLimit;
	         
	        maxBetsPerBlock=newMaxBetsBlock;
                 
		if (newMaxGamble<=0 || newMaxGamble>=this.balance/(20*35)) throw; 
		else { maxGamble=newMaxGamble; }
                 
                if (newMaxInvestor<setting_maxInvestors || newMaxInvestor>149) throw;
                else { setting_maxInvestors=newMaxInvestor;}
                 
                setting_minInvestment=newMinInvestment;
                 
                if (setting_lockPeriod>5184000) throw;  
                setting_lockPeriod=newLockPeriod;
		         
		if (blockDelay<1) throw;
		        blockDelay=newBlockDelay;
                updateMaxBet();
		if (newBlockExpiration<100) throw;
		blockExpiration=newBlockExpiration;
	}
 

     
     
     

 
     
     
    function () 
   {
        
       if (playerStatus[msg.sender]==Status.waitingForBet)  betOnNumber(7);
        
       else spinTheWheel();
    } 

    function updateMaxBet() private
    {
     
        if (payroll/(casinoStatisticalLimit*35) > maxGamble) 
		{ 
			currentMaxGamble=maxGamble;
                }
	else
		{ 
			currentMaxGamble = payroll/(20*35);
		}
     }

 
    function checkBetValue() private returns(uint256 playerBetValue)
    {
        updateMaxBet();
		if (msg.value > currentMaxGamble)  
		{
		    msg.sender.send(msg.value-currentMaxGamble);
		    playerBetValue=currentMaxGamble;
		}
                else
                { playerBetValue=msg.value; }
       }


     
    modifier checkNbBetsCurrentBlock()
    {
        if (gambles.length!=0 && block.number==gambles[gambles.length-1].blockNumber) nbBetsCurrentBlock+=1;
        else nbBetsCurrentBlock=0;
        if (nbBetsCurrentBlock>=maxBetsPerBlock) throw;
        _
    }
     
    modifier checkWaitingForBet{
         
        if (playerStatus[msg.sender]!=Status.waitingForBet)
        {
              
             if (gambles[gambleIndex[msg.sender]].blockNumber+blockExpiration>block.number) throw;
              
             else
             {
                   
                  solveBet(msg.sender, 255, false, 0) ;

              }
        }
	_
	}

     
    enum BetTypes{ number, color, parity, dozen, column, lowhigh} BetTypes private initbetTypes;

    function updateStatusPlayer() private
    expireGambles
    {
	playerStatus[msg.sender]=Status.waitingForSpin;
	gambleIndex[msg.sender]=gambles.length-1;
     }

 
    function betOnNumber(uint8 numberChosen)
    checkWaitingForBet
    onlyActive
    checkNbBetsCurrentBlock
    {
         
        if (numberChosen>36) throw;
		 
        uint256 betValue= checkBetValue();
	    gambles.push(Gamble(msg.sender, false, false, BetTypes.number, numberChosen, betValue, block.number, 37));
        updateStatusPlayer();
    }

 
	 
	 
	 
    function betOnColor(bool Red, bool Black)
    checkWaitingForBet
    onlyActive
    checkNbBetsCurrentBlock
    {
        uint8 count;
        uint8 input;
        if (Red) 
        { 
             count+=1; 
             input=0;
         }
        if (Black) 
        {
             count+=1; 
             input=1;
         }
        if (count!=1) throw;
	 
        uint256 betValue= checkBetValue();
	    gambles.push(Gamble(msg.sender, false, false, BetTypes.color, input, betValue, block.number, 37));
        updateStatusPlayer();
    }

 
	 
	 
	 
    function betOnLowHigh(bool Low, bool High)
    checkWaitingForBet
    onlyActive
    checkNbBetsCurrentBlock
    {
        uint8 count;
        uint8 input;
        if (Low) 
        { 
             count+=1; 
             input=0;
         }
        if (High) 
        {
             count+=1; 
             input=1;
         }
        if (count!=1) throw;
	 
        uint256 betValue= checkBetValue();
	gambles.push(Gamble(msg.sender, false, false, BetTypes.lowhigh, input, betValue, block.number, 37));
        updateStatusPlayer();
    }

 
	 
      
     
    function betOnOddEven(bool Odd, bool Even)
    checkWaitingForBet
    onlyActive
    checkNbBetsCurrentBlock
    {
        uint8 count;
        uint8 input;
        if (Even) 
        { 
             count+=1; 
             input=0;
         }
        if (Odd) 
        {
             count+=1; 
             input=1;
         }
        if (count!=1) throw;
	 
        uint256 betValue= checkBetValue();
	gambles.push(Gamble(msg.sender, false, false, BetTypes.parity, input, betValue, block.number, 37));
        updateStatusPlayer();
    }


 
 
 
 
 
    function betOnDozen(bool First, bool Second, bool Third)
    checkWaitingForBet
    onlyActive
    checkNbBetsCurrentBlock
    {
         betOnColumnOrDozen(First,Second,Third, BetTypes.dozen);
    }


 
 
 
 
 
    function betOnColumn(bool First, bool Second, bool Third)
    checkWaitingForBet
    onlyActive
    checkNbBetsCurrentBlock
    {
         betOnColumnOrDozen(First, Second, Third, BetTypes.column);
     }

    function betOnColumnOrDozen(bool First, bool Second, bool Third, BetTypes bet) private
    { 
        uint8 count;
        uint8 input;
        if (First) 
        { 
             count+=1; 
             input=0;
         }
        if (Second) 
        {
             count+=1; 
             input=1;
         }
        if (Third) 
        {
             count+=1; 
             input=2;
         }
        if (count!=1) throw;
	 
        uint256 betValue= checkBetValue();
	    gambles.push(Gamble(msg.sender, false, false, bet, input, betValue, block.number, 37));
        updateStatusPlayer();
    }

     
     
     

	event Win(address player, uint8 result, uint value_won);
	event Loss(address player, uint8 result, uint value_loss);

     
    modifier checkWaitingForSpin{
        if (playerStatus[msg.sender]!=Status.waitingForSpin) throw;
	_
	}
     
    modifier noEthSent()
    {
        if (msg.value>0) msg.sender.send(msg.value);
        _
    }

 
    function spinTheWheel()
    checkWaitingForSpin
    noEthSent
    {
         
         
	uint playerblock = gambles[gambleIndex[msg.sender]].blockNumber;
	if (block.number<playerblock+blockDelay || block.number>playerblock+blockExpiration) throw;
    else
	{
	    uint8 wheelResult;
         
		wheelResult = uint8(uint256(block.blockhash(playerblock+blockDelay))%37);
		updateFirstActiveGamble(gambleIndex[msg.sender]);
		gambles[gambleIndex[msg.sender]].wheelResult=wheelResult;
         
		checkBetResult(wheelResult, gambles[gambleIndex[msg.sender]].betType);
	}
    }

function updateFirstActiveGamble(uint bet_id) private
     {
         if (bet_id==firstActiveGamble)
         {   
              uint index=firstActiveGamble;
              while (true)
              {
                 if (index<gambles.length && gambles[index].spinned){
                     index=index+1;
                 }
                 else {break; }
               }
              firstActiveGamble=index;
              return;
          }
 }
	
 
modifier expireGambles{
    if (  (gambles.length!=0 && gambles.length-1>=firstActiveGamble ) 
          && gambles[firstActiveGamble].blockNumber + blockExpiration <= block.number && !gambles[firstActiveGamble].spinned )  
    { 
	solveBet(gambles[firstActiveGamble].player, 255, false, 0);
        updateFirstActiveGamble(firstActiveGamble);
    }
        _
}
	

      
     function checkBetResult(uint8 result, BetTypes betType) private
     {
           
          if (betType==BetTypes.number) checkBetNumber(result);
          else if (betType==BetTypes.parity) checkBetParity(result);
          else if (betType==BetTypes.color) checkBetColor(result);
	 else if (betType==BetTypes.lowhigh) checkBetLowhigh(result);
	 else if (betType==BetTypes.dozen) checkBetDozen(result);
	else if (betType==BetTypes.column) checkBetColumn(result);
          updateMaxBet(); 
     }

      
     function solveBet(address player, uint8 result, bool win, uint8 multiplier) private
     {
        playerStatus[msg.sender]=Status.waitingForBet;
        gambles[gambleIndex[player]].spinned=true;
	uint bet_v = gambles[gambleIndex[player]].wager;
            if (win)
            {
		  gambles[gambleIndex[player]].win=true;
		  uint win_v = multiplier*bet_v;
                  player.send(win_v);
                  lossSinceChange+=win_v-bet_v;
		  Win(player, result, win_v);
             }
            else
            {
		Loss(player, result, bet_v);
                profitSinceChange+=bet_v;
            }

      }


      
     
     
     function checkBetNumber(uint8 result) private
     {
            bool win;
             
	    if (result==gambles[gambleIndex[msg.sender]].input)
	    {
                  win=true;  
             }
             solveBet(msg.sender, result,win,35);
     }


      
     
     
     function checkBetParity(uint8 result) private
     {
            bool win;
             
	    if (result%2==gambles[gambleIndex[msg.sender]].input && result!=0)
	    {
                  win=true;                
             }
             solveBet(msg.sender,result,win,2);
        
     }
	
      
      
      
     function checkBetLowhigh(uint8 result) private
     {
            bool win;
             
		 if (result!=0 && ( (result<19 && gambles[gambleIndex[msg.sender]].input==0)
			 || (result>18 && gambles[gambleIndex[msg.sender]].input==1)
			 ) )
	    {
                  win=true;
             }
             solveBet(msg.sender,result,win,2);
     }

      
      
      
      uint[18] red_list=[1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
      function checkBetColor(uint8 result) private
      {
             bool red;
              
             for (uint8 k; k<18; k++)
             { 
                    if (red_list[k]==result) 
                    { 
                          red=true; 
                          break;
                    }
             }
             bool win;
              
             if ( result!=0
                && ( (gambles[gambleIndex[msg.sender]].input==0 && red)  
                || ( gambles[gambleIndex[msg.sender]].input==1 && !red)  ) )
             {
                  win=true;
             }
             solveBet(msg.sender,result,win,2);
       }

      
      
      
     function checkBetDozen(uint8 result) private
     { 
            bool win;
             
     		 if ( result!=0 &&
                      ( (result<13 && gambles[gambleIndex[msg.sender]].input==0)
     			||
                     (result>12 && result<25 && gambles[gambleIndex[msg.sender]].input==1)
                    ||
                     (result>24 && gambles[gambleIndex[msg.sender]].input==2) ) )
     	    {
                   win=true;                
             }
             solveBet(msg.sender,result,win,3);
     }

      
      
      
      function checkBetColumn(uint8 result) private
      {
             bool win;
              
             if ( result!=0
                && ( (gambles[gambleIndex[msg.sender]].input==0 && result%3==1)  
                || ( gambles[gambleIndex[msg.sender]].input==1 && result%3==2)
                || ( gambles[gambleIndex[msg.sender]].input==2 && result%3==0)  ) )
             {
                  win=true;
             }
             solveBet(msg.sender,result,win,3);
      }


 


 
    uint256 payroll;
 
    uint256 profitSinceChange;
    uint256 lossSinceChange;
 
    uint8 setting_maxInvestors = 50;
    struct Investor
    {
	    address investor;
	    uint256 time;
    }	
	Investor[150] private investors ;
     
    mapping (address=>uint256) balance; 
     
     
     
    uint256 setting_lockPeriod=604800 ;  
    uint256 setting_minInvestment=10 ether;  
     
     
    uint8 cheapestUnlockedPosition; 
    uint256 minCurrentInvest; 
     
     
    uint8 openPosition;
	
    event newInvest(address player, uint invest_v);


     function invest()
     {
           
          if (msg.value<setting_minInvestment) throw;
           
          bool alreadyInvestor;
           
          openPosition=255;
          cheapestUnlockedPosition=255;
          minCurrentInvest=10000000000000000000000000; 
           
          updateBalances();
           
           
          for (uint8 k = 0; k<setting_maxInvestors; k++)
          { 
                
               if (investors[k].investor==0) openPosition=k; 
                
               else if (investors[k].investor==msg.sender)
               {
                    investors[k].time=now;  
                    alreadyInvestor=true;
                }
                
               else if (investors[k].time+setting_lockPeriod<now && balance[investors[k].investor]<minCurrentInvest && investors[k].investor!=developer)
               {
                    cheapestUnlockedPosition=k;
                    minCurrentInvest=balance[investors[k].investor];
                }
           }
            
           if (alreadyInvestor==false)
           {
                     
                    if (openPosition!=255) investors[openPosition]=Investor(msg.sender, now);
                     
                    else
                    {
                          
                         if (msg.value<=minCurrentInvest || cheapestUnlockedPosition==255) throw;
                          
                         else
                         {
                              address previous = investors[cheapestUnlockedPosition].investor;
                              if (previous.send(balance[previous])==false) throw;
                              balance[previous]=0;
                              investors[cheapestUnlockedPosition]=Investor(msg.sender, now);
                          }
                     }
            }
           

          uint256 maintenanceFees=2*msg.value/100;  
          uint256 netInvest=msg.value - maintenanceFees;
          newInvest(msg.sender, netInvest);
          balance[msg.sender]+=netInvest;  
          payroll+=netInvest;
           
          if (developer.send(maintenanceFees)==false) throw;
          updateMaxBet();
      }

 
     
     
     
	event withdraw(address player, uint withdraw_v);
	
    function withdrawInvestment(uint256 amountToWithdrawInWei)
    noEthSent
    {
         
        updateBalances();
	 
	if (amountToWithdrawInWei>balance[msg.sender]) throw;
         
        uint8 investorID=255;
        for (uint8 k = 0; k<setting_maxInvestors; k++)
        {
               if (investors[k].investor==msg.sender)
               {
                    investorID=k;
                    break;
               }
        }
           if (investorID==255) throw;  
            
           if (investors[investorID].time+setting_lockPeriod>now) throw;
            
           if (balance[msg.sender]-amountToWithdrawInWei>=setting_minInvestment && amountToWithdrawInWei!=0)
           {
               balance[msg.sender]-=amountToWithdrawInWei;
               payroll-=amountToWithdrawInWei;
                
               if (msg.sender.send(amountToWithdrawInWei)==false) throw;
	       withdraw(msg.sender, amountToWithdrawInWei);
           }
           else
            
            
           {
                
               uint256 fullAmount=balance[msg.sender];
               payroll-=fullAmount;
               balance[msg.sender]=0;
               if (msg.sender.send(fullAmount)==false) throw;
                
               delete investors[investorID];
   	       withdraw(msg.sender, fullAmount);
            }
          updateMaxBet();
     }

 

	function manualUpdateBalances()
	expireGambles
	noEthSent
	{
	    updateBalances();
	}
    function updateBalances() private
    {
          
         uint256 profitToSplit;
         uint256 lossToSplit;
         if (profitSinceChange==0 && lossSinceChange==0)
         { return; }
         
         else
         {
              
              
             if (profitSinceChange>lossSinceChange)
             {
                profitToSplit=profitSinceChange-lossSinceChange;
                uint256 developerFees=profitToSplit*2/100;
                profitToSplit-=developerFees;
                if (developer.send(developerFees)==false) throw;
             }
             else
             {
                lossToSplit=lossSinceChange-profitSinceChange;
             }
         
          
          
         uint totalShared;
             for (uint8 k=0; k<setting_maxInvestors; k++)
             {
                 address inv=investors[k].investor;
                 if (inv==0) continue;
                 else
                 {
                       if (profitToSplit!=0) 
                       {
                           uint profitShare=(profitToSplit*balance[inv])/payroll;
                           balance[inv]+=profitShare;
                           totalShared+=profitShare;
                       }
                       if (lossToSplit!=0) 
                       {
                           uint lossShare=(lossToSplit*balance[inv])/payroll;
                           balance[inv]-=lossShare;
                           totalShared+=lossShare;
                           
                       }
                 }
             }
           
          if (profitToSplit !=0) 
          {
              payroll+=profitToSplit;
              balance[developer]+=profitToSplit-totalShared;
          }
          if (lossToSplit !=0) 
          {
              payroll-=lossToSplit;
              balance[developer]-=lossToSplit-totalShared;
          }
          profitSinceChange=0;  
          lossSinceChange=0;  
          
          }
     }
     
     
      
     
     function checkProfitLossSinceInvestorChange() constant returns(uint profit, uint loss)
     {
        profit=profitSinceChange;
        loss=lossSinceChange;
        return;
     }

    function checkInvestorBalance(address investor) constant returns(uint balanceInWei)
    {
          balanceInWei=balance[investor];
          return;
     }

    function getInvestorList(uint index) constant returns(address investor, uint endLockPeriod)
    {
          investor=investors[index].investor;
          endLockPeriod=investors[index].time+setting_lockPeriod;
          return;
    }
	

	function investmentEntryCost() constant returns(bool open_position, bool unlocked_position, uint buyout_amount, uint investLockPeriod)
	{
		if (openPosition!=255) open_position=true;
		if (cheapestUnlockedPosition!=255) 
		{
			unlocked_position=true;
			buyout_amount=minCurrentInvest;
		}
		investLockPeriod=setting_lockPeriod;
		return;
	}
	
	function getSettings() constant returns(uint maxBet, uint8 blockDelayBeforeSpin)
	{
	    maxBet=currentMaxGamble;
	    blockDelayBeforeSpin=blockDelay;
	    return ;
	}
	
    function checkMyBet(address player) constant returns(Status player_status, BetTypes bettype, uint8 input, uint value, uint8 result, bool wheelspinned, bool win, uint blockNb)
    {
          player_status=playerStatus[player];
          bettype=gambles[gambleIndex[player]].betType;
          input=gambles[gambleIndex[player]].input;
          value=gambles[gambleIndex[player]].wager;
          result=gambles[gambleIndex[player]].wheelResult;
          wheelspinned=gambles[gambleIndex[player]].spinned;
          win=gambles[gambleIndex[player]].win;
		blockNb=gambles[gambleIndex[player]].blockNumber;
		  return;
     }

}  