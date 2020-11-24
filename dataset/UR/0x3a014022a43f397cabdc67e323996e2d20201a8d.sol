 

pragma solidity ^0.5.1;

contract CareerOnToken {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed a_owner, address indexed _spender, uint256 _value);
    event OwnerChange(address indexed _old,address indexed _new,uint256 _coin_change);
    
    uint256 public totalSupply;  
    string public name;                    
    uint8 public decimals;                
    string public symbol;                
    address public owner;
    
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
	 
    bool isTransPaused=false;
    
    constructor(
        uint256 _initialAmount,
        uint8 _decimalUnits) public 
    {
        owner=msg.sender; 
		if(_initialAmount<=0){
		    totalSupply = 100000000000000000;    
		    balances[owner]=totalSupply;
		}else{
		    totalSupply = _initialAmount;    
		    balances[owner]=_initialAmount;
		}
		if(_decimalUnits<=0){
		    decimals=8;
		}else{
		    decimals = _decimalUnits;
		}
        name = "CareerOn Chain Token"; 
        symbol = "COT";
    }
    
    
    function transfer(
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        assert(_to!=address(this) && 
                !isTransPaused &&
                balances[msg.sender] >= _value &&
                balances[_to] + _value > balances[_to]
        );
        
        balances[msg.sender] -= _value; 
        balances[_to] += _value; 
		if(msg.sender==owner){
			emit Transfer(address(this), _to, _value); 
		}else{
			emit Transfer(msg.sender, _to, _value); 
		}
        return true;
    }


    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        assert(_to!=address(this) && 
                !isTransPaused &&
                balances[_from] >= _value &&
                balances[_to] + _value > balances[_to] &&
                allowed[_from][msg.sender] >= _value
        );
        
        balances[_to] += _value; 
        balances[_from] -= _value;  
        allowed[_from][msg.sender] -= _value; 
        if(_from==owner){
			emit Transfer(address(this), _to, _value); 
		}else{
			emit Transfer(_from, _to, _value); 
		}
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) 
    { 
        assert(msg.sender!=_spender && _value>0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner, 
        address _spender) public view returns (uint256 remaining) 
    {
        return allowed[_owner][_spender]; 
    }
    
    function balanceOf(address accountAddr) public view returns (uint256) {
        return balances[accountAddr];
    }
	
	 
	 
	function changeOwner(address newOwner) public{
        assert(msg.sender==owner && msg.sender!=newOwner);
        balances[newOwner]=balances[owner];
        balances[owner]=0;
        owner=newOwner;
        emit OwnerChange(msg.sender,newOwner,balances[owner]); 
    }
    
	 
    function setPauseStatus(bool isPaused)public{
        assert(msg.sender==owner);
        isTransPaused=isPaused;
    }
    
	 
    function changeContractName(string memory _newName,string memory _newSymbol) public {
        assert(msg.sender==owner);
        name=_newName;
        symbol=_newSymbol;
    }
    
    
    function () external payable {
        revert();
    }
}