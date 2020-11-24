 

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

 
contract TokenVault {
    using SafeERC20 for ERC20;

     
    ERC20 public token;

    constructor(ERC20 _token) public {
        token = _token;
    }

     
    function fillUpAllowance() public {
        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.approve(token, amount);
    }
}

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }
}

contract IdealCoinToken is BurnableToken, Owned {
    string public constant name = "IdealCoin";
    string public constant symbol = "IDC";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 2200000000 * 10**uint256(decimals);

     
    address public boardTokensAddress;

     
    address public platformTokensAddress;

     
    address public saleTokensAddress;

     
    address public referralBountyTokensAddress;

     
    uint64 public date01Feb2019 = 1548979200;

     
    TokenVault public foundersAdvisorsPartnersTokensVault;

     
    mapping(address => address) public lockOf;

     
    bool public saleClosed = false;

     
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    constructor(address _boardTokensAddress, address _platformTokensAddress,
                address _saleTokensAddress, address _referralBountyTokensAddress) public {
        require(_boardTokensAddress != address(0));
        require(_platformTokensAddress != address(0));
        require(_saleTokensAddress != address(0));
        require(_referralBountyTokensAddress != address(0));

        boardTokensAddress = _boardTokensAddress;
        platformTokensAddress = _platformTokensAddress;
        saleTokensAddress = _saleTokensAddress;
        referralBountyTokensAddress = _referralBountyTokensAddress;

         
        uint256 saleTokens = 73050000;
        createTokens(saleTokens, saleTokensAddress);

         
        uint256 referralBountyTokens = 7950000;
        createTokens(referralBountyTokens, referralBountyTokensAddress);

         
        uint256 boardTokens = 12000000;
        createTokens(boardTokens, boardTokensAddress);

         
        uint256 platformTokens = 2080000000;
        createTokens(platformTokens, platformTokensAddress);

        require(totalSupply_ <= HARD_CAP);
    }

    function createLockingTokenVaults() external onlyOwner beforeSaleClosed {
         
        uint256 foundersAdvisorsPartnersTokens = 27000000;
        foundersAdvisorsPartnersTokensVault = createTokenVault(foundersAdvisorsPartnersTokens);

        require(totalSupply_ <= HARD_CAP);
    }

     
    function createTokenVault(uint256 tokens) internal onlyOwner returns (TokenVault) {
        TokenVault tokenVault = new TokenVault(ERC20(this));
        createTokens(tokens, tokenVault);
        tokenVault.fillUpAllowance();
        return tokenVault;
    }

     
    function createTokens(uint256 _tokens, address _destination) internal onlyOwner {
        uint256 tokens = _tokens * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(tokens);
        balances[_destination] = tokens;
        emit Transfer(0x0, _destination, tokens);

        require(totalSupply_ <= HARD_CAP);
   }

     
    function lockTokens(address _beneficiary, uint256 _tokensAmount) external onlyOwner {
        require(lockOf[_beneficiary] == 0x0);
        require(_beneficiary != address(0));

        TokenTimelock lock = new TokenTimelock(ERC20(this), _beneficiary, date01Feb2019);
        lockOf[_beneficiary] = address(lock);
        require(this.transferFrom(foundersAdvisorsPartnersTokensVault, lock, _tokensAmount));
    }

     
    function releaseLockedTokens() external {
        releaseLockedTokensFor(msg.sender);
    }

     
     
    function releaseLockedTokensFor(address _owner) public {
        TokenTimelock(lockOf[_owner]).release();
    }

     
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        return balances[lockOf[_owner]];
    }

     
    function closeSale() external onlyOwner beforeSaleClosed {
         

        uint256 unsoldTokens = balances[saleTokensAddress];
        balances[platformTokensAddress] = balances[platformTokensAddress].add(unsoldTokens);
        balances[saleTokensAddress] = 0;
        emit Transfer(saleTokensAddress, platformTokensAddress, unsoldTokens);

        uint256 unallocatedBountyTokens = balances[referralBountyTokensAddress];
        balances[platformTokensAddress] = balances[platformTokensAddress].add(unallocatedBountyTokens);
        balances[referralBountyTokensAddress] = 0;
        emit Transfer(referralBountyTokensAddress, platformTokensAddress, unallocatedBountyTokens);

        saleClosed = true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(saleClosed || msg.sender == address(this) || msg.sender == owner) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(saleClosed || msg.sender == saleTokensAddress || msg.sender == referralBountyTokensAddress) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}