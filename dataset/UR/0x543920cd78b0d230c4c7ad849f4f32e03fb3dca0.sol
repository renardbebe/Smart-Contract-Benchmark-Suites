 

pragma solidity ^0.5.1;

contract ERC223Receiver {
    function tokenFallback(address, uint256) public returns (bool);
    function tokenFallback(address, uint256, bytes memory) public returns (bool);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
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

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
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

contract ERC223 is ERC20, ERC20Detailed {
  using SafeMath for uint256;

  constructor(
      string memory name,
      string memory symbol,
      uint8 decimals,
      address owner,
      uint256 totalSupply
  )
      ERC20()
      ERC20Detailed(name, symbol, decimals)
      public
  {
      _mint(owner, (totalSupply * 1 ether));
  }

  function transfer(
      address to,
      uint256 value
  ) public returns (bool) {
      require(super.transfer(to, value));

      uint256 codeLength;
      assembly {
          codeLength := extcodesize(to)
      }

      if (codeLength > 0) {
          ERC223Receiver receiver = ERC223Receiver(to);
          if (!receiver.tokenFallback(msg.sender, value)) {
              revert("Missing Token Receiver");
          }
      }
      return true;
  }

  function transfer(
      address to,
      uint256 value,
      bytes memory data
  ) public returns (bool) {
      require(super.transfer(to, value));

      uint256 codeLength;
      assembly {
          codeLength := extcodesize(to)
      }

      if (codeLength > 0) {
          ERC223Receiver receiver = ERC223Receiver(to);
          if (!receiver.tokenFallback(msg.sender, value, data)) {
              revert("Missing Token Receiver");
          }
      }
      return true;
  }

  function transferFrom(
      address from,
      address to,
      uint256 value
  ) public returns (bool) {
      require(super.transferFrom(from, to, value));

      uint256 codeLength;
      assembly {
          codeLength := extcodesize(to)
      }

      if (codeLength > 0) {
          ERC223Receiver receiver = ERC223Receiver(to);
          if (!receiver.tokenFallback(msg.sender, value)) {
              revert("Missing Token Receiver");
          }
      }
      return true;
  }

  function transferFrom(
      address from,
      address to,
      uint256 value,
      bytes memory data
  ) public returns (bool) {
      require(super.transferFrom(from, to, value));

      uint256 codeLength;
      assembly {
          codeLength := extcodesize(to)
      }

      if (codeLength > 0) {
          ERC223Receiver receiver = ERC223Receiver(to);
          if (!receiver.tokenFallback(msg.sender, value, data)) {
              revert("Missing Token Receiver");
          }
      }
      return true;
  }
}

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN));  

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);  
        require(!(b == -1 && a == INT256_MIN));  

        int256 c = a / b;

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract VIM_ERC20 is ERC223  {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address owner,
        uint256 totalSupply
    )
        ERC223(name, symbol, decimals, owner, totalSupply)
        public
    {
    }
}