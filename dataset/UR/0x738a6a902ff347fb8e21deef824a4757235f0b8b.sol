 

pragma solidity ^0.4.11;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 decimalPalces
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimalPalces);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalPalces;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);        
        require(balanceOf[_from] >= _value);        
        require(balanceOf[_to] + _value > balanceOf[_to]);        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];        
        balanceOf[_from] -= _value;        
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

 
 
 

contract utility
{
    event check1(uint256 val1);
    function calculateEthers(uint numberOfTokens, uint price, uint _decimalValue) constant internal returns(uint ethers)
    {
        ethers = numberOfTokens*price;
        ethers = ethers / 10**_decimalValue;
        check1(ethers);
        return (ethers);
    }
    
    function calculateTokens(uint _amount, uint _rate, uint _decimalValue) constant internal returns(uint tokens, uint excessEthers) 
    {
        tokens = _amount*10**_decimalValue;
        tokens = tokens/_rate;
        excessEthers = _amount-((tokens*_rate)/10**_decimalValue);
        return (tokens, excessEthers);
    } 
    
   
    function decimalAdjustment(uint _amount, uint _decimalPlaces) constant internal returns(uint adjustedValue)
    {
        uint diff = 18-_decimalPlaces;
        uint adjust = 1*10**diff;
       
        adjustedValue = _amount/adjust;
       
        return adjustedValue;       
    }
   
     
     
     
}

 
 
 

contract TokenNWTC is owned, TokenERC20, utility {
    
    event check(uint256 val1);
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    address[] frzAcc;
    address[] users;
    address[] frzAcc1;
    address[] users1;
    uint256 sellTokenAmount;

    bool emergencyFreeze;        

    mapping (address => bool) public frozenAccount;
    mapping (uint => address) public tokenUsers;

     
    event FrozenFunds(address target, bool frozen);

     
    function TokenNWTC(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 decimalPalces
    ) TokenERC20(initialSupply, tokenName, tokenSymbol, decimalPalces) public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                 
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        require(!emergencyFreeze);                           
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
        sellTokenAmount += _value;
        
        if (users.length>0){
                uint count=0;
            for (uint a=0;a<users.length;a++)
            {
            if (users[a]==_to){
            count=count+1;
            }
            }
            if (count==0){
                users.push(_to);
            }
                 
        }
        else{
            users.push(_to);
        }
    }
    

     
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
         
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
        sellTokenAmount += mintedAmount;
        
         if (users.length>0){
                uint count1=0;
            for (uint a=0;a<users.length;a++)
            {
            if (users[a]==target){
            count1=count1+1;
            }
            }
            if (count1==0){
                users.push(target);
            }
                 
        }
        else{
            users.push(target);
        }
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
         
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
        if (frzAcc.length>0){
                uint count=0;
            for (uint a=0;a<frzAcc.length;a++)
            {
            if (frzAcc[a]==target){
            count=count+1;
            }
            }
            if (count==0){
                frzAcc.push(target);
            }
        }
        else{
            frzAcc.push(target);
        }
    }

    function freezeAllAccountInEmergency(bool freezeAll) onlyOwner public
    {
        emergencyFreeze = freezeAll;    
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        require(newSellPrice!=0 || sellPrice!=0);
        require(newBuyPrice!=0 || buyPrice!=0); 
        if(newSellPrice!=0)
        {
            sellPrice = newSellPrice;
        }
        if(newBuyPrice!=0)
        {
            buyPrice = newBuyPrice;
        }
    }

     
    function buy() payable public {
        require(msg.value!=0);
        require(buyPrice!=0);
        uint exceededEthers;
        uint amount = msg.value;                                 
        (amount, exceededEthers) = calculateTokens(amount, buyPrice, decimals);
        require(amount!=0);
        _transfer(this, msg.sender, amount);               
        msg.sender.transfer(exceededEthers); 
        
        
        
        if (users.length>0){
                uint count=0;
            for (uint a=0;a<users.length;a++)
            {
            if (users[a]==msg.sender){
            count=count+1;
            }
            }
            if (count==0){
                users.push(msg.sender);
            }
                 
        }
        else{
            users.push(msg.sender);
        }
        
        
    }

     
     
     
    function sell(uint256 amount) public {
        require(amount!=0);
        require(sellPrice!=0);
        uint etherAmount;
        etherAmount = calculateEthers(amount, sellPrice, decimals);
        require(this.balance >= etherAmount);            
        _transfer(msg.sender, this, amount);      
        check(etherAmount);
        msg.sender.transfer(etherAmount);                
    }


    function readAllUsers()constant returns(address[]){
	      
	      
	          for (uint k=0;k<users.length;k++){
	              if (balanceOf[users[k]]>0){
	                  users1.push(users[k]);
	              }
	          }
	      
       return users1;
   }
   
   function readAllFrzAcc()constant returns(address[]){
       for (uint k=0;k<frzAcc.length;k++){
	              if (frozenAccount[frzAcc[k]] == true){
	                  frzAcc1.push(frzAcc[k]);
	              }
	          }
       return frzAcc1;
   }
   
   function readSellTokenAmount()constant returns(uint256){
       return sellTokenAmount;
   }
   
   
 
 
 
 
   
 

 
 
 
 
 
 
 
 
 
 

 
 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 

 

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
    
     
    function getTokenName() constant public returns (string)
    {
        return name;
    }
    
     
    function getTokenSymbol() constant public returns (string)
    {
        return symbol;
    }

     
    function getSpecifiedDecimal() constant public returns (uint)
    {
        return decimals;
    }

     
    function getTotalSupply() constant public returns (uint)
    {
        return totalSupply;
    }
    
}