 

pragma solidity ^0.5.0;

 
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

 
contract Ownable {
  address payable public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address payable _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address payable _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

  
contract ERC20Basic {
     uint public totalSupply;
     function balanceOf(address who) public view returns (uint); 
     function transfer(address to, uint value) public ; 
     event Transfer(address indexed from, address indexed to, uint value); 
} 

 

contract BasicToken is ERC20Basic, Ownable{
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }
  
  function transfer(address _to, uint _value) 
    public 
    onlyPayloadSize(2 * 32)
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public view returns (uint) {
    return balances[_owner];
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  event Burn(address indexed from, uint256 value);
  event Mint(address indexed to, uint256 value);


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    onlyPayloadSize(3 * 32)
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

contract NineTestAgainToken is StandardToken {
  using SafeMath for uint256;
  
  string constant public name = "Nine Test Again Token";
  string constant public symbol = "NTAT";
  uint8 constant public decimals = 2;
  uint public totalSupply = 100000000 * (10 ** uint256(decimals));

  event PaymentReceived(address _from, uint256 _amount);

  constructor(address _wallet) public {
    balances[_wallet] = totalSupply;
    emit Transfer(address(0), _wallet, totalSupply);
  }

  function burn(uint256 _value) public returns (bool) 
  {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

   
    function mint(address addr, uint256 value) onlyOwner public returns (bool) {
      totalSupply = totalSupply.add(value);
      balances[addr] = balances[addr].add(value);

      emit Mint(addr, value);
      emit Transfer(address(0), addr, value);

      return true;
    }

  
  function withdrawEther(uint256 _amount) public onlyOwner {
    owner.transfer(_amount);
  }

  function () external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }
}