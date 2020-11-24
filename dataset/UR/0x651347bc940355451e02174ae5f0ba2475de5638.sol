 

pragma solidity 0.4.19;

 
contract Per_Annum{
	string public symbol = "ANNUM";
	string public name = "Per Annum";
	uint8 public constant decimals = 8;
	uint256 _totalSupply = 0;
	address contract_owner;
	uint256 current_remaining = 0;  
	uint256 _maxTotalSupply = 1600000000000000;  
	uint256 _miningReward = 10000000000;  
	uint256 _maxMiningReward = 100000000000000;  
	uint256 _year = 1514782800;  
	uint256 _year_count = 2018;  
	uint256 _currentMined = 0;  


	event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

     
    function Per_Annum(){
    	_totalSupply += 25000000000000;
    	_currentMined += 25000000000000;	
    	contract_owner = msg.sender;
    	balances[msg.sender] += 25000000000000;
    	Transfer(this,msg.sender,25000000000000);
    }

	function totalSupply() constant returns (uint256) {        
		return _totalSupply;
	}

	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}


	function transfer(address _to, uint256 _amount) returns (bool success) {
		if (balances[msg.sender] >= _amount 
			&& _amount > 0
			&& balances[_to] + _amount > balances[_to]) {
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
		} else {
            return false;
		}
	}

	function transferFrom(
		address _from,
		address _to,
		uint256 _amount
	) returns (bool success) {
		if (balances[_from] >= _amount
			&& allowed[_from][msg.sender] >= _amount
			&& _amount > 0
			&& balances[_to] + _amount > balances[_to]) {
			balances[_from] -= _amount;
			allowed[_from][msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(_from, _to, _amount);
			return true;
		} else {
			return false;
		}
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}
	 
	function is_leap_year() private{
		if(now >= _year + 31557600){	
			_year = _year + 31557600;	 
			_year_count = _year_count + 1;  
			_currentMined = 0;	 
			if(((_year_count-2018)%4 == 0) && (_year_count != 2018)){
				_maxMiningReward = _maxMiningReward/2;  
				_miningReward = _maxMiningReward/10000;   

			}
			if((_year_count%4 == 1) && ((_year_count-1)%100 != 0)){
				_year = _year + 86400;	 
				

			}
			else if((_year_count-1)%400 == 0){
				_year = _year + 86400;  

			}
 
		}	

	}


	function date_check() private returns(bool check_newyears){

		is_leap_year();  
		 
	    if((_year <= now) && (now <= (_year + 1209600))){
			return true;	 
		}
		else{
			return false;  
		}
	}
	
	function mine() returns(bool success){
		if(date_check() != true){
			current_remaining = _maxMiningReward - _currentMined; 
			if((current_remaining > 0) && (_currentMined != 0)){
				_currentMined += current_remaining;
				balances[contract_owner] += current_remaining;
				Transfer(this, contract_owner, current_remaining);
				current_remaining = 0;
			}
			revert();
		}
		else if((_currentMined < _maxMiningReward) && (_maxMiningReward - _currentMined >= _miningReward)){
			if((_totalSupply+_miningReward) <= _maxTotalSupply){
				 
				balances[msg.sender] += _miningReward;	
				_currentMined += _miningReward;
				_totalSupply += _miningReward;
				Transfer(this, msg.sender, _miningReward); 
				return true;
			}
		
		}
		return false;
	}

	function MaxTotalSupply() constant returns(uint256)
	{
		return _maxTotalSupply;
	}
	
	function MiningReward() constant returns(uint256)
	{
		return _miningReward;
	}
	
	function MaxMiningReward() constant returns(uint256)
	{
		return _maxMiningReward;
	}
	function MinedThisYear() constant returns(uint256)
	{
		return _currentMined;  
	}



}