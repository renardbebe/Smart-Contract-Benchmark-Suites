 

pragma solidity ^0.4.25;

interface tokenRecipient 
{ 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}
 
contract owned 
{    
  	address public owner;

    constructor() public    
    {        
    	owner = msg.sender;

    }    
    modifier onlyOwner     
    {        
    	require(msg.sender == owner);
        _;

    }

    function transferOwnership(address newOwner) onlyOwner public     
    {        
    	owner = newOwner;

    }
}

contract TokenPrueba1 is owned
{    
     
   	string public name;

    string public symbol;

     
    uint8 public decimals = 8;

     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;

     
    mapping (address => mapping (address => uint256)) public allowance;

     
    mapping (address => bool) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(uint256 value);

     
    event FrozenFunds(address target, bool frozen);

         
    constructor(uint256 initialSupply,string tokenName,string tokenSymbol, address centralMinter) public     
    {        
    	 
    	totalSupply = initialSupply * 10 ** uint256(decimals);

         
        balanceOf[msg.sender] = totalSupply;

         
        name = tokenName;

         
        symbol = tokenSymbol;

         
        if(centralMinter != 0 ) owner = centralMinter;

    }        
         
    function mintToken(address target, uint256 mintedAmount) onlyOwner public    
    {        
    	balanceOf[target] += mintedAmount;

        totalSupply += mintedAmount;

        emit Transfer(0, owner, mintedAmount);

        emit Transfer(owner, target, mintedAmount);

    }     
         
    function burn(uint256 _value) onlyOwner public returns (bool success)    
    {        
     
    	totalSupply -= _value;

        emit Burn(_value);

        return true;

    }    
         
    function freezeAccount(address target, bool freeze) onlyOwner public    
    {        
    	frozenAccount[target] = freeze;

        emit FrozenFunds(target, freeze);

    }    
         
    function _transfer(address _from, address _to, uint _value) internal {        
     
    	require(_to != 0x0);

         
        require(balanceOf[_from] >= _value);

         
        require(balanceOf[_to] + _value >= balanceOf[_to]);

         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

         
        balanceOf[_from] -= _value;

         
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);

         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }    
         
    function transfer(address _to, uint256 _value) public returns (bool success)    
    {        
    	require(!frozenAccount[msg.sender]);

        _transfer(msg.sender, _to, _value);

        return true;

    }    
         
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)    {        
    	require(_value <= allowance[_from][msg.sender]);

      
    	allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;

    }    
         
    function approve(address _spender, uint256 _value) public returns (bool success)    {        
    	allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }    
         
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)    {        
    	tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value))        
        {            
        	spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;

        }    
    }
}