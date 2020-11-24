 

pragma solidity ^0.4.13;
contract owned {
     
    address public owner;  
    function owned() { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner); _; }
    function transferOwnership(address newOwner) onlyOwner { owner = newOwner; }
}
contract token { 
     
    string  public name;         
    string  public symbol;       
    uint8   public decimals;     
    uint256 public totalSupply;  

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function token(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) {
        balanceOf[msg.sender] = initialSupply;  
        totalSupply           = initialSupply;  
        name                  = tokenName;      
        symbol                = tokenSymbol;    
        decimals              = decimalUnits;   
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                
        require(balanceOf[_from] > _value);                 
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[_from] -= _value;  
        balanceOf[_to]   += _value;  
        Transfer(_from, _to, _value);  
    }

     
     
     
    function transfer(address _to, uint256 _value) {
        _transfer(msg.sender, _to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);  
        allowance[_from][msg.sender] -= _value;  
        _transfer(_from, _to, _value);  
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;  
        return true;
    }
}

contract BSCToken is owned, token {
     
    uint256 public sellPrice         = 5000000000000000;   
    uint256 public buyPrice          = 10000000000000000;  
    bool    public closeBuy          = false;              
    bool    public closeSell         = false;              
    uint256 public tokensAvailable   = balanceOf[this];    
    uint256 public distributedTokens = 0;                  
    uint256 public solvency          = this.balance;       
    uint256 public profit            = 0;                  

     
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
     
    event LogDeposit(address sender, uint amount);
     
    event LogMigration(address receiver, uint amount);
     
    event LogWithdrawal(address receiver, uint amount);

     
    function BSCToken( uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol ) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                
        require(balanceOf[_from] >= _value);                
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                     
        require(!frozenAccount[_to]);                       
        
        balanceOf[_from] -= _value;  
        balanceOf[_to]   += _value;  

        _updateTokensAvailable(balanceOf[this]);  
        
        Transfer(_from, _to, _value);  
    }

     
    function _updateTokensAvailable(uint256 _tokensAvailable) internal {
        tokensAvailable = _tokensAvailable;
    }

     
    function _updateSolvency(uint256 _solvency) internal {
        solvency = _solvency;
    }

     
    function _updateProfit(uint256 _increment, bool add) internal{
        if (add){
             
            profit = profit + _increment;
        }else{
             
            if(_increment > profit){
                profit = 0;
            }else{
                profit = profit - _increment;
            }
        }
    }

     
     
     
    function completeMigration(address _to, uint256 _value) onlyOwner payable{
        require( msg.value >= (_value * sellPrice) );        
        require((this.balance + msg.value) > this.balance);  
        
         
        _updateSolvency(this.balance);    
        _updateProfit(msg.value, false);  
         

        _transfer(msg.sender, _to, _value);  
        distributedTokens = distributedTokens + _value;  

        LogMigration( _to, _value);  
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;  
        totalSupply       += mintedAmount;  

        _updateTokensAvailable(balanceOf[this]);  
        
        Transfer(0, this, mintedAmount);       
        Transfer(this, target, mintedAmount);  
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;  
        FrozenFunds(target, freeze);  
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;  
        buyPrice = newBuyPrice;    
    }

     
     
     
    function setStatus(bool isClosedBuy, bool isClosedSell) onlyOwner {
        closeBuy = isClosedBuy;    
        closeSell = isClosedSell;  
    }

     
    function deposit() payable returns(bool success) {
        require((this.balance + msg.value) > this.balance);  
        
         
        _updateSolvency(this.balance);    
        _updateProfit(msg.value, false);  
         
         

        LogDeposit(msg.sender, msg.value);  
        return true;
    }

     
     
    function withdraw(uint amountInWeis) onlyOwner {
        LogWithdrawal(msg.sender, amountInWeis);  
        _updateSolvency( (this.balance - amountInWeis) );  
        _updateProfit(amountInWeis, true);                 
        owner.transfer(amountInWeis);  
    }

     
    function buy() payable {
        require(!closeBuy);  
        uint amount = msg.value / buyPrice;  
        uint256 profit_in_transaction = msg.value - (amount * sellPrice);  
        require( profit_in_transaction > 0 );

         
        _transfer(this, msg.sender, amount);  
        distributedTokens = distributedTokens + amount;  
        _updateSolvency(this.balance - profit_in_transaction);    
        _updateProfit(profit_in_transaction, true);               
        owner.transfer(profit_in_transaction);  
    }

     
     
    function sell(uint256 amount) {
        require(!closeSell);  
        require(this.balance >= amount * sellPrice);  
        
        _transfer(msg.sender, this, amount);  
        distributedTokens = distributedTokens - amount;  
        _updateSolvency( (this.balance - (amount * sellPrice)) );  
        msg.sender.transfer(amount * sellPrice);  
    }
}