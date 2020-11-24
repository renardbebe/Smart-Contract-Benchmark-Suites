 

pragma solidity 0.4.24;
 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

contract IHuddlToken is IERC20{

    function mint(address to, uint256 value)external returns (bool);
    
    function decimals() public view returns(uint8);
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

contract HuddlDistribution is Ownable {
    
    using SafeMath for uint256;

    IHuddlToken token;
    
    uint256 lastReleasedQuarter;

    address public usersPool;
    address public contributorsPool;
    address public reservePool;

    uint256 public inflationRate;
     
    uint16 public constant INFLATION_RATE_OF_CHANGE = 400;

    uint256 public contributorDistPercent;
    uint256 public reserveDistPercent;

    uint16 public contributorROC;
    uint16 public reserveROC;

    uint8 public lastQuarter; 
    
    bool public launched;
    
     
    uint256 public constant MAX_SUPPLY = 1000000000000000000000000000;

    uint256[] public quarterSchedule;

    event DistributionLaunched();

    event TokensReleased(
        uint256 indexed userShare, 
        uint256 indexed reserveShare, 
        uint256 indexed contributorShare
    );

    event ReserveDistributionPercentChanged(uint256 indexed newPercent);

    event ContributorDistributionPercentChanged(uint256 indexed newPercent);

    event ReserveROCChanged(uint256 indexed newROC);

    event ContributorROCChanged(uint256 indexed newROC);

    modifier distributionLaunched() {
        require(launched, "Distribution not launched");
        _;
    }

    modifier quarterRunning() {
        require(
            lastQuarter < 72 && now >= quarterSchedule[lastQuarter],
            "Quarter not started"
        );
        _;
    }

    constructor(
        address huddlTokenAddress, 
        address _usersPool, 
        address _contributorsPool, 
        address _reservePool
    )
        public 
    {

        require(
            huddlTokenAddress != address(0), 
            "Please provide valid huddl token address"
        );
        require(
            _usersPool != address(0), 
            "Please provide valid user pool address"
        );
        require(
            _contributorsPool != address(0), 
            "Please provide valid contributors pool address"
        );
        require(
            _reservePool != address(0), 
            "Please provide valid reserve pool address"
        );
        
        usersPool = _usersPool;
        contributorsPool = _contributorsPool;
        reservePool = _reservePool;

         
        inflationRate = 100000000000000000;

         
        contributorDistPercent = 333330000000000000; 
        reserveDistPercent = 333330000000000000;
        
         
        contributorROC = 100; 
        reserveROC = 100; 

        token = IHuddlToken(huddlTokenAddress);

         
        quarterSchedule.push(1554076800);  
        quarterSchedule.push(1561939200);  
        quarterSchedule.push(1569888000);  
        quarterSchedule.push(1577836800);  
        quarterSchedule.push(1585699200);  
        quarterSchedule.push(1593561600);  
        quarterSchedule.push(1601510400);  
        quarterSchedule.push(1609459200);  
        quarterSchedule.push(1617235200);  
        quarterSchedule.push(1625097600);  
        quarterSchedule.push(1633046400);  
        quarterSchedule.push(1640995200);  
        quarterSchedule.push(1648771200);  
        quarterSchedule.push(1656633600);  
        quarterSchedule.push(1664582400);  
        quarterSchedule.push(1672531200);  
        quarterSchedule.push(1680307200);  
        quarterSchedule.push(1688169600);  
        quarterSchedule.push(1696118400);  
        quarterSchedule.push(1704067200);  
        quarterSchedule.push(1711929600);  
        quarterSchedule.push(1719792000);  
        quarterSchedule.push(1727740800);  
        quarterSchedule.push(1735689600);  
        quarterSchedule.push(1743465600);  
        quarterSchedule.push(1751328000);  
        quarterSchedule.push(1759276800);  
        quarterSchedule.push(1767225600);  
        quarterSchedule.push(1775001600);  
        quarterSchedule.push(1782864000);  
        quarterSchedule.push(1790812800);  
        quarterSchedule.push(1798761600);  
        quarterSchedule.push(1806537600);  
        quarterSchedule.push(1814400000);  
        quarterSchedule.push(1822348800);  
        quarterSchedule.push(1830297600);  
        quarterSchedule.push(1838160000);  
        quarterSchedule.push(1846022400);  
        quarterSchedule.push(1853971200);  
        quarterSchedule.push(1861920000);  
        quarterSchedule.push(1869696000);  
        quarterSchedule.push(1877558400);  
        quarterSchedule.push(1885507200);  
        quarterSchedule.push(1893456000);  
        quarterSchedule.push(1901232000);  
        quarterSchedule.push(1909094400);  
        quarterSchedule.push(1917043200);  
        quarterSchedule.push(1924992000);  
        quarterSchedule.push(1932768000);  
        quarterSchedule.push(1940630400);  
        quarterSchedule.push(1948579200);  
        quarterSchedule.push(1956528000);  
        quarterSchedule.push(1964390400);  
        quarterSchedule.push(1972252800);  
        quarterSchedule.push(1980201600);  
        quarterSchedule.push(1988150400);  
        quarterSchedule.push(1995926400);  
        quarterSchedule.push(2003788800);  
        quarterSchedule.push(2011737600);  
        quarterSchedule.push(2019686400);  
        quarterSchedule.push(2027462400);  
        quarterSchedule.push(2035324800);  
        quarterSchedule.push(2043273600);  
        quarterSchedule.push(2051222400);  
        quarterSchedule.push(2058998400);  
        quarterSchedule.push(2066860800);  
        quarterSchedule.push(2074809600);  
        quarterSchedule.push(2082758400);  
        quarterSchedule.push(2090620800);  
        quarterSchedule.push(2098483200);  
        quarterSchedule.push(2106432000);  
        quarterSchedule.push(2114380800);  

    }

     
    function launchDistribution() external onlyOwner {

        require(!launched, "Distribution already launched");

        launched = true;

        (
            uint256 userShare, 
            uint256 reserveShare, 
            uint256 contributorShare
        ) = getDistributionShares(token.totalSupply());

        token.transfer(usersPool, userShare);
        token.transfer(contributorsPool, contributorShare);
        token.transfer(reservePool, reserveShare);
        adjustDistributionPercentage();
        emit DistributionLaunched();
    } 

     
    function releaseTokens()
        external 
        onlyOwner 
        distributionLaunched
        quarterRunning 
        returns(bool)
    {   
        
         
        lastQuarter = lastQuarter + 1;

         
        uint256 amount = getTokensToMint();

         
        require(amount>0, "No tokens to be released");

         
        (
            uint256 userShare, 
            uint256 reserveShare, 
            uint256 contributorShare
        ) = getDistributionShares(amount);

         
        adjustInflationRate();

         
        adjustDistributionPercentage();

         
        token.mint(usersPool, userShare);
        token.mint(contributorsPool, contributorShare);
        token.mint(reservePool, reserveShare);

         
        emit TokensReleased(
            userShare, 
            reserveShare, 
            contributorShare
        );
    }
   
     
    function nextReleaseTime() external view returns(uint256 time) {
        time = quarterSchedule[lastQuarter];
    }

     
    function canRelease() external view returns(bool release) {
        release = now >= quarterSchedule[lastQuarter];
    }

     
    function userDistributionPercent() external view returns(uint256) {
        uint256 totalPercent = 1000000000000000000;
        return(
            totalPercent.sub(contributorDistPercent.add(reserveDistPercent))
        );
    }

     
    function changeReserveDistributionPercent(
        uint256 newPercent
    )
        external 
        onlyOwner
    {
        reserveDistPercent = newPercent;
        emit ReserveDistributionPercentChanged(newPercent);
    }

     
    function changeContributorDistributionPercent(
        uint256 newPercent
    )
        external 
        onlyOwner
    {
        contributorDistPercent = newPercent;
        emit ContributorDistributionPercentChanged(newPercent);
    }

     
    function changeReserveROC(uint16 newROC) external onlyOwner {
        reserveROC = newROC;
        emit ReserveROCChanged(newROC);
    }

     
    function changeContributorROC(uint16 newROC) external onlyOwner {
        contributorROC = newROC;
        emit ContributorROCChanged(newROC);
    }

     
    function getDistributionShares(
        uint256 amount
    )
        public 
        view 
        returns(
            uint256 userShare, 
            uint256 reserveShare, 
            uint256 contributorShare
        )
    {
        contributorShare = contributorDistPercent.mul(
            amount.div(10**uint256(token.decimals()))
        );

        reserveShare = reserveDistPercent.mul(
            amount.div(10**uint256(token.decimals()))
        );

        userShare = amount.sub(
            contributorShare.add(reserveShare)
        );

        assert(
            contributorShare.add(reserveShare).add(userShare) == amount
        );
    }

    
         
    function getTokensToMint() public view returns(uint256 amount) {
        
        if (MAX_SUPPLY == token.totalSupply()){
            return 0;
        }

         
        amount = token.totalSupply().div(
            10 ** uint256(token.decimals())
        ).mul(inflationRate);

        if (amount.add(token.totalSupply()) > MAX_SUPPLY){
            amount = MAX_SUPPLY.sub(token.totalSupply());
        }
    }

    function adjustDistributionPercentage() private {
        contributorDistPercent = contributorDistPercent.sub(
            contributorDistPercent.mul(contributorROC).div(10000)
        );

        reserveDistPercent = reserveDistPercent.sub(
            reserveDistPercent.mul(reserveROC).div(10000)
        );
    }

    function adjustInflationRate() private {
        inflationRate = inflationRate.sub(
            inflationRate.mul(INFLATION_RATE_OF_CHANGE).div(10000)
        );
    }

    
}

 

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

 

 
contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

 

 
contract HuddlToken is ERC20Mintable{

    using SafeMath for uint256;

    string private _name;
    string private _symbol ;
    uint8 private _decimals;

    constructor(
        string name, 
        string symbol, 
        uint8 decimals, 
        uint256 totalSupply
    )
        public 
    {
    
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        
         
         
        _mint(msg.sender, totalSupply.mul(10 ** uint256(decimals)));
    }

    
     
    function name() public view returns(string) {
        return _name;
    }

     
    function symbol() public view returns(string) {
        return _symbol;
    }

     
    function decimals() public view returns(uint8) {
        return _decimals;
    }

}

 

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) 
            _;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}