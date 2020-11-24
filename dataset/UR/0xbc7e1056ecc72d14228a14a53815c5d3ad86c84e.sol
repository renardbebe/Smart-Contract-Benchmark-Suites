 

pragma solidity ^0.5.10;

 
 
import './ERC20.sol';
import './SafeMath.sol';

 
import './ownable.sol';
import './blacklistable.sol';
import "./pausable.sol";


 
contract MFPH_v1 is Ownable, ERC20, Pausable, Blacklistable {
    using SafeMath for uint256;
 

 
    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public MFMinter;
    bool internal initialized;

 
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_ = 0;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MFMinterChanged(address indexed newMFMinter);

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _currency,
        uint8 _decimals,
        address _MFMinter,
        address _pauser,
        address _blacklister,
        address _owner
    ) public {
        require(!initialized);
        require(_MFMinter != address(0));
        require(_pauser != address(0));
        require(_blacklister != address(0));
        require(_owner != address(0));
 

        name = _name;
        symbol = _symbol;
        currency = _currency;
        decimals = _decimals;
        MFMinter = _MFMinter;
        pauser = _pauser;
        blacklister = _blacklister;
         
        setOwner(_owner);
        initialized = true;
    }

     
    modifier onlyMinters() {
        require(minters[msg.sender] == true);
        _;
    }

     
     
    function mint(address _to, uint256 _amount) whenNotPaused onlyMinters notBlacklisted(msg.sender) notBlacklisted(_to) public returns (bool) {
        require(_to != address(0));
        require(_amount > 0);

        uint256 mintingAllowedAmount = minterAllowed[msg.sender];
        require(_amount <= mintingAllowedAmount);

        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        minterAllowed[msg.sender] = mintingAllowedAmount.sub(_amount);
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

     
    modifier onlyMFMinter() {
        require(msg.sender == MFMinter);
        _;
    }

     
    function minterAllowance(address minter) public view returns (uint256) {
        return minterAllowed[minter];
    }

     
    function isMinter(address account) public view returns (bool) {
        return minters[account];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_spender) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused notBlacklisted(_to) notBlacklisted(msg.sender) notBlacklisted(_from) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function transfer(address _to, uint256 _value) whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_to) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function configureMinter(address minter, uint256 minterAllowedAmount) whenNotPaused onlyMFMinter public returns (bool) {
        minters[minter] = true;
        minterAllowed[minter] = minterAllowedAmount;
        emit MinterConfigured(minter, minterAllowedAmount);
        return true;
    }

     
    function removeMinter(address minter) onlyMFMinter public returns (bool) {
        minters[minter] = false;
        minterAllowed[minter] = 0;
        emit MinterRemoved(minter);
        return true;
    }

     
    function burn(uint256 _amount) whenNotPaused onlyMinters notBlacklisted(msg.sender) public {
        uint256 balance = balances[msg.sender];
        require(_amount > 0);
        require(balance >= _amount);
 
 
        totalSupply_ = totalSupply_.sub(_amount);
        balances[msg.sender] = balance.sub(_amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

 
    function updateMFMinter(address _newMFMinter) onlyOwner public {
        require(_newMFMinter != address(0));
        MFMinter = _newMFMinter;
        emit MFMinterChanged(MFMinter);
    }
}
