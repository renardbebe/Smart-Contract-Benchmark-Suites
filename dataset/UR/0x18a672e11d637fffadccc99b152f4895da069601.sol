 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract Rouleth
{
     
    address developer;
    uint8 blockDelay;  
    uint8 blockExpiration;  
    uint256 maxGamble;  
    uint256 minGamble;  
    uint maxBetsPerBlock;  
    uint nbBetsCurrentBlock;  
    uint casinoStatisticalLimit;  
     
    uint256 currentMaxGamble; 
     
    enum BetTypes{number, color, parity, dozen, column, lowhigh} 
    struct Gamble
    {
	address player;
        bool spinned;  
	bool win;
	 
        BetTypes betType;
	uint8 input;  
	uint256 wager;
	uint256 blockNumber;  
	uint256 blockSpinned;  
        uint8 wheelResult;
    }
    Gamble[] private gambles;
    uint totalGambles; 
     
    mapping (address=>uint) gambleIndex;  
     
    enum Status {waitingForBet, waitingForSpin} mapping (address=>Status) playerStatus; 


     
     
     

    function  Rouleth() private  
    { 
        developer = msg.sender;
        blockDelay=1;  
	blockExpiration=200;  
        minGamble=50 finney;  
        maxGamble=500 finney;  
        maxBetsPerBlock=5;  
        casinoStatisticalLimit=100;  
    }
    
    modifier onlyDeveloper() 
    {
	if (msg.sender!=developer) throw;
	_
    }
    
    function changeDeveloper_only_Dev(address new_dev)
    noEthSent
    onlyDeveloper
    {
	developer=new_dev;
    }

     
    modifier noEthSent()
    {
        if (msg.value>0) 
	{
	    throw;
	}
        _
    }


     
    enum States{active, inactive} States private contract_state;
    
    function disableBetting_only_Dev()
    noEthSent
    onlyDeveloper
    {
        contract_state=States.inactive;
    }


    function enableBetting_only_Dev()
    noEthSent
    onlyDeveloper
    {
        contract_state=States.active;

    }
    
    modifier onlyActive()
    {
        if (contract_state==States.inactive) throw;
        _
    }



     
    function changeSettings_only_Dev(uint newCasinoStatLimit, uint newMaxBetsBlock, uint256 newMinGamble, uint256 newMaxGamble, uint16 newMaxInvestor, uint256 newMinInvestment,uint256 newMaxInvestment, uint256 newLockPeriod, uint8 newBlockDelay, uint8 newBlockExpiration)
    noEthSent
    onlyDeveloper
    {


         
        if (newCasinoStatLimit<100) throw;
        casinoStatisticalLimit=newCasinoStatLimit;
         
        maxBetsPerBlock=newMaxBetsBlock;
         
        if (newMaxGamble<newMinGamble) throw;  
	else { maxGamble=newMaxGamble; }
         
        if (newMinGamble<0) throw; 
	else { minGamble=newMinGamble; }
         
         
         
        if (newMaxInvestor!=setting_maxInvestors && gambles.length<25000) throw;
        if ( newMaxInvestor<setting_maxInvestors 
             || newMaxInvestor>investors.length) throw;
        else { setting_maxInvestors=newMaxInvestor;}
         
        computeResultVoteExtraInvestFeesRate();
        if (newMaxInvestment<newMinInvestment) throw;
         
        setting_minInvestment=newMinInvestment;
         
        setting_maxInvestment=newMaxInvestment;
         
	 
	 
        if (setting_lockPeriod>360 days) throw; 
        setting_lockPeriod=newLockPeriod;
         
	blockDelay=newBlockDelay;
	if (newBlockExpiration<blockDelay+20) throw;
	blockExpiration=newBlockExpiration;
        updateMaxBet();
    }


     
     
     

     
    mapping (address => string) nicknames;
    function setNickname(string name) 
    noEthSent
    {
        if (bytes(name).length >= 2 && bytes(name).length <= 30)
            nicknames[msg.sender] = name;
    }
    function getNickname(address _address) constant returns(string _name) {
        _name = nicknames[_address];
    }

    
     
     
     

     
     
     
    function () 
    {
	 
	betOnColor(true,false);
    } 

     
     
     
    function updateMaxBet() private
    {
	 
        if (payroll/(casinoStatisticalLimit*35) > maxGamble) 
	{ 
	    currentMaxGamble=maxGamble;
        }
	else
	{ 
	    currentMaxGamble = payroll/(casinoStatisticalLimit*35);
	}
    }


     
     
    function checkBetValue() private returns(uint256 playerBetValue)
    {
        if (msg.value < minGamble) throw;
	if (msg.value > currentMaxGamble)  
	{
            playerBetValue=currentMaxGamble;
	}
        else
        { playerBetValue=msg.value; }
        return;
    }


     
    modifier checkNbBetsCurrentBlock()
    {
        if (gambles.length!=0 && block.number==gambles[gambles.length-1].blockNumber) nbBetsCurrentBlock+=1;
        else nbBetsCurrentBlock=0;
        if (nbBetsCurrentBlock>=maxBetsPerBlock) throw;
        _
    }


     
    function placeBet(BetTypes betType_, uint8 input_) private
    {
	 
	 
	 
	 
	 
	 
	if (playerStatus[msg.sender]!=Status.waitingForBet)
	{
            SpinTheWheel(msg.sender);
	}
         
	playerStatus[msg.sender]=Status.waitingForSpin;
	gambleIndex[msg.sender]=gambles.length;
        totalGambles++;
         
        uint256 betValue = checkBetValue();
	gambles.push(Gamble(msg.sender, false, false, betType_, input_, betValue, block.number, 0, 37));  
	 
        if (betValue<msg.value) 
        {
 	    if (msg.sender.send(msg.value-betValue)==false) throw;
        }
    }


     
    function betOnNumber(uint8 numberChosen)
    onlyActive
    checkNbBetsCurrentBlock
    {
         
        if (numberChosen>36) throw;
        placeBet(BetTypes.number, numberChosen);
    }

     
     
     
     
    function betOnColor(bool Red, bool Black)
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
        placeBet(BetTypes.color, input);
    }

     
     
     
     
    function betOnLowHigh(bool Low, bool High)
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
        placeBet(BetTypes.lowhigh, input);
    }

     
     
     
     
    function betOnOddEven(bool Odd, bool Even)
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
        placeBet(BetTypes.parity, input);
    }


     
     
     
     
     
    function betOnDozen(bool First, bool Second, bool Third)
    {
        betOnColumnOrDozen(First,Second,Third, BetTypes.dozen);
    }


     
     
     
     
     
    function betOnColumn(bool First, bool Second, bool Third)
    {
        betOnColumnOrDozen(First, Second, Third, BetTypes.column);
    }

    function betOnColumnOrDozen(bool First, bool Second, bool Third, BetTypes bet) private
    onlyActive
    checkNbBetsCurrentBlock
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
        placeBet(bet, input);
    }


     
     
     

    event Win(address player, uint8 result, uint value_won, bytes32 bHash, bytes32 sha3Player, uint gambleId);
    event Loss(address player, uint8 result, uint value_loss, bytes32 bHash, bytes32 sha3Player, uint gambleId);

     
     
    function spinTheWheel(address spin_for_player)
    noEthSent
    {
        SpinTheWheel(spin_for_player);
    }


    function SpinTheWheel(address playerSpinned) private
    {
        if (playerSpinned==0)
	{
	    playerSpinned=msg.sender;          
	}

	 
        if (playerStatus[playerSpinned]!=Status.waitingForSpin) throw;
         
        if (gambles[gambleIndex[playerSpinned]].spinned==true) throw;
         
         
	uint playerblock = gambles[gambleIndex[playerSpinned]].blockNumber;
         
	if (block.number<=playerblock+blockDelay) throw;
         
        else if (block.number>playerblock+blockExpiration)  solveBet(playerSpinned, 255, false, 1, 0, 0) ;
	 
        else
	{
	    uint8 wheelResult;
             
            bytes32 blockHash= block.blockhash(playerblock+blockDelay);
             
            if (blockHash==0) throw;
	     
            bytes32 shaPlayer = sha3(playerSpinned, blockHash);
	     
	    wheelResult = uint8(uint256(shaPlayer)%37);
             
	    checkBetResult(wheelResult, playerSpinned, blockHash, shaPlayer);
	}
    }
    

     
    function checkBetResult(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
    {
        BetTypes betType=gambles[gambleIndex[player]].betType;
         
        if (betType==BetTypes.number) checkBetNumber(result, player, blockHash, shaPlayer);
        else if (betType==BetTypes.parity) checkBetParity(result, player, blockHash, shaPlayer);
        else if (betType==BetTypes.color) checkBetColor(result, player, blockHash, shaPlayer);
	else if (betType==BetTypes.lowhigh) checkBetLowhigh(result, player, blockHash, shaPlayer);
	else if (betType==BetTypes.dozen) checkBetDozen(result, player, blockHash, shaPlayer);
        else if (betType==BetTypes.column) checkBetColumn(result, player, blockHash, shaPlayer);
        updateMaxBet();   
    }

     
    function solveBet(address player, uint8 result, bool win, uint8 multiplier, bytes32 blockHash, bytes32 shaPlayer) private
    {
         
        playerStatus[player]=Status.waitingForBet;
        gambles[gambleIndex[player]].wheelResult=result;
        gambles[gambleIndex[player]].spinned=true;
        gambles[gambleIndex[player]].blockSpinned=block.number;
	uint bet_v = gambles[gambleIndex[player]].wager;
	
        if (win)
        {
	    gambles[gambleIndex[player]].win=true;
	    uint win_v = (multiplier-1)*bet_v;
            lossSinceChange+=win_v;
            Win(player, result, win_v, blockHash, shaPlayer, gambleIndex[player]);
             
	     
            if (player.send(win_v+bet_v)==false) throw;
        }
        else
        {
	    Loss(player, result, bet_v-1, blockHash, shaPlayer, gambleIndex[player]);
            profitSinceChange+=bet_v-1;
             
            if (player.send(1)==false) throw;
        }

    }

     
     
     
    function checkBetNumber(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
    {
        bool win;
         
	if (result==gambles[gambleIndex[player]].input)
	{
            win=true;  
        }
        solveBet(player, result,win,36, blockHash, shaPlayer);
    }


     
     
     
    function checkBetParity(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
    {
        bool win;
         
	if (result%2==gambles[gambleIndex[player]].input && result!=0)
	{
            win=true;                
        }
        solveBet(player,result,win,2, blockHash, shaPlayer);
    }
    
     
     
     
    function checkBetLowhigh(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
    {
        bool win;
         
	if (result!=0 && ( (result<19 && gambles[gambleIndex[player]].input==0)
			   || (result>18 && gambles[gambleIndex[player]].input==1)
			 ) )
	{
            win=true;
        }
        solveBet(player,result,win,2, blockHash, shaPlayer);
    }

     
     
     
    uint[18] red_list=[1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36];
    function checkBetColor(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
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
             && ( (gambles[gambleIndex[player]].input==0 && red)  
                  || ( gambles[gambleIndex[player]].input==1 && !red)  ) )
        {
            win=true;
        }
        solveBet(player,result,win,2, blockHash, shaPlayer);
    }

     
     
     
    function checkBetDozen(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
    { 
        bool win;
         
     	if ( result!=0 &&
             ( (result<13 && gambles[gambleIndex[player]].input==0)
     	       ||
               (result>12 && result<25 && gambles[gambleIndex[player]].input==1)
               ||
               (result>24 && gambles[gambleIndex[player]].input==2) ) )
     	{
            win=true;                
        }
        solveBet(player,result,win,3, blockHash, shaPlayer);
    }

     
     
     
    function checkBetColumn(uint8 result, address player, bytes32 blockHash, bytes32 shaPlayer) private
    {
        bool win;
         
        if ( result!=0
             && ( (gambles[gambleIndex[player]].input==0 && result%3==1)  
                  || ( gambles[gambleIndex[player]].input==1 && result%3==2)
                  || ( gambles[gambleIndex[player]].input==2 && result%3==0)  ) )
        {
            win=true;
        }
        solveBet(player,result,win,3, blockHash, shaPlayer);
    }


     


     
    uint256 payroll;
     
    uint256 profitSinceChange;
    uint256 lossSinceChange;
     
    struct Investor
    {
	address investor;
	uint256 time;
    }	
    
    Investor[777] private investors;  
    uint16 setting_maxInvestors = 77;  
     
    mapping (address=>uint256) balance; 
     
     
    uint256 setting_lockPeriod=30 days ;
    uint256 setting_minInvestment=100 ether;  
    uint256 setting_maxInvestment=200 ether;  
    
    event newInvest(address player, uint invest_v, uint net_invest_v);


     
    function invest()
    {
         
        updateBalances();
        uint256 netInvest;
        uint excess;
         
         
        uint16 openPosition=999;
        bool alreadyInvestor;
         
         
        for (uint16 k = 0; k<setting_maxInvestors; k++)
        { 
             
            if (investors[k].investor==0) openPosition=k; 
             
            else if (investors[k].investor==msg.sender)
            {
                alreadyInvestor=true;
                break;
            }
        }
         
        if (!alreadyInvestor)
        {
             
            if (msg.value<setting_minInvestment) throw;
             
             
            if (msg.value>setting_maxInvestment)
            {
                excess=msg.value-setting_maxInvestment;
  		netInvest=setting_maxInvestment;
            }
	    else
	    {
		netInvest=msg.value;
	    }
             
            if (setting_maxInvestors >77 && openPosition<77) throw;
             
            else if (openPosition!=999) investors[openPosition]=Investor(msg.sender, now);
             
            else
            {
                throw;
            }
        }
         
        else
        {
            netInvest=msg.value;
             
	     
            if (balance[msg.sender]+msg.value>setting_maxInvestment)
            {
                throw;
            }
	     
	    if (msg.value<setting_minInvestment/5) throw;
        }

         
         
         
	 
         
        uint256 developmentAllocation;
        developmentAllocation=10*netInvest/100; 
        netInvest-=developmentAllocation;
         
        if (developer.send(developmentAllocation)==false) throw;

	 
	 
	 
	 
	 
        if (setting_maxInvestors>77)
        {
             
             
             
             
            uint256 entryExtraCost=voted_extraInvestFeesRate*netInvest/100;
             
            profitVIP += entryExtraCost;
            netInvest-=entryExtraCost;
        }
        newInvest(msg.sender, msg.value, netInvest); 
        balance[msg.sender]+=netInvest;  
        payroll+=netInvest;  
        updateMaxBet();
         
        if (excess>0) 
        {
            if (msg.sender.send(excess)==false) throw;
        }
    }


     
     
     
     
    function transferInvestorAccount(address newInvestorAccountOwner, address newInvestorAccountOwner_confirm)
    noEthSent
    {
        if (newInvestorAccountOwner!=newInvestorAccountOwner_confirm) throw;
        if (newInvestorAccountOwner==0) throw;
         
        uint16 investorID=999;
        for (uint16 k = 0; k<setting_maxInvestors; k++)
        {
	     
            if (investors[k].investor==newInvestorAccountOwner) throw;

	     
            if (investors[k].investor==msg.sender)
            {
                investorID=k;
            }
        }
        if (investorID==999) throw;  
	else
	     
	     
	     
	{
	    balance[newInvestorAccountOwner]=balance[msg.sender];
	    balance[msg.sender]=0;
            investors[investorID].investor=newInvestorAccountOwner;
	}
    }
    
     
     
     
     
    event withdraw(address player, uint withdraw_v);
    
    function withdrawInvestment(uint256 amountToWithdrawInWei)
    noEthSent
    {
	 
	if (amountToWithdrawInWei!=0 && amountToWithdrawInWei<setting_minInvestment/10) throw;
         
        updateBalances();
	 
	if (amountToWithdrawInWei>balance[msg.sender]) throw;
         
        uint16 investorID=999;
        for (uint16 k = 0; k<setting_maxInvestors; k++)
        {
            if (investors[k].investor==msg.sender)
            {
                investorID=k;
                break;
            }
        }
        if (investorID==999) throw;  
         
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

	     
            delete investors[investorID];
            if (msg.sender.send(fullAmount)==false) throw;
   	    withdraw(msg.sender, fullAmount);
        }
        updateMaxBet();
    }

     
     
    function manualUpdateBalances_only_Dev()
    noEthSent
    onlyDeveloper
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
                uint256 developerFees=profitToSplit*20/100;
                profitToSplit-=developerFees;
                if (developer.send(developerFees)==false) throw;
            }
            else
            {
                lossToSplit=lossSinceChange-profitSinceChange;
            }
            
             
             

            uint totalShared;
            for (uint16 k=0; k<setting_maxInvestors; k++)
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
                    else if (lossToSplit!=0) 
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
            else if (lossToSplit !=0) 
            {
		payroll-=lossToSplit;
		balance[developer]-=lossToSplit-totalShared;
            }
            profitSinceChange=0;  
            lossSinceChange=0;  
        }
    }
    

     
     
    mapping (address=>uint) hundredminus_extraInvestFeesRate;
     
     
    function voteOnNewEntryFees_only_VIP(uint8 extraInvestFeesRate_0_to_99)
    noEthSent
    {
        if (extraInvestFeesRate_0_to_99<1 || extraInvestFeesRate_0_to_99>99) throw;
        hundredminus_extraInvestFeesRate[msg.sender]=100-extraInvestFeesRate_0_to_99;
    }

    uint256 payrollVIP;
    uint256 voted_extraInvestFeesRate;
    function computeResultVoteExtraInvestFeesRate() private
    {
        payrollVIP=0;
        voted_extraInvestFeesRate=0;
         
         
        for (uint8 k=0; k<77; k++)
        {
            if (investors[k].investor==0) continue;
            else
            {
                 
                if (hundredminus_extraInvestFeesRate[investors[k].investor]==0) continue;
                else
                {
                    payrollVIP+=balance[investors[k].investor];
                    voted_extraInvestFeesRate+=hundredminus_extraInvestFeesRate[investors[k].investor]*balance[investors[k].investor];
                }
            }
        }
	 
	    if (payrollVIP!=0)
	    {
            voted_extraInvestFeesRate=100-voted_extraInvestFeesRate/payrollVIP;
     	    }
    }


     
    uint profitVIP;
    function splitProfitVIP_only_Dev()
    noEthSent
    onlyDeveloper
    {
        payrollVIP=0;
         
        for (uint8 k=0; k<77; k++)
        {
            if (investors[k].investor==0) continue;
            else
            {
                payrollVIP+=balance[investors[k].investor];
            }
        }
         
	uint totalSplit;
        for (uint8 i=0; i<77; i++)
        {
            if (investors[i].investor==0) continue;
            else
            {
		uint toSplit=balance[investors[i].investor]*profitVIP/payrollVIP;
                balance[investors[i].investor]+=toSplit;
		totalSplit+=toSplit;
            }
        }
	 
	balance[developer]+=profitVIP-totalSplit;
	payroll+=profitVIP;
	 
        profitVIP=0;
    }

    
     
    function checkProfitLossSinceInvestorChange() constant returns(uint profit_since_update_balances, uint loss_since_update_balances, uint profit_VIP_since_update_balances)
    {
        profit_since_update_balances=profitSinceChange;
        loss_since_update_balances=lossSinceChange;
        profit_VIP_since_update_balances=profitVIP;	
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
    
    function investmentEntryInfos() constant returns(uint current_max_nb_of_investors, uint investLockPeriod, uint voted_Fees_Rate_on_extra_investments)
    {
    	investLockPeriod=setting_lockPeriod;
    	voted_Fees_Rate_on_extra_investments=voted_extraInvestFeesRate;
    	current_max_nb_of_investors=setting_maxInvestors;
    	return;
    }
    
    function getSettings() constant returns(uint maxBet, uint8 blockDelayBeforeSpin)
    {
    	maxBet=currentMaxGamble;
    	blockDelayBeforeSpin=blockDelay;
    	return ;
    }

    function getTotalGambles() constant returns(uint _totalGambles)
    {
        _totalGambles=totalGambles;
    	return ;
    }
    
    function getPayroll() constant returns(uint payroll_at_last_update_balances)
    {
        payroll_at_last_update_balances=payroll;
    	return ;
    }

    
    function checkMyBet(address player) constant returns(Status player_status, BetTypes bettype, uint8 input, uint value, uint8 result, bool wheelspinned, bool win, uint blockNb, uint blockSpin, uint gambleID)
    {
        player_status=playerStatus[player];
        bettype=gambles[gambleIndex[player]].betType;
        input=gambles[gambleIndex[player]].input;
        value=gambles[gambleIndex[player]].wager;
        result=gambles[gambleIndex[player]].wheelResult;
        wheelspinned=gambles[gambleIndex[player]].spinned;
        win=gambles[gambleIndex[player]].win;
        blockNb=gambles[gambleIndex[player]].blockNumber;
        blockSpin=gambles[gambleIndex[player]].blockSpinned;
    	gambleID=gambleIndex[player];
    	return;
    }
    
    function getGamblesList(uint256 index) constant returns(address player, BetTypes bettype, uint8 input, uint value, uint8 result, bool wheelspinned, bool win, uint blockNb, uint blockSpin)
    {
        player=gambles[index].player;
        bettype=gambles[index].betType;
        input=gambles[index].input;
        value=gambles[index].wager;
        result=gambles[index].wheelResult;
        wheelspinned=gambles[index].spinned;
        win=gambles[index].win;
    	blockNb=gambles[index].blockNumber;
        blockSpin=gambles[index].blockSpinned;
    	return;
    }

}  