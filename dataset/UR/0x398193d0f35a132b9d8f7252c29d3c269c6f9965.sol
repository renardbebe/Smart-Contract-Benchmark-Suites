 

pragma solidity ^0.4.24;
 
 

pragma solidity ^0.4.24;

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
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

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() public {
    pausers.add(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function renouncePauser() public {
    pausers.remove(msg.sender);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

contract Pausable is PauserRole {
  event Paused();
  event Unpaused();

  bool private _paused = false;


   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused();
  }
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
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
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
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(_balances[to].add(value) > _balances[to]);
    require(to != address(0));

    uint previousBalances = _balances[from].add(_balances[to]);
    assert(_balances[from].add(_balances[to]) == previousBalances);
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

   
  function retrieveFrom(
    address from,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(_balances[msg.sender].add(value) > _balances[msg.sender]);

    uint previousBalances = _balances[from].add(_balances[msg.sender]);
    assert(_balances[from].add(_balances[msg.sender]) == previousBalances);

    _balances[from] = _balances[from].sub(value);
    _balances[msg.sender] = _balances[msg.sender].add(value);
    emit Transfer(from, msg.sender, value);
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
  
     
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    _allowed[msg.sender][_spender] = (
    _allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = _allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      _allowed[msg.sender][_spender] = 0;
    } else {
      _allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
    return true;
   }
}


contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function sudoBurnFrom(address from, uint256 value) public {
    _burn(from, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }

   
  function _burn(address who, uint256 value) internal {
    super._burn(who, value);
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

contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
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

contract ERC20Pausable is ERC20, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

contract StandardTokenERC20Custom is ERC20Detailed, ERC20Burnable, ERC20Pausable, ERC20Mintable {

  using SafeERC20 for ERC20;

   
   
   
   
   

  constructor(string name, string symbol, uint8 decimals, uint256 _totalSupply)
    ERC20Pausable()
    ERC20Burnable()
    ERC20Detailed(name, symbol, decimals)
    ERC20()
    public
  {
    _mint(msg.sender, _totalSupply * (10 ** uint256(decimals)));
    addPauser(msg.sender);
    addMinter(msg.sender);
  }

  function approveAndPlayFunc(address _spender, uint _value, string _func) public returns(bool success){
    require(_spender != address(this));
    require(super.approve(_spender, _value));
    require(_spender.call(bytes4(keccak256(string(abi.encodePacked(_func, "(address,uint256)")))), msg.sender, _value));
    return true;
  }
}

library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
  }
}


 
 
contract Ownership {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

     
    function estalishOwnership() public {
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


 
contract Bank is Ownership {

    function terminate() public onlyOwner {
        selfdestruct(owner);
    }

    function withdraw(uint amount) payable public onlyOwner {
        if(!owner.send(amount)) revert();
    }

    function depositSpecificAmount(uint _deposit) payable public onlyOwner {
        require(msg.value == _deposit);
    }

    function deposit() payable public onlyOwner {
        require(msg.value > 0);
    }

  
}

 
contract LuckyBar is Bank {

    struct record {
        uint[5] date;
        uint[5] amount;
        address[5] account;
    }
    
    struct pair {
        uint256 maxBet;
        uint256 minBet;
        uint256 houseEdge;  
        uint256 reward;
        bool bEnabled;
        record ranking;
        record latest;
    }

    pair public sE2E;
    pair public sE2C;
    pair public sC2E;
    pair public sC2C;

    uint256 public E2C_Ratio;
    uint256 private salt;
    IERC20 private token;
    StandardTokenERC20Custom private chip;
    address public manager;

     
     
    event Won(bool _status, string _rewardType, uint _amount);
    event Swapped(string _target, uint _amount);

     
    constructor() payable public {
        estalishOwnership();
        setProperties("thisissaltIneedtomakearandomnumber", 100000);
        setToken(0x0bfd1945683489253e401485c6bbb2cfaedca313);  
        setChip(0x27a88bfb581d4c68b0fb830ee4a493da94dcc86c);  
        setGameMinBet(100e18, 0.1 ether, 100e18, 0.1 ether);
        setGameMaxBet(10000000e18, 1 ether, 100000e18, 1 ether);
        setGameFee(1,0,5,5);
        enableGame(true, true, false, true);
        setReward(0,5000,0,5000);
        manager = owner;
    }
    
    function getRecordsE2E() public view returns(uint[5], uint[5], address[5],uint[5], uint[5], address[5]) {
        return (sE2E.ranking.date,sE2E.ranking.amount,sE2E.ranking.account, sE2E.latest.date,sE2E.latest.amount,sE2E.latest.account);
    }
    function getRecordsE2C() public view returns(uint[5], uint[5], address[5],uint[5], uint[5], address[5]) {
        return (sE2C.ranking.date,sE2C.ranking.amount,sE2C.ranking.account, sE2C.latest.date,sE2C.latest.amount,sE2C.latest.account);
    }
    function getRecordsC2E() public view returns(uint[5], uint[5], address[5],uint[5], uint[5], address[5]) {
        return (sC2E.ranking.date,sC2E.ranking.amount,sC2E.ranking.account, sC2E.latest.date,sC2E.latest.amount,sC2E.latest.account);
    }
    function getRecordsC2C() public view returns(uint[5], uint[5], address[5],uint[5], uint[5], address[5]) {
        return (sC2C.ranking.date,sC2C.ranking.amount,sC2C.ranking.account, sC2C.latest.date,sC2C.latest.amount,sC2C
        .latest.account);
    }

    function emptyRecordsE2E() public onlyOwner {
        for(uint i=0;i<5;i++) {
            sE2E.ranking.amount[i] = 0;
            sE2E.ranking.date[i] = 0;
            sE2E.ranking.account[i] = 0x0;
            sE2E.latest.amount[i] = 0;
            sE2E.latest.date[i] = 0;
            sE2E.latest.account[i] = 0x0;
        }
    }

    function emptyRecordsE2C() public onlyOwner {
        for(uint i=0;i<5;i++) {
            sE2C.ranking.amount[i] = 0;
            sE2C.ranking.date[i] = 0;
            sE2C.ranking.account[i] = 0x0;
            sE2C.latest.amount[i] = 0;
            sE2C.latest.date[i] = 0;
            sE2C.latest.account[i] = 0x0;
        }
    }

    function emptyRecordsC2E() public onlyOwner {
        for(uint i=0;i<5;i++) {
            sC2E.ranking.amount[i] = 0;
            sC2E.ranking.date[i] = 0;
            sC2E.ranking.account[i] = 0x0;
            sC2E.latest.amount[i] = 0;
            sC2E.latest.date[i] = 0;
            sC2E.latest.account[i] = 0x0;     
        }
    }

    function emptyRecordsC2C() public onlyOwner {
        for(uint i=0;i<5;i++) {
            sC2C.ranking.amount[i] = 0;
            sC2C.ranking.date[i] = 0;
            sC2C.ranking.account[i] = 0x0;
            sC2C.latest.amount[i] = 0;
            sC2C.latest.date[i] = 0;
            sC2C.latest.account[i] = 0x0;
        }
    }


    function setReward(uint256 C2C, uint256 E2C, uint256 C2E, uint256 E2E) public onlyOwner {
        sC2C.reward = C2C;
        sE2C.reward = E2C;
        sC2E.reward = C2E;
        sE2E.reward = E2E;
    }
    
    function enableGame(bool C2C, bool E2C, bool C2E, bool E2E) public onlyOwner {
        sC2C.bEnabled = C2C;
        sE2C.bEnabled = E2C;
        sC2E.bEnabled = C2E;
        sE2E.bEnabled = E2E;
    }

    function setGameFee(uint256 C2C, uint256 E2C, uint256 C2E, uint256 E2E) public onlyOwner {
        sC2C.houseEdge = C2C;
        sE2C.houseEdge = E2C;
        sC2E.houseEdge = C2E;
        sE2E.houseEdge = E2E;
    }
    
    function setGameMaxBet(uint256 C2C, uint256 E2C, uint256 C2E, uint256 E2E) public onlyOwner {
        sC2C.maxBet = C2C;
        sE2C.maxBet = E2C;
        sC2E.maxBet = C2E;
        sE2E.maxBet = E2E;
    }

    function setGameMinBet(uint256 C2C, uint256 E2C, uint256 C2E, uint256 E2E) public onlyOwner {
        sC2C.minBet = C2C;
        sE2C.minBet = E2C;
        sC2E.minBet = C2E;
        sE2E.minBet = E2E;
    }

    function setToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    function setChip(address _chip) public onlyOwner {
        chip = StandardTokenERC20Custom(_chip);
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    function setProperties(string _salt, uint _E2C_Ratio) public onlyOwner {
        require(_E2C_Ratio > 0);
        salt = uint(keccak256(_salt));
        E2C_Ratio = _E2C_Ratio;
    }

    function() public {  
        revert();
    }

    function swapC2T(address _from, uint256 _value) payable public {
        require(chip.transferFrom(_from, manager, _value));
        require(token.transferFrom(manager, _from, _value));

        emit Swapped("TOKA", _value);
    }

    function swapT2C(address _from, uint256 _value) payable public {
        require(token.transferFrom(_from, manager, _value));
        require(chip.transferFrom(manager, _from, _value));

        emit Swapped("CHIP", _value);
    }

    function playC2C(address _from, uint256 _value) payable public {
        require(sC2C.bEnabled);
        require(_value >= sC2C.minBet && _value <= sC2C.maxBet);
        require(chip.transferFrom(_from, manager, _value));

        uint256 amountWon = _value * (50 + uint256(keccak256(block.timestamp, block.difficulty, salt++)) % 100 - sC2C.houseEdge) / 100;
        require(chip.transferFrom(manager, _from, amountWon + _value * sC2C.reward));  
        
         
        for(uint i=0;i<5;i++) {
            if(sC2C.ranking.amount[i] < amountWon) {
                for(uint j=4;j>i;j--) {
                    sC2C.ranking.amount[j] = sC2C.ranking.amount[j-1];
                    sC2C.ranking.date[j] = sC2C.ranking.date[j-1];
                    sC2C.ranking.account[j] = sC2C.ranking.account[j-1];
                }
                sC2C.ranking.amount[i] = amountWon;
                sC2C.ranking.date[i] = now;
                sC2C.ranking.account[i] = _from;
                break;
            }
        }
         
        for(i=4;i>0;i--) {
            sC2C.latest.amount[i] = sC2C.latest.amount[i-1];
            sC2C.latest.date[i] = sC2C.latest.date[i-1];
            sC2C.latest.account[i] = sC2C.latest.account[i-1];
        }
        sC2C.latest.amount[0] = amountWon;
        sC2C.latest.date[0] = now;
        sC2C.latest.account[0] = _from;

        emit Won(amountWon > _value, "CHIP", amountWon); 
    }

    function playC2E(address _from, uint256 _value) payable public {
        require(sC2E.bEnabled);
        require(_value >= sC2E.minBet && _value <= sC2E.maxBet);
        require(chip.transferFrom(_from, manager, _value));

        uint256 amountWon = _value * (50 + uint256(keccak256(block.timestamp, block.difficulty, salt++)) % 100 - sC2E.houseEdge) / 100 / E2C_Ratio;
        require(_from.send(amountWon));
        
         
        for(uint i=0;i<5;i++) {
            if(sC2E.ranking.amount[i] < amountWon) {
                for(uint j=4;j>i;j--) {
                    sC2E.ranking.amount[j] = sC2E.ranking.amount[j-1];
                    sC2E.ranking.date[j] = sC2E.ranking.date[j-1];
                    sC2E.ranking.account[j] = sC2E.ranking.account[j-1];
                }
                sC2E.ranking.amount[i] = amountWon;
                sC2E.ranking.date[i] = now;
                sC2E.ranking.account[i] = _from;
                break;
            }
        }
         
        for(i=4;i>0;i--) {
            sC2E.latest.amount[i] = sC2E.latest.amount[i-1];
            sC2E.latest.date[i] = sC2E.latest.date[i-1];
            sC2E.latest.account[i] = sC2E.latest.account[i-1];
        }
        sC2E.latest.amount[0] = amountWon;
        sC2E.latest.date[0] = now;
        sC2E.latest.account[0] = _from;

        emit Won(amountWon > (_value / E2C_Ratio), "ETH", amountWon); 
    }

    function playE2E() payable public {
        require(sE2E.bEnabled);
        require(msg.value >= sE2E.minBet && msg.value <= sE2E.maxBet);

        uint amountWon = msg.value * (50 + uint(keccak256(block.timestamp, block.difficulty, salt++)) % 100 - sE2E.houseEdge) / 100;
        require(msg.sender.send(amountWon));
        require(chip.transferFrom(manager, msg.sender, msg.value * sE2E.reward));  

         
        for(uint i=0;i<5;i++) {
            if(sE2E.ranking.amount[i] < amountWon) {
                for(uint j=4;j>i;j--) {
                    sE2E.ranking.amount[j] = sE2E.ranking.amount[j-1];
                    sE2E.ranking.date[j] = sE2E.ranking.date[j-1];
                    sE2E.ranking.account[j] = sE2E.ranking.account[j-1];
                }
                sE2E.ranking.amount[i] = amountWon;
                sE2E.ranking.date[i] = now;
                sE2E.ranking.account[i] = msg.sender;
                break;
            }
        }
         
        for(i=4;i>0;i--) {
            sE2E.latest.amount[i] = sE2E.latest.amount[i-1];
            sE2E.latest.date[i] = sE2E.latest.date[i-1];
            sE2E.latest.account[i] = sE2E.latest.account[i-1];
        }
        sE2E.latest.amount[0] = amountWon;
        sE2E.latest.date[0] = now;
        sE2E.latest.account[0] = msg.sender;

        emit Won(amountWon > msg.value, "ETH", amountWon); 
    }

    function playE2C() payable public {
        require(sE2C.bEnabled);
        require(msg.value >= sE2C.minBet && msg.value <= sE2C.maxBet);

        uint amountWon = msg.value * (50 + uint(keccak256(block.timestamp, block.difficulty, salt++)) % 100 - sE2C.houseEdge) / 100 * E2C_Ratio;
        require(chip.transferFrom(manager, msg.sender, amountWon));
        require(chip.transferFrom(manager, msg.sender, msg.value * sE2C.reward));  
        
         
        for(uint i=0;i<5;i++) {
            if(sE2C.ranking.amount[i] < amountWon) {
                for(uint j=4;j>i;j--) {
                    sE2C.ranking.amount[j] = sE2C.ranking.amount[j-1];
                    sE2C.ranking.date[j] = sE2C.ranking.date[j-1];
                    sE2C.ranking.account[j] = sE2C.ranking.account[j-1];
                }
                sE2C.ranking.amount[i] = amountWon;
                sE2C.ranking.date[i] = now;
                sE2C.ranking.account[i] = msg.sender;
                break;
            }
        }
         
        for(i=4;i>0;i--) {
            sE2C.latest.amount[i] = sE2C.latest.amount[i-1];
            sE2C.latest.date[i] = sE2C.latest.date[i-1];
            sE2C.latest.account[i] = sE2C.latest.account[i-1];
        }
        sE2C.latest.amount[0] = amountWon;
        sE2C.latest.date[0] = now;
        sE2C.latest.account[0] = msg.sender;

        emit Won(amountWon > (msg.value * E2C_Ratio), "CHIP", amountWon); 
    }

     
    function checkContractBalance() onlyOwner public view returns(uint) {
        return address(this).balance;
    }
    function checkContractBalanceToka() onlyOwner public view returns(uint) {
        return token.balanceOf(manager);
    }
    function checkContractBalanceChip() onlyOwner public view returns(uint) {
        return chip.balanceOf(manager);
    }
}