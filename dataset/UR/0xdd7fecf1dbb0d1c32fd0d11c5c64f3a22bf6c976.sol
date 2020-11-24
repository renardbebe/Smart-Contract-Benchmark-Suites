 

pragma solidity ^0.4.16;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    address public owner;
    uint256 public totalSupply;
    bool public lockIn;
    mapping (address => bool) whitelisted;
	mapping (address => bool) admin;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     
    event Burn(address indexed from, uint256 value);
     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address crowdsaleOwner
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        lockIn = true;
		admin[msg.sender] = true;
        whitelisted[msg.sender] = true;
        admin[crowdsaleOwner]=true;
        whitelisted[crowdsaleOwner]=true;
        owner = crowdsaleOwner;
    }
    
    function toggleLockIn() public {
        require(msg.sender == owner);
        lockIn = !lockIn;
    }
    
    function addToWhitelist(address newAddress) public {
        require(admin[msg.sender]);
        whitelisted[newAddress] = true;
    }
	
	function removeFromWhitelist(address oldaddress) public {
	    require(admin[msg.sender]);
		require(oldaddress != owner);
		whitelisted[oldaddress] = false;
	}
	
	function addToAdmin(address newAddress) public {
		require(admin[msg.sender]);
		admin[newAddress]=true;
	}
	
	function removeFromAdmin(address oldAddress) public {
		require(admin[msg.sender]);
		require(oldAddress != owner);
		admin[oldAddress]=false;
	}
     
    function _transfer(address _from, address _to, uint _value) internal {
        if (lockIn) {
            require(whitelisted[_from]);
        }
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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
     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }
     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}