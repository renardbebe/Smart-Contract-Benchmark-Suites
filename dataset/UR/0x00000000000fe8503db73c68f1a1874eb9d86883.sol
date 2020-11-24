 

 

pragma solidity 0.5.0;

 
contract Ownable {

    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
     
    constructor() public {
        setOwner(msg.sender);
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "msg.sender should be onlyPendingOwner");
        _;
    }

     
    modifier onlyOwner() {
        require(msg.sender == _owner, "msg.sender should be owner");
        _;
    }

     
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }
    
     
    function owner() public view returns (address ) {
        return _owner;
    }
    
     
    function setOwner(address _newOwner) internal {
        _owner = _newOwner;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _pendingOwner = _newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0); 
    }
    
}

 

pragma solidity 0.5.0;


contract Operable is Ownable {

    address private _operator; 

    event OperatorChanged(address indexed previousOperator, address indexed newOperator);

     
    function operator() external view returns (address) {
        return _operator;
    }
    
     
    modifier onlyOperator() {
        require(msg.sender == _operator, "msg.sender should be operator");
        _;
    }

     
    function updateOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0), "Cannot change the newOperator to the zero address");
        emit OperatorChanged(_operator, _newOperator);
        _operator = _newOperator;
    }

}

 

pragma solidity 0.5.0;

 
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

 

pragma solidity 0.5.0;



contract TokenStore is Operable {

    using SafeMath for uint256;

    uint256 public totalSupply;
    
    string  public name = "PingAnToken";
    string  public symbol = "PAT";
    uint8 public decimals = 18;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function changeTokenName(string memory _name, string memory _symbol) public onlyOperator {
        name = _name;
        symbol = _symbol;
    }

    function addBalance(address _holder, uint256 _value) public onlyOperator {
        balances[_holder] = balances[_holder].add(_value);
    }

    function subBalance(address _holder, uint256 _value) public onlyOperator {
        balances[_holder] = balances[_holder].sub(_value);
    }

    function setBalance(address _holder, uint256 _value) public onlyOperator {
        balances[_holder] = _value;
    }

    function addAllowance(address _holder, address _spender, uint256 _value) public onlyOperator {
        allowed[_holder][_spender] = allowed[_holder][_spender].add(_value);
    }

    function subAllowance(address _holder, address _spender, uint256 _value) public onlyOperator {
        allowed[_holder][_spender] = allowed[_holder][_spender].sub(_value);
    }

    function setAllowance(address _holder, address _spender, uint256 _value) public onlyOperator {
        allowed[_holder][_spender] = _value;
    }

    function addTotalSupply(uint256 _value) public onlyOperator {
        totalSupply = totalSupply.add(_value);
    }

    function subTotalSupply(uint256 _value) public onlyOperator {
        totalSupply = totalSupply.sub(_value);
    }

    function setTotalSupply(uint256 _value) public onlyOperator {
        totalSupply = _value;
    }

}

 

pragma solidity 0.5.0;


interface ERC20Interface {  

    function totalSupply() external view returns (uint256);

    function balanceOf(address holder) external view returns (uint256);

    function allowance(address holder, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed holder, address indexed spender, uint256 value);

}

 

pragma solidity 0.5.0;




contract ERC20StandardToken is ERC20Interface, Ownable {


    TokenStore public tokenStore;
    
    event TokenStoreSet(address indexed previousTokenStore, address indexed newTokenStore);
    event ChangeTokenName(string newName, string newSymbol);

     
    function setTokenStore(address _newTokenStore) public onlyOwner returns (bool) {
        emit TokenStoreSet(address(tokenStore), _newTokenStore);
        tokenStore = TokenStore(_newTokenStore);
        return true;
    }
    
    function changeTokenName(string memory _name, string memory _symbol) public onlyOwner {
        tokenStore.changeTokenName(_name, _symbol);
        emit ChangeTokenName(_name, _symbol);
    }

    function totalSupply() public view returns (uint256) {
        return tokenStore.totalSupply();
    }

    function balanceOf(address _holder) public view returns (uint256) {
        return tokenStore.balances(_holder);
    }

    function allowance(address _holder, address _spender) public view returns (uint256) {
        return tokenStore.allowed(_holder, _spender);
    }
    
    function name() public view returns (string memory) {
        return tokenStore.name();
    }
    
    function symbol() public view returns (string memory) {
        return tokenStore.symbol();
    }
    
    function decimals() public view returns (uint8) {
        return tokenStore.decimals();
    }
    
     
    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        require (_spender != address(0), "Cannot approve to the zero address");       
        tokenStore.setAllowance(msg.sender, _spender, _value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    ) public returns (bool success) {
        require (_spender != address(0), "Cannot increaseApproval to the zero address");      
        tokenStore.addAllowance(msg.sender, _spender, _addedValue);
        emit Approval(msg.sender, _spender, tokenStore.allowed(msg.sender, _spender));
        return true;
    }
    
     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue 
    ) public returns (bool success) {
        require (_spender != address(0), "Cannot decreaseApproval to the zero address");       
        tokenStore.subAllowance(msg.sender, _spender, _subtractedValue);
        emit Approval(msg.sender, _spender, tokenStore.allowed(msg.sender, _spender));
        return true;
    }

     
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address"); 
        tokenStore.subAllowance(_from, msg.sender, _value);          
        tokenStore.subBalance(_from, _value);
        tokenStore.addBalance(_to, _value);
        emit Transfer(_from, _to, _value);
        return true;
    } 

     
    function transfer(
        address _to, 
        uint256 _value
    ) public returns (bool success) {
        require (_to != address(0), "Cannot transfer to zero address");    
        tokenStore.subBalance(msg.sender, _value);
        tokenStore.addBalance(_to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

}

 

pragma solidity 0.5.0;



contract PausableToken is ERC20StandardToken {

    address private _pauser;
    bool public paused = false;

    event Pause();
    event Unpause();
    event PauserChanged(address indexed previousPauser, address indexed newPauser);
    
     
    function pauser() public view returns (address) {
        return _pauser;
    }
    
     
    modifier whenNotPaused() {
        require(!paused, "state shouldn't be paused");
        _;
    }

     
    modifier onlyPauser() {
        require(msg.sender == _pauser, "msg.sender should be pauser");
        _;
    }

     
    function pause() public onlyPauser {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyPauser {
        paused = false;
        emit Unpause();
    }

     
    function updatePauser(address _newPauser) public onlyOwner {
        require(_newPauser != address(0), "Cannot update the newPauser to the zero address");
        emit PauserChanged(_pauser, _newPauser);
        _pauser = _newPauser;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public whenNotPaused returns (bool success) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    ) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    } 

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue 
    ) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) public whenNotPaused returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    } 

    function transfer(
        address _to, 
        uint256 _value
    ) public whenNotPaused returns (bool success) {
        return super.transfer(_to, _value);
    }

}

 

