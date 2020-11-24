 

 

pragma solidity ^0.4.18;





contract PingPong {
  string private last;
  uint private pong_count;

  function PingPong() public {
    last = "";
    pong_count = 0;
  }

  event Pinged( string payload );
  event Ponged( uint indexed count, string payload );

  function ping( string payload ) public {
    last = payload;

    Pinged( payload );
  }

  function pong() public {
    pong_count += 1;

    Ponged( pong_count, last );
  }

  function count() public view returns (uint n) {
    n = pong_count;
  }
}