 

pragma solidity 0.5.3;

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

contract Documentable is Ownable {
  address private _provenanceDocuments;
  bytes32 public assetHash;

  constructor (address documentsContract) public Ownable() {
    _provenanceDocuments = documentsContract;
  }

  function getProvenanceDocuments() public view returns(address) {
    return _provenanceDocuments;
  }

  function setAssetHash(bytes32 _newHash) public onlyOwner {
    require(assetHash == 0x0, "Asset Hash can only be set once");
    assetHash = _newHash;
  }
}

contract Migratable is ERC20, Ownable{
  address private _new;
  mapping (address => bool) private _old;

  event NewVersionChanges(address old, address new_);
  
  event OldVersionAdded(address old);
  event OldVersionRemoved(address old);
  
  event Migrated(address account, uint256 balance);

  modifier onlyOldVersion(){
    require(msg.sender != address(0x0), "Invalid caller");
    require(_old[msg.sender], "Only callable by old version");
    _;
  }

  modifier onlyIfNewVersionIsDefined(){
    require(_new != address(0x0), "Unknow new version");
    _;
  }

  function appendOldVersion(address old) public onlyOwner{
    require(_old[old] == false, "Know old version");
    _old[old] = true;
    emit OldVersionAdded(old);
  }

  function appendOldVersions(address[] memory olds) public{
    for (uint i = 0; i < olds.length; i++) {
      appendOldVersion(olds[i]);
    }
  }

  function removeOldVersion(address old) public onlyOwner{
    require(_old[old], "Unknow old version");
    _old[old] = false;
    emit OldVersionRemoved(old);
  }

  function removeOldVersions(address[] memory olds) public{
    for (uint i = 0; i < olds.length; i++) {
      removeOldVersion(olds[i]);
    }
  }

  function setNewVersion(address new_) public onlyOwner{
    emit NewVersionChanges(_new, new_);
    _new = new_;
  }

  function newVersion() public view returns(address){
    return _new;
  }

  function isOldVersion(address address_) public view returns(bool){
    return _old[address_];
  }

  function migrate() public onlyIfNewVersionIsDefined {
    address account = msg.sender;
    uint256 balance = balanceOf(account);
    require(balance > 0, "Current balance is zero");

    _burn(account, balance);
    Migratable(_new).migration(account, balance);
    emit Migrated(account, balance);
  }

  function migration(address account, uint256 balance) public onlyOldVersion{
    _mint(account,balance);
    emit Migrated(account, balance);
  }
}

contract Pausable is Ownable {
    event Paused();
    event Unpaused();

    bool private _paused;

    constructor () public {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Unpaused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

     
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }
}

contract Policable is Ownable {
    ITransferPolicy public transferPolicy;
    event PolicyChanged(address _oldPolicy, address _newPolicy);

    constructor(
        address policyContract
    ) public {
        transferPolicy = ITransferPolicy(policyContract);
    }


    modifier onlyIfIsTransferPossible(address from, address to, uint256 value){
        require(transferPolicy.isTransferPossible(from, to, value), "Transfer is not possible");
        _;
    }

    modifier onlyIfIsBehalfTransferPossible(address sender, address from, address to, uint256 value){
        require(transferPolicy.isBehalfTransferPossible(sender, from, to, value), "Transfer is not possible");
        _;
    }

    function setTransferPolicy(address _newPolicy) public onlyOwner {
        address old = address(transferPolicy);
        transferPolicy = ITransferPolicy(_newPolicy);
        emit PolicyChanged(old, _newPolicy);
    }
}

contract Seizable is ERC20, Ownable {
    mapping(address => uint256) public seizedAmounts;
    event Seizure(address indexed seized, uint256 amount);

    function seize(address _seized) public onlyOwner {
        uint256 _amount = balanceOf(_seized);
        _burn(_seized, _amount);
        _mint(owner(), _amount);
        emit Seizure(_seized, _amount);
    }
}

contract Token is ERC20, ERC20Detailed {
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 mint) ERC20Detailed(name,symbol,decimals) public {
        _mint(msg.sender, mint);
    }
}

contract ArtworkToken is Token, Policable, Seizable, Pausable, Documentable, Migratable{
    

    constructor (
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 amount,
        address policyContract,
        address documentsContract
    ) public 
        Token(name, symbol, decimals, amount)
        Policable(policyContract)
        Pausable()
        Documentable(documentsContract)
    { }

    function transfer(address to, uint256 value) public
        whenNotPaused
        onlyIfIsTransferPossible(msg.sender, to, value)
    returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value)  public
        whenNotPaused
        onlyIfIsBehalfTransferPossible(msg.sender, from, to, value)
    returns (bool) {
        return super.transferFrom(from, to, value);
    }
}

interface ITransferPolicy {
    function isTransferPossible(address from, address to, uint256 amount) 
        external view returns (bool);
    
    function isBehalfTransferPossible(address sender, address from, address to, uint256 amount) 
        external view returns (bool);
}