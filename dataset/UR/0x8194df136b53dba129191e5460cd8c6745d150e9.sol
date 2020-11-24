 

contract Mortal {
     
    address owner;

     
    constructor() public { owner = msg.sender; }

     
    function kill() public { if (msg.sender == owner) selfdestruct(owner); }
}

contract Greeter is Mortal {
     
    string greeting;

     
    constructor() public {
        greeting = "Well, hello there! I am Gruvin's first Ethereum contract!";
    }

     
    function greet() public constant returns (string) {
        return greeting;
    }
}