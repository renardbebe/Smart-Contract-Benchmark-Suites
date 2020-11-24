 

pragma solidity ^0.4.7;
contract TheEthereumLottery {
  
 
 
function TheEthereumLottery()
{
  owner=msg.sender;
  ledger.length=0;
  IndexOfCurrentDraw=0;
  referral_fee=90;
}
modifier OnlyOwner()
{  
  if (msg.sender != owner) throw;
  _;
}
address owner;
string public Announcements; 
uint public IndexOfCurrentDraw; 
uint8 public referral_fee;
mapping(address=>uint256) public referral_ledger;
struct bet_t {
  address referral;
  uint8[4] Nums;
  bool can_withdraw; 
}
struct ledger_t {
  uint8 WinningNum1;
  uint8 WinningNum2;
  uint8 WinningNum3;
  uint8 WinningNum4;
  bytes32 ClosingHash;
  bytes32 OpeningHash;
  mapping(address=>bet_t) bets;
  uint Guess4OutOf4;
  uint Guess3OutOf4;
  uint Guess2OutOf4;
  uint Guess1OutOf4;
  uint PriceOfTicket;
  uint ExpirationTime; 
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
  ledger[IndexOfCurrentDraw].ClosingHash =
     
     
    block.blockhash(block.number-1); 
   
   
   
   
   
   
   
   
   
   
   
  IndexOfCurrentDraw=ledger.length-1;
  ledger[IndexOfCurrentDraw].OpeningHash = new_hash;
  ledger[IndexOfCurrentDraw].Guess4OutOf4=guess4outof4;
  ledger[IndexOfCurrentDraw].Guess3OutOf4=guess3outof4;
  ledger[IndexOfCurrentDraw].Guess2OutOf4=guess2outof4;
  ledger[IndexOfCurrentDraw].Guess1OutOf4=guess1outof4;
  ledger[IndexOfCurrentDraw].PriceOfTicket=priceofticket;
  ledger[IndexOfCurrentDraw].ExpirationTime=now + 2 weeks; 
  NewDrawReadyToPlay(IndexOfCurrentDraw, new_hash, priceofticket, guess4outof4); 
}
function announce_therand(uint32 index,
			  bytes32 the_rand
			  )
OnlyOwner
{
  if(sha3(the_rand)
     !=
     ledger[index].OpeningHash)
    throw; 


  bytes32 combined_rand=sha3(the_rand, ledger[index].ClosingHash); 
   
   

  ledger[index].ClosingHash = combined_rand; 
     
     
     


   
  uint8[4] memory Numbers; 

  uint8 i=0; 
  while(i<4)
    {
      Numbers[i]=uint8(combined_rand); 
      combined_rand>>=8; 
      for(uint j=0;j<i;++j) 
	if(Numbers[j]==Numbers[i]) {--i;break;} 
      ++i;
    }
   
   
   

   
  for(uint8 n=4;n>1;n--) 
    {
      bool sorted=true; 
      for(uint8 k=0;k<n-1;++k)
	if(Numbers[k] > Numbers[k+1]) 
	  {
	    sorted=false;
	    (Numbers[k], Numbers[k+1])=(Numbers[k+1], Numbers[k]);
	  }
      if(sorted) break; 
    }

  
  ledger[index].WinningNum1 = Numbers[0];
  ledger[index].WinningNum2 = Numbers[1];
  ledger[index].WinningNum3 = Numbers[2];
  ledger[index].WinningNum4 = Numbers[3];
  
  DrawReadyToPayout(index,
		    Numbers[0],Numbers[1],Numbers[2],Numbers[3],
		    the_rand); 
}

function PlayReferred(uint8 MyNum1,
		      uint8 MyNum2,
		      uint8 MyNum3,
		      uint8 MyNum4,
		      address ref
		      )
payable
{
  if(msg.value != ledger[IndexOfCurrentDraw].PriceOfTicket || 
     ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[3] != 0) 
    throw;

   
  if(MyNum1 >= MyNum2 ||
     MyNum2 >= MyNum3 ||
     MyNum3 >= MyNum4
     )
    throw; 
  if(ref!=0) 
    ledger[IndexOfCurrentDraw].bets[msg.sender].referral=ref;
  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[0]=MyNum1;
  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[1]=MyNum2;
  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[2]=MyNum3;
  ledger[IndexOfCurrentDraw].bets[msg.sender].Nums[3]=MyNum4;
  ledger[IndexOfCurrentDraw].bets[msg.sender].can_withdraw=true;
}
 
function Play(uint8 MyNum1,
	      uint8 MyNum2,
	      uint8 MyNum3,
	      uint8 MyNum4
	      )
{
  PlayReferred(MyNum1,
	       MyNum2,
	       MyNum3,
	       MyNum4,
	       0 
	       );
}
function Deposit_referral() 
  payable 
{ 
  referral_ledger[msg.sender]+=msg.value;
}
function Withdraw_referral()
{
  uint val=referral_ledger[msg.sender];
  referral_ledger[msg.sender]=0;
  if(!msg.sender.send(val))  
    throw;
}
function set_referral_fee(uint8 new_fee)
OnlyOwner
{
  if(new_fee<50 || new_fee>100)
    throw; 
  referral_fee=new_fee;
}
function Withdraw(uint32 DrawIndex)
{
   
   

  if(ledger[DrawIndex].bets[msg.sender].can_withdraw==false)
    throw; 

   
   
  if(ledger[DrawIndex].WinningNum4 == 0) 
    throw; 
   
  
  uint8 hits=0;
  uint8 i=0;
  uint8 j=0;
  uint8[4] memory playernum=ledger[DrawIndex].bets[msg.sender].Nums;
  uint8[4] memory nums;
  (nums[0],nums[1],nums[2],nums[3])=
    (ledger[DrawIndex].WinningNum1,
     ledger[DrawIndex].WinningNum2,
     ledger[DrawIndex].WinningNum3,
     ledger[DrawIndex].WinningNum4);
   
  
  while(i<4) 
    { 
      while(j<4 && playernum[j] < nums[i]) ++j;
      if(j==4) break; 
      if(playernum[j] == nums[i]) ++hits;
      ++i;
    }
  if(hits==0) throw;
  uint256 win=0;
  if(hits==1) win=ledger[DrawIndex].Guess1OutOf4;
  if(hits==2) win=ledger[DrawIndex].Guess2OutOf4;
  if(hits==3) win=ledger[DrawIndex].Guess3OutOf4;
  if(hits==4) win=ledger[DrawIndex].Guess4OutOf4;
    
  ledger[DrawIndex].bets[msg.sender].can_withdraw=false;
  if(!msg.sender.send(win))  
    throw;

  if(ledger[DrawIndex].bets[msg.sender].referral==0) 
    referral_ledger[owner]+=win/100;
  else
    {
      referral_ledger[ledger[DrawIndex].bets[msg.sender].referral]+=
	win/10000*referral_fee; 
      referral_ledger[owner]+=
	win/10000*(100-referral_fee); 
    }

  
  PlayerWon(win); 
}
function Refund(uint32 DrawIndex)
{
   
   

  if(ledger[DrawIndex].WinningNum4 != 0) 
    throw;  

  if(now < ledger[DrawIndex].ExpirationTime)
    throw; 
  
 
  if(ledger[DrawIndex].bets[msg.sender].can_withdraw==false)
    throw; 
  
  ledger[DrawIndex].bets[msg.sender].can_withdraw=false;
  if(!msg.sender.send(ledger[DrawIndex].PriceOfTicket))  
    throw;
}
 
 
 

function CheckHash(bytes32 TheRand)
  constant returns(bytes32 OpeningHash)
{
  return sha3(TheRand);
}
function MyBet(uint8 DrawIndex, address PlayerAddress)
  constant returns (uint8[4] Nums)
{ 
  return ledger[DrawIndex].bets[PlayerAddress].Nums;
}
function announce(string MSG)
  OnlyOwner
{
  Announcements=MSG;
}
event NewDrawReadyToPlay(uint indexed IndexOfDraw,
			 bytes32 OpeningHash,
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