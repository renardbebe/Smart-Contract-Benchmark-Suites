 

contract Ethereum_doubler
{

string[8] hexComparison;							 
string hexcomparisonchr;
string A;
uint8 i;
uint8 lotteryticket;
address creator;
int lastgainloss;
string lastresult;
uint lastblocknumberused;
bytes32 lastblockhashused;
uint8 hashLastNumber;
address player;
uint8 result; 
uint128 wager; 
uint8 lowOrHigh;  
uint8 HashtoLowOrHigh; 
 

   function  Ethereum_doubler() private 
    { 
        creator = msg.sender; 								
    }

  function Set_your_game_number(string Set_your_game_number_L_or_H)			 
 {	result=0;
    	A=Set_your_game_number_L_or_H ;
     	uint128 wager = uint128(msg.value); 
	comparisonchr(A);
	inputToDigit(i);
	checkHash();
	changeHashtoLowOrHigh(hashLastNumber);
 	checkBet();
	returnmoneycreator(result,wager);
}

 

    function comparisonchr(string A) private					 
    {    hexComparison= ["L", "l", "H", "h", "K","N.A.","dummy","0 or F"];
	for (i = 0; i < 6; i ++) 
{

	hexcomparisonchr=hexComparison[i];

    

	bytes memory a = bytes(hexcomparisonchr);
 	bytes memory b = bytes(A);
        
          
        
          if (a[0]==b[0])
              return ;

}}

function inputToDigit(uint i) private
{
if(i==0 || i==1)
{lowOrHigh=0;
return;}
else if (i==2 ||i==3)
{lowOrHigh=2;
return;}
else if (i==4)
{lowOrHigh=4;
return;}
else if (i==6)
{lowOrHigh=6;}
return;}

	function checkHash() private
{
   	lastblocknumberused = (block.number-1)  ;				 
    	lastblockhashused = block.blockhash(lastblocknumberused);		 

    	
    	hashLastNumber=uint8(lastblockhashused & 0xf);				 
}

	function changeHashtoLowOrHigh(uint  hashLastNumber) private
{
	if (hashLastNumber>0 && hashLastNumber<8)
	{HashtoLowOrHigh=0;
	return;}
	else if (hashLastNumber>7 && hashLastNumber<15)
	{HashtoLowOrHigh=2;
	return;}
	else
	{HashtoLowOrHigh=7;
	lastresult = "0 or F, house wins";
	return;} 
	
 
	 
}

 

	function checkBet() private

 { 
	lotteryticket=lowOrHigh;
	player=msg.sender;
        
                
    
  		  
    	if(msg.value > (this.balance/4))					 
    	{
    		lastresult = "Bet is too large. Maximum bet is the game balance/4.";
    		lastgainloss = 0;
    		msg.sender.send(msg.value);  
    		return;
    	}
	else if(msg.value <100000000000000000)					 
    	{
    		lastresult = "Minimum bet is 0.1 eth";
    		lastgainloss = 0;
    		msg.sender.send(msg.value);  
    		return;

	}
    	else if (msg.value == 0)
    	{
    		lastresult = "Bet was zero";
    		lastgainloss = 0;
    		 
    		return;
    	}
    		
    	uint128 wager = uint128(msg.value);          				 
    	
 

   	 if(lotteryticket==6)							 
	{
	lastresult = "give a character L or H ";
	msg.sender.send(msg.value);
	lastgainloss=0;
	
	return;
	}

	else if (lotteryticket==4 && msg.sender == creator)			 
	{
		suicide(creator);} 

	else if(lotteryticket != HashtoLowOrHigh)
	{
	    	lastgainloss = int(wager) * -1;
	    	lastresult = "Loss";
	    	result=1;
	    									 
	    	return;
	}
	    else if(lotteryticket==HashtoLowOrHigh)
	{
	    	lastgainloss =(2*wager);
	    	lastresult = "Win!";
	    	msg.sender.send(wager * 2); 
		return;			 					 
	} 	
    }

	function returnmoneycreator(uint8 result,uint128 wager) private		 
	{
	if (result==1&&this.balance>50000000000000000000)
	{creator.send(wager);
	return; 
	}
 
	else if
	(
	result==1&&this.balance>20000000000000000000)				 
	{creator.send(wager/2);
	return; }
	}
 
 
 
 	function Results_of_the_last_round() constant returns (string last_result,string Last_player_s_lottery_ticket,address last_player,string The_right_lottery_number,int Player_s_gain_or_Loss_in_Wei,string info)
    { 
   	last_player=player;	
	Last_player_s_lottery_ticket=hexcomparisonchr;
	The_right_lottery_number=hexComparison[HashtoLowOrHigh];
	last_result=lastresult;
	Player_s_gain_or_Loss_in_Wei=lastgainloss;
	info = "The right lottery number is decided by the last character of the most recent blockhash available during the game. 1-7 =Low, 8-e =High. One Eth is 10**18 Wei.";
	
 
    }

 	function Last_block_number_and_blockhash_used() constant returns (uint last_blocknumber_used,bytes32 last_blockhash_used)
    {
        last_blocknumber_used=lastblocknumberused;
	last_blockhash_used=lastblockhashused;


    }
    
   
	function Game_balance_in_Ethers() constant returns (uint balance, string info)
    { 
        info = "Game balance is shown in full Ethers";
    	balance=(this.balance/10**18);

    }
    
   
}