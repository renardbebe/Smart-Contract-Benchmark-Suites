 

pragma solidity ^0.5.7;


 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeMath {
     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a * _b;
        require(_a == 0 || c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a / _b;
        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}


 
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0), "New owner cannot be address(0)");
		emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
contract Administrator is Ownable {
    mapping (address=>bool) public admin;
    
     
    uint    public   adminLength;   
     
    uint    public   adminMaxLength;      
    
    event   AddAdmin(address indexed _address);
    event   RemoveAdmin(address indexed _address);
    
    constructor (uint _len) public {        
        adminMaxLength = _len;
    }
    
    modifier isAdmin(address _addr) {
        require(admin[_addr], "Not administrator");
        _;
    }
    
    modifier isNotAdmin(address _addr) {
        require(!admin[_addr], "Is administrator");
        _;        
    }
    
     
	modifier onlyOwnerOrAdmin() {
		require(msg.sender == owner || admin[msg.sender], "msg.sender is nether owner nor administator");
		_;
	}
    
     
    function addAdmin(address _addr) onlyOwner isNotAdmin(_addr) public returns (bool) {
        require(_addr != address(0), "Administrator cannot be address(0)");
        require(_addr != owner, "Administrator cannot be owner");
        require(adminLength < adminMaxLength, "Exceeded the maximum number of administrators");
        
        admin[_addr] = true;
        adminLength++; 
        
        emit AddAdmin(_addr);
        return true;
    } 
    
     
    function removeAdmin(address _addr) onlyOwner isAdmin(_addr) public returns (bool) {
        delete admin[_addr];
        adminLength--;
        
        emit RemoveAdmin(_addr);
        return true;
    }
}

 
contract Blacklisted is Administrator {
	mapping (address => bool) public blacklist;

	event SetBlacklist(address indexed _address, bool _bool);

	 
	modifier notInBlacklist(address _address) {
		require(!blacklist[_address], "Is in Blacklist");
		_;
	}

	 
	function setBlacklist(address _address, bool _bool) public onlyOwnerOrAdmin {
		require(_address != address(0));
		
		if(_bool) {
		    require(!blacklist[_address], "Already in blacklist");
		} else {
		    require(blacklist[_address], "Not in blacklist yet");
		}
		
		blacklist[_address] = _bool;
		emit SetBlacklist(_address, _bool);
	}
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


 
contract StandardToken is ERC20, Pausable, Blacklisted {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused notInBlacklist(msg.sender) notInBlacklist(_to) public returns (bool) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused notInBlacklist(msg.sender) notInBlacklist(_from) notInBlacklist(_to) public returns (bool) {
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }


     
    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool) {
		require(_value == 0 || allowed[msg.sender][_spender] == 0 );
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function increaseApproval(address _spender, uint256 _addedValue) whenNotPaused public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) whenNotPaused public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}



 
contract Oratium is StandardToken {
    string public constant name = "Oratium";
    string public constant symbol = "ORT";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 950000000;
    
    constructor() Administrator(3) public {
        totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
}