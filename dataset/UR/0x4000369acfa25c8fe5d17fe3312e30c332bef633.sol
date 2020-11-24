 

pragma solidity ^0.5;

 
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
     
     
     
    return a / b;
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

contract Owned {
	 
	address payable internal Owner;
	constructor() public{
	    
	    Owner = msg.sender;
	}
    
	function IsOwner(address addr) view public returns(bool)
	{
	    return Owner == addr;
	}
	
	function TransferOwner(address payable newOwner) public onlyOwner
	{
	    Owner = newOwner;
	}
	
	function Terminate() public onlyOwner
	{
	    selfdestruct(Owner);
	}
	
	modifier onlyOwner(){
        require(msg.sender == Owner);
        _;
    }
}


 

 
contract DetailedERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}



 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) public balances_;

  mapping (address => mapping (address => uint256)) public allowed_;

  uint256 public totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances_[_owner];
  }

   
  function allowance(
    address _owner,
    address _spender
  )
  public
  view
  returns (uint256)
  {
    return allowed_[_owner][_spender];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances_[msg.sender]);
    require(_to != address(0));

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
  public
  returns (bool)
  {
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);
    require(_to != address(0));

    balances_[_from] = balances_[_from].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
  public
  returns (bool)
  {
    allowed_[msg.sender][_spender] = (
    allowed_[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
  public
  returns (bool)
  {
    uint256 oldValue = allowed_[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed_[msg.sender][_spender] = 0;
    } else {
      allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

   
  function _mint(address _account, uint256 _amount) internal {
    require(_account != address(0));
    totalSupply_ = totalSupply_.add(_amount);
    balances_[_account] = balances_[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

   
  function _burn(address _account, uint256 _amount) internal {
    require(_account != address(0));
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

   
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed_[_account][msg.sender]);

     
     
    allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(
      _amount);
    _burn(_account, _amount);
  }
}
contract WholeIssuableToken is StandardToken, Owned {

    event Mint(uint256 indexed _value, bytes32 indexed _note);

     
    function mint(uint256 _value, bytes32 _note) public onlyOwner {
        
        uint256 totalVal = _value * 10**9;
        
        balances_[address(this)] += totalVal;
        totalSupply_ += totalVal;
        emit Mint(totalVal, _note);
        emit Transfer(address(0), address(this), totalVal);

    }

     
    function issue(uint256 _value, address _target) public onlyOwner {
        
        uint256 totalVal = _value * 10**9;
        
        require(balances_[address(this)] >= totalVal);
        balances_[address(this)] -= totalVal;
        balances_[_target] += totalVal;
        emit Transfer(address(this),_target, totalVal);
    }
}



contract USG is StandardToken, DetailedERC20, WholeIssuableToken   {
    constructor() DetailedERC20("USGold", "USG", 9) public {}
    
    event Redeemed(address addr, uint256 amt, bytes32 notes);
    
     
    function redeem(uint256 amt, bytes32 notes) public {
        uint256 total = amt * 10**9;
        _burn(msg.sender, total);
        emit Redeemed(msg.sender, amt, notes);
        
    }
   
}