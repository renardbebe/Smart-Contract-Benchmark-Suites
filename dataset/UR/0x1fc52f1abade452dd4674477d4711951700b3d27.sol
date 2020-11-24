 

pragma solidity 0.4.13;
contract Burnable {

    event LogBurned(address indexed burner, uint256 indexed amount);

    function burn(uint256 amount) returns (bool burned);
}
contract Mintable {

    function mint(address to, uint256 amount) returns (bool minted);

    function mintLocked(address to, uint256 amount) returns (bool minted);
}
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
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

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) {
         
         
        require(_releaseTime > now);

        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event LogVestingCreated(address indexed beneficiary, uint256 startTime, uint256 indexed cliff,
        uint256 indexed duration, bool revocable);
    event LogVestedTokensReleased(address indexed token, uint256 indexed released);
    event LogVestingRevoked(address indexed token, uint256 indexed refunded);

     
    address public beneficiary;

     
    uint256 public cliff;
    
     
    uint256 public startTime;
    
     
    uint256 public duration;

     
    bool public revocable;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;

     
    function TokenVesting(address _beneficiary, uint256 _startTime, uint256 _cliff, uint256 _duration, bool _revocable) public {
        require(_beneficiary != address(0));
        require(_startTime >= now);
        require(_duration > 0);
        require(_cliff <= _duration);

        beneficiary = _beneficiary;
        startTime = _startTime;
        cliff = _startTime.add(_cliff);
        duration = _duration;
        revocable = _revocable;

        LogVestingCreated(beneficiary, startTime, cliff, duration, revocable);
    }

     
    function release(ERC20Basic token) public {
        uint256 unreleased = releasableAmount(token);
        require(unreleased > 0);

        released[token] = released[token].add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        LogVestedTokensReleased(address(token), unreleased);
    }

     
    function revoke(ERC20Basic token) public onlyOwner {
        require(revocable);
        require(!revoked[token]);

        uint256 balance = token.balanceOf(this);

        uint256 unreleased = releasableAmount(token);
        uint256 refundable = balance.sub(unreleased);

        revoked[token] = true;

        token.safeTransfer(owner, refundable);

        LogVestingRevoked(address(token), refundable);
    }

     
    function releasableAmount(ERC20Basic token) public constant returns (uint256) {
        return vestedAmount(token).sub(released[token]);
    }

     
    function vestedAmount(ERC20Basic token) public constant returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (now < cliff) {
            return 0;
        } else if (now >= startTime.add(duration) || revoked[token]) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(startTime)).div(duration);
        }
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}
 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
contract AdaptableToken is Burnable, Mintable, PausableToken {

    uint256 public transferableFromBlock;

    uint256 public lockEndBlock;
    
    mapping (address => uint256) public initiallyLockedAmount;
    
    function AdaptableToken(uint256 _transferableFromBlock, uint256 _lockEndBlock) internal {
        require(_lockEndBlock > _transferableFromBlock);
        transferableFromBlock = _transferableFromBlock;
        lockEndBlock = _lockEndBlock;
    }

    modifier canTransfer(address _from, uint _value) {
        require(block.number >= transferableFromBlock);

        if (block.number < lockEndBlock) {
            uint256 locked = lockedBalanceOf(_from);
            if (locked > 0) {
                uint256 newBalance = balanceOf(_from).sub(_value);
                require(newBalance >= locked);
            }
        }
        _;
    }

    function lockedBalanceOf(address _to) public constant returns(uint256) {
        uint256 locked = initiallyLockedAmount[_to];
        if (block.number >= lockEndBlock) return 0;
        else if (block.number <= transferableFromBlock) return locked;

        uint256 releaseForBlock = locked.div(lockEndBlock.sub(transferableFromBlock));
        uint256 released = block.number.sub(transferableFromBlock).mul(releaseForBlock);
        return locked.sub(released);
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    modifier canMint() {
        require(!mintingFinished());
        _;
    }

    function mintingFinished() public constant returns(bool finished) {
        return block.number >= transferableFromBlock;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool minted) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function mintLocked(address _to, uint256 _amount) public onlyOwner canMint returns (bool minted) {
        initiallyLockedAmount[_to] = initiallyLockedAmount[_to].add(_amount);
        return mint(_to, _amount);
    }

     
    function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime) public
        onlyOwner canMint returns (TokenTimelock tokenTimelock) {

        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        mint(timelock, _amount);

        return timelock;
    }

     
    function mintVested(address _to, uint256 _amount, uint256 _startTime, uint256 _duration) public
        onlyOwner canMint returns (TokenVesting tokenVesting) {

        TokenVesting vesting = new TokenVesting(_to, _startTime, 0, _duration, true);
        mint(vesting, _amount);

        return vesting;
    }

     
    function burn(uint256 _amount) public returns (bool burned) {
         

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        Transfer(msg.sender, address(0), _amount);
        
        return true;
    }

     
    function releaseVested(TokenVesting _vesting) public {
        require(_vesting != address(0));

        _vesting.release(this);
    }

     
    function revokeVested(TokenVesting _vesting) public onlyOwner {
        require(_vesting != address(0));

        _vesting.revoke(this);
    }
}
contract NokuMasterToken is AdaptableToken {
    string public constant name = "NOKU";
    string public constant symbol = "NOKU";
    uint8 public constant decimals = 18;

    function NokuMasterToken(uint256 _transferableFromBlock, uint256 _lockEndBlock)
        AdaptableToken(_transferableFromBlock, _lockEndBlock) public {
    }
}