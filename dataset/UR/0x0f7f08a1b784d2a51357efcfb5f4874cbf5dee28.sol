 

 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}


 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 

pragma solidity ^0.5.0;

 
interface IERC20WCC {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address owner, uint256 amount) external returns (bool);

    function burn(address owner, uint256 amount) external returns (bool);
}


 

 
pragma solidity ^0.5.11;





contract CoffeeHandler is Ownable {

   
  event LogSetDAIContract(address indexed _owner, IERC20 _contract);
  event LogSetWCCContract(address indexed _owner, IERC20WCC _contract);
  event LogSetCoffeePrice(address indexed _owner, uint _coffeePrice);
  event LogSetStakeRate(address indexed _owner, uint _stakeRate);
  event LogStakeDAI(address indexed _staker, uint _amount, uint _currentStake);
  event LogRemoveStakedDAI(address indexed _staker, uint _amount, uint _currentStake);
  event LogRemoveAllStakedDAI(address indexed _staker, uint _amount, uint _currentStake);
  event LogMintTokens(address indexed _staker, address owner, uint _amount, uint _currentUsed);
  event LogBurnTokens(address indexed _staker, address owner, uint _amount, uint _currentUsed);
  event LogApproveMint(address indexed _owner, address _staker, uint amount);
  event LogRedeemTokens(address indexed _staker, address owner, uint _amount, uint _currentUsed);
  event LogLiquidateStakedDAI(address indexed _owner, uint _amount);

  using SafeMath for uint256;

   
  IERC20WCC public WCC_CONTRACT;

   
  IERC20 public DAI_CONTRACT;

   
  uint public COFFEE_PRICE;

   
  uint public STAKE_RATE;

   
  mapping (address => uint) public userToStake;

   
  mapping (address => uint) public tokensUsed;

   
  mapping (address => mapping (address => uint)) public tokensMintApproved;

   
  mapping (address => address) public userToValidator;

   
  uint256 public openingTime;

   
  modifier onlyPaused() {
     
    require(now >= openingTime + 90 days, "only available after 3 months of deployment");
    _;
  }

   
  modifier onlyNotPaused() {
     
    require(now <= openingTime + 90 days, "only available during the 3 months of deployment");
    _;
  }

   
  constructor() public {
     
    openingTime = now;
  }

   
  function setDAIContract(IERC20 _DAI_CONTRACT) public onlyOwner {
    DAI_CONTRACT = _DAI_CONTRACT;
    emit LogSetDAIContract(msg.sender, _DAI_CONTRACT);
  }

   
  function setWCCContract(IERC20WCC _WCC_CONTRACT) public onlyOwner {
    WCC_CONTRACT = _WCC_CONTRACT;
    emit LogSetWCCContract(msg.sender, _WCC_CONTRACT);
  }

   
  function setCoffeePrice(uint _COFFEE_PRICE) public onlyOwner {
    COFFEE_PRICE = _COFFEE_PRICE;
    emit LogSetCoffeePrice(msg.sender, _COFFEE_PRICE);
  }

   
  function setStakeRate(uint _STAKE_RATE) public onlyOwner{
    STAKE_RATE = _STAKE_RATE;
    emit LogSetStakeRate(msg.sender, _STAKE_RATE);
  }

   
  function stakeDAI(uint _amount) public onlyNotPaused onlyOwner {
    require(DAI_CONTRACT.balanceOf(msg.sender) >= _amount, "Not enough balance");
    require(DAI_CONTRACT.allowance(msg.sender, address(this)) >= _amount, "Contract allowance is to low or not approved");
    userToStake[msg.sender] = userToStake[msg.sender].add(_amount);
    DAI_CONTRACT.transferFrom(msg.sender, address(this), _amount);
    emit LogStakeDAI(msg.sender, _amount, userToStake[msg.sender]);
  }

   
  function _removeStakedDAI(uint _amount) private {
    require(userToStake[msg.sender] >= _amount, "Amount bigger than current available to retrive");
    userToStake[msg.sender] = userToStake[msg.sender].sub(_amount);
    DAI_CONTRACT.transfer(msg.sender, _amount);
  }

   
  function removeStakedDAI(uint _amount) public {
    _removeStakedDAI(_amount);
    emit LogRemoveStakedDAI(msg.sender, _amount, userToStake[msg.sender]);
  }

   
  function removeAllStakedDAI() public {
    uint amount = userToStake[msg.sender];
    _removeStakedDAI(amount);
    emit LogRemoveAllStakedDAI(msg.sender, amount, userToStake[msg.sender]);
  }

   
  function mintTokens(address _receiver, uint _amount) public onlyOwner {
    require(tokensMintApproved[_receiver][msg.sender] >= _amount, "Mint value bigger than approved by user");
    uint expectedAvailable = requiredAmount(_amount);
    require(userToStake[msg.sender] >= expectedAvailable, "Not enough DAI Staked");
    userToStake[msg.sender] = userToStake[msg.sender].sub(expectedAvailable);
    tokensUsed[msg.sender] = tokensUsed[msg.sender].add(_amount);
    tokensMintApproved[_receiver][msg.sender] = 0;
    userToValidator[_receiver] = msg.sender;
    WCC_CONTRACT.mint(_receiver, _amount);
    emit LogMintTokens(msg.sender, _receiver, _amount, tokensUsed[msg.sender]);
  }

   
  function burnTokens(uint _amount) public {
    uint expectedAvailable = requiredAmount(_amount);
    address validator = userToValidator[msg.sender];
    require(tokensUsed[validator] >= _amount, "Burn amount higher than stake minted");
    userToStake[validator] = userToStake[validator].add(expectedAvailable);
    tokensUsed[validator] = tokensUsed[validator].sub(_amount);
    WCC_CONTRACT.burn(msg.sender, _amount);
    emit LogBurnTokens(validator, msg.sender, _amount, tokensUsed[validator]);
  }

   
  function requiredAmount(uint _amount) public view returns(uint) {
    return _amount.mul(COFFEE_PRICE.mul(STAKE_RATE)).div(100);
  }

   
  function approveMint(address _validator, uint _amount) public {
    tokensMintApproved[msg.sender][_validator] = _amount;
    emit LogApproveMint(msg.sender, _validator, _amount);
  }

   
  function redeemTokens(uint _amount) public onlyPaused {
    uint expectedAvailable = requiredAmount(_amount);
    address validator = userToValidator[msg.sender];
    require(tokensUsed[validator] >= _amount, "Redeem amount is higher than redeemable amount");
    uint tokenToDai = COFFEE_PRICE.mul(_amount);
    userToStake[validator] = userToStake[validator].add(expectedAvailable).sub(tokenToDai);
    tokensUsed[validator] = tokensUsed[validator].sub(_amount);
    WCC_CONTRACT.burn(msg.sender, _amount);
    DAI_CONTRACT.transfer(msg.sender, tokenToDai);
    emit LogRedeemTokens(validator, msg.sender, _amount, tokensUsed[validator]);
  }

   
  function liquidateStakedDAI() public onlyOwner {
     
    require(now >= openingTime + 90 days, "only available after 6 months of deployment");
    uint amount = DAI_CONTRACT.balanceOf(address(this));
    DAI_CONTRACT.transfer(owner(), amount);
    emit LogLiquidateStakedDAI(msg.sender, amount);
  }
}


 

