 

pragma solidity ^0.4.16;
contract owned {
    address public owner;
    function owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }	
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
    string public name = "DIVMGroup";
    string public symbol = "DIVM";
    uint8 public decimals = 18;
	uint256 public initialSupply = 10000;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    function TokenERC20() public {
    totalSupply = initialSupply * 1 ether;
    balanceOf[msg.sender] = totalSupply;
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

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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
contract MyAdvancedToken is owned, TokenERC20 {
	address public beneficiary;
	address public reserveFund;
	address public Bounty;
    uint256 public sellPriceInWei;
    uint256 public buyPriceInWei;
	uint256 public Limit;
	uint256 public issueOfTokens;
    bool    public TokenSaleStop = false;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
	
    function MyAdvancedToken()  public {
	beneficiary = 0xe0C3c3FBA6D9793EDCeA6EA18298Fe22310Ed094;
	Bounty = 0xC87bB60EB3f7052f66E60BB5d961Eeffee1A8765;
	reserveFund = 0x60ab253bD32429ACD4242f14F54A8e50E233c0C5;
	}

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               
        require (balanceOf[_from] > _value);               
        require (balanceOf[_to] + _value > balanceOf[_to]); 
        require(!frozenAccount[_from]);                    
        require(!frozenAccount[_to]);                       
        balanceOf[_from] -= _value;                        
        balanceOf[_to] += _value;                          
        Transfer(_from, _to, _value);
    }
	
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner  public  {
	    require (!TokenSaleStop);
        require (mintedAmount <= 7000000 * 1 ether - totalSupply);
        require (totalSupply + mintedAmount <= 7000000 * 1 ether); 
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
		issueOfTokens = totalSupply / 1 ether - initialSupply;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newLimit) onlyOwner public {
        sellPriceInWei = newSellPrice;
        buyPriceInWei = newBuyPrice;
		Limit = newLimit;
    }

     
    function () payable public {
	    require (msg.value * Limit / 1 ether > 1);
	    require (!TokenSaleStop);
        uint amount = msg.value * 1 ether / buyPriceInWei;               
        _transfer(this, msg.sender, amount);
        if (this.balance > 2 ether) {
		Bounty.transfer(msg.value / 40);}		
		if (this.balance > 10 ether) {
		reserveFund.transfer(msg.value / 7);}
    }

    function forwardFunds(uint256 withdraw) onlyOwner public {
	     require (withdraw > 0);
         beneficiary.transfer(withdraw * 1 ether);  
  }
	
     
     
    function sell(uint256 amount) public {
	    require (amount > Limit);
	    require (!TokenSaleStop);
        require(this.balance >= amount * sellPriceInWei);       
        _transfer(msg.sender, this, amount * 1 ether);              
        msg.sender.transfer(amount * sellPriceInWei);          
    }
    	  
  function crowdsaleStop(bool Stop) onlyOwner public {
      TokenSaleStop = Stop;
  }
}