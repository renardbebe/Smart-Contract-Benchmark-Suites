 

pragma solidity 0.4.24;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
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

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
contract TokenVesting is Owned {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract AgateToken is BurnableToken, StandardToken, Owned {
    string public constant name = "AGATE";
    string public constant symbol = "AGT";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 490000000 * 10**uint256(decimals);

     
    address public saleTokensAddress;

     
    address public bountyTokensAddress;

     
    address public teamTokensAddress;
    
     
    TokenVesting public teamTokensVesting;

     
    address public advisorsTokensAddress;

     
    address public reserveTokensAddress;

     
    bool public saleClosed = false;

     
    bool public tradingOpen = false;

     
    uint64 public constant date15Nov2018 = 1542240000;

     
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    constructor(address _teamTokensAddress, address _reserveTokensAddress, 
                address _advisorsTokensAddress, address _saleTokensAddress, address _bountyTokensAddress) public {
        require(_teamTokensAddress != address(0));
        require(_reserveTokensAddress != address(0));
        require(_advisorsTokensAddress != address(0));
        require(_saleTokensAddress != address(0));
        require(_bountyTokensAddress != address(0));

        teamTokensAddress = _teamTokensAddress;
        reserveTokensAddress = _reserveTokensAddress;
        advisorsTokensAddress = _advisorsTokensAddress;
        saleTokensAddress = _saleTokensAddress;
        bountyTokensAddress = _bountyTokensAddress;

         
         
        uint256 saleTokens = 318500000 * 10**uint256(decimals);
        totalSupply_ = saleTokens;
        balances[saleTokensAddress] = saleTokens;
        emit Transfer(address(0), saleTokensAddress, balances[saleTokensAddress]);
 
         
        uint256 teamTokens = 49000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(teamTokens);
        teamTokensVesting = new TokenVesting(teamTokensAddress, date15Nov2018, 92 days, 365 days, false);
        balances[address(teamTokensVesting)] = teamTokens;
        emit Transfer(address(0), address(teamTokensVesting), balances[address(teamTokensVesting)]);
 
         
        uint256 bountyTokens = 24500000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(bountyTokens);
        balances[bountyTokensAddress] = bountyTokens;
        emit Transfer(address(0), bountyTokensAddress, balances[bountyTokensAddress]);
 
         
        uint256 advisorsTokens = 24500000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(advisorsTokens);
        balances[advisorsTokensAddress] = advisorsTokens;
        emit Transfer(address(0), advisorsTokensAddress, balances[advisorsTokensAddress]);

         
        uint256 reserveTokens = 73500000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(reserveTokens);
        balances[reserveTokensAddress] = reserveTokens;
        emit Transfer(address(0), reserveTokensAddress, balances[reserveTokensAddress]);

        require(totalSupply_ <= HARD_CAP);
    }

     
    function closeSale() external onlyOwner beforeSaleClosed {
         

        _burn(saleTokensAddress, balances[saleTokensAddress]);
        saleClosed = true;
    }

     
    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(tradingOpen) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(tradingOpen || msg.sender == saleTokensAddress || msg.sender == bountyTokensAddress
                        || msg.sender == advisorsTokensAddress) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}