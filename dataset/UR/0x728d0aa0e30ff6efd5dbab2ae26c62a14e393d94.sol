 

pragma solidity ^0.4.21;

contract EIP20Interface {
	 
    uint256 public totalSupply;
     
    function balanceOf(address _owner) public view returns (uint256 balance);
     
    function transfer(address _to, uint256 _value) public returns (bool success);
     
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     
	function approve(address _spender, uint256 _value) public returns (bool success);
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyToken is EIP20Interface {
     
    uint256 public totalSupply;
    uint8 public decimals;
    string public name;
    string public symbol;
    
    mapping(address=>uint256) public balances;
    mapping(address=>mapping(address=>uint256)) public allowed;
    
    function MyToken(
        uint256 _totalSupply,
        uint8 _decimal,
        string _name,
        string _symbol) public {
            
        totalSupply = _totalSupply;
        decimals = _decimal;
        name = _name;
        symbol = _symbol;
        
        balances[msg.sender] = totalSupply;
    }

    
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && _value > 0);
        require(balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    
     
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    uint256 allow = allowed[_from][_to];
	    require(_to == msg.sender && allow >= _value && balances[_from] >= _value);
	    require(balances[_to] + _value > balances[_to]);
	    allowed[_from][_to] -= _value;
	    balances[_from] -= _value;
	    balances[_to] += _value;
	    emit Transfer(_from, _to, _value);
	    return true;
	}
	
     
	function approve(address _spender, uint256 _value) public returns (bool success) {
	    require(balances[msg.sender] >= _value && _value > 0 );
	    allowed[msg.sender][_spender] = _value;
	    emit Approval(msg.sender, _spender, _value);
	    return true;
	}
	
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}