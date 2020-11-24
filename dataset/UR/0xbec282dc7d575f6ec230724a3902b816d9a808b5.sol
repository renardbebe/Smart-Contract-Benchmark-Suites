 

 
 
pragma solidity ^0.5.12;

contract PotLike {
    function drip() external;
}

contract JugLike {
    function drip(bytes32) external;
}

contract OsmLike {
    function poke() external;
    function pass() external view returns (bool);
}

contract SpotLike {
    function poke(bytes32) external;
}

contract MegaPoker {
    OsmLike constant public eth = OsmLike(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
    OsmLike constant public bat = OsmLike(0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6);
    PotLike constant public pot = PotLike(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugLike constant public jug = JugLike(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotLike constant public spot = SpotLike(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    function poke() external {
        if (eth.pass()) eth.poke();
        if (bat.pass()) bat.poke();
        spot.poke("ETH-A");
        spot.poke("BAT-A");
        jug.drip("ETH-A");
        jug.drip("BAT-A");
        pot.drip();
    }
}