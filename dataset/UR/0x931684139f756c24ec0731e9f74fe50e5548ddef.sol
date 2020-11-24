 

pragma solidity ^0.4.21;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
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

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

 









 
contract TokenVesting is Ownable {
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

   
  function TokenVesting(
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

 
contract PresaleTokenVesting is TokenVesting {

    function PresaleTokenVesting(address _beneficiary, uint256 _duration) TokenVesting(_beneficiary, 0, _duration, _duration, false) public {
    }

    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        UrbitToken urbit = UrbitToken(token); 
        if (!urbit.saleClosed()) {
            return(0);
        } else {
            uint256 currentBalance = token.balanceOf(this);
            uint256 totalBalance = currentBalance.add(released[token]);
            uint256 saleClosedTime = urbit.saleClosedTimestamp();
            if (block.timestamp >= duration.add(saleClosedTime)) {  
                return totalBalance;
            } else {
                return totalBalance.mul(block.timestamp.sub(saleClosedTime)).div(duration);  

            }
        }
    }
}

 
contract TokenVault {
    using SafeERC20 for ERC20;

     
    ERC20 public token;

    function TokenVault(ERC20 _token) public {
        token = _token;
    }

     
    function fillUpAllowance() public {
        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.approve(token, amount);
    }
}

 
contract UrbitToken is BurnableToken, StandardToken {
    string public constant name = "Urbit Token";  
    string public constant symbol = "URB";  
    uint8 public constant decimals = 18;  
    uint256 public constant MAGNITUDE = 10**uint256(decimals);

     
    uint256 public constant HARD_CAP = 600000000 * MAGNITUDE;

     
    address public urbitAdminAddress;

     
    address public saleTokensAddress;

     
    TokenVault public bountyTokensVault;

     
    TokenVault public urbitTeamTokensVault;

     
    TokenVault public advisorsTokensVault;

     
    TokenVault public rewardsTokensVault;

     
    TokenVault public retainedTokensVault;

     
    mapping(address => address[]) public vestingsOf;

     
    uint256 public saleClosedTimestamp = 0;

     
    modifier beforeSaleClosed {
        require(!saleClosed());
        _;
    }

     
    modifier onlyAdmin {
        require(senderIsAdmin());
        _;
    }

    function UrbitToken(
        address _urbitAdminAddress,
        address _saleTokensAddress) public
    {
        require(_urbitAdminAddress != address(0));
        require(_saleTokensAddress != address(0));

        urbitAdminAddress = _urbitAdminAddress;
        saleTokensAddress = _saleTokensAddress;
    }

     
    function changeAdmin(address _newUrbitAdminAddress) external onlyAdmin {
        require(_newUrbitAdminAddress != address(0));
        urbitAdminAddress = _newUrbitAdminAddress;
    }

     
    function createSaleTokens() external onlyAdmin beforeSaleClosed {
        require(bountyTokensVault == address(0));

         
         
        createTokens(252000000, saleTokensAddress);

         
        bountyTokensVault = createTokenVault(24000000);
    }

     
    function closeSale() external onlyAdmin beforeSaleClosed {
        createAwardTokens();
        saleClosedTimestamp = block.timestamp;  
    }

     
     
    function burnUnsoldTokens() external onlyAdmin {
        require(saleClosed());
        _burn(saleTokensAddress, balances[saleTokensAddress]);
        _burn(bountyTokensVault, balances[bountyTokensVault]);
    }

    function lockBountyTokens(uint256 _tokensAmount, address _beneficiary, uint256 _duration) external beforeSaleClosed {
        require(msg.sender == saleTokensAddress || senderIsAdmin());
        _presaleLock(bountyTokensVault, _tokensAmount, _beneficiary, _duration);
    }

     
    function lockTokens(address _fromVault, uint256 _tokensAmount, address _beneficiary, uint256 _unlockTime) external onlyAdmin {
        this.vestTokens(_fromVault, _tokensAmount, _beneficiary, _unlockTime, 0, 0, false);  
    }

     
    function vestTokens(
        address _fromVault,
        uint256 _tokensAmount,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable)
        external onlyAdmin
    {
        TokenVesting vesting = new TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable);
        vestingsOf[_beneficiary].push(address(vesting));

        require(this.transferFrom(_fromVault, vesting, _tokensAmount));
    }

     
    function releaseVestedTokens() external {
        this.releaseVestedTokensFor(msg.sender);
    }

     
     
    function releaseVestedTokensFor(address _owner) external {
        ERC20Basic token = ERC20Basic(address(this));
        for (uint i = 0; i < vestingsOf[_owner].length; i++) {
            TokenVesting tv = TokenVesting(vestingsOf[_owner][i]);
            if (tv.releasableAmount(token) > 0) {
                tv.release(token);
            }
        }
    }

     
    function senderIsAdmin() public view returns (bool) {
        return (msg.sender == urbitAdminAddress || msg.sender == address(this));
    }

     
    function saleClosed() public view returns (bool) {
        return (saleClosedTimestamp > 0);
    }

     
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        uint256 result = 0;
        for (uint i = 0; i < vestingsOf[_owner].length; i++) {
            result += balances[vestingsOf[_owner][i]];
        }
        return result;
    }

     
    function releasableBalanceOf(address _owner) public view returns (uint256) {
        uint256 result = 0;
        for (uint i = 0; i < vestingsOf[_owner].length; i++) {
            result += TokenVesting(vestingsOf[_owner][i]).releasableAmount(this);
        }
        return result;
    }

     
    function vestingCountOf(address _owner) public view returns (uint) {
        return vestingsOf[_owner].length;
    }

     
    function vestingOf(address _owner, uint _index) public view returns (address) {
        return vestingsOf[_owner][_index];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if (saleClosed() || msg.sender == saleTokensAddress || senderIsAdmin()) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (saleClosed() || msg.sender == saleTokensAddress || senderIsAdmin()) {
            return super.transfer(_to, _value);
        }
        return false;
    }

     
    function _presaleLock(TokenVault _fromVault, uint256 _tokensAmount, address _beneficiary, uint256 _duration) internal {
        PresaleTokenVesting vesting = new PresaleTokenVesting(_beneficiary, _duration);
        vestingsOf[_beneficiary].push(address(vesting));

        require(this.transferFrom(_fromVault, vesting, _tokensAmount));
    }

     
    function createTokens(uint32 count, address destination) internal onlyAdmin {
        uint256 tokens = count * MAGNITUDE;
        totalSupply_ = totalSupply_.add(tokens);
        balances[destination] = tokens;
        emit Transfer(0x0, destination, tokens);
    }

     
    function createTokenVault(uint32 count) internal onlyAdmin returns (TokenVault) {
        TokenVault tokenVault = new TokenVault(ERC20(this));
        createTokens(count, tokenVault);
        tokenVault.fillUpAllowance();
        return tokenVault;
    }

     
    function createAwardTokens() internal onlyAdmin {
         
        urbitTeamTokensVault = createTokenVault(30000000);

         
        advisorsTokensVault = createTokenVault(24000000);

         
        rewardsTokensVault = createTokenVault(150000000);

         
        retainedTokensVault = createTokenVault(120000000);
    }
}