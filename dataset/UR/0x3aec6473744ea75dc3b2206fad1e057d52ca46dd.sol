 

pragma solidity >=0.4.22 <0.6.0;


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Addpublish(address indexed from, uint256 value);
}


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
          return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
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
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances;

    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    uint256 public totalSupplyN;
    uint256 totalSupply_;
  
  function totalSupply() public view returns (uint256) {
      return totalSupplyN;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
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
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
    uint8 public constant decimals = 18;
    
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
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
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
   
  function burn(uint256 _value) onlyOwner public {
      require(totalSupplyN >= _value * 10 ** uint256(decimals));
      balances[msg.sender] -= _value * 10 ** uint256(decimals);
      totalSupplyN -= _value * 10 ** uint256(decimals);
      emit Burn(msg.sender, _value * 10 ** uint256(decimals));
  }

  function addPublish(uint256 _value) onlyOwner public {
      totalSupplyN += _value * 10 ** uint256(decimals);
      balances[msg.sender] += _value * 10 ** uint256(decimals);
      emit Addpublish(msg.sender, _value * (10 ** uint256(decimals)));
      emit Transfer(address(this), msg.sender, (_value * 10 ** uint256(decimals)));
  }
}

contract EVIC is StandardToken {
    string public constant name = "evic";
    string public constant symbol = "EVIC";
    uint8 public constant decimals = 18;
    
constructor ( uint256 _totalSupply ) public {
        owner = msg.sender;
        totalSupplyN = _totalSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupplyN;
        emit Transfer(address(this), msg.sender, totalSupplyN);
 }
 
}