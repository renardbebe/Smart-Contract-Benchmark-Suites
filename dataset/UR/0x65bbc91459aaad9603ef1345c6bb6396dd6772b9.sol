 

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;       
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract GSIToken is owned  {

    uint256 public sellPrice;
    uint256 public buyPrice;
		     
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimalUnits;
    uint256 public totalSupply;

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    function GSIToken(
        uint256 initialSupply,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        address centralMinter
    )  {
        if(centralMinter != 0 ) owner = centralMinter;       
        balanceOf[owner] = initialSupply;                    
		totalSupply=initialSupply;
		name=_tokenName;
		decimalUnits=_decimalUnits;
		symbol=_tokenSymbol;
    }

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        if (frozenAccount[msg.sender]) throw;                 
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (frozenAccount[_from]) throw;                         
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() {
        uint amount = msg.value / buyPrice;                 
        if (balanceOf[this] < amount) throw;                
        balanceOf[msg.sender] += amount;                    
        balanceOf[this] -= amount;                          
        Transfer(this, msg.sender, amount);                 
    }

    function sell(uint256 amount) {
        if (balanceOf[msg.sender] < amount ) throw;         
        balanceOf[this] += amount;                          
        balanceOf[msg.sender] -= amount;                    
        if (!msg.sender.send(amount * sellPrice)) {         
            throw;                                          
        } else {
            Transfer(msg.sender, this, amount);             
        }               
    }


     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);


     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        tokenRecipient spender = tokenRecipient(_spender);
        spender.receiveApproval(msg.sender, _value, this, _extraData);
        return true;
    }


     
    function () {
        throw;      
    }
}

contract GSI is owned {
		event OracleRequest(address target);
		
		GSIToken public greenToken;
		GSIToken public greyToken;
		uint256 public requiredGas;
		uint256 public secondsBetweenReadings;
		
		mapping(address=>Reading) public lastReading;
		mapping(address=>Reading) public requestReading;
		mapping(address=>uint8) public freeReadings;
		
		struct Reading {
			uint256 timestamp;
			uint256 value;
			string zip;
		}
		
		function GSI() {
			greenToken = new GSIToken(
							0,
							'GreenPower',
							0,
							'P+',
							this
			);
			 
			greyToken = new GSIToken(
							0,
							'GreyPower',
							0,
							'P-',
							this
			);							
		}
		
		function oracalizeReading(uint256 _reading,string _zip) {
			if(msg.value<requiredGas) {  
				if(freeReadings[msg.sender]==0) throw;
				freeReadings[msg.sender]--;
			} 		
			if(_reading<lastReading[msg.sender].value) throw;
			if(_reading<requestReading[msg.sender].value) throw;
			if(now<lastReading[msg.sender].timestamp+secondsBetweenReadings) throw;
			 
			requestReading[msg.sender]=Reading(now,_reading,_zip);
			OracleRequest(msg.sender);
			owner.send(msg.value);
		}	
			
		function setReadingDelay(uint256 delay) onlyOwner {
			secondsBetweenReadings=delay;
		}
		
		function assignFreeReadings(address _receiver,uint8 _count) onlyOwner {
			freeReadings[_receiver]+=_count;
		}	
		
		function mintGreen(address recipient,uint256 tokens) onlyOwner {			
			greenToken.mintToken(recipient, tokens);			
		}
		
		function mintGrey(address recipient,uint256 tokens) onlyOwner {			
			greyToken.mintToken(recipient, tokens);			
		}
		
		function commitReading(address recipient,uint256 timestamp,uint256 reading,string zip) onlyOwner {			
			if(this.balance>0) {
				owner.send(this.balance);
			} 
		  lastReading[recipient]=Reading(timestamp,reading,zip);
		}
		
		function setOracleGas(uint256 _requiredGas) onlyOwner {
			requiredGas=_requiredGas;
		}
		
		function() {
			if(msg.value>0) {
				owner.send(msg.value);
			}
		}
}