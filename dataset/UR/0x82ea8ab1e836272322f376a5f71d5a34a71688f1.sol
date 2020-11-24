 

 

pragma solidity ^0.4.10;

contract Fortune {
  string[] public fortunes;  

  function Fortune( string initialFortune ) public {
    addFortune( initialFortune );
  }

  function addFortune( string fortune ) public {
    fortunes.push( fortune );

    FortuneAdded( msg.sender, fortune );
  }

  function drawFortune() public view returns ( string fortune ) {
    fortune = fortunes[ shittyRandom() % fortunes.length ];
  }

  function countFortunes() public view returns ( uint count ) {
    count = fortunes.length;	   
  }

  function shittyRandom() private view returns ( uint number ) {
    number = uint( block.blockhash( block.number - 1 ) );  	   
  }

  event FortuneAdded( address author, string fortune );	
}