 

pragma solidity ^ 0.4.24;

 
 
 
 
contract ERC20Interface {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    function balanceOf(address _owner) external view returns (uint256 amount);
    function transfer(address _to, uint256 _value) external returns(bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract Burnable {
    
    function burn(uint256 _value) external returns(bool success);
    function burnFrom(address _from, uint256 _value) external returns(bool success);
    
     
    event Burn(address indexed _from, uint256 _value);
}

 
 
 
contract Owned {
    
    address public owner;
    address public newOwner;

    modifier onlyOwner {
        require(msg.sender == owner, "only Owner can do this");
        _;
    }

    function transferOwnership(address _newOwner) 
    external onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() 
    external {
        require(msg.sender == newOwner, "only new Owner can do this");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

contract Permissioned {
    
    function approve(address _spender, uint256 _value) public returns(bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 amount);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "mul overflow");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by zero");
        uint256 c = a / b;
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub overflow");
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "add overflow");
        return c;
    }
}

 
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

 
contract NelCoin is ERC20Interface, Burnable, Owned, Permissioned {
     
    using SafeMath for uint256;

     
    mapping(address => uint256) internal _balanceOf;
    
     
    mapping(address => mapping(address => uint256)) internal _allowance;
	
	uint public forSale;

     
    constructor()
    public {
        owner = msg.sender;
        symbol = "NEL";
        name = "NelCoin";
        decimals = 2;
        forSale = 12000000 * (10 ** uint(decimals));
        totalSupply = 21000000 * (10 ** uint256(decimals));
        _balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

     
    function balanceOf(address _owner)
    external view
    returns(uint256 balance) {
        return _balanceOf[_owner];
    }

     
    function _transfer(address _from, address _to, uint256 _value)
    internal {
         
        require(_to != address(0), "use burn() instead");
         
        require(_balanceOf[_from] >= _value, "not enough balance");
         
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
         
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value)
    external
    returns(bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
    external
    returns(bool success) {
        require(_value <= _allowance[_from][msg.sender], "allowance too loow");      
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        emit Approval(_from, _to, _allowance[_from][_to]);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
    public
    returns(bool success) {
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    external
    returns(bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function allowance(address _owner, address _spender)
    external view
    returns(uint256 amount) {
        return _allowance[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue)
    external
    returns(bool success) {
        _allowance[msg.sender][_spender] = _allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue)
    external
    returns(bool success) {
        uint256 oldValue = _allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            _allowance[msg.sender][_spender] = 0;
        } else {
            _allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowance[msg.sender][_spender]);
        return true;
    }

     
    function burn(uint256 _value)
    external
    returns(bool success) {
        _burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value)
    external
    returns(bool success) {
        require(_value <= _allowance[_from][msg.sender], "allowance too low");                            
        require(_value <= _balanceOf[_from], "balance too low");                                        
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);   
        _burn(_from, _value);
        emit Approval(_from, msg.sender, _allowance[_from][msg.sender]);
        return true;
    }

     
    function _burn(address _from, uint256 _value)
    internal {
        require(_balanceOf[_from] >= _value, "balance too low");                
        _balanceOf[_from] = _balanceOf[_from].sub(_value);   
        totalSupply = totalSupply.sub(_value);               
        emit Burn(msg.sender, _value);
        emit Transfer(_from, address(0), _value);
    }

	 
    event Donated(address indexed _from, uint256 _value);

	 
	function donation() 
    external payable 
    returns (bool success){
        emit Donated(msg.sender, msg.value);
        return(true);
    }
    
     
    function()
    external payable
    {
        require(false, "Use fund() or donation()");
    }
    
	 
	function fund()
	external payable
	returns (uint amount){
		require(forSale > 0, "Sold out!");
		uint tokenCount = ((msg.value).mul(20000 * (10 ** uint(decimals)))).div(10**18);
		require(tokenCount >= 1, "Send more ETH to buy at least one token!");
		require(tokenCount <= forSale, "You want too much! Check forSale()");
		forSale -= tokenCount;
		_transfer(owner, msg.sender, tokenCount);
		return tokenCount;
	}
	
	 
    function withdraw()
    onlyOwner external
    returns (bool success){
        require(address(this).balance > 0, "Nothing to withdraw");
        owner.transfer(address(this).balance);
        return true;
    }
	
	 
	function withdraw(uint _value)
    onlyOwner external
    returns (bool success){
		require(_value > 0, "provide amount pls");
		require(_value < address(this).balance, "Too much! Check balance()");
		owner.transfer(_value);
        return true;
	}
	
     
	function balance()
	external view
	returns (uint amount){
		return (address(this).balance);
	}
    
	 
	function transferAnyERC20Token(address _tokenAddress, uint256 _amount)
    onlyOwner external
    returns(bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _amount);
    }
}