 

pragma solidity 0.5.7;

 
contract Ownable {
    address public owner;
    address public newOwner;

     

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

     
    modifier onlyNewOwner() {
        require(msg.sender == newOwner, "Only New Owner");
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Address is Null");
        _;
    }

     

     
    constructor() public {
        owner = msg.sender;
    }

     
     
    
    function transferOwnership(address _newOwner) public notNull(_newOwner) onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public onlyNewOwner {
        address oldOwner = owner;
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

     
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}


 
contract Pausable is Ownable {

    bool public paused = false;

     

     
    modifier whenNotPaused() {
        require(!paused, "only when not paused");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "only when paused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

     

    event Pause();

    event Unpause();
}


 
 

contract ERC20Interface {
     
    function totalSupply() public view returns(uint256 supply);

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

 
contract ERC20Token is Ownable, ERC20Interface {

    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 internal _totalSupply;
    
     

    constructor(uint256 initialAmount) public {
        if (initialAmount == 0)
            return;
        balances[msg.sender] = initialAmount;
        _totalSupply = initialAmount;
        emit Transfer(address(0), msg.sender, initialAmount);
    }

     

     

    function totalSupply() public view returns(uint256 supply)
    {
        return _totalSupply;
    }

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {

        return transferInternal(msg.sender, _to, _value);
    }

     

     
   
     
     
     
     
    function approve(address _spender, uint256 _value) public notNull(_spender) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender], "insufficient tokens");

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return transferInternal(_from, _to, _value);
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     

     
     
     
     
     
    function transferInternal(address _from, address _to, uint256 _value) internal notNull(_from) notNull(_to) returns (bool) {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }   

     
}

 

contract PausableToken is ERC20Token, Pausable {

     
     
     
     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        return super.transfer(_to, _value);
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

     
     
     
     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        return super.approve(_spender, _value);
    }
}


 

contract MintableToken is PausableToken
{
    using SafeMath for uint256;

    mapping(address => bool) internal minters;  

     

    modifier onlyMinter {
        require(minters[msg.sender], "Caller not minter");
        _; 
    }

     

    constructor() public {
        addMinter(msg.sender);    
    }

     

     

     
     
     
     
    function mint(address _to, uint256 _value) public onlyMinter {
        mintInternal(_to, _value);
    }

     
     
     
    function addMinter(address _newMinter) public notNull(_newMinter) onlyOwner {
        if (minters[_newMinter])
            return;
        minters[_newMinter] = true;
        emit AddMinter(_newMinter);
    }

     
     
     
    function removeMinter(address _oldMinter) public notNull(_oldMinter) onlyOwner {
        if (!minters[_oldMinter])
            return;
        minters[_oldMinter] = false;
        emit RemoveMinter(_oldMinter);
    }

     
     
     
    function isMinter(address _minter) public notNull(_minter) view returns(bool)  {
        return minters[_minter];
    }

     

     
     
     
     
    function mintInternal(address _to, uint256 _value) internal notNull(_to) {
        balances[_to] = balances[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);
        emit Transfer(address(0), _to, _value);
    }

     
     
     
     
    function burn(address _from, uint256 _value) internal notNull(_from) {
        balances[_from] = balances[_from].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Transfer(_from, address(0), _value);
    }


     

     
    
    event AddMinter(address indexed newMinter);
    
    event RemoveMinter(address indexed oldMinter);
}

 
contract MigrationAgent is Ownable, Pausable {

    address public migrationToContract;  
    address public migrationFromContract;  

     
    
    modifier onlyMigrationFromContract() {
        require(msg.sender == migrationFromContract, "Only from migration contract");
        _;
    }
     

     

     
     
    function startMigrateToContract(address _toContract) public onlyOwner whenPaused {
        migrationToContract = _toContract;
        require(MigrationAgent(migrationToContract).isMigrationAgent(), "not a migratable contract");
        emit StartMigrateToContract(address(this), _toContract);
    }

     
     
    function startMigrateFromContract(address _fromContract) public onlyOwner whenPaused {
        migrationFromContract = _fromContract;
        require(MigrationAgent(migrationFromContract).isMigrationAgent(), "not a migratable contract");
        emit StartMigrateFromContract(_fromContract, address(this));
    }

     
    function migrate() public;   

     
     
     
    function migrateFrom(address _from, uint256 _value) public returns(bool);

     
     
    function isMigrationAgent() public pure returns(bool) {
        return true;
    }

     

     

     

    event StartMigrateToContract(address indexed fromContract, address indexed toContract);

    event StartMigrateFromContract(address indexed fromContract, address indexed toContract);

    event MigratedTo(address indexed owner, address indexed _contract, uint256 value);

    event MigratedFrom(address indexed owner, address indexed _contract, uint256 value);
}


contract ActiveBitcoinEtherCertificate is MintableToken, MigrationAgent {

    using SafeMath for uint256;

    string constant public name = "Active Bitcoin Ether Certificate";
    string constant public symbol = "ABEC";
    uint8 constant public decimals = 5;
    string constant public version = "1.0.0.0";

    address public redeemAddress;
    string public description;

     

    constructor(address _redeemAddress) ERC20Token(0) notNull(_redeemAddress) public {
        redeemAddress = _redeemAddress;
    }

     

     
     
    function updateDescription(string calldata _text) external onlyMinter {
        description = _text;
    }

     

     
     
     
     
     
    function migrateFrom(address _from, uint256 _value) public onlyMigrationFromContract whenNotPaused returns(bool) {
        mintInternal(_from, _value);

        emit MigratedFrom(_from, migrationFromContract, _value);
        return true;
    }

     
    function migrate() public whenNotPaused {
        require(migrationToContract != address(0), "not in migration mode");  
        uint256 value = balanceOf(msg.sender);
        require (value > 0, "no balance");  
        burn(msg.sender, value);
        require(MigrationAgent(migrationToContract).migrateFrom(msg.sender, value)==true, "migrateFrom must return true");
        emit MigratedTo(msg.sender, migrationToContract, value);
    }

     

     
     
     
    function refundForeignTokens(address _tokenaddress,address _to) public notNull(_to) onlyMinter {
        require(_tokenaddress != address(this), "Must not be self");
        ERC20Interface token = ERC20Interface(_tokenaddress);

         
         
        (bool success, bytes memory returndata) = address(token).call(abi.encodeWithSelector(token.transfer.selector, _to, token.balanceOf(address(this))));
        require(success);

        if (returndata.length > 0) {  
            require(abi.decode(returndata, (bool)));
        }        
    }

     
     
     
     
    function transferAccount(address _from, address _to) public onlyMinter returns (bool result) {
        uint256 balance = balanceOf(_from);
        if(_to == redeemAddress) {
            result = transferInternal(_from, _to, balance);
        } else {
            result = super.transferInternal(_from, _to, balance);
        }
        emit TransferAccount(_from, _to);
    }

     

     
     
     
     
     
    function transferInternal(address _from, address _to, uint256 _value) internal notNull(_from) returns (bool) {
        require(_to == redeemAddress, "Wrong destination address");
         
        balances[_from] = balances[_from].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
         
        emit Transfer(_from, _to, _value);
        emit Transfer(_to, address(0), _value);
        return true;
    }

     

    event TransferAccount(address indexed _from, address indexed _to);
}