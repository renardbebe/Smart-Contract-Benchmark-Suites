 

pragma solidity ^0.4.24;

 
 
 
library SafeMath {
    
     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
        assert(_a == _b * c + _a % _b);  

        return c;
    }
}


 
 
 
 
contract ERC20Interface {
     
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
 
 
contract DXCToken is ERC20Interface {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    address public owner;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;

    event Burn(address indexed _from, uint256 _value);

     
    constructor(string _symbol, string _name, uint _totalSupply, uint8 _decimals, address _owner) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        totalSupply = _totalSupply;
        owner = _owner;
        balances[_owner] = _totalSupply;

        emit Transfer(address(0), _owner, _totalSupply);
    }

     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);

        uint previousBalance = balances[_from].add(balances[_to]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);

        assert(balances[_from].add(balances[_to]) == previousBalance);
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        
        if (_from == msg.sender) {
            _transfer(_from, _to, _value);

        } else {
            require(allowed[_from][msg.sender] >= _value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

            _transfer(_from, _to, _value);

        }

        return true;
    }

     
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(balances[msg.sender] >= _value);
        require(_value > 0);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
         
        totalSupply = totalSupply.sub(_value);

        emit Burn(msg.sender, _value);

        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function () public payable {
        revert();
    }
}