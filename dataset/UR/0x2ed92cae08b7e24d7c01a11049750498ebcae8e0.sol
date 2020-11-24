 

pragma solidity ^0.4.25;


 
 
 
 
 
 


 
library SafeMath {

   
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

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {

  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner)public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}



 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value)
    external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
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

 
contract SecuryptoToken is IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;

  mapping (address => bool) private frozenAccount;

  uint256 private totalSupply_;

  event FrozenFunds(
      address target, 
      bool frozen
      );
      
  string public constant name = "Securypto";
  string public constant symbol = "SCU";
  uint256 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 100000000 * 10**decimals;

   
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    

    balances_[msg.sender] = totalSupply_.mul(10).div(100);  
    balances_[0x80DBF0C72C682a422D7A2C73890117ab8499d227] = totalSupply_.mul(70).div(100);  
    balances_[0x2e61DF87983C4bE9Fe4CDb583a99DC3a51877EEf] = totalSupply_.mul(5).div(100);  
    balances_[0x8924E322d42AC7Ba595d38c921F4501D59ee41f3] = totalSupply_.mul(5).div(100);  
    balances_[0xf5a4FC1C72B8411519057E18b62c878A6aC2784c] = totalSupply_.mul(7).div(100);  
    balances_[0x3F184ee7a1b5b7a299687EFF581C78A6C67f2b16] = totalSupply_.mul(3).div(100);  
    
    emit Transfer(address(0), msg.sender, totalSupply_);  
    emit Transfer(address(0), 0x80DBF0C72C682a422D7A2C73890117ab8499d227, totalSupply_.mul(70).div(100));
    emit Transfer(address(0), 0x2e61DF87983C4bE9Fe4CDb583a99DC3a51877EEf, totalSupply_.mul(5).div(100));
    emit Transfer(address(0), 0x8924E322d42AC7Ba595d38c921F4501D59ee41f3, totalSupply_.mul(5).div(100));
    emit Transfer(address(0), 0xf5a4FC1C72B8411519057E18b62c878A6aC2784c, totalSupply_.mul(7).div(100));
    emit Transfer(address(0), 0x3F184ee7a1b5b7a299687EFF581C78A6C67f2b16, totalSupply_.mul(3).div(100));

  }
  
   
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
    require(!frozenAccount[msg.sender]);
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
    require(!frozenAccount[_from]);


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
  
      
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


}