 

contract SimpleCoinFlipGame {
    event FlippedCoin(address msgSender, uint msgValue, int coinsFlipped);
    
    int public coinsFlipped = 422;
    int public won = 253;
    int public lost = 169;
    address private owner = msg.sender;
     
     
     

    function flipTheCoinAndWin() {
        var randomNumber = (uint(sha3(msg.gas)) + uint(coinsFlipped)) % 10;
        
         
         
         
        
        FlippedCoin(msg.sender, msg.value, coinsFlipped++);
        
         
        if(msg.value > 42000000000000000){
            msg.sender.send(msg.value - 100000);
            won++;
            return;   
        }
        
        if(randomNumber < 4) {
            msg.sender.send(2 * (msg.value - 100000));
            won++;
            return;
        } 
        lost++;
    } 
    
    function terminate() onlyByOwner { 
            suicide(owner); 
    }
    
    modifier onlyByOwner() {
        if (msg.sender != owner)
            throw;
        _
    }
}