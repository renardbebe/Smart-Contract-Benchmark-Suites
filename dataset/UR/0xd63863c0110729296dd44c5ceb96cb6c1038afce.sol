 

pragma solidity ^0.4.18;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract LibraToken is StandardToken {

    string public constant name = "LibraToken";  
    string public constant symbol = "LBA";  
    uint8 public constant decimals = 18;  

    uint256 public constant INITIAL_SUPPLY = (10 ** 9) * (10 ** uint256(decimals));

     
    function LibraToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
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

contract LibraTokenVault is Ownable {
    using SafeMath for uint256;

     
    address public teamReserveWallet = 0x373c69fDedE072A3F5ab1843a0e5fE0102Cc6793;
    address public firstReserveWallet = 0x99C83f62DBE1a488f9C9d370DA8e86EC55224eB4;
    address public secondReserveWallet = 0x90DfF11810dA6227d348C86C59257C1C0033D307;

     
    uint256 public teamReserveAllocation = 2 * (10 ** 8) * (10 ** 18);
    uint256 public firstReserveAllocation = 15 * (10 ** 7) * (10 ** 18);
    uint256 public secondReserveAllocation = 15 * (10 ** 7) * (10 ** 18);

     
    uint256 public totalAllocation = 5 * (10 ** 8) * (10 ** 18);

    uint256 public teamTimeLock = 2 * 365 days;
    uint256 public teamVestingStages = 8;
    uint256 public firstReserveTimeLock = 2 * 365 days;
    uint256 public secondReserveTimeLock = 3 * 365 days;

     
    mapping(address => uint256) public allocations;

       
    mapping(address => uint256) public timeLocks;

     
    mapping(address => uint256) public claimed;

     
    uint256 public lockedAt = 0;

    LibraToken public token;

     
    event Allocated(address wallet, uint256 value);

     
    event Distributed(address wallet, uint256 value);

     
    event Locked(uint256 lockTime);

     
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier onlyTeamReserve {
        require(msg.sender == teamReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier onlyTokenReserve {
        require(msg.sender == firstReserveWallet || msg.sender == secondReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier notLocked {
        require(lockedAt == 0);
        _;
    }

    modifier locked {
        require(lockedAt > 0);
        _;
    }

     
    modifier notAllocated {
        require(allocations[teamReserveWallet] == 0);
        require(allocations[firstReserveWallet] == 0);
        require(allocations[secondReserveWallet] == 0);
        _;
    }

    function LibraTokenVault(ERC20 _token) public {

        owner = msg.sender;
        token = LibraToken(_token);
        
    }

    function allocate() public notLocked notAllocated onlyOwner {

         
        require(token.balanceOf(address(this)) == totalAllocation);
        
        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[firstReserveWallet] = firstReserveAllocation;
        allocations[secondReserveWallet] = secondReserveAllocation;

        Allocated(teamReserveWallet, teamReserveAllocation);
        Allocated(firstReserveWallet, firstReserveAllocation);
        Allocated(secondReserveWallet, secondReserveAllocation);

        lock();
    }

     
    function lock() internal notLocked onlyOwner {

        lockedAt = block.timestamp;

        timeLocks[teamReserveWallet] = lockedAt.add(teamTimeLock);
        timeLocks[firstReserveWallet] = lockedAt.add(firstReserveTimeLock);
        timeLocks[secondReserveWallet] = lockedAt.add(secondReserveTimeLock);

        Locked(lockedAt);
    }

     
     
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

         
        require(token.transfer(owner, token.balanceOf(address(this))));
    }

     
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

     
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return allocations[msg.sender].sub(claimed[msg.sender]);

    }

     
    function claimTokenReserve() onlyTokenReserve locked public {

        address reserveWallet = msg.sender;

         
        require(block.timestamp > timeLocks[reserveWallet]);

         
        require(claimed[reserveWallet] == 0);

        uint256 amount = allocations[reserveWallet];

        claimed[reserveWallet] = amount;

        require(token.transfer(reserveWallet, amount));

        Distributed(reserveWallet, amount);
    }

     
    function claimTeamReserve() onlyTeamReserve locked public {

        uint256 vestingStage = teamVestingStage();

         
        uint256 totalUnlocked = vestingStage.mul(allocations[teamReserveWallet]).div(teamVestingStages);

        require(totalUnlocked <= allocations[teamReserveWallet]);

         
        require(claimed[teamReserveWallet] < totalUnlocked);

        uint256 payment = totalUnlocked.sub(claimed[teamReserveWallet]);

        claimed[teamReserveWallet] = totalUnlocked;

        require(token.transfer(teamReserveWallet, payment));

        Distributed(teamReserveWallet, payment);
    }

     
    function teamVestingStage() public view onlyTeamReserve returns(uint256){
        
         
        uint256 vestingMonths = teamTimeLock.div(teamVestingStages); 

        uint256 stage = (block.timestamp.sub(lockedAt)).div(vestingMonths);

         
        if(stage > teamVestingStages){
            stage = teamVestingStages;
        }

        return stage;

    }

     
    function canCollect() public view onlyReserveWallets returns(bool) {

        return block.timestamp > timeLocks[msg.sender] && claimed[msg.sender] == 0;

    }

}