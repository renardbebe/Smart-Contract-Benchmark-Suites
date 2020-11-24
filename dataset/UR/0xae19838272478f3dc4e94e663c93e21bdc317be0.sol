 

pragma solidity ^0.4.24;

 

 
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

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract MidasPooling is Ownable {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    string public name = "MidasPooling";
    address public owner;
    address public admin;
    address public feeAccount;
    address public tokenAddress;

    uint256 public withdrawStartTime;
    uint256 public withdrawEndTime;

    mapping(address => uint256) public balances;  

    event SetOwner(address indexed previousOwner, address indexed newOwner);
    event SetAdmin(address indexed previousAdmin, address indexed newAdmin);
    event SetFeeAcount(address indexed previousFeeAccount, address indexed newFeeAccount);
    event Deposit(address user, uint256 amount, uint256 balance);
    event Withdraw(address user, uint256 amount, uint256 balance);
    event TransferERC20Token(address token, address owner, uint256 amount);
    event SetBalance(address user, uint256 balance);
    event ChangeWithdrawTimeRange(uint256 withdrawStartTime, uint256 withdrawEndTime);

    modifier onlyAdminOrOwner {
        require(msg.sender == owner);
        require(msg.sender == admin);
        _;
    }

    function setOwner(address newOwner) onlyOwner public {
        owner = newOwner;
        emit SetOwner(owner, newOwner);
    }

    function setAdmin(address newAdmin) onlyOwner public {
        admin = newAdmin;
        emit SetAdmin(admin, newAdmin);
    }

    function setFeeAccount(address newFeeAccount) onlyOwner public {
        feeAccount = newFeeAccount;
        emit SetFeeAcount(feeAccount, newFeeAccount);
    }

    constructor (
        string _name,
        address _admin,
        address _feeAccount,
        address _tokenAddress,
        uint _withdrawStartTime,
        uint _withdrawEndTime) public {
        owner = msg.sender;
        name = _name;
        admin = _admin;
        feeAccount = _feeAccount;
        tokenAddress = _tokenAddress;
        withdrawStartTime = _withdrawStartTime;
        withdrawEndTime = _withdrawEndTime;
    }

    function changeWithdrawTimeRange(uint _withdrawStartTime, uint _withdrawEndTime) onlyAdminOrOwner public {
        require(_withdrawStartTime <= _withdrawEndTime);
        withdrawStartTime = _withdrawStartTime;
        withdrawEndTime = _withdrawEndTime;
        emit ChangeWithdrawTimeRange(_withdrawStartTime, _withdrawEndTime);
    }

    function depositToken(uint256 amount) public returns (bool success) {
        require(amount > 0);
        require(StandardToken(tokenAddress).balanceOf(msg.sender) >= amount);
        require(StandardToken(tokenAddress).transferFrom(msg.sender, this, amount));
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);
        emit Deposit(msg.sender, amount, balances[msg.sender]);
        return true;
    }

    function withdraw(uint256 amount) public returns (bool success) {
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        require(now >= withdrawStartTime);
        require(now <= withdrawEndTime);
        require(StandardToken(tokenAddress).transfer(msg.sender, amount));
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        emit Withdraw(msg.sender, amount, balances[msg.sender]);
        return true;
    }

    function adminWithdraw(address user, uint256 amount, uint256 feeWithdrawal) onlyAdminOrOwner public returns (bool success) {
        require(balances[user] > amount);
        require(amount > feeWithdrawal);
        uint256 transferAmt = safeSub(amount, feeWithdrawal);
        require(StandardToken(tokenAddress).transfer(user, transferAmt));
        balances[user] = safeSub(balances[user], amount);
        balances[feeAccount] = safeAdd(balances[feeAccount], feeWithdrawal);
        emit Withdraw(user, amount, balances[user]);
        return true;
    }

    function transferERC20Token(address token, uint256 amount) public onlyOwner returns (bool success) {
        emit TransferERC20Token(token, owner, amount);
        return StandardToken(token).transfer(owner, amount);
    }

    function balanceOf(address user) constant public returns (uint256) {
        return balances[user];
    }

    function setBalance(address user, uint256 amount) onlyAdminOrOwner public {
        require(amount >= 0);
        balances[user] = amount;
        emit SetBalance(user, balances[user]);
    }

    function setBalances(address[] users, uint256[] amounts) onlyAdminOrOwner public {
        for (uint i = 0; i < users.length; i++) {
            setBalance(users[i], amounts[i]);
        }
    }
}