pragma solidity 0.5.0;


contract BlacklistStore is Operable {

    mapping (address => uint256) public blacklisted;

     
    function setBlacklist(address _account, uint256 _status) public onlyOperator {
        blacklisted[_account] = _status;
    }

}

 

pragma solidity 0.5.0;



 
contract BlacklistableToken is PausableToken {

    BlacklistStore public blacklistStore;

    address private _blacklister;

    event BlacklisterChanged(address indexed previousBlacklister, address indexed newBlacklister);
    event BlacklistStoreSet(address indexed previousBlacklistStore, address indexed newblacklistStore);
    event Blacklist(address indexed account, uint256 _status);


     
    modifier notBlacklisted(address _account) {
        require(blacklistStore.blacklisted(_account) == 0, "Account in the blacklist");
        _;
    }

     
    modifier onlyBlacklister() {
        require(msg.sender == _blacklister, "msg.sener should be blacklister");
        _;
    }

     
    function blacklister() public view returns (address) {
        return _blacklister;
    }
    
     
    function setBlacklistStore(address _newblacklistStore) public onlyOwner returns (bool) {
        emit BlacklistStoreSet(address(blacklistStore), _newblacklistStore);
        blacklistStore = BlacklistStore(_newblacklistStore);
        return true;
    }
    
     
    function updateBlacklister(address _newBlacklister) public onlyOwner {
        require(_newBlacklister != address(0), "Cannot update the blacklister to the zero address");
        emit BlacklisterChanged(_blacklister, _newBlacklister);
        _blacklister = _newBlacklister;
    }

     
    function queryBlacklist(address _account) public view returns (uint256) {
        return blacklistStore.blacklisted(_account);
    }

     
    function changeBlacklist(address _account, uint256 _status) public onlyBlacklister {
        blacklistStore.setBlacklist(_account, _status);
        emit Blacklist(_account, _status);
    }

    function approve(
        address _spender,
        uint256 _value
    ) public notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool success) {
        return super.approve(_spender, _value);
    }
    
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    ) public notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    } 

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue 
    ) public notBlacklisted(msg.sender) notBlacklisted(_spender) returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) public notBlacklisted(_from) notBlacklisted(_to) notBlacklisted(msg.sender) returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    } 

    function transfer(
        address _to, 
        uint256 _value
    ) public notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool success) {
        return super.transfer(_to, _value);
    }

}

 

pragma solidity 0.5.0;


contract BurnableToken is BlacklistableToken {

    event Burn(address indexed burner, uint256 value);
    
     
    function burn(
        uint256 _value
    ) public whenNotPaused notBlacklisted(msg.sender) returns (bool success) {   
        tokenStore.subBalance(msg.sender, _value);
        tokenStore.subTotalSupply(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

}

 

pragma solidity 0.5.0;



contract MintableToken is BlacklistableToken {

    event MinterChanged(address indexed previousMinter, address indexed newMinter);
    event Mint(address indexed minter, address indexed to, uint256 value);

    address private _minter;

    modifier onlyMinter() {
        require(msg.sender == _minter, "msg.sender should be minter");
        _;
    }

     
    function minter() public view returns (address) {
        return _minter;
    }
 
     
    function updateMinter(address _newMinter) public onlyOwner {
        require(_newMinter != address(0), "Cannot update the newPauser to the zero address");
        emit MinterChanged(_minter, _newMinter);
        _minter = _newMinter;
    }

     
    function mint(
        address _to, 
        uint256 _value
    ) public onlyMinter whenNotPaused notBlacklisted(msg.sender) notBlacklisted(_to) returns (bool) {
        require(_to != address(0), "Cannot mint to zero address");
        tokenStore.addTotalSupply(_value);
        tokenStore.addBalance(_to, _value);  
        emit Mint(msg.sender, _to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

}

 

pragma solidity 0.5.0;




contract PingAnToken is BurnableToken, MintableToken {


     
    bool private initialized = true;

     
    function initialize(address _owner) public {
        require(!initialized, "already initialized");
        require(_owner != address(0), "Cannot initialize the owner to zero address");
        setOwner(_owner);
        initialized = true;
    }

}