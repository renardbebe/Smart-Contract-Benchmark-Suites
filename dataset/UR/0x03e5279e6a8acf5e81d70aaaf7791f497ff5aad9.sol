 

pragma solidity ^0.4.19;


 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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


 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract OperatableBasic {
    function setPrimaryOperator (address addr) public;
    function setSecondaryOperator (address addr) public;
    function isPrimaryOperator(address addr) public view returns (bool);
    function isSecondaryOperator(address addr) public view returns (bool);
}

contract Operatable is Ownable, OperatableBasic {
    address public primaryOperator;
    address public secondaryOperator;

    modifier canOperate() {
        require(msg.sender == primaryOperator || msg.sender == secondaryOperator || msg.sender == owner);
        _;
    }

    function Operatable() public {
        primaryOperator = owner;
        secondaryOperator = owner;
    }

    function setPrimaryOperator (address addr) public onlyOwner {
        primaryOperator = addr;
    }

    function setSecondaryOperator (address addr) public onlyOwner {
        secondaryOperator = addr;
    }

    function isPrimaryOperator(address addr) public view returns (bool) {
        return (addr == primaryOperator);
    }

    function isSecondaryOperator(address addr) public view returns (bool) {
        return (addr == secondaryOperator);
    }
}


contract XClaimable is Claimable {

    function cancelOwnershipTransfer() onlyOwner public {
        pendingOwner = owner;
    }

}

contract VUULRTokenConfig {
    string public constant NAME = "Vuulr Token";
    string public constant SYMBOL = "VUU";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}



contract Salvageable is Operatable {
     
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public canOperate {
        if (address(oddToken) == address(0)) {
            owner.transfer(amount);
            return;
        }
        oddToken.transfer(owner, amount);
    }
}

interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}


contract VUULRToken is XClaimable, PausableToken, VUULRTokenConfig, Salvageable {
    using SafeMath for uint;

    string public name = NAME;
    string public symbol = SYMBOL;
    uint8 public decimals = DECIMALS;
    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint _amount) canOperate canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}


