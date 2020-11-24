 

pragma solidity ^0.4.2;
contract blockcdn {
    mapping (address => uint256) balances;
	mapping (address => uint256) fundValue;
	address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public minFundedValue;
	uint256 public maxFundedValue;
    bool public isFundedMax;
    bool public isFundedMini;
    uint256 public closeTime;
    uint256 public startTime;
    
      
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function blockcdn(
	    address _owner,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
		uint256 _totalSupply,
        uint256 _closeTime,
        uint256 _startTime,
		uint256 _minValue,
		uint256 _maxValue
        ) { 
        owner = _owner;                                       
        name = _tokenName;                                    
        symbol = _tokenSymbol;                                
        decimals = _decimalUnits;                             
        closeTime = _closeTime;                               
		startTime = _startTime;                               
		totalSupply = _totalSupply;                           
		minFundedValue = _minValue;                           
		maxFundedValue = _maxValue;                           
		isFundedMax = false;                                  
		isFundedMini = false;                                 
		balances[owner] = _totalSupply;                       
    }
    
	 
	function () payable {
       buyBlockCDN();
    }
	
     
    function buyBlockCDN() payable returns (bool success){
		if(msg.sender == owner) throw;
        if(now > closeTime) throw; 
        if(now < startTime) throw;
        if(isFundedMax) throw;
        uint256 token = 0;
        if(closeTime - 2 weeks > now) {
             token = msg.value;
        }else {
            uint day = (now - (closeTime - 2 weeks))/(2 days) + 1;
            token = msg.value;
            while( day > 0) {
                token  =   token * 95 / 100 ;    
                day -= 1;
            }
        }
        
        balances[msg.sender] += token;
        if(balances[owner] < token) 
            return false;
        balances[owner] -= token;
        if(this.balance >= minFundedValue) {
            isFundedMini = true;
        }
        if(this.balance >= maxFundedValue) {
            isFundedMax = true;   
        }
		fundValue[msg.sender] += msg.value;
        Transfer(owner, msg.sender, token);    
        return true;
    }    
    
      
    function balanceOf( address _owner) constant returns (uint256 value)
    {
        return balances[_owner];
    }
	
	 
	function balanceOfFund(address _owner) constant returns (uint256 value)
	{
		return fundValue[_owner];
	}

     
    function reFund() payable returns (bool success) {
        if(now <= closeTime) throw;     
		if(isFundedMini) throw;             
		uint256 value = fundValue[msg.sender];
		fundValue[msg.sender] = 0;
		if(value <= 0) throw;
        if(!msg.sender.send(value)) 
            throw;
        balances[owner] +=  balances[msg.sender];
        balances[msg.sender] = 0;
        Transfer(msg.sender, this, balances[msg.sender]); 
        return true;
    }

	
	 
	function reFundByOther(address _fundaddr) payable returns (bool success) {
	    if(now <= closeTime) throw;    
		if(isFundedMini) throw;           
		uint256 value = fundValue[_fundaddr];
		fundValue[_fundaddr] = 0;
		if(value <= 0) throw;
        if(!_fundaddr.send(value)) throw;
        balances[owner] += balances[_fundaddr];
        balances[_fundaddr] = 0;
        Transfer(msg.sender, this, balances[_fundaddr]); 
        return true;
	}

    
     
    function transfer(address _to, uint256 _value) payable returns (bool success) {
        if(_value <= 0 ) throw;                                       
		if (balances[msg.sender] < _value) throw;                     
        if (balances[_to] + _value < balances[_to]) throw;            
		if(now < closeTime ) {										  
			if(_to == address(this)) {
				fundValue[msg.sender] -= _value;
				balances[msg.sender] -= _value;
				balances[owner] += _value;
				if(!msg.sender.send(_value))
					return false;
				Transfer(msg.sender, _to, _value); 							 
				return true;      
			}
		} 										
		
		balances[msg.sender] -= _value;                           
		balances[_to] += _value;                                  
		 
		Transfer(msg.sender, _to, _value); 							 
		return true;      
    }
    
     
    function sendRewardBlockCDN(address rewarder, uint256 value) payable returns (bool success) {
        if(msg.sender != owner) throw;
		if(now <= closeTime) throw;        
		if(!isFundedMini) throw;               
        if( balances[owner] < value) throw;
        balances[rewarder] += value;
        uint256 halfValue  = value / 2;
        balances[owner] -= halfValue;
        totalSupply +=  halfValue;
        Transfer(owner, rewarder, value);    
        return true;
       
    }
    
    function modifyStartTime(uint256 _startTime) {
		if(msg.sender != owner) throw;
        startTime = _startTime;
    }
    
    function modifyCloseTime(uint256 _closeTime) {
		if(msg.sender != owner) throw;
       closeTime = _closeTime;
    }
    
     
    function withDrawEth(uint256 value) payable returns (bool success) {
        if(now <= closeTime ) throw;
        if(!isFundedMini) throw;
        if(this.balance < value) throw;
        if(msg.sender != owner) throw;
        if(!msg.sender.send(value))
            return false;
        return true;
    }
}