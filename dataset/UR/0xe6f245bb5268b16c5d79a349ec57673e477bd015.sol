 

pragma solidity ^0.4.0;
 
contract AddressLotteryV2{
    struct SeedComponents{
        uint component1;
        uint component2;
        uint component3;
        uint component4;
    }
    
    address owner;
    uint private secretSeed;
    uint private lastReseed;
    
    uint winnerLuckyNumber = 7;
    
    uint public ticketPrice = 1 ether;
        
    address owner2;
        
    mapping (address => bool) participated;

    modifier onlyOwner() {
        require(msg.sender == owner||msg.sender==owner2);
        _;
    }
  
    modifier onlyHuman() {
        require(msg.sender == tx.origin);
        _;
    }
    
    function AddressLotteryV2(address _owner2) {
        owner = msg.sender;
        owner2 = _owner2;
        reseed(SeedComponents(12345678, 0x12345678, 0xabbaeddaacdc, 0x22222222));
    }
    
    function setTicketPrice(uint newPrice) onlyOwner {
        ticketPrice = newPrice;
    }
    
    function participate() payable onlyHuman { 
        require(msg.value >= ticketPrice);
        
         
        if(!participated[msg.sender]){
        
        if ( luckyNumberOfAddress(msg.sender) == winnerLuckyNumber)
        {
            participated[msg.sender] = true;
            require(msg.sender.call.value(this.balance)());
        }
            
        }
    }
    
    function luckyNumberOfAddress(address addr) constant returns(uint n){
         
        n = uint(keccak256(uint(addr), secretSeed)[0]) % 8;
    }
    
    function reseed(SeedComponents components) internal{
        secretSeed = uint256(keccak256(
            components.component1,
            components.component2,
            components.component3,
            components.component4
        ));
        lastReseed = block.number;
    }
    
    function kill() onlyOwner {
        suicide(owner);
    }
    
    function forceReseed() onlyOwner{
        SeedComponents s;
        s.component1 = uint(owner);
        s.component2 = uint256(block.blockhash(block.number - 1));
        s.component3 = block.number * 1337;
        s.component4 = tx.gasprice * 7;
        reseed(s);
    }
    
    function () payable {}
    
     
    function _myLuckyNumber() constant returns(uint n){
        n = luckyNumberOfAddress(msg.sender);
    }
}