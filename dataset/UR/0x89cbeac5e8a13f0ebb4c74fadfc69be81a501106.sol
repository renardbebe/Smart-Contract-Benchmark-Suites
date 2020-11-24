 

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

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

     
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

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
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

 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint64 public releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
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

contract DepoToken is StandardToken, BurnableToken, Owned {
    string public constant name = "Depository Network Token";
    string public constant symbol = "DEPO";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 3000000000 * 10**uint256(decimals);

     
    address public saleTokensAddress;

     
    address public bountyTokensAddress;

     
    address public reserveTokensAddress;

     
    address public teamTokensAddress;

     
    address public advisorsTokensAddress;

     
    TokenTimelock public teamTokensLock;

     
    bool public saleClosed = false;

     
    mapping(address => bool) public whitelisted;

     
    modifier beforeEnd {
        require(!saleClosed);
        _;
    }

    constructor(address _teamTokensAddress, address _advisorsTokensAddress, address _reserveTokensAddress,
                address _saleTokensAddress, address _bountyTokensAddress) public {
        require(_teamTokensAddress != address(0));
        require(_advisorsTokensAddress != address(0));
        require(_reserveTokensAddress != address(0));
        require(_saleTokensAddress != address(0));
        require(_bountyTokensAddress != address(0));

        teamTokensAddress = _teamTokensAddress;
        advisorsTokensAddress = _advisorsTokensAddress;
        reserveTokensAddress = _reserveTokensAddress;
        saleTokensAddress = _saleTokensAddress;
        bountyTokensAddress = _bountyTokensAddress;

        whitelisted[saleTokensAddress] = true;
        whitelisted[bountyTokensAddress] = true;

         
         
        uint256 saleTokens = 1500000000 * 10**uint256(decimals);
        totalSupply_ = saleTokens;
        balances[saleTokensAddress] = saleTokens;
        emit Transfer(address(0), saleTokensAddress, saleTokens);

         
        uint256 bountyTokens = 180000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(bountyTokens);
        balances[bountyTokensAddress] = bountyTokens;
        emit Transfer(address(0), bountyTokensAddress, bountyTokens);

         
        uint256 reserveTokens = 780000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(reserveTokens);
        balances[reserveTokensAddress] = reserveTokens;
        emit Transfer(address(0), reserveTokensAddress, reserveTokens);

         
        uint256 teamTokens = 360000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(teamTokens);
        teamTokensLock = new TokenTimelock(this, teamTokensAddress, uint64(now + 2 * 365 days));
        balances[address(teamTokensLock)] = teamTokens;
        emit Transfer(address(0), address(teamTokensLock), teamTokens);

         
        uint256 advisorsTokens = 180000000 * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(advisorsTokens);
        balances[advisorsTokensAddress] = advisorsTokens;
        emit Transfer(address(0), advisorsTokensAddress, advisorsTokens);

        require(totalSupply_ <= HARD_CAP);
    }

     
    function close() public onlyOwner beforeEnd {
        saleClosed = true;
    }

     
     
    function whitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(!saleClosed) return false;
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(!saleClosed && !whitelisted[msg.sender]) return false;
        return super.transfer(_to, _value);
    }
}