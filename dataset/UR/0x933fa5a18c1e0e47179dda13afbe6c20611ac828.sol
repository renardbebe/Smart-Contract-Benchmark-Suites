 

pragma solidity ^0.4.8;



 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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


 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}


 
 contract YCTDataControl {
    mapping (address => uint256) public balances;
    mapping (address => bool) accessAllowed;
    string public constant name = "You Cloud Token";  
    string public constant symbol = "YCT";  
    uint8 public constant decimals = 18;  
    uint256 public constant INITIAL_SUPPLY = 100 * 10 ** 8;
    uint256 public totalSupply_;
    
    constructor() public {
        accessAllowed[msg.sender] = true;
        totalSupply_ = INITIAL_SUPPLY * 10 ** uint256(decimals);
        setBalance(msg.sender, totalSupply_);
    }
    
    function setBalance(address _address,uint256 v) platform public {
        balances[_address] = v;
    }
    
    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }
    
    modifier platform() {
        require(accessAllowed[msg.sender] == true);
        _;
    }
     
    function allowAccess(address _addr) platform public {
        accessAllowed[_addr] = true;
    }
     
    function denyAccess(address _addr) platform public {
        accessAllowed[_addr] = false;
    }
    
    function isAccessAllowed(address _addr) public view returns (bool) {
        return accessAllowed[_addr];
    }
 }
 
 
 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) private allowed;
  
  YCTDataControl public dataContract;
  address public dataControlAddr;

  uint256 public totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  function getDataContract() public view returns (YCTDataControl) {
      return dataContract;
  }
  

   
  function balanceOf(address _owner) public view returns (uint256) {
    return dataContract.balanceOf(_owner);
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= dataContract.balances(msg.sender));
    require(_to != address(0));

    dataContract.setBalance(msg.sender, dataContract.balances(msg.sender).sub(_value));
    dataContract.setBalance(_to, dataContract.balances(_to).add(_value));
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
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
    require(_value <= dataContract.balances(_from));
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    dataContract.setBalance(_from, dataContract.balances(_from).sub(_value));
    dataContract.setBalance(_to, dataContract.balances(_to).add(_value));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


   
  function _burn(address _account, uint256 _amount) internal {
    require(_amount <= dataContract.balances(_account));

    totalSupply_ = totalSupply_.sub(_amount);
    dataContract.setBalance(_account, dataContract.balances(_account).sub(_amount));
    emit Transfer(_account, address(0), _amount);
  }

   
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

     
     
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
  }
}



 
 

contract YCTToken is StandardToken {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public INITIAL_SUPPLY;

   
   
  constructor(address _dataContractAddr) public {
    dataControlAddr = _dataContractAddr;
    dataContract = YCTDataControl(dataControlAddr);
    name = dataContract.name();
    symbol = dataContract.symbol();
    decimals = dataContract.decimals();
    INITIAL_SUPPLY = dataContract.INITIAL_SUPPLY();
    totalSupply_ = dataContract.totalSupply_();
  }
}