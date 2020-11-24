 

 

pragma solidity ^0.4.25;

 
interface IERC20 {
  function balanceOf(address _owner) external view returns (uint256);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract ToolsChain is IERC20 {
  using SafeMath for uint256;
  address private owner;
  string public name = "Tools Chain";
  string public symbol = "Tools";
  uint8 public constant decimals = 18;
  uint256 public constant decimalFactor = 10 ** uint256(decimals);
  uint256 public constant totalSupply = 1024000000 * decimalFactor;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  mapping (address => bool) public frozenAccount;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    event FrozenFunds(address target, bool frozen);
  constructor() public {
    balances[msg.sender] = totalSupply;
    owner = msg.sender;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }
   function() external payable {
    }
    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
   
     
    require(!frozenAccount[msg.sender]);
    require(!frozenAccount[_to]);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(block.timestamp >= 1537164000);
     
    require(!frozenAccount[_from]);
    require(!frozenAccount[_to]);
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
  
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    } 

}