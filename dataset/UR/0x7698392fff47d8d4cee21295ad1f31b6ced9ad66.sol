 

contract TheEthereumLottery {
  
 


  
 
function TheEthereumLottery()
{
  owner=msg.sender;
  ledger.length=0;
}
modifier OnlyOwner()
{  
  if (msg.sender != owner) throw;
  _
}
address owner;
string public Announcements; 
uint public IndexOfCurrentDraw; 
struct bet_t {
  uint8[4] Nums;
  bool can_withdraw; 
}
struct ledger_t {
  uint8 WinningNum1;
  uint8 WinningNum2;
  uint8 WinningNum3;
  uint8 WinningNum4;
  bytes32 TheRand;
  bytes32 TheHash;
  mapping(address=>bet_t) bets;
  uint Guess4OutOf4;
  uint Guess3OutOf4;
  uint Guess2OutOf4;
  uint Guess1OutOf4;
  uint PriceOfTicket;
  uint ExpirencyTime; 
}
ledger_t[] public ledger;
 
 
 
 
function next_draw(bytes32 new_hash,
	  uint priceofticket,
	  uint guess4outof4,
	  uint guess3outof4,
	  uint guess2outof4,
	  uint guess1outof4
	  )
OnlyOwner
{
  ledger.length++;
  IndexOfCurrentDraw=ledger.length-1;
  ledger[IndexOfCurrentDraw].TheHash = new_hash;
  ledger[IndexOfCurrentDraw].Guess4OutOf4=guess4outof4;
  ledger[IndexOfCurrentDraw].Guess3OutOf4=guess3outof4;
  ledger[IndexOfCurrentDraw].Guess2OutOf4=guess2outof4;
  ledger[IndexOfCurrentDraw].Guess1OutOf4=guess1outof4;
  ledger[IndexOfCurrentDraw].PriceOfTicket=priceofticket;
  ledger[IndexOfCurrentDraw].ExpirencyTime=now + 2 weeks; 

  NewDrawReadyToPlay(IndexOfCurrentDraw, new_hash, priceofticket, guess4outof4); 
}
function announce_numbers(uint8 no1,
			  uint8 no2,
			  uint8 no3,
			  uint8 no4,
			  uint32 index,
			  bytes32 the_rand
			  )
OnlyOwner
{
  ledger[index].WinningNum1 = no1;
  ledger[index].WinningNum2 = no2;
  ledger[index].WinningNum3 = no3;
  ledger[index].WinningNum4 = no4;
  ledger[index].TheRand = the_rand;

  DrawReadyToPayout(index,
		    no1, no2, no3, no4,
		    the_rand); 
}
function Play(uint8 MyNum1,
	      uint8 MyNum2,
	      uint8 MyNum3,
	      uint8 MyNum4
	      )
{
  if(msg.value != ledger[IndexOfCurrentDraw].PriceOfTicket || 
     ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[3] != 0) 
    throw;

   
  if(MyNum1 >= MyNum2 ||
     MyNum2 >= MyNum3 ||
     MyNum3 >= MyNum4
     )
    throw; 

  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[0]=MyNum1;
  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[1]=MyNum2;
  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[2]=MyNum3;
  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[3]=MyNum4;
  ledger[IndexOfCurrentDraw].bets[msg.sender].can_withdraw=true;


   
   
   

  
}
	
function Withdraw(uint32 DrawNumber)
{
  if(msg.value!=0)
    throw; 

  if(ledger[DrawNumber].bets[msg.sender].can_withdraw==false)
    throw; 

   
   
  if(ledger[DrawNumber].WinningNum4==0) 
    throw; 
   
   

  
  uint8 hits=0;
  uint8 i=0;
  uint8 j=0;
  uint8[4] memory playernum=ledger[DrawNumber].bets[msg.sender].Nums;
  uint8[4] memory nums;
  (nums[0],nums[1],nums[2],nums[3])=
    (ledger[DrawNumber].WinningNum1,
     ledger[DrawNumber].WinningNum2,
     ledger[DrawNumber].WinningNum3,
     ledger[DrawNumber].WinningNum4);
   
  
  while(i<4) 
    { 
      while(j<4 && playernum[j] < nums[i]) ++j;
      if(j==4) break; 
      if(playernum[j] == nums[i]) ++hits;
      ++i;
    }
  if(hits==0) throw;
  uint256 win=0;
  if(hits==1) win=ledger[DrawNumber].Guess1OutOf4;
  if(hits==2) win=ledger[DrawNumber].Guess2OutOf4;
  if(hits==3) win=ledger[DrawNumber].Guess3OutOf4;
  if(hits==4) win=ledger[DrawNumber].Guess4OutOf4;
    
  ledger[DrawNumber].bets[msg.sender].can_withdraw=false;
  if(!msg.sender.send(win))  
    throw;
  PlayerWon(win); 
  if(!owner.send(win/100))
    throw; 
}
function Refund(uint32 DrawNumber)
{
  if(msg.value!=0)
    throw; 

  if(
     sha3( ledger[DrawNumber].WinningNum1,
	   ledger[DrawNumber].WinningNum2,
	   ledger[DrawNumber].WinningNum3,
	   ledger[DrawNumber].WinningNum4,
	   ledger[DrawNumber].TheRand)
     ==
     ledger[DrawNumber].TheHash ) throw;
   

  if(now < ledger[DrawNumber].ExpirencyTime)
    throw; 
  
 
  if(ledger[DrawNumber].bets[msg.sender].can_withdraw==false)
    throw; 
  
  ledger[DrawNumber].bets[msg.sender].can_withdraw=false;
  if(!msg.sender.send(ledger[DrawNumber].PriceOfTicket))  
    throw;
}
 
 
 

function CheckHash(uint8 Num1,
		   uint8 Num2,
		   uint8 Num3,
		   uint8 Num4,
		   bytes32 TheRandomValue
		   )
  constant returns(bytes32 TheHash)
{
  return sha3(Num1, Num2, Num3, Num4, TheRandomValue);
}
function MyBet(uint8 DrawNumber, address PlayerAddress)
  constant returns (uint8[4] Nums)
{ 
  return ledger[DrawNumber].bets[PlayerAddress].Nums;
}
function announce(string MSG)
  OnlyOwner
{
  Announcements=MSG;
}
event NewDrawReadyToPlay(uint indexed IndexOfDraw,
			 bytes32 TheHash,
			 uint PriceOfTicketInWei,
			 uint WeiToWin);
event DrawReadyToPayout(uint32 indexed IndexOfDraw,
			uint8 WinningNumber1,
			uint8 WinningNumber2,
			uint8 WinningNumber3,
			uint8 WinningNumber4,
			bytes32 TheRand);
event PlayerWon(uint Wei);


			      

} 