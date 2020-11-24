 

 

pragma solidity ^0.5.0;

 
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











 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
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





 

pragma solidity ^0.5.12;






contract EtheousToken is Ownable, ERC20, ERC20Detailed("Etheous", "EHS", 18) {
  uint256 public maxUnlockIterationCount = 100;     
    
  mapping (address => uint256) public lockedBalances;    
  mapping (address => uint256[]) public releaseTimestamps;  
  mapping (address => mapping(uint256 => uint256)) public lockedTokensForReleaseTime;  

  constructor() public {
    uint256 tokensAmount = 630720000 * 10 ** 18;
    _mint(msg.sender, tokensAmount);
  }
  
   
  function getReleaseTimestamps(address _address) public view returns(uint256[] memory) {
    return releaseTimestamps[_address];
  }
  
   
  function getMyReleaseTimestamps() public view returns(uint256[] memory) {
    return releaseTimestamps[msg.sender];
  }
  
   
  function updateMaxUnlockIterationCount(uint256 _amount) public onlyOwner {
    require(_amount > 0, "Wrong amount");
    maxUnlockIterationCount = _amount;
  }
  
   
  function lockedTransferAmount(address _address) public view returns(uint256) {
    return releaseTimestamps[_address].length;
  }
  
   
  function myLockedTransferAmount() public view returns(uint256) {
    return releaseTimestamps[msg.sender].length;
  }

   
  function unlockExpired(uint256 _amount) public {
    require(_amount <= maxUnlockIterationCount, "Wrong amount");
    
    uint256 length = releaseTimestamps[msg.sender].length;
    for(uint256 i = 0; i < length; i ++) {
      if(i > maxUnlockIterationCount) {
          return;
      }
      if(releaseTimestamps[msg.sender][i] <= now) {
        uint256 tokens = lockedTokensForReleaseTime[msg.sender][releaseTimestamps[msg.sender][i]];
        lockedBalances[msg.sender] = lockedBalances[msg.sender].sub(tokens);
        delete lockedTokensForReleaseTime[msg.sender][releaseTimestamps[msg.sender][i]];

        length = length.sub(1);
        if(length > 0) {
          releaseTimestamps[msg.sender][i] = releaseTimestamps[msg.sender][length];
          delete releaseTimestamps[msg.sender][length];
          releaseTimestamps[msg.sender].length = releaseTimestamps[msg.sender].length.sub(1);
          i --;
        } else {
          releaseTimestamps[msg.sender].length = 0;
        }
      }
    }
  }

   
  function transferLocked(address recipient, uint256 amount, uint256 lockDuration, uint256 loopIteractions) public returns (bool) {
    unlockExpired(loopIteractions);
    
    require(balanceOf(msg.sender).sub(lockedBalances[msg.sender]) >= amount, "Not enough tokens.");

    if(lockDuration > 0) {
        lockedBalances[recipient] = lockedBalances[recipient].add(amount);
        releaseTimestamps[recipient].push(now.add(lockDuration));
        lockedTokensForReleaseTime[recipient][now.add(lockDuration)] = amount;
    }
    
    super.transfer(recipient, amount);    
  }
  
   
  function transferLockedFrom(address sender, address recipient, uint256 amount, uint256 lockDuration) public returns (bool) {
    require(balanceOf(sender).sub(lockedBalances[sender]) >= amount, "Not enough tokens.");
    
    if(lockDuration > 0) {
        lockedBalances[recipient] = lockedBalances[recipient].add(amount);
        releaseTimestamps[recipient].push(now.add(lockDuration));
        lockedTokensForReleaseTime[recipient][now.add(lockDuration)] = amount;
    }
    super.transferFrom(sender, recipient, amount);
  }

   
  function transfer(address recipient, uint256 amount) public returns (bool) {
    require(false, "Disabled");
  }

   
  function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(false, "Disabled");
  }
}