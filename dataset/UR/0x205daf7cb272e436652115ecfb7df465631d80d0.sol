 

pragma solidity ^0.4.19;

contract Token {

     
    function totalSupply() public constant returns (uint supply);

     
     
    function balanceOf(address _owner) public constant returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RegularToken is Token {

    function transfer(address _to, uint _value) public returns (bool) {
         
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint)  {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool) {
		if (_value >= 0){
		    allowed[msg.sender][_spender] = _value;
			emit Approval(msg.sender, _spender, _value);
			return true;
		} else { return false; }
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }
	
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnboundedRegularToken is RegularToken {

    uint constant MAX_UINT = 2**256 - 1;
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract BYToken is UnboundedRegularToken {

    uint public totalSupply = 5*10**10;
    uint8 constant public decimals = 2;
    string constant public name = "BYB Token";
    string constant public symbol = "BY2";
	address public owner;
	mapping (address => uint) public freezes;

	 
    event Burn(address indexed from, uint value);
	
	 
    event Freeze(address indexed from, uint value);
	
	 
    event Unfreeze(address indexed from, uint value);
	
    function BYToken() public {
        balances[msg.sender] = totalSupply;
		owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
	
	function totalSupply() public constant returns (uint){
		return totalSupply;
	}
    
    function burn(uint _value) public returns (bool success) {
		if (balances[msg.sender] >= _value && totalSupply - _value <= totalSupply){
			balances[msg.sender] -= _value; 								 
            totalSupply -= _value;
			emit Burn(msg.sender, _value);
			return true;
		}else {
            return false;
        }    
    }
	
	function freeze(uint _value) public returns (bool success) {
		if (balances[msg.sender] >= _value &&
		freezes[msg.sender] + _value >= freezes[msg.sender]){
			balances[msg.sender] -= _value;   				 
			freezes[msg.sender] += _value;            		 
			emit Freeze(msg.sender, _value);
			return true;
		}else {
            return false;
        }  
    }
	
	function unfreeze(uint _value) public returns (bool success) {
        if (freezes[msg.sender] >= _value &&
		balances[msg.sender] + _value >= balances[msg.sender]){
			freezes[msg.sender] -= _value;
			balances[msg.sender] += _value;
			emit Unfreeze(msg.sender, _value);
			return true;
		}else {
            return false;
        } 
    }
	
	function transferAndCall(address _to, uint _value, bytes _extraData) public returns (bool success) {
		if(transfer(_to,_value)){
			if(_to.call(bytes4(bytes32(keccak256("receiveTransfer(address,uint,address,bytes)"))), msg.sender, _value, this, _extraData)) { return true; }
		}
		else {
            return false;
        } 
    }
	
	function approveAndCall(address _spender, uint _value, bytes _extraData) public returns (bool success) {
		if(approve(_spender,_value)){
			if(_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint,address,bytes)"))), msg.sender, _value, this, _extraData)) { return true; }
		}
		else {
            return false;
        } 
    }
	
	 
	function withdrawEther(uint amount) public {
		if(msg.sender == owner){
			owner.transfer(amount);
		}
	}
	
	 
	function() public payable {
    }
}