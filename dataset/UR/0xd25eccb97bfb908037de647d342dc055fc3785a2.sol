 

pragma solidity ^0.4.25;




 
contract AccessControl {
     
    event ContractUpgrade(address newContract);
    event Paused();
    event Unpaused();

     
    address public ceoAddress;

     
    address public cfoAddress;

     
    address public cooAddress;

     
    address public withdrawalAddress;

    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
    modifier onlyCLevel() {
        require(
        msg.sender == cooAddress ||
        msg.sender == ceoAddress ||
        msg.sender == cfoAddress
        );
        _;
    }

     
    modifier onlyCEOOrCFO() {
        require(
        msg.sender == cfoAddress ||
        msg.sender == ceoAddress
        );
        _;
    }

     
    modifier onlyCEOOrCOO() {
        require(
        msg.sender == cooAddress ||
        msg.sender == ceoAddress
        );
        _;
    }

     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyCLevel whenNotPaused {
        paused = true;
        emit Paused();
    }

     
    function unpause() public onlyCEO whenPaused {
        paused = false;
        emit Unpaused();
    }
}

 
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


contract LockToken is AccessControl {
    mapping (address => uint256) private lockTokenNum;
    mapping (address => uint256) private lockTokenTime;
    
    event SetLockTokenNum(address from,uint256 num);
    event SetLockTokenTime(address from,uint256 time);
    event SetLockTokenInfo(address from,uint256 num,uint256 time);

    function setLockTokenNum (address from,uint256 num) public  whenNotPaused onlyCEO {
        require(from != address(0));
        lockTokenNum[from] = num;
        emit SetLockTokenNum(from,num);
    }
    
    function setLockTokenTime(address from,uint256 time) public whenNotPaused onlyCEO {
        require(from != address(0));
        lockTokenTime[from] = time;
        emit SetLockTokenTime(from,time);
    }
    
    function setLockTokenInfo(address from,uint256 num,uint256 time) public whenNotPaused onlyCEO {
        require(from != address(0));
        lockTokenNum[from] = num;
        lockTokenTime[from] = time;
        emit SetLockTokenInfo(from,num,time);
    }
    
    
    function setLockTokenInfoList (address[] froms,uint256[] nums, uint256[] times) public whenNotPaused onlyCEO {
        for(uint256 i =0;i<froms.length ;i++ ){
            require(froms[i] != address(0));
            lockTokenNum[froms[i]] = nums[i];
            lockTokenTime[froms[i]] = times[i];
        }
    }
    
    function getLockTokenNum (address from) public view returns (uint256) {
        require(from != address(0));
        return lockTokenNum[from];
    }
    
    function getLockTokenTime(address from) public view returns (uint256) {
        require(from != address(0));
        return lockTokenTime[from];
    }
    
    function getBlockTime() public view returns(uint256){
        return block.timestamp;
    }
}

 
contract ERC20 is IERC20,LockToken{
  using SafeMath for uint256;

  mapping (address => uint256) public _balances;

  mapping (address => mapping (address => uint256)) public _allowed;

  uint256 public _totalSupply;

   
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
    view whenNotPaused
    returns (uint256) 
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    uint256 time = getLockTokenTime(msg.sender);
    uint256 blockTime = block.timestamp;
    require(blockTime >time);
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    require(spender != address(0));
    uint256 time = getLockTokenTime(msg.sender);
    uint256 blockTime = block.timestamp;
    require(blockTime >time);
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public whenNotPaused
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
    uint256 time = getLockTokenTime(from);
    uint256 blockTime = block.timestamp;
    require(blockTime >time);
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
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

   
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

   
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}



 
contract FTV is ERC20 {

  string public constant name = "fashion tv";
  string public constant symbol = "FTV";
  uint8 public constant decimals = 8;

  uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));

   
  constructor() public {
    paused =false;
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    _mint(msg.sender, INITIAL_SUPPLY);
  }

}