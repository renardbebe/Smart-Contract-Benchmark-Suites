 

pragma solidity ^0.5.1;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

contract BasicToken is ERC20Basic {

    using SafeMath for uint256;

    mapping(address => uint256) _balances;

    uint256 _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[msg.sender]);

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

}

contract ERC20 {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;
    

    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= _balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

 
}

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner is able to call this function");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
     }


    function _transferOwnership(address newOwner) internal{
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    

}

contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused || msg.sender == owner);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
  
}


contract BlackListable is Ownable {

    mapping (address => bool) public blacklist;

    event BlackListAdded(address _address);
    event BlackListRemoved(address _address);

    function isBlacklisted(address _address)  external view returns (bool) {
        return blacklist[_address];
    }

    function getOwner() external view returns (address) {
        return owner;
    }


    function addBlackList (address _address) public onlyOwner {
        blacklist[_address] = true;
        emit BlackListAdded(_address);
    }

    function removeBlackList (address _address) public onlyOwner {
        blacklist[_address] = false;
        emit BlackListRemoved(_address);
    }


}


contract Freezeable is Ownable, StandardToken, Pausable, BlackListable{

    event AccountFrozen(address indexed _address, uint256 amount);
    event AccountUnfrozen(address indexed _address);

    mapping(address => uint256) public freezeAccounts;
    
    function transfer(address _to, uint256 _value) public whenNotPaused  returns (bool) {
        require(_to != address(0));
        require(!blacklist[_to]);
        require(!blacklist[msg.sender]);

        require(balanceOf(msg.sender) >= freezeOf(msg.sender).add(_value));
        
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused  returns (bool) {
        require(_to != address(0));
        require(!blacklist[msg.sender]);
        require(!blacklist[_from]);
        require(!blacklist[_to]);
        
        require(balanceOf(_from) >= freezeOf(_from).add(_value));

        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused  returns (bool) {
        require(_spender != address(0));
        require(!blacklist[_spender]);
        require(!blacklist[msg.sender]);
        require(balanceOf(msg.sender) >= freezeOf(msg.sender).add(_value));
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused  returns (bool success) {
        require(_spender != address(0));
        require(!blacklist[_spender]);
        require(!blacklist[msg.sender]);
        require(balanceOf(msg.sender) >= freezeOf(msg.sender).add(_addedValue));
        
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused  returns (bool success) {
        require(_spender != address(0));
        require(!blacklist[msg.sender]);
        
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    
    function freezeOf(address _address) public view returns (uint256 _value) {
        require(!blacklist[msg.sender]);

		return freezeAccounts[_address];
	}

	function freezeAmount() public view returns (uint256 _value) {
        require(!blacklist[msg.sender]);
		return freezeAccounts[msg.sender];
	}
	
    function freeze(address _address, uint256 _value) public onlyOwner {
		require(_value <= _totalSupply);
		require(_address != address(0));

		freezeAccounts[_address] = _value;
		emit AccountFrozen(_address, _value);
	}
	

    function unfreeze(address _address) public onlyOwner {
		require(_address != address(0));

		freezeAccounts[_address] = 0;
		emit AccountUnfrozen(_address);
	}

}


contract OneToken is Freezeable{
   
    string  public  name;
    string  public  symbol;
    uint256 public  decimals;
  
 
    constructor(uint  _initialSupply, string  memory _name, string memory _symbol, uint  _decimals) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		
        _totalSupply = _initialSupply;
		_balances[owner] = _initialSupply;
		emit Transfer(address(0x0), owner, _totalSupply);
    }
    


    event Burn( address indexed to, uint256 value);

    function burn( uint256 value) public  onlyOwner{
        require(value <= _balances[owner]);

        _totalSupply = _totalSupply.sub(value);
        _balances[owner] = _balances[owner].sub(value);
        emit Burn(address(0), value);
    }
    
    function() external payable {
 	   revert();
	}

}