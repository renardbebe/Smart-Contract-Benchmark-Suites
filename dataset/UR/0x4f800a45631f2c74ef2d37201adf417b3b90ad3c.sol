 

pragma solidity ^0.4.13;

contract owned {
     
    address public owner;  
    function owned() internal {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner); _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        owner = newOwner;
    }
}

contract token { 
     
    string  public name;         
    string  public symbol;       
    uint8   public decimals;     
    uint256 public totalSupply;  

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function token(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) internal {
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

     
     
     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);  
        allowance[_from][msg.sender] -= _value;  
        _transfer(_from, _to, _value);  
        return true;
    }

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;  
        return true;
    }
}

contract HormitechToken is owned, token {
     
    uint256 public sellPrice         = 5000000000000000;   
    uint256 public buyPrice          = 10000000000000000;  
    bool    public closeBuy          = false;              
    bool    public closeSell         = false;              
    uint256 public tokensAvailable   = balanceOf[this];    
    uint256 public solvency          = this.balance;       
    uint256 public profit            = 0;                  
    address public comisionGetter = 0xCd8bf69ad65c5158F0cfAA599bBF90d7f4b52Bb0;  
    mapping (address => bool) public frozenAccount;  

     
    event FrozenFunds(address target, bool frozen);
     
    event LogDeposit(address sender, uint amount);
     
    event LogWithdrawal(address receiver, uint amount);

     
    function HormitechToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) public token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

     
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

    function refillTokens(uint256 _value) public onlyOwner{
         
        _transfer(msg.sender, this, _value);
    }

     
    function transfer(address _to, uint256 _value) public {
    	 
        uint market_value = _value * sellPrice;
        uint comision = market_value * 4 / 1000;
         
        require(this.balance >= comision);
        comisionGetter.transfer(comision);  
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);  
         
        uint market_value = _value * sellPrice;
        uint comision = market_value * 4 / 1000;
         
        require(this.balance >= comision);
        comisionGetter.transfer(comision);  
        allowance[_from][msg.sender] -= _value;  
        _transfer(_from, _to, _value);  
        return true;
    }

     
    function _updateTokensAvailable(uint256 _tokensAvailable) internal { tokensAvailable = _tokensAvailable; }

     
    function _updateSolvency(uint256 _solvency) internal { solvency = _solvency; }

     
    function _updateProfit(uint256 _increment, bool add) internal{
        if (add){
             
            profit = profit + _increment;
        }else{
             
            if(_increment > profit){ profit = 0; }
            else{ profit = profit - _increment; }
        }
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;  
        totalSupply       += mintedAmount;  
        _updateTokensAvailable(balanceOf[this]);  
        Transfer(0, this, mintedAmount);       
        Transfer(this, target, mintedAmount);  
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;  
        FrozenFunds(target, freeze);  
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;  
        buyPrice = newBuyPrice;    
    }

     
     
     
    function setStatus(bool isClosedBuy, bool isClosedSell) onlyOwner public {
        closeBuy = isClosedBuy;    
        closeSell = isClosedSell;  
    }

     
    function deposit() payable public returns(bool success) {
        require((this.balance + msg.value) > this.balance);  
         
        _updateSolvency(this.balance);    
        _updateProfit(msg.value, false);  
         
         
        LogDeposit(msg.sender, msg.value);  
        return true;
    }

     
     
    function withdraw(uint amountInWeis) onlyOwner public {
        LogWithdrawal(msg.sender, amountInWeis);  
        _updateSolvency( (this.balance - amountInWeis) );  
        _updateProfit(amountInWeis, true);                 
        owner.transfer(amountInWeis);  
    }

     
    function buy() public payable {
        require(!closeBuy);  
        uint amount = msg.value / buyPrice;  
        uint market_value = amount * buyPrice;  
        uint comision = market_value * 4 / 1000;  
        uint profit_in_transaction = market_value - (amount * sellPrice) - comision;  
        require(this.balance >= comision);  
        comisionGetter.transfer(comision);  
        _transfer(this, msg.sender, amount);  
        _updateSolvency((this.balance - profit_in_transaction));  
        _updateProfit(profit_in_transaction, true);  
        owner.transfer(profit_in_transaction);  
    }

     
     
    function sell(uint256 amount) public {
        require(!closeSell);  
        uint market_value = amount * sellPrice;  
        uint comision = market_value * 4 / 1000;  
        uint amount_weis = market_value + comision;  
        require(this.balance >= amount_weis);  
        comisionGetter.transfer(comision);  
        _transfer(msg.sender, this, amount);  
        _updateSolvency( (this.balance - amount_weis) );  
        msg.sender.transfer(market_value);  
    }

     
    function () public payable { buy(); }
}