contract VUULRVesting is XClaimable, Salvageable {
    using SafeMath for uint;

    struct VestingSchedule {
        uint lockPeriod;         
        uint numPeriods;         
        uint tokens;        
        uint amountWithdrawn;    
        uint startTime;
    }

    bool public started;


    VUULRToken public vestingToken;
    address public vestingWallet;
    uint public vestingOwing;
    uint public decimals;


     
    mapping (address => VestingSchedule) public vestingSchedules;

    event VestingScheduleRegistered(address registeredAddress, address theWallet, uint lockPeriod,  uint tokens);
    event Started(uint start);
    event Withdraw(address registeredAddress, uint amountWithdrawn);
    event VestingRevoked(address revokedAddress, uint amountWithdrawn, uint amountRefunded);
    event VestingAddressChanged(address oldAddress, address newAddress);

    function VUULRVesting(VUULRToken _vestingToken, address _vestingWallet ) public {
        require(_vestingToken != address(0));
        require(_vestingWallet != address(0));
        vestingToken = _vestingToken;
        vestingWallet = _vestingWallet;
        decimals = uint(vestingToken.decimals());
    }

     
     
    function start() public onlyOwner {
        require(!started);
        require(!vestingToken.paused());
        started = true;
        emit Started(now);

         
        if (vestingOwing > 0) {
            require(vestingToken.transferFrom(vestingWallet, address(this), vestingOwing));
            vestingOwing = 0;
        }
    }

     
     
    function registerVestingSchedule(address _newAddress, uint _numDays,
        uint _numPeriods, uint _tokens, uint startFrom)
        public
        canOperate
    {

        uint _lockPeriod;

         
        require(_newAddress != address(0));
         
        require(vestingSchedules[_newAddress].tokens == 0);

         
        require(_numDays > 0);
        require(_numPeriods > 0);

        _lockPeriod = _numDays * 1 days;

        vestingSchedules[_newAddress] = VestingSchedule({
            lockPeriod : _lockPeriod,
            numPeriods : _numPeriods,
            tokens : _tokens,
            amountWithdrawn : 0,
            startTime : startFrom
        });
        if (started) {
            require(vestingToken.transferFrom(vestingWallet, address(this), _tokens));
        } else {
            vestingOwing = vestingOwing.add(_tokens);
        }

        emit VestingScheduleRegistered(_newAddress, vestingWallet, _lockPeriod, _tokens);
    }

     
     
     
    function whichPeriod(address whom, uint time) public view returns (uint period) {
        VestingSchedule memory v = vestingSchedules[whom];
        if (started && (v.tokens > 0) && (time >= v.startTime)) {
            period = Math.min256(1 + (time - v.startTime) / v.lockPeriod,v.numPeriods);
        }
    }

     
    function vested(address beneficiary) public view returns (uint _amountVested) {
        VestingSchedule memory _vestingSchedule = vestingSchedules[beneficiary];
         
        if ((_vestingSchedule.tokens == 0) || (_vestingSchedule.numPeriods == 0) || (now < _vestingSchedule.startTime)){
            return 0;
        }
        uint _end = _vestingSchedule.lockPeriod.mul(_vestingSchedule.numPeriods);
        if (now >= _vestingSchedule.startTime.add(_end)) {
            return _vestingSchedule.tokens;
        }
        uint period = now.sub(_vestingSchedule.startTime).div(_vestingSchedule.lockPeriod)+1;
        if (period >= _vestingSchedule.numPeriods) {
            return _vestingSchedule.tokens;
        }
        uint _lockAmount = _vestingSchedule.tokens.div(_vestingSchedule.numPeriods);

        uint vestedAmount = period.mul(_lockAmount);
        return vestedAmount;
    }


    function withdrawable(address beneficiary) public view returns (uint amount) {
        return vested(beneficiary).sub(vestingSchedules[beneficiary].amountWithdrawn);
    }

    function withdrawVestedTokens() public {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        if (vestingSchedule.tokens == 0)
            return;

        uint _vested = vested(msg.sender);
        uint _withdrawable = withdrawable(msg.sender);
        vestingSchedule.amountWithdrawn = _vested;

        if (_withdrawable > 0) {
            require(vestingToken.transfer(msg.sender, _withdrawable));
            emit Withdraw(msg.sender, _withdrawable);
        }
    }

    function revokeSchedule(address _addressToRevoke, address _addressToRefund) public onlyOwner {
        require(_addressToRefund != 0x0);

        uint _withdrawable = withdrawable(_addressToRevoke);
        uint _refundable = vestingSchedules[_addressToRevoke].tokens.sub(vested(_addressToRevoke));

        delete vestingSchedules[_addressToRevoke];
        if (_withdrawable > 0)
            require(vestingToken.transfer(_addressToRevoke, _withdrawable));
        if (_refundable > 0)
            require(vestingToken.transfer(_addressToRefund, _refundable));
        emit VestingRevoked(_addressToRevoke, _withdrawable, _refundable);
    }

    function changeVestingAddress(address _oldAddress, address _newAddress) public onlyOwner {
        VestingSchedule memory vestingSchedule = vestingSchedules[_oldAddress];
        require(vestingSchedule.tokens > 0);
        require(_newAddress != 0x0);
        require(vestingSchedules[_newAddress].tokens == 0x0);

        VestingSchedule memory newVestingSchedule = vestingSchedule;
        delete vestingSchedules[_oldAddress];
        vestingSchedules[_newAddress] = newVestingSchedule;

        emit VestingAddressChanged(_oldAddress, _newAddress);
    }

    function emergencyERC20Drain( ERC20 oddToken, uint amount ) public canOperate {
         
        require(!started || address(oddToken) != address(vestingToken));
        super.emergencyERC20Drain(oddToken,amount);
    }
}