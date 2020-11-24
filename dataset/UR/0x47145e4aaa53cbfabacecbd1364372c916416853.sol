 

pragma solidity ^0.4.24;

contract Erc20Token {
	uint256 public totalSupply;  
	
	 
    function balanceOf(address _owner) public constant returns (uint256 balance);
    
	 
    function transfer(address _to, uint256 _value) public returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);
	
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);


    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract ownerYHT {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
	
    function transferOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

 
contract BKC is ownerYHT,Erc20Token {
    string public name= 'Bick coin'; 
    string public symbol = 'BKC'; 
    uint8 public decimals = 18;
	
	uint256 public moneyTotal = 230000000; 
	uint256 public moneyFreeze = 0; 
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	
	 
    constructor() public {
        totalSupply = (moneyTotal - moneyFreeze) * 10 ** uint256(decimals);

        balances[msg.sender] = totalSupply;
    }
	
	
    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
		return true;
    }
	
	 
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success){
        
        require(_value <= allowed[_from][msg.sender]);    
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
	
	function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }
	
	 
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        return true;
    }
	
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {

		require(_to != 0x0);

		require(balances[_from] >= _value);

		require(balances[_to] + _value > balances[_to]);

		uint previousBalances = balances[_from] + balances[_to];

		balances[_from] -= _value;

		balances[_to] += _value;

		emit Transfer(_from, _to, _value);

		assert(balances[_from] + balances[_to] == previousBalances);

    }
    
	 
	event EventUnLockFreeze(address indexed from,uint256 value);
    function unLockFreeze(uint256 _value) onlyOwner public {
        require(_value <= moneyFreeze);
        
		moneyFreeze -= _value;
		
		balances[msg.sender] += _value * 10 ** uint256(decimals);
		
		emit EventUnLockFreeze(msg.sender,_value);
    }
}