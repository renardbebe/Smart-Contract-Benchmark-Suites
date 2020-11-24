 

pragma solidity ^0.4.24;

 
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

 
contract Ownable {
  address public owner;


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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract GanapatiReservedToken is StandardToken, Ownable {
     
    string public name = "G8Cβ";
     
    string public symbol = "GAECβ";
     
    uint public decimals = 8;
     
    bool public locked = true;

     
    mapping( address => bool ) public validAddresses;

     
    modifier isValidTransfer() {
        require(!locked || validAddresses[msg.sender]);
        _;
    }

     
    constructor(address _owner) public {
        uint _initialSupply = 2800000000000 * 10 ** decimals;
        totalSupply_ = _initialSupply;

         
        owner = _owner;
        validAddresses[_owner] = true;

         
        address sale = 0xd01fafa4eb615a6d62d0501d8d062b197a0adfc9;
        balances[sale] = _initialSupply.mul(60).div(100);
        emit Transfer(0x0, sale, balances[sale]);
        validAddresses[sale] = true;

         
        address team = 0x1a2d931f4f22fad1e767632c1985dc74e9ce4a1f;
        balances[team] = _initialSupply.mul(15).div(100);
        emit Transfer(0x0, team, balances[team]);
        validAddresses[team] = true;

         
        address marketor = 0xc6a0474c40dcaa9e7a471583d181ca5c9faadbd1;
        balances[marketor] = _initialSupply.mul(12).div(100);
        emit Transfer(0x0, marketor, balances[marketor]);
        validAddresses[marketor] = true;

         
        address advisor = 0x0b05e495d7b536d403e7805cd08847cbb634d846;
        balances[advisor] = _initialSupply.mul(10).div(100);
        emit Transfer(0x0, advisor, balances[advisor]);
        validAddresses[advisor] = true;

         
        address developer = 0x8eb312173e823995583580bb268b2e15dac67441;
        balances[developer] = _initialSupply.mul(3).div(100);
        emit Transfer(0x0, developer, balances[developer]);
        validAddresses[developer] = true;
    }

     
    function setLocked(bool _locked) onlyOwner public {
        locked = _locked;
    }

     
    function transfer(address _to, uint256 _value) public isValidTransfer() returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public isValidTransfer() returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}