pragma solidity ^0.5.0;




 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}


 

pragma solidity ^0.5.0;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


 

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


 

pragma solidity ^0.5.0;



 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}


 

 
pragma solidity ^0.5.11;





contract DaiToken is ERC20Detailed, ERC20Mintable, Ownable {
  constructor() ERC20Detailed("Dai Stablecoin v1.0 TEST", "DAI", 18) public {}

  function faucet(uint amount) public{
    _mint(msg.sender, amount);
  }
}


 

 
pragma solidity ^0.5.11;





contract WrappedCoffeeCoin is ERC20, ERC20Detailed, Ownable, MinterRole {

   
  event LogSetCoffeeHandler(address indexed _owner, address _contract);
  event LogUpdateCoffee(address indexed _owner, string _ipfsHash);

   
  string private ipfsHash;
   
  address public coffeeHandler;

   
  constructor() ERC20Detailed("Single Coffee Token", "CAFE", 18) public {}

   
  function setCoffeeHandler(address _coffeeHandler) public onlyOwner{
    addMinter(_coffeeHandler);
    coffeeHandler = _coffeeHandler;
    renounceMinter();
    emit LogSetCoffeeHandler(msg.sender, _coffeeHandler);
  }

   
  function mint(address _account, uint256 _amount) public onlyMinter returns (bool) {
    require(coffeeHandler != address(0), "Coffee Handler must be set");
    _mint(_account, _amount);
    return true;
  }

   
  function burn(address _account, uint256 _amount) public onlyMinter returns (bool) {
    require(coffeeHandler != address(0), "Coffee Handler must be set");
    _burn(_account, _amount);
    return true;
  }

   
  function getCoffee() public view returns(string memory) {
    return ipfsHash;
  }

   
  function updateCoffee(string memory _ipfs) public onlyOwner {
    require(bytes(_ipfs).length != 0, "The IPFS pointer cannot be empty");
    ipfsHash = _ipfs;
    emit LogUpdateCoffee(msg.sender, ipfsHash);
  }
}