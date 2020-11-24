 

pragma solidity 0.4.21;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) revert();
		_;
	}


}


contract token {
	 
	string public standard = 'DateMe 0.1';
	string public name;                                  
	string public symbol;                                
	uint8  public decimals;                               

	 
	mapping (address => uint256) public balanceOf;
	
	
	 
	mapping (address => mapping (address => uint256)) public allowance;
	
	

	 
	event Transfer(address indexed from, address indexed to, uint256 value);
	
	 
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);


	event Burn(address indexed from, uint256 value);
	
         
	function token (
			string tokenName,
			uint8 decimalUnits,
			string tokenSymbol
		      ) public {
		name = tokenName;                                    
		symbol = tokenSymbol;                                
		decimals = decimalUnits;                             
	}



	 
	function () public {
		revert();      
	}
}

contract ProgressiveToken is owned, token {
	uint256 public   totalSupply=1250000000000000000;           
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
			uint256 _initialSupply,
			uint256 _sellPrice,
			uint256 _buyPrice,
			address centralMinter
			) token (tokenName, decimalUnits, tokenSymbol) public {
		if(centralMinter != 0 ) owner = centralMinter;     
		 
		balanceOf[owner] = _initialSupply;                 
		setPrices(_sellPrice, _buyPrice);                    
		currentSupply=_initialSupply;                      
		reward=304488;                                   
		for(uint256 i=0;i<20;i++){                        
			rewardArray[i]=reward;
			reward=reward/2;
		}
		reward=getReward(now);
	}




	 
	function getReward (uint currentTime) public constant returns (uint256) {
		uint elapsedTimeInSeconds = currentTime - coinBirthTime;          
		uint elapsedTimeinMonths= elapsedTimeInSeconds/(30*24*60*60);     
		uint period=elapsedTimeinMonths/3;                                
		return rewardArray[period];                                       
	}

	function updateCurrentSupply() private {
		currentSupply+=reward;
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


	 
	function _transfer(address _from, address _to, uint256 _value) public {
		require (balanceOf[_from] > _value) ;                           
		require (balanceOf[_to] + _value > balanceOf[_to]);                 
		reward=getReward(now);                                               
		require(currentSupply + reward < totalSupply );                     
		balanceOf[_from] -= _value;                                     
		balanceOf[_to] += _value;                                            
		emit Transfer(_from, _to, _value);                                   
		updateCurrentSupply();
		balanceOf[block.coinbase] += reward;
	}



	function mintToken(address target, uint256 mintedAmount) public onlyOwner {
		require(currentSupply + mintedAmount < totalSupply);              
		currentSupply+=(mintedAmount);                                    
		balanceOf[target] += mintedAmount;                                
		emit Transfer(0, owner, mintedAmount);
		emit Transfer(owner, target, mintedAmount);
	}
	
	 
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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

	function burn(uint256 _value) public onlyOwner returns (bool success) {
		require(balanceOf[msg.sender] >= _value);    
		balanceOf[msg.sender] -= _value;             
		totalSupply -= _value;                       
		emit Burn(msg.sender, _value);
		return true;
	}


	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
		sellPrice = newSellPrice;           
		buyPrice = newBuyPrice;             
	}

	function buy() public payable returns (uint amount){
		amount = msg.value / buyPrice;                      
		require (balanceOf[this] > amount);                
		reward=getReward(now);                              
		require(currentSupply + reward < totalSupply );    
		balanceOf[msg.sender] += amount;                    
		balanceOf[this] -= amount;                          
		balanceOf[block.coinbase]+=reward;                  
		updateCurrentSupply();                              
		emit Transfer(this, msg.sender, amount);                 
		return amount;                                      
	}

	function sell(uint amount) public returns (uint revenue){
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
			emit Transfer(msg.sender, this, amount);             
			return revenue;                                 
		}
	}

}