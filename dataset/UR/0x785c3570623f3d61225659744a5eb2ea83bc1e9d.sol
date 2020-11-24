 

pragma solidity ^0.4.24;

 

 
contract ERC223Receiver {
    constructor() internal {}

     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 

 
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ERC223Token is StandardToken {
    using SafeMath for uint;

    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    modifier enoughBalance(uint _value) {
        require (_value <= balanceOf(msg.sender));
        _;
    }

      
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        require(_to != address(0));

        return isContract(_to) ?
            transferToContract(_to, _value, _data) :
            transferToAddress(_to, _value, _data)
        ;
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
        bytes memory empty;

        return transfer(_to, _value, empty);
    }

     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;

        assembly {
             
            length := extcodesize(_addr)
        }

        return (length > 0);
    }
    
     
    function transferToAddress(address _to, uint _value, bytes _data) private enoughBalance(_value) returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balanceOf(_to).add(_value);

        emit Transfer(msg.sender, _to, _value, _data);

        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private enoughBalance(_value) returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balanceOf(_to).add(_value);

        ERC223Receiver receiver = ERC223Receiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);

        emit Transfer(msg.sender, _to, _value, _data);

        return true;
    }
}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

 

 
contract BaseToken is ERC223Token, StandardBurnableToken {
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

 

 
contract ShintakuToken is BaseToken, Ownable {
    using SafeMath for uint;

    string public constant symbol = "SHN";
    string public constant name = "Shintaku";
    uint8 public constant demicals = 18;

     
    uint public constant TOKEN_UNIT = (10 ** uint(demicals));

     

     
    uint public PERIOD_BLOCKS;
     
    uint public OWNER_LOCK_BLOCKS;
     
    uint public USER_LOCK_BLOCKS;
     
    uint public constant TAIL_EMISSION = 400 * (10 ** 3) * TOKEN_UNIT;
     
    uint public constant INITIAL_EMISSION_FACTOR = 25;
     
     
     
     
    uint public constant MAX_RECEIVED_PER_PERIOD = 10000 ether;

     
    struct Period {
         
        uint started;

         
        uint totalReceived;
         
        uint ownerLockedBalance;
         
        uint minting;

         
        mapping (address => bytes32) sealedPurchaseOrders;
         
        mapping (address => uint) receivedBalances;
         
        mapping (address => uint) lockedBalances;

         
        mapping (address => address) aliases;
    }

     

    modifier validPeriod(uint _period) {
        require(_period <= currentPeriodIndex());
        _;
    }

     

     
    Period[] internal periods;

     
    address public ownerAlias;

     

    event NextPeriod(uint indexed _period, uint indexed _block);
    event SealedOrderPlaced(address indexed _from, uint indexed _period, uint _value);
    event SealedOrderRevealed(address indexed _from, uint indexed _period, address indexed _alias, uint _value);
    event OpenOrderPlaced(address indexed _from, uint indexed _period, address indexed _alias, uint _value);
    event Claimed(address indexed _from, uint indexed _period, address indexed _alias, uint _value);

     

    constructor(address _alias, uint _periodBlocks, uint _ownerLockFactor, uint _userLockFactor) public {
        require(_alias != address(0));
        require(_periodBlocks >= 2);
        require(_ownerLockFactor > 0);
        require(_userLockFactor > 0);

        periods.push(Period(block.number, 0, 0, calculateMinting(0)));
        ownerAlias = _alias;

        PERIOD_BLOCKS = _periodBlocks;
        OWNER_LOCK_BLOCKS = _periodBlocks.mul(_ownerLockFactor);
        USER_LOCK_BLOCKS = _periodBlocks.mul(_userLockFactor);
    }

     
    function nextPeriod() public {
        uint periodIndex = currentPeriodIndex();
        uint periodIndexNext = periodIndex.add(1);
        require(block.number.sub(periods[periodIndex].started) > PERIOD_BLOCKS);

        periods.push(Period(block.number, 0, 0, calculateMinting(periodIndexNext)));

        emit NextPeriod(periodIndexNext, block.number);
    }

     
    function createPurchaseOrder(address _from, uint _period, uint _value, bytes32 _salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_from, _period, _value, _salt));
    }

     
    function placePurchaseOrder(bytes32 _sealedPurchaseOrder) public payable {
        if (block.number.sub(periods[currentPeriodIndex()].started) > PERIOD_BLOCKS) {
            nextPeriod();
        }
         
        Period storage period = periods[currentPeriodIndex()];
         
        require(period.sealedPurchaseOrders[msg.sender] == bytes32(0));

        period.sealedPurchaseOrders[msg.sender] = _sealedPurchaseOrder;
        period.receivedBalances[msg.sender] = msg.value;

        emit SealedOrderPlaced(msg.sender, currentPeriodIndex(), msg.value);
    }

     
    function revealPurchaseOrder(bytes32 _sealedPurchaseOrder, uint _period, uint _value, bytes32 _salt, address _alias) public {
         
        require(_alias != address(0));
         
        require(currentPeriodIndex() == _period.add(1));
        Period storage period = periods[_period];
         
        require(period.aliases[msg.sender] == address(0));

         

        bytes32 h = createPurchaseOrder(msg.sender, _period, _value, _salt);
        require(h == _sealedPurchaseOrder);

         
        require(_value <= period.receivedBalances[msg.sender]);

        period.totalReceived = period.totalReceived.add(_value);
        uint remainder = period.receivedBalances[msg.sender].sub(_value);
        period.receivedBalances[msg.sender] = _value;
        period.aliases[msg.sender] = _alias;

        emit SealedOrderRevealed(msg.sender, _period, _alias, _value);

         
        _alias.transfer(remainder);
    }

     
    function placeOpenPurchaseOrder(address _alias) public payable {
         
        require(_alias != address(0));

        if (block.number.sub(periods[currentPeriodIndex()].started) > PERIOD_BLOCKS) {
            nextPeriod();
        }
         
        Period storage period = periods[currentPeriodIndex()];
         
        require(period.aliases[msg.sender] == address(0));

        period.totalReceived = period.totalReceived.add(msg.value);
        period.receivedBalances[msg.sender] = msg.value;
        period.aliases[msg.sender] = _alias;

        emit OpenOrderPlaced(msg.sender, currentPeriodIndex(), _alias, msg.value);
    }

     
    function claim(address _from, uint _period) public {
         
        require(currentPeriodIndex() > _period.add(1));
        Period storage period = periods[_period];
        require(period.receivedBalances[_from] > 0);

        uint value = period.receivedBalances[_from];
        delete period.receivedBalances[_from];

        (uint emission, uint spent) = calculateEmission(_period, value);
        uint remainder = value.sub(spent);

        address alias = period.aliases[_from];
         
        mint(alias, emission);

         
        period.lockedBalances[_from] = period.lockedBalances[_from].add(remainder);
         
        period.ownerLockedBalance = period.ownerLockedBalance.add(spent);

        emit Claimed(_from, _period, alias, emission);
    }

     
    function withdraw(address _from, uint _period) public {
        require(currentPeriodIndex() > _period);
        Period storage period = periods[_period];
        require(block.number.sub(period.started) > USER_LOCK_BLOCKS);

        uint balance = period.lockedBalances[_from];
        require(balance <= address(this).balance);
        delete period.lockedBalances[_from];

        address alias = period.aliases[_from];
         
         
        alias.transfer(balance);
    }

     
    function withdrawOwner(uint _period) public onlyOwner {
        require(currentPeriodIndex() > _period);
        Period storage period = periods[_period];
        require(block.number.sub(period.started) > OWNER_LOCK_BLOCKS);

        uint balance = period.ownerLockedBalance;
        require(balance <= address(this).balance);
        delete period.ownerLockedBalance;

        ownerAlias.transfer(balance);
    }

     
    function withdrawOwnerUnrevealed(uint _period, address _from) public onlyOwner {
         
        require(currentPeriodIndex() > _period.add(1));
        Period storage period = periods[_period];
        require(block.number.sub(period.started) > OWNER_LOCK_BLOCKS);

        uint balance = period.receivedBalances[_from];
        require(balance <= address(this).balance);
        delete period.receivedBalances[_from];

        ownerAlias.transfer(balance);
    }

     
    function calculateMinting(uint _period) internal pure returns (uint) {
         
        return
            _period < INITIAL_EMISSION_FACTOR ?
            TAIL_EMISSION.mul(INITIAL_EMISSION_FACTOR.sub(_period)) :
            TAIL_EMISSION
        ;
    }

     
    function currentPeriodIndex() public view returns (uint) {
        assert(periods.length > 0);

        return periods.length.sub(1);
    }

     
    function calculateEmission(uint _period, uint _value) internal view returns (uint, uint) {
        Period storage currentPeriod = periods[_period];
        uint minting = currentPeriod.minting;
        uint totalReceived = currentPeriod.totalReceived;

        uint scaledValue = _value;
        if (totalReceived > MAX_RECEIVED_PER_PERIOD) {
             
             
            scaledValue = _value.mul(MAX_RECEIVED_PER_PERIOD).div(totalReceived);
        }

        uint emission = scaledValue.mul(minting).div(MAX_RECEIVED_PER_PERIOD);
        return (emission, scaledValue);
    }

     
    function mint(address _account, uint _value) internal {
        balances[_account] = balances[_account].add(_value);
        totalSupply_ = totalSupply_.add(_value);
    }

     

    function getPeriodStarted(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].started;
    }

    function getPeriodTotalReceived(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].totalReceived;
    }

    function getPeriodOwnerLockedBalance(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].ownerLockedBalance;
    }

    function getPeriodMinting(uint _period) public view validPeriod(_period) returns (uint) {
        return periods[_period].minting;
    }

    function getPeriodSealedPurchaseOrderFor(uint _period, address _account) public view validPeriod(_period) returns (bytes32) {
        return periods[_period].sealedPurchaseOrders[_account];
    }

    function getPeriodReceivedBalanceFor(uint _period, address _account) public view validPeriod(_period) returns (uint) {
        return periods[_period].receivedBalances[_account];
    }

    function getPeriodLockedBalanceFor(uint _period, address _account) public view validPeriod(_period) returns (uint) {
        return periods[_period].lockedBalances[_account];
    }

    function getPeriodAliasFor(uint _period, address _account) public view validPeriod(_period) returns (address) {
        return periods[_period].aliases[_account];
    }
}