 

pragma solidity ^0.4.25;


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

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }

}

contract ERC20Interface {
   

   
   
   

   
   

   
   

   
   

   
  function totalSupply() public view returns (uint256);

   
  function balanceOf(address _owner) public view returns (uint256 balance);

   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20Interface {
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    
     
    function totalSupply() public view returns(uint256) {
        return totalSupply;
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public returns (bool) {
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    

}


contract CreateToken is StandardToken, Ownable {
    using SafeMath for uint256;
    
     
    modifier validRecipient(address _recipient) {
        require(_recipient != address(0) && _recipient != address(this));
        _;
    }
    
    constructor(
        string _name,
        string _symbol,
        uint256 _decimals,
        uint256 _totalSupply
        ) public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (10 ** _decimals);
        balances[msg.sender] = totalSupply;
    }
    
     
    function approve(address _spender, uint256 _value)
        public
        validRecipient(_spender)
        returns (bool)
    {
        return super.approve(_spender, _value);
    }
    
     
    function transfer(address _to, uint256 _value)
        public
        validRecipient(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validRecipient(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }
    
}