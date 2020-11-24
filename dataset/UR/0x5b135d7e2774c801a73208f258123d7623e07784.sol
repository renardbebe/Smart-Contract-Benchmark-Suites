 

pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract FreezableToken is Ownable {

    mapping (address => bool) public frozenList;

    event FrozenFunds(address indexed wallet, bool frozen);

     
    function freezeAccount(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        frozenList[_wallet] = true;
        emit FrozenFunds(_wallet, true);
    }

     
    function unfreezeAccount(address _wallet) public onlyOwner {
        require(_wallet != address(0));
        frozenList[_wallet] = false;
        emit FrozenFunds(_wallet, false);
    }

      
    function isFrozen(address _wallet) public view returns (bool) {
        return frozenList[_wallet];
    }

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint256 public releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

         
        token.transfer(beneficiary, amount);
    }
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

}

 

contract SaifuToken is StandardToken, FreezableToken {
    using SafeMath for uint256;

    string public constant name = "Saifu";
    string public constant symbol = "SFU";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_TOTAL_SUPPLY = 200e6 * (10 ** uint256(decimals));
    uint256 public constant AMOUNT_TOKENS_FOR_SELL = 130e6 * (10 ** uint256(decimals));

    uint256 public constant RESERVE_FUND = 20e6 * (10 ** uint256(decimals));
    uint256 public constant RESERVED_FOR_TEAM = 50e6 * (10 ** uint256(decimals));

    uint256 public constant RESERVED_TOTAL_AMOUNT = 70e6 * (10 ** uint256(decimals));
    
    uint256 public alreadyReservedForTeam = 0;

    address public burnAddress;

    bool private isReservedFundsDone = false;

    uint256 private setBurnAddressCount = 0;

     
    mapping (address => address) private lockedList;

     
    modifier onlyBurnAddress() {
        require(msg.sender == burnAddress);
        _;
    }

     
    constructor() public {
        totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);

        balances[owner] = balances[owner].add(AMOUNT_TOKENS_FOR_SELL);
        emit Transfer(address(0), owner, AMOUNT_TOKENS_FOR_SELL);

        balances[this] = balances[this].add(RESERVED_TOTAL_AMOUNT);
        emit Transfer(address(0), this, RESERVED_TOTAL_AMOUNT);
    }

      
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!isFrozen(msg.sender));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!isFrozen(msg.sender));
        require(!isFrozen(_from));
        return super.transferFrom(_from, _to, _value);
    }

     
    function setBurnAddress(address _address) public onlyOwner {
        require(setBurnAddressCount < 3);
        require(_address != address(0));
        burnAddress = _address;
        setBurnAddressCount = setBurnAddressCount.add(1);
    }

     
    function reserveFunds(address _address) public onlyOwner {
        require(_address != address(0));

        require(!isReservedFundsDone);

        sendFromContract(_address, RESERVE_FUND);
        
        isReservedFundsDone = true;
    }

     
    function getLockedContract(address _address) public view returns(address) {
        return lockedList[_address];
    }

     
    function reserveForTeam(address _address, uint256 _amount, uint256  _time) public onlyOwner {
        require(_address != address(0));
        require(_amount > 0 && _amount <= RESERVED_FOR_TEAM.sub(alreadyReservedForTeam));

        if (_time > 0) {
            address lockedAddress = new TokenTimelock(this, _address, now.add(_time * 1 days));
            lockedList[_address] = lockedAddress;
            sendFromContract(lockedAddress, _amount);
        } else {
            sendFromContract(_address, _amount);
        }
        
        alreadyReservedForTeam = alreadyReservedForTeam.add(_amount);
    }

     
    function sendWithFreeze(address _address, uint256 _amount, uint256  _time) public onlyOwner {
        require(_address != address(0) && _amount > 0 && _time > 0);

        address lockedAddress = new TokenTimelock(this, _address, now.add(_time));
        lockedList[_address] = lockedAddress;
        transfer(lockedAddress, _amount);
    }

     
    function unlockTokens(address _address) public {
        require(lockedList[_address] != address(0));

        TokenTimelock lockedContract = TokenTimelock(lockedList[_address]);

        lockedContract.release();
    }

     
    function burnFromAddress(uint256 _amount) public onlyBurnAddress {
        require(_amount > 0);
        require(_amount <= balances[burnAddress]);

        balances[burnAddress] = balances[burnAddress].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Transfer(burnAddress, address(0), _amount);
    }

     
    function sendFromContract(address _address, uint256 _amount) internal {
        balances[this] = balances[this].sub(_amount);
        balances[_address] = balances[_address].add(_amount);
        emit Transfer(this, _address, _amount);
    }
}