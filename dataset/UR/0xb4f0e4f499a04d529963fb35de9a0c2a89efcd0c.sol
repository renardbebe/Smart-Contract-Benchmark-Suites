 

pragma solidity ^0.4.23;


contract EIP20Interface {

    uint256 public totalSupply;


    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
       
       
       
        if (a == 0) {
            return 0;
        }

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
contract CommunicationCreatesValueToken is EIP20Interface {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public freezeOf;
    mapping(address => mapping(address=> uint256)) allowed;

     
    event Burn(address indexed from, uint256 value);
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);

    constructor (
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) public {
        balanceOf[msg.sender] = _totalSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
    }   
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(_to != address(0));
        require(balanceOf[_from] >= _value && allowance >= _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value); 
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);            
        require(_value>0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                       
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);                                 
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);             
	    require(_value>0);
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);                       
		balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balanceOf[_who]);
         
         

        balanceOf[_who] = balanceOf[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}