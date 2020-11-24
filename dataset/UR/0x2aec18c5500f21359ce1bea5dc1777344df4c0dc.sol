 

pragma solidity ^0.4.18;

contract ERC20Basic {
    uint256 public totalSupply;
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

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract Ownable {

    address public owner;

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isOwner(address _address) public constant returns (bool) {
        return owner == _address;
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

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

contract FTT is Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply = 1000000000 * 10**uint256(decimals);
    string public constant name = "FarmaTrust Token";
    string public symbol = "FTT";
    uint8 public constant decimals = 18;

    mapping(address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FTTIssued(address indexed from, address indexed to, uint256 indexed amount, uint256 timestamp);
    event TdeStarted(uint256 startTime);
    event TdeStopped(uint256 stopTime);
    event TdeFinalized(uint256 finalizeTime);

     
    uint256 public constant FT_TOKEN_SALE_CAP = 600000000 * 10**uint256(decimals);

     
    uint256 public FT_OPERATIONAL_FUND = totalSupply - FT_TOKEN_SALE_CAP;

     
    uint256 public FT_TEAM_FUND = FT_OPERATIONAL_FUND / 10;

     
    uint256 public fttIssued = 0;

    address public tdeIssuer = 0x2Ec9F52A5e4E7B5e20C031C1870Fd952e1F01b3E;
    address public teamVestingAddress;
    address public unsoldVestingAddress;
    address public operationalReserveAddress;

    bool public tdeActive;
    bool public tdeStarted;
    bool public isFinalized = false;
    bool public capReached;
    uint256 public tdeDuration = 60 days;
    uint256 public tdeStartTime;

    function FTT() public {

    }

    modifier onlyTdeIssuer {
        require(msg.sender == tdeIssuer);
        _;
    }

    modifier tdeRunning {
        require(tdeActive && block.timestamp < tdeStartTime + tdeDuration);
        _;
    }

    modifier tdeEnded {
        require(((!tdeActive && block.timestamp > tdeStartTime + tdeDuration) && tdeStarted) || capReached);
        _;
    }

     
    function startTde()
        public
        onlyOwner
    {
        require(!isFinalized);
        tdeActive = true;
        tdeStarted = true;
        if (tdeStartTime == 0) {
            tdeStartTime = block.timestamp;
        }
        TdeStarted(tdeStartTime);
    }

     
    function stopTde(bool _restart)
        external
        onlyOwner
    {
      tdeActive = false;
      if (_restart) {
        tdeStartTime = 0;
      }
      TdeStopped(block.timestamp);
    }

     
    function extendTde(uint256 _time)
        external
        onlyOwner
    {
      tdeDuration = tdeDuration.add(_time);
    }

     
    function shortenTde(uint256 _time)
        external
        onlyOwner
    {
      tdeDuration = tdeDuration.sub(_time);
    }

     
    function setTdeIssuer(address _tdeIssuer)
        external
        onlyOwner
    {
        tdeIssuer = _tdeIssuer;
    }

     
    function setOperationalReserveAddress(address _operationalReserveAddress)
        external
        onlyOwner
        tdeRunning
    {
        operationalReserveAddress = _operationalReserveAddress;
    }

     
    function issueFTT(address _user, uint256 _fttAmount)
        public
        onlyTdeIssuer
        tdeRunning
        returns(bool)
    {
        uint256 newAmountIssued = fttIssued.add(_fttAmount);
        require(_user != address(0));
        require(_fttAmount > 0);
        require(newAmountIssued <= FT_TOKEN_SALE_CAP);

        balances[_user] = balances[_user].add(_fttAmount);
        fttIssued = newAmountIssued;
        FTTIssued(tdeIssuer, _user, _fttAmount, block.timestamp);

        if (fttIssued == FT_TOKEN_SALE_CAP) {
            capReached = true;
        }

        return true;
    }

     
    function fttIssued()
        external
        view
        returns (uint256)
    {
        return fttIssued;
    }

     
    function finalize()
        external
        tdeEnded
        onlyOwner
    {
        require(!isFinalized);

         
        uint256 teamVestingCliff = 15778476;   
        uint256 teamVestingDuration = 1 years;
        TokenVesting teamVesting = new TokenVesting(owner, now, teamVestingCliff, teamVestingDuration, true);
        teamVesting.transferOwnership(owner);
        teamVestingAddress = address(teamVesting);
        balances[teamVestingAddress] = FT_TEAM_FUND;

        if (!capReached) {
             
            uint256 unsoldVestingCliff = 3 years;
            uint256 unsoldVestingDuration = 10 years;
            TokenVesting unsoldVesting = new TokenVesting(owner, now, unsoldVestingCliff, unsoldVestingDuration, true);
            unsoldVesting.transferOwnership(owner);
            unsoldVestingAddress = address(unsoldVesting);
            balances[unsoldVestingAddress] = FT_TOKEN_SALE_CAP - fttIssued;
        }

         
        balances[operationalReserveAddress] = FT_OPERATIONAL_FUND - FT_TEAM_FUND;

        isFinalized = true;
        TdeFinalized(block.timestamp);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        if (!isFinalized) return false;
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

      
    function transfer(address _to, uint256 _value)
        public
        returns (bool)
    {
        if (!isFinalized) return false;
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function balanceOf(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        returns (bool success)
    {
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