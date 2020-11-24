 

pragma solidity ^0.4.13;
 
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    
}


contract token {
     
    string public standard = 'BixCoin 0.1';
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
        revert();      
    }
}

contract ProgressiveToken is owned, token {
    uint256 public constant totalSupply=2100000000000;           
    uint256 public reward;                                     
    uint256 internal coinBirthTime=now;                        
    uint256 public currentSupply;                            
    uint256 internal initialSupply;                            
    uint256 public sellPrice;                                  
    uint256 public buyPrice;                                   
    
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
	setPrices(sellPrice,buyPrice);                    
        currentSupply=initialSupply;                      
        reward=837139;                                   
        for(uint256 i=0;i<20;i++){                        
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
        require (balanceOf[msg.sender] > _value) ;                           
        require (balanceOf[_to] + _value > balanceOf[_to]);                 
        reward=getReward(now);                                               
        require(currentSupply + reward < totalSupply );                     
        balanceOf[msg.sender] -= _value;                                     
        balanceOf[_to] += _value;                                            
        Transfer(msg.sender, _to, _value);                                   
        updateCurrentSupply();
        balanceOf[block.coinbase] += reward;
    }



    function mintToken(address target, uint256 mintedAmount) onlyOwner {
            require(currentSupply + mintedAmount < totalSupply);              
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
        require (balanceOf[this] > amount);                
        reward=getReward(now);                              
        require(currentSupply + reward < totalSupply );    
        balanceOf[msg.sender] += amount;                    
        balanceOf[this] -= amount;                          
        balanceOf[block.coinbase]+=reward;                  
        updateCurrentSupply();                              
        Transfer(this, msg.sender, amount);                 
        return amount;                                      
    }

    function sell(uint amount) returns (uint revenue){
        require (balanceOf[msg.sender] > amount );         
        reward=getReward(now);                              
        require(currentSupply + reward < totalSupply );    
        balanceOf[this] += amount;                          
        balanceOf[msg.sender] -= amount;                    
        balanceOf[block.coinbase]+=reward;                  
        updateCurrentSupply();                              
        revenue = amount * sellPrice;                       
        if (!msg.sender.send(revenue)) {                    
            revert();                                          
        } else {
            Transfer(msg.sender, this, amount);             
            return revenue;                                 
        }
    }

}