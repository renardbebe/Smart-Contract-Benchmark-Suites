 

pragma solidity ^0.4.8;

contract Rouleth
{
   
  address public developer;
  uint8 public blockDelay;  
  uint8 public blockExpiration;  
  uint256 public maxGamble;  
  uint256 public minGamble;  
  uint public maxBetsPerBlock;  
  uint nbBetsCurrentBlock;  

    
   
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
  uint public totalGambles; 
   
  mapping (address=>uint) gambleIndex;  
   
  enum Status {waitingForBet, waitingForSpin} mapping (address=>Status) playerStatus; 


   
   
   

  function  Rouleth()  
  { 
    developer = msg.sender;
    blockDelay=0;  
    blockExpiration=200;  
    minGamble=50 finney;  
    maxGamble=750 finney;  
    maxBetsPerBlock=5;  
  }
    
  modifier onlyDeveloper() 
  {
    if (msg.sender!=developer) throw;
    _;
  }

  function addBankroll()
    onlyDeveloper
    payable {
  }

  function removeBankroll(uint256 _amount_wei)
    onlyDeveloper
  {
    if (!developer.send(_amount_wei)) throw;
  }
    
  function changeDeveloper_only_Dev(address new_dev)
    onlyDeveloper
  {
    developer=new_dev;
  }


   
  enum States{active, inactive} States private contract_state;
    
  function disableBetting_only_Dev()
    onlyDeveloper
  {
    contract_state=States.inactive;
  }


  function enableBetting_only_Dev()
    onlyDeveloper
  {
    contract_state=States.active;

  }
    
  modifier onlyActive()
  {
    if (contract_state==States.inactive) throw;
    _;
  }



   
  function changeSettings_only_Dev(uint newMaxBetsBlock, uint256 newMinGamble, uint256 newMaxGamble, uint8 newBlockDelay, uint8 newBlockExpiration)
    onlyDeveloper
  {
     
    maxBetsPerBlock=newMaxBetsBlock;
     
    if (newMaxGamble<newMinGamble) throw;  
    maxGamble=newMaxGamble; 
    minGamble=newMinGamble;
     
    blockDelay=newBlockDelay;
    if (newBlockExpiration < blockDelay + 250) throw;
    blockExpiration=newBlockExpiration;
  }


   
   
   

   
   
   
  function ()
    payable
    {
       
      betOnColor(false);
    } 

   
   
  function checkBetValue() private returns(uint256)
  {
    uint256 playerBetValue;
    if (msg.value < minGamble) throw;
    if (msg.value > maxGamble){
      playerBetValue = maxGamble;
    }
    else{
      playerBetValue=msg.value;
    }
    return playerBetValue;
  }


   
  modifier checkNbBetsCurrentBlock()
  {
    if (gambles.length!=0 && block.number==gambles[gambles.length-1].blockNumber) nbBetsCurrentBlock+=1;
    else nbBetsCurrentBlock=0;
    if (nbBetsCurrentBlock>=maxBetsPerBlock) throw;
    _;
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
     
    if (betValue < msg.value) 
      {
	if (msg.sender.send(msg.value-betValue)==false) throw;
      }
  }


   
  function betOnNumber(uint8 numberChosen)
    payable
    onlyActive
    checkNbBetsCurrentBlock
  {
     
    if (numberChosen>36) throw;
    placeBet(BetTypes.number, numberChosen);
  }

   
   
   
   
  function betOnColor(bool Black)
    payable
    onlyActive
    checkNbBetsCurrentBlock
  {
    uint8 input;
    if (!Black) 
      { 
	input=0;
      }
    else{
      input=1;
    }
    placeBet(BetTypes.color, input);
  }

   
   
   
   
  function betOnLowHigh(bool High)
    payable
    onlyActive
    checkNbBetsCurrentBlock
  {
    uint8 input;
    if (!High) 
      { 
	input=0;
      }
    else 
      {
	input=1;
      }
    placeBet(BetTypes.lowhigh, input);
  }

   
   
   
   
  function betOnOddEven(bool Odd)
    payable
    onlyActive
    checkNbBetsCurrentBlock
  {
    uint8 input;
    if (!Odd) 
      { 
	input=0;
      }
    else{
      input=1;
    }
    placeBet(BetTypes.parity, input);
  }

   
   
   
   
   
  function betOnDozen(uint8 dozen_selected_0_1_2)
    payable
    onlyActive
    checkNbBetsCurrentBlock
  {
    if (dozen_selected_0_1_2 > 2) throw;
    placeBet(BetTypes.dozen, dozen_selected_0_1_2);
  }


   
   
   
   
   
  function betOnColumn(uint8 column_selected_0_1_2)
    payable
    onlyActive
    checkNbBetsCurrentBlock
  {
    if (column_selected_0_1_2 > 2) throw;
    placeBet(BetTypes.column, column_selected_0_1_2);
  }

   
   
   

  event Win(address player, uint8 result, uint value_won, bytes32 bHash, bytes32 sha3Player, uint gambleId, uint bet);
  event Loss(address player, uint8 result, uint value_loss, bytes32 bHash, bytes32 sha3Player, uint gambleId, uint bet);

   
   
  function spinTheWheel(address spin_for_player)
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
	 
	bytes32 shaPlayer = sha3(playerSpinned, blockHash, this);
	 
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
	Win(player, result, win_v, blockHash, shaPlayer, gambleIndex[player], bet_v);
	 
	 
	if (player.send(win_v+bet_v)==false) throw;
      }
    else
      {
	Loss(player, result, bet_v-1, blockHash, shaPlayer, gambleIndex[player], bet_v);
	 
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