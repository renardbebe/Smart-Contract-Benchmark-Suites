 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

contract Smartcop is DetailedERC20, StandardToken {

    address public owner ;

    constructor() public
        DetailedERC20("Azilowon", "AWN", 18)
    {
        totalSupply_ = 1000000000 * (uint(10)**decimals);
        balances[msg.sender] = totalSupply_;
        owner = msg.sender;
    }

}

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }
  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
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

 

 

pragma solidity ^0.4.24;






 
contract LockerVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public start;
  uint256 public period;
  uint256 public chunks;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _period,
    uint256 _chunks,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));

    beneficiary = _beneficiary;
    revocable = _revocable;
    period = _period;
    chunks = _chunks;
    start = _start;
  }

   
  function release(ERC20Basic _token) public {
    uint256 unreleased = releasableAmount(_token);

    require(unreleased > 0);

    released[_token] = released[_token].add(unreleased);

    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic _token) public onlyOwner {
    require(revocable);
    require(!revoked[_token]);

    uint256 balance = _token.balanceOf(address(this));

    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[_token] = true;

    _token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic _token) public view returns (uint256) {
    return vestedAmount(_token).sub(released[_token]);
  }

   
  function vestedAmount(ERC20Basic _token) public view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[_token]);

    require(chunks < 100);
     
    if (block.timestamp < start) {
      return 0;
    } 
    for (uint i=0; i<chunks; i++) {
      if (block.timestamp > start.add(period.mul(i)) && block.timestamp <= start.add(period.mul(i+1))) {
         
        return totalBalance.div(chunks).mul(i+1);
      } 
    }
    return 0;
  }
}

 

 

pragma solidity ^0.4.24;




contract Smartcop_Locker 
{
    using SafeMath for uint;

    address tokOwner;
    uint startTime;
    Smartcop AWN;

    mapping (address => address) TTLaddress;

    event LockInvestor( address indexed purchaser, uint tokens);
    event LockAdvisor( address indexed purchaser, uint tokens);
    event LockCompanyReserve( address indexed purchaser, uint tokens);
    event LockCashBack( address indexed purchaser, uint tokens);
    event LockAffiliateMarketing( address indexed purchaser, uint tokens);
    event LockStrategicPartners( address indexed purchaser, uint tokens);
 
     
    constructor(address _token) public
    { 
        AWN = Smartcop(_token);
        startTime = now;
        tokOwner = AWN.owner();
    }

    function totalTokens() public view returns(uint) {
        return AWN.totalSupply();
    }

    function getMyLocker() public view returns(address) {
        return TTLaddress[msg.sender]; 
    }

    function PrivateSale(address buyerAddress, uint amount) public returns(bool) {
         
        AWN.transferFrom(tokOwner, buyerAddress, amount);
        emit LockInvestor( buyerAddress, amount);
    }

    function AdvisorsAndFounders(address buyerAddress, uint amount) public returns(bool) {
         
        uint tamount = amount.mul(30);
        tamount = tamount.div(100);
        AWN.transferFrom(tokOwner, buyerAddress, tamount );
        assignTokens(buyerAddress, amount.sub(tamount), startTime, 2630000, 14);
        emit LockAdvisor(buyerAddress, amount);
        return true;
    }
    function CompanyReserve(address buyerAddress, uint amount) public returns(bool) {
         
        assignTokens(buyerAddress, amount ,startTime.add(15780000), 7890000, 5);
        emit LockCompanyReserve(buyerAddress, amount);
        return true;
    }

    function AffiliateMarketing(address buyerAddress, uint amount) public returns(bool) {
         
        assignTokens(buyerAddress, amount, startTime,2630000, 10);
        emit LockAffiliateMarketing(buyerAddress, amount);
        return true;
    }

    function Cashback(address buyerAddress, uint amount) public returns(bool) {
         
        assignTokens(buyerAddress, amount, startTime,2630000, 10 );
        emit LockCashBack(buyerAddress, amount);
        return true;
    }

    function StrategicPartners(address buyerAddress, uint amount) public returns(bool) {
         
        assignTokens(buyerAddress, amount, startTime, 2630000, 10);
        emit LockStrategicPartners(buyerAddress, amount);
        return true;
    }

    function ArbitraryLocker(address buyerAddress, uint amount, uint start, uint period, uint chunks) public returns(bool) {
        assignTokens(buyerAddress, amount, start, period, chunks);
        return true;
    }

    function assignTokens(address buyerAddress, uint amount, 
                                    uint start, uint period, uint chunks ) internal returns(address) {
        require(amount <= AWN.allowance(tokOwner, address(this)) ,"Type 1 Not enough Tokens to transfer");
        address ttl1 = getMyLocker();

        if (ttl1 == 0x0) {
         
            ttl1 = new LockerVesting(buyerAddress, start, period, chunks, false);
        }
            
        AWN.transferFrom(tokOwner, ttl1, amount);
        TTLaddress[buyerAddress] = ttl1;

        return ttl1;
    }


}