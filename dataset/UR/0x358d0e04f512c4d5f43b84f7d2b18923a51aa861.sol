 

pragma solidity ^0.4.24;

contract PixelFactory {
    address public contractOwner;
    uint    public startPrice = 0.1 ether;
    bool    public isInGame = false;
    uint    public finishTime;
    
    uint    public lastWinnerId;
    address public lastWinnerAddress;

    constructor() public {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    struct Pixel {
        uint price;
    }

    Pixel[] public pixels;

    mapping(uint => address) pixelToOwner;
    mapping(address => string) ownerToUsername;

     
    event Username(string username);
    
    function setUsername(string username) public {
        ownerToUsername[msg.sender] = username;
        emit Username(username);
    }
    
    function getUsername() public view returns(string) {
        return ownerToUsername[msg.sender];
    }

     
     
    function startGame() public onlyOwner {
        require(isInGame == false);
        isInGame = true;
        finishTime = 86400 + now;
    }
    
    function sendOwnerCommission() public payable onlyOwner {
        contractOwner.transfer(msg.value);
    } 
     
    function _sendWinnerJackpot(address winner) private {
        uint jackpot = 10 ether;
        winner.transfer(jackpot);
    } 
    
     
    function getFinishTime() public view returns(uint) {
        return finishTime;
    }
    
    function getLastWinner() public view returns(uint id, address addr) {
        id = lastWinnerId;
        addr = lastWinnerAddress;
    }
    
    function _rand(uint min, uint max) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(now)))%(min+max)-min;
    }
    
     
    function finisGame() public onlyOwner {
        require(isInGame == true);
        isInGame = false;
        finishTime = 0;

         
        uint winnerId = _rand(0, 399);
        lastWinnerId = winnerId;
        
         
        address winnerAddress = pixelToOwner[winnerId];
        lastWinnerAddress = winnerAddress;
        
         
        _sendWinnerJackpot(winnerAddress);
        
         
        delete pixels;
    }
    
     
    function createPixels(uint amount) public onlyOwner {
         
        require(pixels.length + amount <= 400);
        
         
        
         
        for(uint i=0; i<amount; i++) {
            uint id = pixels.push(Pixel(startPrice)) - 1;
            pixelToOwner[id] = msg.sender;
        }
    }

    function getAllPixels() public view returns(uint[], uint[], address[]) {
        uint[]    memory id           = new uint[](pixels.length);
        uint[]    memory price        = new uint[](pixels.length);
        address[] memory owner        = new address[](pixels.length);

        for (uint i = 0; i < pixels.length; i++) {
            Pixel storage pixel = pixels[i];
            
            id[i]           = i;
            price[i]        = pixel.price;
            owner[i]        = pixelToOwner[i];
        }

        return (id, price, owner);
    }

    function _checkPixelIdExists(uint id) private constant returns(bool) {
        if(id < pixels.length) return true;
        return false;
    }

    function _transfer(address to, uint id) private {
        pixelToOwner[id] = to;
    }

    function buy(uint id) external payable {
         
        require(_checkPixelIdExists(id) == true);

         
        Pixel storage pixel = pixels[id];
        uint currentPrice = pixel.price;
        address currentOwner = pixelToOwner[id];
        address newOwner = msg.sender;
        
         
        require(currentPrice == msg.value);
        
         
        require(currentOwner != msg.sender);

         
        uint newPrice = currentPrice * 2;
        pixel.price = newPrice;

         
        if(currentOwner != contractOwner) {
            currentOwner.transfer(msg.value);
        }
        
         
        _transfer(newOwner, id);
    }
}