 

 

pragma solidity 0.5.9;

 
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
        require(isOwner());
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
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.9;

 
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

 

pragma solidity 0.5.9;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity 0.5.9;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 internal _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

pragma solidity 0.5.9;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity 0.5.9;



 
contract ERC20Mintable is ERC20, Ownable {
     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

pragma solidity 0.5.9;



contract FTIToken is ERC20Burnable, ERC20Mintable {
  string public constant name = "FTI NEWS Token";
  string public constant symbol = "TECH";
  uint8 public constant decimals = 10;

  uint256 public constant initialSupply = 299540000 * (10 ** uint256(decimals)); 

  constructor () public {
    _totalSupply = initialSupply;
    _balances[0x8D44D27D2AF7BE632baA340eA52E443756ea1aD3] = initialSupply;
  }
}

 

pragma solidity 0.5.9;




contract FTICrowdsale is Ownable {
  using SafeMath for uint256;

  uint256 public rate;
  uint256 public minPurchase;
  uint256 public maxSupply;

   
  uint256 public stage1ReleaseTime;
  uint256 public stage2ReleaseTime;
  uint256 public stage3ReleaseTime;

   
  uint256 public stage1Amount;
  uint256 public stage2Amount;
  uint256 public stage3Amount;

  bool public stage1Released;
  bool public stage2Released;
  bool public stage3Released;

   
  address payable public wallet;

  bool public isPaused;

  FTIToken public token;

  constructor () public {
    token = new FTIToken();

    minPurchase = 0.00000000000005 ether;  
    rate = 0.000194 ether;

    maxSupply = 2395600000 * (10 ** 10);  
    wallet = 0x8D44D27D2AF7BE632baA340eA52E443756ea1aD3;

    stage1ReleaseTime = now + 180 days;  
    stage2ReleaseTime = now + 270 days;  
    stage3ReleaseTime = now + 365 days;  

    stage1Amount = 299540000 * (10 ** uint256(token.decimals()));
    stage2Amount = 299540000 * (10 ** uint256(token.decimals()));
    stage3Amount = 299540000 * (10 ** uint256(token.decimals()));
  }

   
  function pause() public onlyOwner {
    require(!isPaused, 'Sales must be not paused');
    isPaused = true;
  }

   
  function unpause() public onlyOwner {
    require(isPaused, 'Sales must be paused');
    isPaused = false;
  }

   
  function changeWallet(address payable newWallet) public onlyOwner {
    require(newWallet != address(0));
    wallet = newWallet;
  }

   
  function transferTokenOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    token.transferOwnership(newOwner);
  }

   
  function burnUnsold() public onlyOwner {
    token.burn(token.balanceOf(address(this)));
  }

   
  function releaseStage1() public onlyOwner {
    require(now > stage1ReleaseTime, 'Release time has not come yet');
    require(stage1Released != true, 'Tokens already released');

    stage1Released = true;
    token.mint(wallet, stage1Amount);
  }

   
  function releaseStage2() public onlyOwner {
    require(now > stage2ReleaseTime, 'Release time has not come yet');
    require(stage2Released != true, 'Tokens already released');

    stage2Released = true;
    token.mint(wallet, stage2Amount);
  }

   
  function releaseStage3() public onlyOwner {
    require(now > stage3ReleaseTime, 'Release time has not come yet');
    require(stage3Released != true, 'Tokens already released');

    stage3Released = true;
    token.mint(wallet, stage3Amount);
  }

   
  function() external payable {
    buyTokens();
  }

  function buyTokens() public payable {
    require(!isPaused, 'Sales are temporarily paused');

    address payable inv = msg.sender;
    require(inv != address(0));

    uint256 weiAmount = msg.value;
    require(weiAmount >= minPurchase, 'Amount of ether is not enough to buy even the smallest token part');

    uint256 cleanWei;  
    uint256 change;
    uint256 tokens;
    uint256 tokensNoBonuses;
    uint256 totalSupply;
    uint256 supply;

    tokensNoBonuses = weiAmount.mul(1E10).div(rate);

    if (weiAmount >= 10 ether) {
      tokens = tokensNoBonuses.mul(112).div(100);
    } else if (weiAmount >= 5 ether) {
      tokens = tokensNoBonuses.mul(105).div(100);
    } else {
      tokens = tokensNoBonuses;
    }

    totalSupply = token.totalSupply();
    supply = totalSupply.sub(token.balanceOf(address(this)));

    if (supply.add(tokens) > maxSupply) {
      tokens = maxSupply.sub(supply);
      require(tokens > 0, 'There are currently no tokens for sale');
      if (tokens >= tokensNoBonuses) {
        cleanWei = weiAmount;
      } else {
        cleanWei = tokens.mul(rate).div(1E10);
        change = weiAmount.sub(cleanWei);
      }
    } else {
      cleanWei = weiAmount;
    }

    if (token.balanceOf(address(this)) >= tokens) {
      token.transfer(inv, tokens);
    } else if (token.balanceOf(address(this)) == 0) {
      token.mint(inv, tokens);
    } else {
      uint256 mintAmount = tokens.sub(token.balanceOf(address(this)));

      token.mint(address(this), mintAmount);
      token.transfer(inv, tokens);
    }

    wallet.transfer(cleanWei);

    if (change > 0) {
      inv.transfer(change); 
    }
  }
}