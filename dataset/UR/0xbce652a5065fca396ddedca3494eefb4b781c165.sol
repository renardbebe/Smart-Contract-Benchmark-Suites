 

 

pragma solidity ^0.4.10;





contract Fortune {
  string[] private fortunes;

  function Fortune( string initialFortune ) public {
    addFortune( initialFortune );
  }

  function addFortune( string fortune ) public {
    fortunes.push( fortune );

    FortuneAdded( msg.sender, fortune );
  }

  function drawFortune() public constant returns ( string fortune ) {
    fortune = fortunes[ shittyRandom() % fortunes.length ];
  }

  function shittyRandom() private constant returns ( uint number ) {
    number = uint( block.blockhash( block.number - 1 ) );  	   
  }

  event FortuneAdded( address author, string fortune );	
}