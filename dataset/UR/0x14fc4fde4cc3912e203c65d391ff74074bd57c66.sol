 

pragma solidity ^0.4.24;
 
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure  returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  
}
contract ERC20Interface {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address owner ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool success);
    function transferFrom( address from, address to, uint value) public returns (bool success);
    function approve( address spender, uint value ) public returns (bool success);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract IECCAuth is ERC20Interface {
    address      public  owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }
}

contract IECCStop is IECCAuth {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public onlyOwner {
        stopped = true;
    }
    function start() public onlyOwner {
        stopped = false;
    }

}

contract IECCToken is IECCStop {
    using SafeMath for uint;

    mapping(address => uint) balances;
    mapping(address => mapping (address => uint256)) allowed;
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 public totalSupply;
    
    constructor(uint256 _initialAmount, string _tokenName, string _tokenSymbol) public  {
        balances[msg.sender] = _initialAmount;               
        totalSupply = _initialAmount;                        
        name = _tokenName;                                   
        symbol = _tokenSymbol;
    }
     
    function name() public view returns (string _name) {
        return name;
    }
     
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
     
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
     
    function totalSupply() public view returns (uint _totalSupply) {
        return totalSupply;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) public stoppable returns (bool success) {
        assert(_value > 0);
        assert(balances[msg.sender] >= _value);
        assert(msg.sender != _to);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public stoppable returns (bool success) {
        assert(balances[_from] >= _value);
        assert(allowed[_from][msg.sender] >= _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        return true;
        
    }

    function approve(address _spender, uint256 _value) public stoppable returns (bool success) {
        assert(_value > 0);
        assert(msg.sender != _spender);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

}