 

pragma solidity ^0.5.0;

 

 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) { return 0; }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

 
 
contract Token {
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8  public decimals;
    address public owner; 
    
    uint256 constant INITIAL_SUPPLY = 5000000000;
    uint256 totalSupply_;
    bool public mintingFinished = false;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

     
    event Transfer(address indexed from,  address indexed to,      uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

     
    constructor() public {
        name     = "ITTonion";
        symbol   = "ITT";
        decimals = 18;
        
        owner = msg.sender;
        totalSupply_ = INITIAL_SUPPLY * 10 ** uint(decimals);
        balances[msg.sender] = totalSupply_;
    }
    
     
     
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
     
    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }
  
     
     
    function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
     
    function finishMinting() hasMintPermission canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
    
     
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
     
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
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
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        
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
    
     
     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    
     
     
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        
        balances[_who] = balances[_who].sub(_value);
        totalSupply_   = totalSupply_.sub(_value);
        
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    
}