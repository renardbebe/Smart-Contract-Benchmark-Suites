 

 
pragma solidity ^0.4.18;
 

contract MyAdvancedToken8  {
    address public owner;
    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event Deposit(address from, uint256 value);


     
    string public standard = 'ERC-Token 1.0';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    

    function transferOwnership(address newOwner) public {
        if (msg.sender != owner) revert();
        owner = newOwner;
    }

     
    function approve(address _spender, uint256 _value) public 
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


     
    function MyAdvancedToken8(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) public
    {
        owner = msg.sender;
        
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
    }
    
     
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        if (frozenAccount[msg.sender]) revert();                 
        balanceOf[msg.sender] -= _value;                         
        balanceOf[_to] += _value;                                
        Transfer(msg.sender, _to, _value);                       
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (frozenAccount[_from]) revert();                         
        if (balanceOf[_from] < _value) revert();                  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        if (_value > allowance[_from][msg.sender]) revert();    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) public {
        if (msg.sender != owner) revert();
        
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public {
        if (msg.sender != owner) revert();
        
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public {
        if (msg.sender != owner) revert();
        
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;                 
        if (balanceOf[this] < amount) revert();              
        balanceOf[msg.sender] += amount;                    
        balanceOf[this] -= amount;                          
        Transfer(this, msg.sender, amount);                 
    }

    function sell(uint256 amount) public {
        bool sendSUCCESS = false;
        if (balanceOf[msg.sender] < amount ) revert();         
        balanceOf[this] += amount;                          
        balanceOf[msg.sender] -= amount;                    
        
        
        sendSUCCESS = msg.sender.send(amount * sellPrice);
        if (!sendSUCCESS) {                                      
            revert();                                            
        } else {
            Transfer(msg.sender, this, amount);                  
        }               
    }
    
     
	function() payable public {
		 
		if (msg.value > 0)
			Deposit(msg.sender, msg.value);
	}
    
    
}