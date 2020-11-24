 

pragma solidity 0.4.24;
pragma experimental "v0.5.0";

contract Administration {

    using SafeMath for uint256;

    address public owner;
    address public admin;

    event AdminSet(address _admin);
    event OwnershipTransferred(address _previousOwner, address _newOwner);


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "must be non zero address");
        _;
    }

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    function setAdmin(
        address _newAdmin
    )
        public
        onlyOwner
        nonZeroAddress(_newAdmin)
        returns (bool)
    {
        require(_newAdmin != admin);
        admin = _newAdmin;
        emit AdminSet(_newAdmin);
        return true;
    }

    function transferOwnership(
        address _newOwner
    )
        public
        onlyOwner
        nonZeroAddress(_newOwner)
        returns (bool)
    {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
        return true;
    }

}


library SafeMath {

   
   
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
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

 
interface ERC20Interface {
    function owner() external view returns (address);
    function decimals() external view returns (uint8);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

interface StakeInterface {
    function activeStakes() external view returns (uint256);
}

 
 
 
contract RTCoin is Administration {

    using SafeMath for uint256;

     
    uint256 constant public INITIALSUPPLY = 61600000000000000000000000;
    string  constant public VERSION = "production";

     
    StakeInterface public stake = StakeInterface(0);
     
    address public  stakeContractAddress = address(0);
     
    address public  mergedMinerValidatorAddress = address(0);
    string  public  name = "RTCoin";
    string  public  symbol = "RTC";
    uint256 public  totalSupply = INITIALSUPPLY;
    uint8   public  decimals = 18;
     
    bool    public  transfersFrozen = true;
    bool    public  stakeFailOverRestrictionLifted = false;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) public minters;

    event Transfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event TransfersFrozen(bool indexed _transfersFrozen);
    event TransfersThawed(bool indexed _transfersThawed);
    event ForeignTokenTransfer(address indexed _sender, address indexed _recipient, uint256 _amount);
    event EthTransferOut(address indexed _recipient, uint256 _amount);
    event MergedMinerValidatorSet(address _contractAddress);
    event StakeContractSet(address _contractAddress);
    event FailOverStakeContractSet(address _contractAddress);
    event CoinsMinted(address indexed _stakeContract, address indexed _recipient, uint256 _mintAmount);

    modifier transfersNotFrozen() {
        require(!transfersFrozen, "transfers must not be frozen");
        _;
    }

    modifier transfersAreFrozen() {
        require(transfersFrozen, "transfers must be frozen");
        _;
    }

     
    modifier onlyMinters() {
        require(minters[msg.sender] == true, "sender must be a valid minter");
        _;
    }

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "must be non zero address");
        _;
    }

    modifier nonAdminAddress(address _addr) {
        require(_addr != owner && _addr != admin, "addr cant be owner or admin");
        _;
    }

    constructor() public {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

     
    function transfer(
        address _recipient,
        uint256 _amount
    )
        public
        transfersNotFrozen
        nonZeroAddress(_recipient)
        returns (bool)
    {
         
        require(balances[msg.sender] >= _amount, "sender does not have enough tokens");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(msg.sender, _recipient, _amount);
        return true;
    }

     
    function transferFrom(
        address _owner,
        address _recipient,
        uint256 _amount
    )
        public
        transfersNotFrozen
        nonZeroAddress(_recipient)
        returns (bool)
    {
         
        require(balances[_owner] >= _amount, "owner does not have enough tokens");
         
        require(allowed[_owner][msg.sender] >= _amount, "sender does not have enough allowance");
         
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_amount);
         
        balances[_owner] = balances[_owner].sub(_amount);
         
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_owner, _recipient, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     

     
    function setMergedMinerValidator(address _mergedMinerValidator) external onlyOwner nonAdminAddress(_mergedMinerValidator) returns (bool) {
        mergedMinerValidatorAddress = _mergedMinerValidator;
        minters[_mergedMinerValidator] = true;
        emit MergedMinerValidatorSet(_mergedMinerValidator);
        return true;
    }

     
    function setStakeContract(address _contractAddress) external onlyOwner nonAdminAddress(_contractAddress) returns (bool) {
         
        if (stakeContractAddress != address(0)) {
            require(stake.activeStakes() == 0, "staking contract already configured, to change it must have 0 active stakes");
        }
        stakeContractAddress = _contractAddress;
        minters[_contractAddress] = true;
        stake = StakeInterface(_contractAddress);
        emit StakeContractSet(_contractAddress);
        return true;
    }

     
    function setFailOverStakeContract(address _contractAddress) external onlyOwner nonAdminAddress(_contractAddress) returns (bool) {
        if (stakeFailOverRestrictionLifted == false) {
            stakeFailOverRestrictionLifted = true;
            return true;
        } else {
            minters[_contractAddress] = true;
            stakeFailOverRestrictionLifted = false;
            emit FailOverStakeContractSet(_contractAddress);
            return true;
        }
    }

     
    function mint(
        address _recipient,
        uint256 _amount)
        public
        onlyMinters
        returns (bool)
    {
        balances[_recipient] = balances[_recipient].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Transfer(address(0), _recipient, _amount);
        emit CoinsMinted(msg.sender, _recipient, _amount);
        return true;
    }

     
    function transferForeignToken(
        address _tokenAddress,
        address _recipient,
        uint256 _amount)
        public
        onlyAdmin
        nonZeroAddress(_recipient)
        returns (bool)
    {
         
        require(_tokenAddress != address(this), "token address can't be this contract");
        ERC20Interface eI = ERC20Interface(_tokenAddress);
        require(eI.transfer(_recipient, _amount), "token transfer failed");
        emit ForeignTokenTransfer(msg.sender, _recipient, _amount);
        return true;
    }
    
     
    function transferOutEth()
        public
        onlyAdmin
        returns (bool)
    {
        uint256 balance = address(this).balance;
        msg.sender.transfer(address(this).balance);
        emit EthTransferOut(msg.sender, balance);
        return true;
    }

     
    function freezeTransfers()
        public
        onlyAdmin
        returns (bool)
    {
        transfersFrozen = true;
        emit TransfersFrozen(true);
        return true;
    }

     
    function thawTransfers()
        public
        onlyAdmin
        returns (bool)
    {
        transfersFrozen = false;
        emit TransfersThawed(true);
        return true;
    }


     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     

     
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply;
    }

     
    function balanceOf(
        address _holder
    )
        public
        view
        returns (uint256)
    {
        return balances[_holder];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

}