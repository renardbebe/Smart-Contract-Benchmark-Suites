 

pragma solidity ^0.4.16;
 
  
 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
 
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner == 0x0) throw;
        owner = newOwner;
    }
}
 
 
contract SafeMath {
   

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}
 
contract GemstoneToken is owned, SafeMath {
	
	string 	public EthernetCashWebsite	= "https://ethernet.cash";
	address public EthernetCashAddress 	= this;
	address public creator 				= msg.sender;
    string 	public name 				= "Gemstone Token";
    string 	public symbol 				= "GST";
    uint8 	public decimals 			= 18;											    
    uint256 public totalSupply 			= 19999999986000000000000000000;
    uint256 public buyPrice 			= 18000000;
	uint256 public sellPrice 			= 18000000;
   	
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
	mapping (address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);				
    event FundTransfer(address backer, uint amount, bool isContribution);
      
    event Burn(address indexed from, uint256 value);
	event FrozenFunds(address target, bool frozen);
    
     
    function GemstoneToken() public {
        balanceOf[msg.sender] = totalSupply;    											
		creator = msg.sender;
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
     
    function () payable internal {
        uint amount = msg.value * buyPrice ; 
		uint amountRaised;
		uint bonus = 0;
		
		bonus = getBonus(amount);
		amount = amount +  bonus;
		
		 
		
        require(balanceOf[creator] >= amount);               				
        require(msg.value > 0);
		amountRaised = safeAdd(amountRaised, msg.value);                    
		balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);     
        balanceOf[creator] = safeSub(balanceOf[creator], amount);           
        Transfer(creator, msg.sender, amount);               				
        creator.transfer(amountRaised);
    }
	
	 
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

	
	 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
	
     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
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
	
	function getBonus(uint _amount) constant private returns (uint256) {
        
		if(now >= 1524873600 && now <= 1527551999) { 
            return _amount * 50 / 100;
        }
		
		if(now >= 1527552000 && now <= 1530316799) { 
            return _amount * 40 / 100;
        }
		
		if(now >= 1530316800 && now <= 1532995199) { 
            return _amount * 30 / 100;
        }
		
		if(now >= 1532995200 && now <= 1535759999) { 
            return _amount * 20 / 100;
        }
		
		if(now >= 1535760000 && now <= 1538438399) { 
            return _amount * 10 / 100;
        }
		
        return 0;
    }
	
	 
     
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(amount * sellPrice);           
    }
	
 }
 