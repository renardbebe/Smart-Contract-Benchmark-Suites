 

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

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 is owned{
     
    string public name = "GoodLuck";
    string public symbol = "GLK" ;
    uint8 public decimals = 18;
     
    uint256 public totalSupply=210000000 * 10 ** uint256(decimals);

     
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
	bool public paused = false;
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
	
	 
    event Seo(address indexed from, uint256 value);

     
    function TokenERC20() public {
        totalSupply = uint256(totalSupply);   
        balanceOf[msg.sender] = totalSupply;                 
        name = string(name);                                    
        symbol = string(symbol);                                
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

     
    function transfer(address _to, uint256 _value) isRunning public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) isRunning public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) isRunning public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) isRunning
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) isRunning public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }
	
	
	 
    function seo(uint256 _value) isRunning onlyOwner public returns (bool success) {
        balanceOf[msg.sender] += _value;             
        totalSupply += _value;                       
        Seo(msg.sender, _value);
        return true;
    }
	
	

     
    function burnFrom(address _from, uint256 _value) isRunning public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
	
	function pause() onlyOwner public {
        paused = true;
    }

    function unpause() onlyOwner public {
        paused = false;
    }
	
	modifier isRunning {
        assert (!paused);
        _;
    }
}

 
 
 

contract MyAdvancedToken is owned, TokenERC20 {


    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
	 
    event Freeze(address indexed from, uint256 value);
	 
    event Unfreeze(address indexed from, uint256 value);
	
     
    function MyAdvancedToken() TokenERC20() public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }


     
     
     
    function freezeAccount(address target, bool freeze) isRunning onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
	
	function freeze(address _target,uint256 _value) isRunning onlyOwner public returns (bool success) {
        require (balanceOf[_target] >= _value);             
		require (_value > 0); 
        balanceOf[_target] -= _value;                       
        freezeOf[_target] += _value;                                 
        Freeze(_target, _value);
        return true;
    }
	
	function unfreeze(address _target,uint256 _value) isRunning onlyOwner public returns (bool success) {
        require (freezeOf[_target] >= _value);             
		require (_value > 0); 
        freezeOf[_target]-= _value;                       
		balanceOf[_target]+=  _value;
        Unfreeze(_target, _value);
        return true;
    }
	
}