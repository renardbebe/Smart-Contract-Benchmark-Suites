 

pragma solidity ^0.4.23;

 
library SafeMath 
{

   
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

 
contract Ownable 
{
  address public owner;

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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
  
}


 
contract Pausable is Ownable 
{
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

 
contract ERC20Basic 
{
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic 
{
  function allowance(address owner, address spender) public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

}

 
contract BasicToken is ERC20Basic 
{
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


 
contract StandardToken is ERC20, BasicToken 
{

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
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
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


 
contract PausableToken is StandardToken, Pausable 
{

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}


 
contract FrozenableToken is Ownable 
{
    
    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address indexed to, bool frozen);

    modifier whenNotFrozen(address _who) {
      require(!frozenAccount[msg.sender] && !frozenAccount[_who]);
      _;
    }

    function freezeAccount(address _to, bool _freeze) public onlyOwner {
        require(_to != address(0));
        frozenAccount[_to] = _freeze;
        emit FrozenFunds(_to, _freeze);
    }

}


 
contract Colorbay is PausableToken, FrozenableToken 
{

    string public name = "Colorbay Token";
    string public symbol = "CLOB";
    uint256 public decimals = 18;
    uint256 INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

     
    function() public payable {
        revert();
    }

     
    function transfer(address _to, uint256 _value) public whenNotFrozen(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotFrozen(_from) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }        
    
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;
  
    ERC20Basic public token;

    uint256 public planCount = 0;
    uint256 public payPool = 0;
    
     
    struct Plan {
       
      address beneficiary; 
      
       
      uint256 startTime;
      
       
      uint256 locktoTime;
      
       
      uint256 releaseStages; 
      
       
      uint256 endTime;
      
       
      uint256 totalToken;
      
       
      uint256 releasedAmount;
      
       
      bool revocable;
      
       
      bool isRevoked;
      
       
      string remark;
    }
    
     
    mapping (address => Plan) public plans;
    
    event Released(address indexed beneficiary, uint256 amount);
    event Revoked(address indexed beneficiary, uint256 refund);
    event AddPlan(address indexed beneficiary, uint256 startTime, uint256 locktoTime, uint256 releaseStages, uint256 endTime, uint256 totalToken, uint256 releasedAmount, bool revocable, bool isRevoked, string remark);
    
     
    constructor(address _token) public {
        token = ERC20Basic(_token);
    }

     
    modifier checkPayPool(uint256 _totalToken) {
        require(token.balanceOf(this) >= payPool.add(_totalToken));
        payPool = payPool.add(_totalToken);
        _;
    }

     
    modifier whenPlanExist(address _beneficiary) {
        require(_beneficiary != address(0));
        require(plans[_beneficiary].beneficiary != address(0));
        _;
    }
    
     
    function addPlan(address _beneficiary, uint256 _startTime, uint256 _locktoTime, uint256 _releaseStages, uint256 _endTime, uint256 _totalToken, bool _revocable, string _remark) public onlyOwner checkPayPool(_totalToken) {
        require(_beneficiary != address(0));
        require(plans[_beneficiary].beneficiary == address(0));

        require(_startTime > 0 && _locktoTime > 0 && _releaseStages > 0 && _totalToken > 0);
        require(_locktoTime > block.timestamp && _locktoTime >= _startTime  && _endTime > _locktoTime);

        plans[_beneficiary] = Plan(_beneficiary, _startTime, _locktoTime, _releaseStages, _endTime, _totalToken, 0, _revocable, false, _remark);
        planCount = planCount.add(1);
        emit AddPlan(_beneficiary, _startTime, _locktoTime, _releaseStages, _endTime, _totalToken, 0, _revocable, false, _remark);
    }
    
     
    function release(address _beneficiary) public whenPlanExist(_beneficiary) {

        require(!plans[_beneficiary].isRevoked);
        
        uint256 unreleased = releasableAmount(_beneficiary);

        if(unreleased > 0 && unreleased <= plans[_beneficiary].totalToken) {
            plans[_beneficiary].releasedAmount = plans[_beneficiary].releasedAmount.add(unreleased);
            payPool = payPool.sub(unreleased);
            token.safeTransfer(_beneficiary, unreleased);
            emit Released(_beneficiary, unreleased);
        }        
        
    }
    
     
    function releasableAmount(address _beneficiary) public view whenPlanExist(_beneficiary) returns (uint256) {
        return vestedAmount(_beneficiary).sub(plans[_beneficiary].releasedAmount);
    }

     
    function vestedAmount(address _beneficiary) public view whenPlanExist(_beneficiary) returns (uint256) {

        if (block.timestamp <= plans[_beneficiary].locktoTime) {
            return 0;
        } else if (plans[_beneficiary].isRevoked) {
            return plans[_beneficiary].releasedAmount;
        } else if (block.timestamp > plans[_beneficiary].endTime && plans[_beneficiary].totalToken == plans[_beneficiary].releasedAmount) {
            return plans[_beneficiary].totalToken;
        }
        
        uint256 totalTime = plans[_beneficiary].endTime.sub(plans[_beneficiary].locktoTime);
        uint256 totalToken = plans[_beneficiary].totalToken;
        uint256 releaseStages = plans[_beneficiary].releaseStages;
        uint256 endTime = block.timestamp > plans[_beneficiary].endTime ? plans[_beneficiary].endTime : block.timestamp;
        uint256 passedTime = endTime.sub(plans[_beneficiary].locktoTime);
        
        uint256 unitStageTime = totalTime.div(releaseStages);
        uint256 unitToken = totalToken.div(releaseStages);
        uint256 currStage = passedTime.div(unitStageTime);

        uint256 totalBalance = 0;        
        if(currStage > 0 && releaseStages == currStage && (totalTime % releaseStages) > 0 && block.timestamp < plans[_beneficiary].endTime) {
            totalBalance = unitToken.mul(releaseStages.sub(1));
        } else if(currStage > 0 && releaseStages == currStage) {
            totalBalance = totalToken;
        } else if(currStage > 0) {
            totalBalance = unitToken.mul(currStage);
        }
        return totalBalance;
        
    }
    
     
    function revoke(address _beneficiary) public onlyOwner whenPlanExist(_beneficiary) {

        require(plans[_beneficiary].revocable && !plans[_beneficiary].isRevoked);
        
         
        release(_beneficiary);

        uint256 refund = revokeableAmount(_beneficiary);
    
        plans[_beneficiary].isRevoked = true;
        payPool = payPool.sub(refund);
        
        token.safeTransfer(owner, refund);
        emit Revoked(_beneficiary, refund);
    }
    
     
    function revokeableAmount(address _beneficiary) public view whenPlanExist(_beneficiary) returns (uint256) {

        uint256 totalBalance = 0;
        
        if(plans[_beneficiary].isRevoked) {
            totalBalance = 0;
        } else if (block.timestamp <= plans[_beneficiary].locktoTime) {
            totalBalance = plans[_beneficiary].totalToken;
        } else {
            totalBalance = plans[_beneficiary].totalToken.sub(vestedAmount(_beneficiary));
        }
        return totalBalance;
    }
    
     
    function thisTokenBalance() public view returns (uint256) {
        return token.balanceOf(this);
    }

}