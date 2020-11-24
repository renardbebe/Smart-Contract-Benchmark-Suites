 

contract RockPaperScissors {
   

   
  modifier OnlyOwner()
  {  
    if (msg.sender != owner) throw;
    _
  }
  
  uint8 public LimitOfMinutes; 
  uint public Cost;
  string public Announcement;

  address owner;
  uint TimeOfLastPriceChange;
  mapping(bytes32=>bet_t) bets;
  uint playerssofar;
  struct bet_t {
    bytes32 OpponentHash;
    address sender;
    uint timestamp;
    int8 Pick;
    bool can_withdraw; 
  }
  bytes32 LastHash;
  
  function RockPaperScissors()
  {
    playerssofar=0;
    owner=msg.sender;
     
    LimitOfMinutes=255;
    Cost=100000000000000000; 
    TimeOfLastPriceChange = now - 255*60;
  }
  function SetInternalValues(uint8 limitofminutes, uint cost)
    OnlyOwner
  {
    LimitOfMinutes=limitofminutes;
    if(Cost!=cost)
      {
	Cost=cost;
	TimeOfLastPriceChange=now;
      }
  }
  function OwnerAnnounce(string announcement)
    OnlyOwner
  {
    Announcement=announcement;
  }
 
  function play(bytes32 HASH)
  {
    if(now < TimeOfLastPriceChange + LimitOfMinutes*60 ||  
       msg.value != Cost ||  
        
       bets[HASH].sender != 0 ||  
       HASH == 0  
       )
      throw;

    bets[HASH].sender=msg.sender;
    bets[HASH].can_withdraw=true;
    if(playerssofar%2 == 1)
      {
	bets[HASH].OpponentHash=LastHash;
	bets[LastHash].OpponentHash=HASH;
      }
    else
      LastHash=HASH;
    bets[HASH].timestamp=now;
    playerssofar++;
  }

  function announce(bytes32 MySecretRand)
  {
    if(msg.value != 0 ||
       bets[sha3(MySecretRand)].can_withdraw==false)
      throw;  
    bets[sha3(MySecretRand)].Pick= int8( uint(MySecretRand)%3 + 1 );
     
     
    bets[sha3(MySecretRand)].timestamp=now;
  }

  function withdraw(bytes32 HASH)
  {  
     
     
     
     
    if(msg.value != 0 || 
       bets[HASH].can_withdraw == false)
      throw;

    if(bets[HASH].OpponentHash!=0 &&  
       bets[bets[HASH].OpponentHash].Pick != 0 &&  
       bets[HASH].Pick != 0  
        
       )
      {
	int8 tmp = bets[HASH].Pick - bets[bets[HASH].OpponentHash].Pick;
	if(tmp==0) 
	  {
	    bets[HASH].can_withdraw=false;
	    if(!bets[HASH].sender.send(Cost*99/100))  
	      throw;
	    else
	      if(!owner.send(Cost/100))
		throw;
	  }
	else if(tmp == 1 || tmp == -2) 
	  {
	    bets[HASH].can_withdraw=false;
	    bets[bets[HASH].OpponentHash].can_withdraw=false;
	    if(!bets[HASH].sender.send(2*Cost*99/100))  
	      throw;	    
	    else
	      if(!owner.send(2*Cost/100))
		throw;
	  }
	else
	  throw;
      }
    else if(bets[HASH].OpponentHash==0 &&  
	    now > bets[HASH].timestamp + LimitOfMinutes*60)
      {
	bets[HASH].can_withdraw=false;
	if(!bets[HASH].sender.send(Cost))  
	  throw;

	 
	--playerssofar;
      }
    else if(bets[HASH].OpponentHash!=0 && 
	    bets[bets[HASH].OpponentHash].Pick == 0 &&  
	    bets[HASH].Pick != 0  
	    ) 
      {
	 
	if( 
	   now > bets[HASH].timestamp + LimitOfMinutes*60 &&
	   now > bets[bets[HASH].OpponentHash].timestamp + LimitOfMinutes*60
	   ) 
	  {
	    bets[HASH].can_withdraw=false;
	    bets[bets[HASH].OpponentHash].can_withdraw=false;
	    if(!bets[HASH].sender.send(2*Cost*99/100)) 
	      throw;
	    else
	      if(!owner.send(2*Cost/100))
		throw;
	  }
	else
	  throw; 
      }
    else
      throw;  
     
     
  }

  function IsPayoutReady__InfoFunction(bytes32 MyHash)
    constant
    returns (string Info) 
  {
     
     
     
     
     
     
     
    if(MyHash == 0)
      return "write your hash";
    if(bets[MyHash].sender == 0) 
      return "you can send this hash and double your ETH!";
    if(bets[MyHash].sender != 0 &&
       bets[MyHash].can_withdraw==false) 
      return "this bet is burned";
    if(bets[MyHash].OpponentHash==0 &&
       now < bets[MyHash].timestamp + LimitOfMinutes*60)
      return "wait for other player";
    if(bets[MyHash].OpponentHash==0)
      return "no one played, use withdraw() for refund";
    
     
    bool timeforaction =
      (now < bets[MyHash].timestamp + LimitOfMinutes*60) ||
      (now < bets[bets[MyHash].OpponentHash].timestamp + LimitOfMinutes*60 );
    
    if(bets[MyHash].Pick == 0 &&
       timeforaction
       )
      return "you can announce your SecretRand";
    if(bets[MyHash].Pick == 0)
      return "you have failed to announce your SecretRand but still you can try before opponent withdraws";
    if(bets[bets[MyHash].OpponentHash].Pick == 0 &&
       timeforaction
       )
      return "wait for opponent SecretRand";


    bool win=false;
    bool draw=false;
    int8 tmp = bets[MyHash].Pick - bets[bets[MyHash].OpponentHash].Pick;
    if(tmp==0) 
      draw=true;
    else if(tmp == 1 || tmp == -2) 
      win=true;
    
    if(bets[bets[MyHash].OpponentHash].Pick == 0 ||
       win
       )
      return "you have won! now you can withdraw your ETH";
    if(draw)
      return "Draw happend! withdraw back your funds";


    return "you have lost, try again";
  }

  function WhatWasMyHash(bytes32 SecretRand)
    constant
    returns (bytes32 HASH) 
  {
    return sha3(SecretRand);
  }

  function CreateHash(uint8 RockPaperOrScissors, string WriteHereSomeUniqeRandomStuff)
    constant
    returns (bytes32 SendThisHashToStart,
	     bytes32 YourSecretRandKey,
	     string Info)
  {
    uint SecretRand;

    SecretRand=3*( uint(sha3(WriteHereSomeUniqeRandomStuff))/3 ) + (RockPaperOrScissors-1)%3;
     
     
     
     

    if(RockPaperOrScissors==0)
      return(0,0, "enter 1 for Rock, 2 for Paper, 3 for Scissors");

    return (sha3(bytes32(SecretRand)),bytes32(SecretRand),  bets[sha3(bytes32(SecretRand))].sender != 0 ? "someone have already used this random string - try another one" :
                                                            SecretRand%3==0 ? "Rock" :
	                                                        SecretRand%3==1 ? "Paper" :
	                                                        "Scissors");
  }

}