 

pragma solidity 0.4.18;

 
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

contract YUPTimelock is Ownable {
    using SafeERC20 for StandardToken;
    using SafeMath for uint256;
    
     
    event IsLocked(uint256 _time);
    event IsClaiming(uint256 _time);
    event IsFinalized(uint256 _time);
    event Claimed(address indexed _to, uint256 _value);
    event ClaimedFutureUse(address indexed _to, uint256 _value);
    
     
    enum ContractState { Locked, Claiming, Finalized }
    ContractState public state;
    uint256 constant D160 = 0x0010000000000000000000000000000000000000000;
    StandardToken public token;
    mapping(address => uint256) public allocations;
    mapping(address => bool) public claimed;                 
    uint256 public expectedAmount = 193991920 * (10**18);    
    uint256 public amountLocked;
    uint256 public amountClaimed;
    uint256 public releaseTime;      
    uint256 public claimEndTime;     
    uint256 public fUseAmount;   
    address fUseBeneficiary;     
    uint256 fUseReleaseTime;     
    
     
    modifier isLocked() {
        require(state == ContractState.Locked);
        _;
    }
    
    modifier isClaiming() {
        require(state == ContractState.Claiming);
        _;
    }
    
    modifier isFinalized() {
        require(state == ContractState.Finalized);
        _;
    }
    
     
    function YUPTimelock(
        uint256 _releaseTime,
        uint256 _amountLocked,
        address _fUseBeneficiary,
        uint256 _fUseReleaseTime
    ) public {
        require(_releaseTime > now);
        
        releaseTime = _releaseTime;
        amountLocked = _amountLocked;
        fUseAmount = 84550000 * 10**18;      
        claimEndTime = now + 60*60*24*275;   
        fUseBeneficiary = _fUseBeneficiary;
        fUseReleaseTime = _fUseReleaseTime;
        
        if (amountLocked != expectedAmount)
            revert();
    }
    
     
    function setTokenAddr(StandardToken tokAddr) public onlyOwner {
        require(token == address(0x0));  
        
        token = tokAddr;
        
        state = ContractState.Locked;  
        IsLocked(now);
    }
    
     
    function getUserBalance(address _owner) public view returns (uint256) {
        if (claimed[_owner] == false && allocations[_owner] > 0)
            return allocations[_owner];
        else
            return 0;
    }
    
     
    function startClaim() public isLocked onlyOwner {
        state = ContractState.Claiming;
        IsClaiming(now);
    }
    
     
    function finalize() public isClaiming onlyOwner {
        require(now >= claimEndTime);
        
        state = ContractState.Finalized;
        IsFinalized(now);
    }
    
     
    function ownerClaim() public isFinalized onlyOwner {
        uint256 remaining = token.balanceOf(this);
        amountClaimed = amountClaimed.add(remaining);
        amountLocked = amountLocked.sub(remaining);
        
        token.safeTransfer(owner, remaining);
        Claimed(owner, remaining);
    }
    
     
    function loadBalances(uint256[] data) public isLocked onlyOwner {
        require(token != address(0x0));   
        
        for (uint256 i = 0; i < data.length; i++) {
            address addr = address(data[i] & (D160 - 1));
            uint256 amount = data[i] / D160;
            
            allocations[addr] = amount;
            claimed[addr] = false;
        }
    }
    
     
    function claimFutureUse() public onlyOwner {
        require(now >= fUseReleaseTime);
        
        amountClaimed = amountClaimed.add(fUseAmount);
        amountLocked = amountLocked.sub(fUseAmount);
        
        token.safeTransfer(fUseBeneficiary, fUseAmount);
        ClaimedFutureUse(fUseBeneficiary, fUseAmount);
    }
    
     
    function claim() external isClaiming {
        require(token != address(0x0));  
        require(now >= releaseTime);
        require(allocations[msg.sender] > 0);
        
        uint256 amount = allocations[msg.sender];
        allocations[msg.sender] = 0;
        claimed[msg.sender] = true;
        amountClaimed = amountClaimed.add(amount);
        amountLocked = amountLocked.sub(amount);
        
        token.safeTransfer(msg.sender, amount);
        Claimed(msg.sender, amount);
    }
}