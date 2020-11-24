 

pragma solidity 0.5.8;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = msg.sender;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Claimable {
  function _claimTokens(address tokenAddress, address recipient) internal {
    require(recipient != address(0));
    IERC20 token = IERC20(tokenAddress);
    uint256 balance = token.balanceOf(address(this));
    token.transfer(recipient, balance);
  }
}

interface IMoneyMarketAdapter {
  
  function getRate(address tokenAddress) external view returns (uint256);

  
  function deposit(address tokenAddress, uint256 tokenAmount) external;

  
  function withdraw(address tokenAddress, address recipient, uint256 amount)
    external;

  
  function withdrawAll(address tokenAddress, address recipient) external;

  function claimTokens(address tokenAddress, address recipient) external;

  
  function getSupply(address tokenAddress) external returns (uint256);

  
  function getSupplyView(address tokenAddress) external view returns (uint256);

  
  function supportsToken(address tokenAddress) external view returns (bool);
}

contract ERC20 is IERC20 {
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

contract ERC20Burnable is ERC20 {
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

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

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
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

contract ERC20Mintable is ERC20, MinterRole {
    
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

contract TokenShare is ERC20Burnable, ERC20Mintable {}

contract MetaMoneyMarket is Ownable, Claimable {
  using SafeMath for uint256;

  
  IMoneyMarketAdapter[] public moneyMarkets;

  
  mapping(address => Market) public supportedMarkets;
  address[] public supportedMarketsList;

  struct Market {
    bool isSupported;
    TokenShare tokenShare;
  }

  
  constructor(address[] memory _moneyMarkets) public {
    require(
      _moneyMarkets.length > 0,
      "At least one money market has to be specified"
    );
    for (uint256 i = 0; i < _moneyMarkets.length; i++) {
      moneyMarkets.push(IMoneyMarketAdapter(_moneyMarkets[i]));
    }
  }

  modifier checkMarketSupported(address token) {
    require(isMarketSupported(token), "Market is not supported");
    _;
  }

  
  function deposit(address tokenAddress, uint256 tokenAmount)
    external
    checkMarketSupported(tokenAddress)
  {
    IERC20 token = IERC20(tokenAddress);

    TokenShare tokenShare = supportedMarkets[tokenAddress].tokenShare;
    uint256 tokenShareSupply = tokenShare.totalSupply();
    uint256 tokenSupply = totalSupply(tokenAddress);

    uint256 tokenSharesToMint = tokenSupply > 0
      ? tokenShareSupply * tokenAmount / tokenSupply
      : tokenAmount;

    tokenShare.mint(msg.sender, tokenSharesToMint);

    (IMoneyMarketAdapter bestMoneyMarket, ) = getBestMoneyMarket(tokenAddress);

    require(
      token.balanceOf(msg.sender) >= tokenAmount,
      "MetaMoneyMarket.deposit: User does not have enough balance"
    );
    require(
      token.allowance(msg.sender, address(this)) >= tokenAmount,
      "MetaMoneyMarket.deposit: Cannot transfer tokens from the user"
    );
    token.transferFrom(msg.sender, address(this), tokenAmount);

    bestMoneyMarket.deposit(tokenAddress, tokenAmount);
  }

  
  function withdraw(address tokenAddress, uint256 tokenShareAmount)
    external
    checkMarketSupported(tokenAddress)
  {
    TokenShare tokenShare = supportedMarkets[tokenAddress].tokenShare;
    uint256 tokenShareSupply = tokenShare.totalSupply();
    uint256 tokenSupply = totalSupply(tokenAddress);

    uint256 tokensToTransfer = tokenSupply * tokenShareAmount / tokenShareSupply;

    require(
      tokenShare.balanceOf(msg.sender) >= tokenShareAmount,
      "MetaMoneyMarket.withdraw: Not enough token shares"
    );
    require(
      tokenShare.allowance(msg.sender, address(this)) >= tokenShareAmount,
      "MetaMoneyMarket.withdraw: Cannot burn token shares"
    );
    tokenShare.burnFrom(msg.sender, tokenShareAmount);

    for (uint256 i = 0; i < moneyMarkets.length && tokensToTransfer > 0; i++) {
      if (!moneyMarkets[i].supportsToken(tokenAddress)) {
        continue;
      }
      uint256 supply = moneyMarkets[i].getSupply(tokenAddress);
      if (supply == 0) {
        continue;
      }
      if (supply >= tokensToTransfer) {
        moneyMarkets[i].withdraw(tokenAddress, msg.sender, tokensToTransfer);
        tokensToTransfer = 0;
      } else {
        moneyMarkets[i].withdraw(tokenAddress, msg.sender, supply);
        tokensToTransfer -= supply;
      }
    }

    require(
      tokensToTransfer == 0,
      "MetaMoneyMarket.withdraw: Not all tokens could be withdrawn"
    );
  }

  
  function addMarket(address tokenAddress) external onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    require(
      !supportedMarkets[tokenAddress].isSupported,
      "Market is already supported"
    );

    TokenShare tokenShare = new TokenShare();

    supportedMarketsList.push(tokenAddress);
    supportedMarkets[tokenAddress].isSupported = true;
    supportedMarkets[tokenAddress].tokenShare = tokenShare;

    for (uint256 i = 0; i < moneyMarkets.length; i++) {
      token.approve(address(moneyMarkets[i]), uint256(-1));
      tokenShare.approve(address(moneyMarkets[i]), uint256(-1));
    }
  }

  
  function rebalance(address tokenAddress, uint256[] memory percentages)
    public
    checkMarketSupported(tokenAddress)
    onlyOwner
  {
    IERC20 token = IERC20(tokenAddress);

    require(percentages.length + 1 == moneyMarkets.length);

    for (uint256 i = 0; i < moneyMarkets.length; i++) {
      if (!moneyMarkets[i].supportsToken(tokenAddress)) {
        continue;
      }
      moneyMarkets[i].withdrawAll(tokenAddress, address(this));
    }

    uint256 totalSupply = token.balanceOf(address(this));

    for (uint256 i = 0; i < percentages.length; i++) {
      if (!moneyMarkets[i].supportsToken(tokenAddress)) {
        continue;
      }
      uint256 amountToDeposit = totalSupply * percentages[i] / 10000;
      if (amountToDeposit == 0) {
        continue;
      }
      moneyMarkets[i].deposit(tokenAddress, amountToDeposit);
    }

    uint256 remainingTokens = token.balanceOf(address(this));
    if (
      moneyMarkets[moneyMarkets.length - 1].supportsToken(
        tokenAddress
      ) && remainingTokens > 0
    ) {
      moneyMarkets[moneyMarkets.length - 1].deposit(
        tokenAddress,
        remainingTokens
      );
    }

    require(
      token.balanceOf(address(this)) == 0,
      "MetaMoneyMarket.rebalance: Not all tokens could be rebalanced"
    );
  }

  function claimTokens(address tokenAddress, address recipient)
    public
    onlyOwner
  {
    _claimTokens(tokenAddress, recipient);
  }

  function claimTokensFromAdapter(
    uint256 index,
    address tokenAddress,
    address recipient
  ) public onlyOwner {
    IMoneyMarketAdapter moneyMarket = moneyMarkets[index];
    moneyMarket.claimTokens(tokenAddress, recipient);
  }

  
  function getTokenShare(address tokenAddress)
    external
    view
    checkMarketSupported(tokenAddress)
    returns (address)
  {
    return address(supportedMarkets[tokenAddress].tokenShare);
  }

  
  function totalSupply(address tokenAddress)
    public
    checkMarketSupported(tokenAddress)
    returns (uint256)
  {
    uint256 tokenSupply = 0;
    for (uint256 i = 0; i < moneyMarkets.length; i++) {
      if (!moneyMarkets[i].supportsToken(tokenAddress)) {
        continue;
      }
      tokenSupply += moneyMarkets[i].getSupply(tokenAddress);
    }

    return tokenSupply;
  }

  
  function totalSupplyView(address tokenAddress)
    public
    view
    checkMarketSupported(tokenAddress)
    returns (uint256)
  {
    uint256 tokenSupply = 0;
    for (uint256 i = 0; i < moneyMarkets.length; i++) {
      if (!moneyMarkets[i].supportsToken(tokenAddress)) {
        continue;
      }
      tokenSupply += moneyMarkets[i].getSupplyView(tokenAddress);
    }

    return tokenSupply;
  }

  
  function isMarketSupported(address tokenAddress) public view returns (bool) {
    return supportedMarkets[tokenAddress].isSupported;
  }

  function getMarketSymbol(address tokenAddress)
    public
    view
    checkMarketSupported(tokenAddress)
    returns (string memory)
  {
    ERC20Detailed token = ERC20Detailed(tokenAddress);

    return token.symbol();
  }

  
  function moneyMarketsCount() public view returns (uint256) {
    return moneyMarkets.length;
  }

  function supportedMarketsCount() public view returns (uint256) {
    return supportedMarketsList.length;
  }

  function getDepositedAmount(address tokenAddress, address account)
    public
    view
    checkMarketSupported(tokenAddress)
    returns (uint256)
  {
    TokenShare tokenShare = supportedMarkets[address(tokenAddress)].tokenShare;

    (uint256 tokenSupply, uint256 tokenShareSupply) = getExchangeRate(
      tokenAddress
    );
    uint256 tokenShareBalance = tokenShare.balanceOf(account);

    return tokenShareSupply > 0
      ? tokenShareBalance * tokenSupply / tokenShareSupply
      : 0;
  }

  function getExchangeRate(address tokenAddress)
    public
    view
    checkMarketSupported(tokenAddress)
    returns (uint256 tokenSupply, uint256 tokenShareSupply)
  {
    TokenShare tokenShare = supportedMarkets[address(tokenAddress)].tokenShare;

    tokenSupply = totalSupplyView(tokenAddress);
    tokenShareSupply = tokenShare.totalSupply();
  }

  function getBestMoneyMarket(address tokenAddress)
    public
    view
    checkMarketSupported(tokenAddress)
    returns (IMoneyMarketAdapter bestMoneyMarket, uint256 bestRate)
  {
    bestMoneyMarket = IMoneyMarketAdapter(address(0));
    bestRate = 0;
    for (uint256 i = 0; i < moneyMarkets.length; i++) {
      if (!moneyMarkets[i].supportsToken(tokenAddress)) {
        continue;
      }
      uint256 rate = moneyMarkets[i].getRate(tokenAddress);
      if (rate > bestRate) {
        bestRate = rate;
        bestMoneyMarket = moneyMarkets[i];
      }
    }

    require(address(bestMoneyMarket) != address(0));
  }

  function getBestInterestRate(address tokenAddress)
    public
    view
    checkMarketSupported(tokenAddress)
    returns (uint256)
  {
    (, uint256 bestRate) = getBestMoneyMarket(tokenAddress);

    return bestRate;
  }
}