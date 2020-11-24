 

pragma solidity ^0.4.21;

 

 
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

contract TokenVesting is Ownable {
    using SafeMath for uint256;

     

     
    address public token;

     
    uint256 public totalToken;

     
    uint256 public startingTime;

     
    uint256 public nStages;

     
    uint256 public period;

     
    uint256 public vestInterval;

     
    address public beneficiary;

     
    bool revoked;

     
    event Claimed(uint256 amount);

    constructor() public {
    }

    function initialize(
        address _token,
        uint256 _startingTime,
        uint256 _nStages,
        uint256 _period,
        uint256 _vestInterval,
        address _beneficiary
    ) onlyOwner {
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        require(token == 0x0);
        require(_nStages > 0 && _period > 0 && _vestInterval > 0);
        require(_period % _nStages == 0);
        require(_period % _vestInterval == 0);

        token = _token;
        startingTime = _startingTime;
        nStages = _nStages;
        period = _period;
        vestInterval = _vestInterval;
        beneficiary = _beneficiary;

        StandardToken vestToken = StandardToken(token);
        totalToken = vestToken.allowance(msg.sender, this);
        vestToken.transferFrom(msg.sender, this, totalToken);
    }

    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

    function balance() public view returns (uint256) {
        StandardToken vestToken = StandardToken(token);
        return vestToken.balanceOf(this);
    }

    function claimable() public view returns (uint256) {
        uint256 elapsedSecs = getCurrentTimestamp() - startingTime;
        if (elapsedSecs <= 0) {
            return 0;
        }

        uint256 currentPeriod = elapsedSecs.div(30 days);
        currentPeriod = currentPeriod.div(vestInterval).mul(vestInterval);

         
        if (currentPeriod < period / nStages) {
            return 0;
        }

        if (currentPeriod > period)  {
            currentPeriod = period;
        }

         
        uint256 totalClaimable = totalToken.mul(currentPeriod).div(period);
        uint256 totalLeftOvers = totalToken.sub(totalClaimable);
        uint256 claimable_ = balance().sub(totalLeftOvers);

        return claimable_;
    }

    function claim() public {
        require(!revoked);

        uint256 claimable_ = claimable();
        require(claimable_ > 0);

        StandardToken vestToken = StandardToken(token);
        vestToken.transfer(beneficiary, claimable_);

        emit Claimed(claimable_);
    }

    function revoke() onlyOwner public {
        require(!revoked);

        StandardToken vestToken = StandardToken(token);
        vestToken.transfer(owner, balance());
        revoked = true;
    }

    function () payable {
        revert();
    }
}