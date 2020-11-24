 

pragma solidity 0.4.26;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
     

    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract StandardToken is ERC20 {
    using SafeMath for uint256;
    address private owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MintFinished();
    
    bool public mintingFinished = false;

  mapping(address => uint256) balances;
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transfer(address _to, uint256 _value) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) onlyOwner public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) onlyOwner public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) onlyOwner public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) onlyOwner public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
     
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
    modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
     
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}
 
  
contract MintableTributeToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  string public symbol;
  string public name;
  uint8 public decimals;
  uint public totalSupply;
  address public owner;
  uint public tribute;
  address public guild;
  uint8 private amount;

  bool public mintingFinished = false;

constructor(string memory _symbol, string memory _name, uint _totalSupply, address _owner, uint _tribute, address _guild) public {
    	symbol = _symbol;
    	name = _name;
    	decimals = 0;
    	totalSupply = _totalSupply;
    	owner = _owner;
    	tribute = _tribute;
        guild = _guild;
    	balances[_owner] = _totalSupply;
    	emit Transfer(address(0), _owner, _totalSupply);
}

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
   
  function updateTribute(uint _tribute) onlyOwner public {
    	tribute = _tribute;
	}
    	
   	
  function updateGuild(address _guild) onlyOwner public {
    	guild = _guild;
	}
  
   
  function mint() canMint payable public returns (bool) {
    require(address(this).balance == tribute, "tribute must be funded");
    address(guild).transfer(address(this).balance);
    amount = 1;
    totalSupply = totalSupply.add(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);
    emit Mint(msg.sender, amount);
    emit Transfer(address(0), msg.sender, amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
}
}

contract Factory {

     
    event ContractInstantiation(address sender, address instantiation);

     
    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;

     
     
     
     
    function getInstantiationCount(address creator)
        public
        view
        returns (uint)
    {
        return instantiations[creator].length;
    }

     
     
     
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);
        emit ContractInstantiation(msg.sender, instantiation);
    }
}