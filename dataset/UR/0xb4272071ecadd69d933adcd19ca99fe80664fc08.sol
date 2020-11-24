 

pragma solidity "0.4.25";
 
 
 
 
 
contract InterestRateInterface {

    uint256 public constant SCALEFACTOR = 1e18;

     
    function getCurrentCompoundingLevel() public view returns (uint256);

     
     
    function getCompoundingLevelDate(uint256 _date) public view returns (uint256);

}
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
        require(_address != 0,"address is Null");
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

contract InterestRateNone is InterestRateInterface {
    
     
    function getCurrentCompoundingLevel() public view returns (uint256) {
        return SCALEFACTOR;
    }

     
     
    function getCompoundingLevelDate(uint256  ) public view returns (uint256) {
        return SCALEFACTOR;
    }

}
contract MigrationAgent is Ownable {

    address public migrationToContract;  
    address public migrationFromContract;  

     
    
    modifier onlyMigrationFromContract() {
        require(msg.sender == migrationFromContract, "Only from migration contract");
        _;
    }
     

     

     
     
    function startMigrateToContract(address _toContract) public onlyOwner {
        migrationToContract = _toContract;
        require(MigrationAgent(migrationToContract).isMigrationAgent(), "not a migratable contract");
        emit StartMigrateToContract(address(this), _toContract);
    }

     
     
    function startMigrateFromContract(address _fromConstract) public onlyOwner {
        migrationFromContract = _fromConstract;
        require(MigrationAgent(migrationFromContract).isMigrationAgent(), "not a migratable contract");
        emit StartMigrateFromContract(_fromConstract, address(this));
    }

     
    function migrate() public;   

     
     
     
    function migrateFrom(address _from, uint256 _value) public returns(bool);

     
     
    function isMigrationAgent() public pure returns(bool) {
        return true;
    }

     

     

     

    event StartMigrateToContract(address indexed fromConstract, address indexed toContract);

    event StartMigrateFromContract(address indexed fromConstract, address indexed toContract);

    event MigratedTo(address indexed owner, address indexed _contract, uint256 value);

    event MigratedFrom(address indexed owner, address indexed _contract, uint256 value);
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

contract Operator is Ownable {

    address public operator;

     

     
    modifier onlyOperator {
        require(msg.sender == operator, "Only Operator");
        _;
    }

     

    constructor() public {
        operator = msg.sender;
    }
     
    function transferOperator(address _newOperator) public notNull(_newOperator) onlyOwner {
        operator = _newOperator;
        emit TransferOperator(operator, _newOperator);
    }

     
    
    event TransferOperator(address indexed from, address indexed to);
}

contract ERC20Token is Ownable, ERC20Interface {

    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

     

    constructor() public {
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

     

     
     
     
     
     
    function transferInternal(address _from, address _to, uint256 _value) internal returns (bool) {
        uint256 value = subTokens(_from, _value);
        addTokens(_to, value);
        emit Transfer(_from, _to, value);
        return true;
    }
   
     
     
     
    function addTokens(address _owner, uint256 _value) internal;

     
     
     
    function subTokens(address _owner, uint256 _value) internal returns (uint256 _valueDeducted );
    
     
     
     
    function setBalance(address _owner, uint256 _value) internal notNull(_owner) {
        balances[_owner] = _value;
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

    address public minter;  

    uint256 internal minted;  
    uint256 internal burned;  

     

    modifier onlyMinter {
        assert(msg.sender == minter);
        _; 
    }

    constructor() public {
        minter = msg.sender;    
    }

     

     

     
     
     
     
    function mint(address _to, uint256 _value) public notNull(_to) onlyMinter {
        addTokens(_to, _value);
        notifyMinted(_to, _value);
    }

     
     
     
    function burn(uint256 _value) public whenNotPaused {
        uint256 value = subTokens(msg.sender, _value);
        notifyBurned(msg.sender, value);
    }

     
     
     
    function transferMinter(address _newMinter) public notNull(_newMinter) onlyOwner {
        address oldMinter = minter;
        minter = _newMinter;
        emit TransferMinter(oldMinter, _newMinter);
    }

     

     
     
     
     
    function notifyBurned(address _owner, uint256 _value) internal {
        burned = burned.add(_value);
        emit Transfer(_owner, address(0), _value);
    }

     
     
     
     
    function notifyMinted(address _to, uint256 _value) internal {
        minted = minted.add(_value);
        emit Transfer(address(0), _to, _value);
    }

     
     
     
     
     
    function checkMintOrBurn(address _owner, uint256 _balanceBefore, uint256 _balanceAfter) internal {
        if (_balanceBefore > _balanceAfter) {
            uint256 burnedTokens = _balanceBefore.sub(_balanceAfter);
            notifyBurned(_owner, burnedTokens);
        } else if (_balanceBefore < _balanceAfter) {
            uint256 mintedTokens = _balanceAfter.sub(_balanceBefore);
            notifyMinted(_owner, mintedTokens);
        }
    }

     
    function totalSupply() public view returns(uint256 supply) {
        return minted.sub(burned);
    }

     

     
    
    event TransferMinter(address indexed from, address indexed to);
}

contract CryptoFranc is MintableToken, MigrationAgent, Operator, InterestRateNone {

    using SafeMath for uint256;

    string constant public name = "CryptoFranc";
    string constant public symbol = "XCHF";
    uint256 constant public decimals = 18;
    string constant public version = "1.0.0.0";
    uint256 public dustAmount;

     
    string public currentFullName;
    string public announcedFullName;
    uint256 public currentMaturityDate;
    uint256 public announcedMaturityDate;
    uint256 public currentTermEndDate;
    uint256 public announcedTermEndDate;
    InterestRateInterface public currentTerms;
    InterestRateInterface public announcedTerms;

    mapping(address => uint256) internal compoundedInterestFactor;

     

    constructor(string _initialFullName, uint256 _dustAmount) public {
         
         
         
        currentFullName = _initialFullName;
        announcedFullName = _initialFullName;
        dustAmount = _dustAmount;    
        currentTerms = this;
        announcedTerms = this;
        announcedMaturityDate = block.timestamp;
        announcedTermEndDate = block.timestamp;
    }

     

     

     
     
     
     
     
    function announceRollover(string _newName, address _newTerms, uint256 _newMaturityDate, uint256 _newTermEndDate) public notNull(_newTerms) onlyOperator {
         
        require(block.timestamp >= announcedMaturityDate);

         
        uint256 newMaturityDate;
        if (_newMaturityDate == 0)
            newMaturityDate = block.timestamp;
        else
            newMaturityDate = _newMaturityDate;

         
        require(newMaturityDate >= announcedTermEndDate);

         
         
        require(newMaturityDate <= block.timestamp.add(100 days),"sanitycheck on newMaturityDate");
        require(newMaturityDate <= _newTermEndDate,"term must start before it ends");
        require(_newTermEndDate <= block.timestamp.add(200 days),"sanitycheck on newTermEndDate");

        InterestRateInterface terms = InterestRateInterface(_newTerms);
        
         
         
        uint256 newBeginLevel = terms.getCompoundingLevelDate(newMaturityDate);
        uint256 annEndLevel = announcedTerms.getCompoundingLevelDate(newMaturityDate);
        require(annEndLevel == newBeginLevel,"new initialCompoundingLevel <> old finalCompoundingLevel");

         
        currentTerms = announcedTerms;
        currentFullName = announcedFullName;
        currentMaturityDate = announcedMaturityDate;
        currentTermEndDate = announcedTermEndDate;
        announcedTerms = terms;
        announcedFullName = _newName;
        announcedMaturityDate = newMaturityDate;
        announcedTermEndDate = _newTermEndDate;

        emit AnnounceRollover(_newName, _newTerms, newMaturityDate, _newTermEndDate);
    }

     
     
     
     
     
     
     
    function collectInterest( address _owner) public notNull(_owner) whenNotPaused {
        uint256 rawBalance = super.balanceOf(_owner);
        uint256 adjustedBalance = getAdjustedValue(_owner);
        setBalance(_owner, adjustedBalance);
        checkMintOrBurn(_owner, rawBalance, adjustedBalance);
    }

     
     
     
     
     
    function migrateFrom(address _from, uint256 _value) public onlyMigrationFromContract returns(bool) {
        addTokens(_from, _value);
        notifyMinted(_from, _value);

        emit MigratedFrom(_from, migrationFromContract, _value);
        return true;
    }

     
    function migrate() public whenNotPaused {
        require(migrationToContract != 0, "not in migration mode");  
        uint256 value = balanceOf(msg.sender);
        require (value > 0, "no balance");  
        value = subTokens(msg.sender, value);
        notifyBurned(msg.sender, value);
        require(MigrationAgent(migrationToContract).migrateFrom(msg.sender, value)==true, "migrateFrom must return true");

        emit MigratedTo(msg.sender, migrationToContract, value);
    }

     

     
     
     
    function refundForeignTokens(address _tokenaddress,address _to) public notNull(_to) onlyOperator {
        ERC20Interface token = ERC20Interface(_tokenaddress);
         
        token.transfer(_to, token.balanceOf(this));
    }

     
    function getFullName() public view returns (string) {
        if ((block.timestamp <= announcedMaturityDate))
            return currentFullName;
        else
            return announcedFullName;
    }

     
     
     
    function getCompoundingLevel(address _owner) public view returns (uint256) {
        uint256 level = compoundedInterestFactor[_owner];
        if (level == 0) {
             
            return SCALEFACTOR;
        } else {
            return level;
        }
    }

     
     
    function balanceOf(address _owner) public view returns (uint256) {
        return getAdjustedValue(_owner);
    }

     

     
     
     
    function addTokens(address _owner,uint256 _value) notNull(_owner) internal {
        uint256 rawBalance = super.balanceOf(_owner);
        uint256 adjustedBalance = getAdjustedValue(_owner);
        setBalance(_owner, adjustedBalance.add(_value));
        checkMintOrBurn(_owner, rawBalance, adjustedBalance);
    }

     
     
     
    function subTokens(address _owner, uint256 _value) internal notNull(_owner) returns (uint256 _valueDeducted ) {
        uint256 rawBalance = super.balanceOf(_owner);
        uint256 adjustedBalance = getAdjustedValue(_owner);
        uint256 newBalance = adjustedBalance.sub(_value);
        if (newBalance <= dustAmount) {
             
            _valueDeducted = _value.add(newBalance);
            newBalance =  0;
        } else {
            _valueDeducted = _value;
        }
        setBalance(_owner, newBalance);
        checkMintOrBurn(_owner, rawBalance, adjustedBalance);
    }

     
     
     
    function setBalance(address _owner, uint256 _value) internal {
        super.setBalance(_owner, _value);
         
        if (_value == 0) {
             
            delete compoundedInterestFactor[_owner];
        } else {
             
             
            uint256 currentLevel = getInterestRate().getCurrentCompoundingLevel();
            if (currentLevel != getCompoundingLevel(_owner)) {
                compoundedInterestFactor[_owner] = currentLevel;
            }
        }
    }

     
    function getInterestRate() internal view returns (InterestRateInterface) {
        if ((block.timestamp <= announcedMaturityDate))
            return currentTerms;
        else
            return announcedTerms;
    }

     
     
    function getAdjustedValue(address _owner) internal view returns (uint256) {
        uint256 _rawBalance = super.balanceOf(_owner);
         
        if (_rawBalance == 0)
            return 0;
         
        uint256 startLevel = getCompoundingLevel(_owner);
        uint256 currentLevel = getInterestRate().getCurrentCompoundingLevel();
        return _rawBalance.mul(currentLevel).div(startLevel);
    }

     
     
     
    function getAdjustedValueDate(address _owner,uint256 _date) public view returns (uint256) {
        uint256 _rawBalance = super.balanceOf(_owner);
         
        if (_rawBalance == 0)
            return 0;
         
        uint256 startLevel = getCompoundingLevel(_owner);

        InterestRateInterface dateTerms;
        if (_date <= announcedMaturityDate)
            dateTerms = currentTerms;
        else
            dateTerms = announcedTerms;

        uint256 dateLevel = dateTerms.getCompoundingLevelDate(_date);
        return _rawBalance.mul(dateLevel).div(startLevel);
    }

     

     

    event AnnounceRollover(string newName, address indexed newTerms, uint256 indexed newMaturityDate, uint256 indexed newTermEndDate);
}