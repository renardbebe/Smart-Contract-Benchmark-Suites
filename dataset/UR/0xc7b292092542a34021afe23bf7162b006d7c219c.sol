 

pragma solidity 0.4.25;

 
library SafeMath {

   
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

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
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

 
contract DiscoperiTokenVesting {
    using SafeMath for uint256;  

     
    uint256 public constant VESTING_PARTS = 4;

     
    uint256[VESTING_PARTS] public vestingReleases;

     
    mapping (address => uint256) public vestedAmount;
    
     
    event Vesting(address indexed to, uint256 amount);    

       
    function hasVested(address _who) public view returns (bool) {
        return balanceVested(_who) > 0;
    }

            
    function balanceVested(address _who) public view returns (uint256) {
        for (uint256 i = 0; i < VESTING_PARTS; i++) {
            if (now < vestingReleases[i])  
               return vestedAmount[_who].mul(VESTING_PARTS - i).div(VESTING_PARTS);
        }
    } 
 
      
    function _vest(address _who, uint256 _amount) internal {
        require(_who != address(0), "Vesting target address can't be zero.");
        require(_amount > 0, "Vesting amount should be > 0.");
        vestedAmount[_who] = vestedAmount[_who].add(_amount);
        emit Vesting(_who, _amount);
    }        
}

 
contract DiscoperiTokenLockup {
    using SafeMath for uint256;  

     
    struct LockedUp {
        uint256 amount;  
        uint256 release;  
    }

     
    mapping (address => LockedUp[]) public lockedup;

     
    event Lockup(address indexed to, uint256 amount, uint256 release);

         
    function hasLockedUp(address _who) public view returns (bool) {
        return balanceLockedUp(_who) > 0;
    }    

            
    function balanceLockedUp(address _who) public view returns (uint256) {
        uint256 _balanceLockedUp = 0;
        for (uint256 i = 0; i < lockedup[_who].length; i++) {
            if (lockedup[_who][i].release > block.timestamp)  
                _balanceLockedUp = _balanceLockedUp.add(lockedup[_who][i].amount);
        }
        return _balanceLockedUp;
    }    
    
          
    function _lockup(address _who, uint256 _amount, uint256 _release) internal {
        if (_release != 0) {
            require(_who != address(0), "Lockup target address can't be zero.");
            require(_amount > 0, "Lockup amount should be > 0.");   
            require(_release > block.timestamp, "Lockup release time should be > now.");  
            lockedup[_who].push(LockedUp(_amount, _release));
            emit Lockup(_who, _amount, _release);
        }
    }      

}

 
contract IDiscoperiSale {
    
     
    function acquireTokens(uint256 _collector, uint256 _tx, address _beneficiary, uint256 _funds) external payable;

}

 
contract IDiscoperiToken {

     
    function burnSaleTokens() external;

      
    function transferWithVesting(address _to, uint256 _value) external returns (bool); 

}

 
contract DiscoperiToken is  
    IDiscoperiToken,
    StandardToken, 
    Ownable,
    DiscoperiTokenLockup,
    DiscoperiTokenVesting
{
    using SafeMath for uint256;

     
    string public constant name = "Discoperi Token";  
    string public constant symbol = "DISC";  
    uint8 public constant decimals = 18;  

     
    uint256 public constant TOTAL_SUPPLY = 200000000000 * (10 ** uint256(decimals));  

     
    uint256 public constant SALES_SUPPLY = 50000000000 * (10 ** uint256(decimals));  
    uint256 public constant INVESTORS_SUPPLY = 50000000000 * (10 ** uint256(decimals));  
    uint256 public constant TEAM_SUPPLY = 30000000000 * (10 ** uint256(decimals));  
    uint256 public constant RESERVE_SUPPLY = 22000000000 * (10 ** uint256(decimals));  
    uint256 public constant MARKET_DEV_SUPPLY = 20000000000 * (10 ** uint256(decimals));  
    uint256 public constant PR_ADVERSTISING_SUPPLY = 15000000000 * (10 ** uint256(decimals));  
    uint256 public constant REFERRAL_SUPPLY = 8000000000 * (10 ** uint256(decimals));  
    uint256 public constant ANGEL_INVESTORS_SUPPLY = 5000000000 * (10 ** uint256(decimals));  
    
     
    address public constant MARKET_DEV_ADDRESS = 0x3f272f26C2322cB38781D0C6C42B1c2531Ec79Be;
    address public constant TEAM_ADDRESS = 0xD8069C8c24D10023DBC5823156994aC2A638dBBd;
    address public constant RESERVE_ADDRESS = 0x7656Cee371A812775A5E0Fb98a565Cc731aCC44B;
    address public constant INVESTORS_ADDRESS= 0x25230591492198b6DD4363d03a7dAa5aD7590D2d;
    address public constant PR_ADVERSTISING_ADDRESS = 0xC36d70AE6ddBE87F973bf4248Df52d0370FBb7E7;

     
    address public sale;

     
    modifier onlySale() {
        require(msg.sender == sale, "Attemp to execute by not sale address");
        _;
    }

     
    modifier onlyLockupAuthorized() {
        require(msg.sender == INVESTORS_ADDRESS, "Attemp to lockup tokens by not authorized address");
        _;
    }

     
    modifier spotTransfer(address _from, uint256 _value) {
        require(_value <= balanceSpot(_from), "Attempt to transfer more than balance spot");
        _;
    }

     
    event Burn(address indexed burner, uint256 value);

     
    constructor() public { 
        balances[INVESTORS_ADDRESS] = balances[INVESTORS_ADDRESS].add(INVESTORS_SUPPLY);
        totalSupply_ = totalSupply_.add(INVESTORS_SUPPLY);
        emit Transfer(address(0), INVESTORS_ADDRESS, INVESTORS_SUPPLY);

        balances[INVESTORS_ADDRESS] = balances[INVESTORS_ADDRESS].add(ANGEL_INVESTORS_SUPPLY);
        totalSupply_ = totalSupply_.add(ANGEL_INVESTORS_SUPPLY);
        emit Transfer(address(0), INVESTORS_ADDRESS, ANGEL_INVESTORS_SUPPLY);
    }

     
    function init(
        address _sale, 
        uint256 _teamRelease, 
        uint256 _vestingFirstRelease,
        uint256 _vestingSecondRelease,
        uint256 _vestingThirdRelease,
        uint256 _vestingFourthRelease
    ) 
        external 
        onlyOwner 
    {
        require(sale == address(0), "cannot execute init function twice");
        require(_sale != address(0), "cannot set zero address as sale");
        require(_teamRelease > now, "team tokens release date should be > now");  
        require(_vestingFirstRelease > now, "vesting first release date should be > now");  
        require(_vestingSecondRelease > now, "vesting second release date should be > now");  
        require(_vestingThirdRelease > now, "vesting third release date should be > now");  
        require(_vestingFourthRelease > now, "vesting fourth release date should be > now");  

        sale = _sale;

        balances[sale] = balances[sale].add(SALES_SUPPLY);
        totalSupply_ = totalSupply_.add(SALES_SUPPLY);
        emit Transfer(address(0), sale, SALES_SUPPLY);

        balances[sale] = balances[sale].add(REFERRAL_SUPPLY);
        totalSupply_ = totalSupply_.add(REFERRAL_SUPPLY);
        emit Transfer(address(0), sale, REFERRAL_SUPPLY);

        TokenTimelock teamTimelock = new TokenTimelock(this, TEAM_ADDRESS, _teamRelease);
        balances[teamTimelock] = balances[teamTimelock].add(TEAM_SUPPLY);
        totalSupply_ = totalSupply_.add(TEAM_SUPPLY);
        emit Transfer(address(0), teamTimelock, TEAM_SUPPLY);
         
        balances[MARKET_DEV_ADDRESS] = balances[MARKET_DEV_ADDRESS].add(MARKET_DEV_SUPPLY);
        totalSupply_ = totalSupply_.add(MARKET_DEV_SUPPLY);
        emit Transfer(address(0), MARKET_DEV_ADDRESS, MARKET_DEV_SUPPLY);

        balances[RESERVE_ADDRESS] = balances[RESERVE_ADDRESS].add(RESERVE_SUPPLY);
        totalSupply_ = totalSupply_.add(RESERVE_SUPPLY);
        emit Transfer(address(0), RESERVE_ADDRESS, RESERVE_SUPPLY);
       
        balances[PR_ADVERSTISING_ADDRESS] = balances[PR_ADVERSTISING_ADDRESS].add(PR_ADVERSTISING_SUPPLY);
        totalSupply_ = totalSupply_.add(PR_ADVERSTISING_SUPPLY);
        emit Transfer(address(0), PR_ADVERSTISING_ADDRESS, PR_ADVERSTISING_SUPPLY);

        vestingReleases[0] = _vestingFirstRelease;
        vestingReleases[1] = _vestingSecondRelease;
        vestingReleases[2] = _vestingThirdRelease;
        vestingReleases[3] = _vestingFourthRelease;
    }

     
    function transferWithVesting(address _to, uint256 _value) external onlySale returns (bool) {    
        _vest(_to, _value);
        return super.transfer(_to, _value);
    }

     
    function transferWithLockup(address _to, uint256 _value, uint256 _release) external onlyLockupAuthorized returns (bool) {    
        _lockup(_to, _value, _release);
        return super.transfer(_to, _value);
    }

     
    function burnSaleTokens() external onlySale {
        uint256 _amount = balances[sale];
        balances[sale] = 0;
        totalSupply_ = totalSupply_.sub(_amount);
        emit Burn(sale, _amount);
        emit Transfer(sale, address(0), _amount);        
    }

     
    function transfer(address _to, uint256 _value) public spotTransfer(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public spotTransfer(_from, _value) returns (bool) {    
        return super.transferFrom(_from, _to, _value);
    }

        
    function balanceSpot(address _who) public view returns (uint256) {
        return balanceOf(_who).sub(balanceVested(_who)).sub(balanceLockedUp(_who));
    }     

}