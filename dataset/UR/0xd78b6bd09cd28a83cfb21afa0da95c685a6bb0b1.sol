 

pragma solidity 0.4.18;

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint256 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
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

contract ILivepeerToken is ERC20, Ownable {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _amount) public;
}

contract GenesisManager is Ownable {
    using SafeMath for uint256;

     
    ILivepeerToken public token;

     
    address public tokenDistribution;
     
    address public bankMultisig;
     
    address public minter;

     
    uint256 public initialSupply;
     
    uint256 public crowdSupply;
     
    uint256 public companySupply;
     
    uint256 public teamSupply;
     
    uint256 public investorsSupply;
     
    uint256 public communitySupply;

     
    uint256 public teamGrantsAmount;
     
    uint256 public investorsGrantsAmount;
     
    uint256 public communityGrantsAmount;

     
     
    uint256 public grantsStartTimestamp;

     
    mapping (address => address) public vestingHolders;
     
    mapping (address => address) public timeLockedHolders;

    enum Stages {
         
        GenesisAllocation,
         
        GenesisStart,
         
         
        GenesisEnd
    }

     
    Stages public stage;

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

     
    function GenesisManager(
        address _token,
        address _tokenDistribution,
        address _bankMultisig,
        address _minter,
        uint256 _grantsStartTimestamp
    )
        public
    {
        token = ILivepeerToken(_token);
        tokenDistribution = _tokenDistribution;
        bankMultisig = _bankMultisig;
        minter = _minter;
        grantsStartTimestamp = _grantsStartTimestamp;

        stage = Stages.GenesisAllocation;
    }

     
    function setAllocations(
        uint256 _initialSupply,
        uint256 _crowdSupply,
        uint256 _companySupply,
        uint256 _teamSupply,
        uint256 _investorsSupply,
        uint256 _communitySupply
    )
        external
        onlyOwner
        atStage(Stages.GenesisAllocation)
    {
        require(_crowdSupply.add(_companySupply).add(_teamSupply).add(_investorsSupply).add(_communitySupply) == _initialSupply);

        initialSupply = _initialSupply;
        crowdSupply = _crowdSupply;
        companySupply = _companySupply;
        teamSupply = _teamSupply;
        investorsSupply = _investorsSupply;
        communitySupply = _communitySupply;
    }

     
    function start() external onlyOwner atStage(Stages.GenesisAllocation) {
         
        token.mint(this, initialSupply);

        stage = Stages.GenesisStart;
    }

     
    function addTeamGrant(
        address _receiver,
        uint256 _amount,
        uint256 _timeToCliff,
        uint256 _vestingDuration
    )
        external
        onlyOwner
        atStage(Stages.GenesisStart)
    {
        uint256 updatedGrantsAmount = teamGrantsAmount.add(_amount);
         
        require(updatedGrantsAmount <= teamSupply);

        teamGrantsAmount = updatedGrantsAmount;

        addVestingGrant(_receiver, _amount, _timeToCliff, _vestingDuration);
    }

     
    function addInvestorGrant(
        address _receiver,
        uint256 _amount,
        uint256 _timeToCliff,
        uint256 _vestingDuration
    )
        external
        onlyOwner
        atStage(Stages.GenesisStart)
    {
        uint256 updatedGrantsAmount = investorsGrantsAmount.add(_amount);
         
        require(updatedGrantsAmount <= investorsSupply);

        investorsGrantsAmount = updatedGrantsAmount;

        addVestingGrant(_receiver, _amount, _timeToCliff, _vestingDuration);
    }

     
    function addVestingGrant(
        address _receiver,
        uint256 _amount,
        uint256 _timeToCliff,
        uint256 _vestingDuration
    )
        internal
    {
         
        require(vestingHolders[_receiver] == address(0));

         
         
        TokenVesting holder = new TokenVesting(_receiver, grantsStartTimestamp, _timeToCliff, _vestingDuration, true);
        vestingHolders[_receiver] = holder;

         
         
        holder.transferOwnership(bankMultisig);

        token.transfer(holder, _amount);
    }

     
    function addCommunityGrant(
        address _receiver,
        uint256 _amount
    )
        external
        onlyOwner
        atStage(Stages.GenesisStart)
    {
        uint256 updatedGrantsAmount = communityGrantsAmount.add(_amount);
         
        require(updatedGrantsAmount <= communitySupply);

        communityGrantsAmount = updatedGrantsAmount;

         
        require(timeLockedHolders[_receiver] == address(0));

         
        TokenTimelock holder = new TokenTimelock(token, _receiver, grantsStartTimestamp);
        timeLockedHolders[_receiver] = holder;

        token.transfer(holder, _amount);
    }

     
    function end() external onlyOwner atStage(Stages.GenesisStart) {
         
        token.transfer(tokenDistribution, crowdSupply);
         
        token.transfer(bankMultisig, companySupply);
         
        token.transferOwnership(minter);

        stage = Stages.GenesisEnd;
    }
}