 

pragma solidity 0.4.8;


contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    
}


contract token {
     
    string public standard = 'AdsCash 0.1';
    string public name;                                  
    string public symbol;                                
    uint8  public decimals;                               

     
    mapping (address => uint256) public balanceOf;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function token(
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
    }

    

     
    function () {
        throw;      
    }
}

 contract ProgressiveToken is owned, token {
    uint256 public constant totalSupply=30000000000;           
    uint256 public reward;                                     
    uint256 internal coinBirthTime=now;                        
    uint256 public currentSupply;                            
    uint256 internal initialSupply;                            
    uint256 public sellPrice;                                  
    uint256 public buyPrice;                                   
    bytes32 internal currentChallenge;                         
    uint public timeOfLastProof;                               
    uint internal difficulty = 10**32;                           
    
    mapping  (uint256 => uint256) rewardArray;                   
   

     
    function ProgressiveToken(
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        uint256 initialSupply,
        uint256 sellPrice,
        uint256 buyPrice,
        address centralMinter                                  
    ) token ( tokenName, decimalUnits, tokenSymbol) {
        if(centralMinter != 0 ) owner = centralMinter;     
                                                           
        balanceOf[owner] = initialSupply;                 
	timeOfLastProof = now;                            
	setPrices(sellPrice,buyPrice);                    
        currentSupply=initialSupply;                      
        reward=22380;                          
        for(uint256 i=0;i<12;i++){                        
            rewardArray[i]=reward;
            reward=reward/2;
        }
        reward=getReward(now);
    }
    
    
    
  
    
    function getReward (uint currentTime) constant returns (uint256) {
        uint elapsedTimeInSeconds = currentTime - coinBirthTime;          
        uint elapsedTimeinMonths= elapsedTimeInSeconds/(30*24*60*60);     
        uint period=elapsedTimeinMonths/3;                                
        return rewardArray[period];                                       
    }

    function updateCurrentSupply() private {
        currentSupply+=reward;
    }

   

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;                           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;                 
        reward=getReward(now);                                               
        if(currentSupply + reward > totalSupply ) throw;                     
        balanceOf[msg.sender] -= _value;                                     
        balanceOf[_to] += _value;                                            
        Transfer(msg.sender, _to, _value);                                   
        updateCurrentSupply();
        balanceOf[block.coinbase] += reward;
    }



    function mintToken(address target, uint256 mintedAmount) onlyOwner {
            if(currentSupply + mintedAmount> totalSupply) throw;              
            currentSupply+=(mintedAmount);                                    
            balanceOf[target] += mintedAmount;                                
            Transfer(0, owner, mintedAmount);
            Transfer(owner, target, mintedAmount);
    }




    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;           
        buyPrice = newBuyPrice;             
    }
    
   function buy() payable returns (uint amount){
        amount = msg.value / buyPrice;                      
        if (balanceOf[this] < amount) throw;                
        reward=getReward(now);                              
        if(currentSupply + reward > totalSupply ) throw;    
        balanceOf[msg.sender] += amount;                    
        balanceOf[this] -= amount;                          
        balanceOf[block.coinbase]+=reward;                  
        updateCurrentSupply();                              
        Transfer(this, msg.sender, amount);                 
        return amount;                                      
    }

    function sell(uint amount) returns (uint revenue){
        if (balanceOf[msg.sender] < amount ) throw;         
        reward=getReward(now);                              
        if(currentSupply + reward > totalSupply ) throw;    
        balanceOf[this] += amount;                          
        balanceOf[msg.sender] -= amount;                    
        balanceOf[block.coinbase]+=reward;                  
        updateCurrentSupply();                              
        revenue = amount * sellPrice;                       
        if (!msg.sender.send(revenue)) {                    
            throw;                                          
        } else {
            Transfer(msg.sender, this, amount);             
            return revenue;                                 
        }
    }



    
    
    function proofOfWork(uint nonce){
        bytes8 n = bytes8(sha3(nonce, currentChallenge));     
        if (n < bytes8(difficulty)) throw;                    
    
        uint timeSinceLastProof = (now - timeOfLastProof);    
        if (timeSinceLastProof <  5 seconds) throw;           
        reward=getReward(now);                                
        if(currentSupply + reward > totalSupply ) throw;      
        updateCurrentSupply();                                
        balanceOf[msg.sender] += reward;                       
        difficulty = difficulty * 12 seconds / timeSinceLastProof + 1;   
        timeOfLastProof = now;                                 
        currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number-1));   
    }

}