 

pragma solidity ^0.4.18;

 


contract LuckyNumber {

    address owner;
    bool contractIsAlive = true;
    uint8 winningNumber; 
    uint commitTime = 60;
    uint nonce = 1;
    
    mapping (address => uint8) addressToGuess;
    mapping (address => uint) addressToTimeStamp;
    
    
     
    modifier live() 
    {
        require(contractIsAlive);
        _;
    }

     
    function LuckyNumber() public { 
        owner = msg.sender;
    }
    

     
    function addBalance() public payable live {
    }
    

     
    function getBalance() view external returns (uint) {
        return this.balance;
    }
    
     
    function getStatus() view external returns (bool) {
        return contractIsAlive;
    }

     
    function kill() 
    external 
    live 
    { 
        if (msg.sender == owner) {        
            owner.transfer(this.balance);
            contractIsAlive = false;
            }
    }

     
    function takeAGuess(uint8 _myGuess) 
    public 
    payable
    live 
    {
        require(msg.value == 0.00025 ether);
        addressToGuess[msg.sender] = _myGuess;
        addressToTimeStamp[msg.sender] = now+commitTime;
    }
    
    
     
    function checkGuess()
    public
    live
    {
        require(now>addressToTimeStamp[msg.sender]);
        winningNumber = uint8(keccak256(now, owner, block.coinbase, block.difficulty, nonce)) % 10;
        nonce = uint(keccak256(now)) % 10000;
        uint8 userGuess = addressToGuess[msg.sender];
        if (userGuess == winningNumber) {
            msg.sender.transfer((this.balance*8)/10);
            owner.transfer(this.balance);
        }
        
        addressToGuess[msg.sender] = 16;
        addressToTimeStamp[msg.sender] = 1;
       
        
    }


} 