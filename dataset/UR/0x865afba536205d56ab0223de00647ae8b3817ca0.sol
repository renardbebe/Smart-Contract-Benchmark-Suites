 

pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
    constructor() public {
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

    function getOwner() public view returns (address) {
        return owner;
    }

    function getOwnerStatic(address ownableContract) internal view returns (address) {
        bytes memory callcodeOwner = abi.encodeWithSignature("getOwner()");
        (bool success, bytes memory returnData) = address(ownableContract).staticcall(callcodeOwner);
        require(success, "input address has to be a valid ownable contract");
        return parseAddr(returnData);
    }

    function getTokenVestingStatic(address tokenFactoryContract) internal view returns (address) {
        bytes memory callcodeTokenVesting = abi.encodeWithSignature("getTokenVesting()");
        (bool success, bytes memory returnData) = address(tokenFactoryContract).staticcall(callcodeTokenVesting);
        require(success, "input address has to be a valid TokenFactory contract");
        return parseAddr(returnData);
    }


    function parseAddr(bytes memory data) public pure returns (address parsed){
        assembly {parsed := mload(add(data, 32))}
    }




}

 
contract Registry is Ownable {

    struct Creator {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address proposer;
        address vestingBeneficiary;
        uint8 initialPercentage;
        uint256 vestingPeriodInWeeks;
        bool approved;
    }

    mapping(bytes32 => Creator) public rolodex;
    mapping(string => bytes32)  nameToIndex;
    mapping(string => bytes32)  symbolToIndex;

    event LogProposalSubmit(string name, string symbol, address proposer, bytes32 indexed hashIndex);
    event LogProposalApprove(string name, address indexed tokenAddress);

     
    function submitProposal(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint8 _initialPercentage,
        uint256 _vestingPeriodInWeeks,
        address _vestingBeneficiary,
        address _proposer
    )
    public
    onlyOwner
    returns (bytes32 hashIndex)
    {
        nameDoesNotExist(_name);
        symbolDoesNotExist(_symbol);
        hashIndex = keccak256(abi.encodePacked(_name, _symbol, _proposer));
        rolodex[hashIndex] = Creator({
            token : address(0),
            name : _name,
            symbol : _symbol,
            decimals : _decimals,
            totalSupply : _totalSupply,
            proposer : _proposer,
            vestingBeneficiary : _vestingBeneficiary,
            initialPercentage : _initialPercentage,
            vestingPeriodInWeeks : _vestingPeriodInWeeks,
            approved : false
        });
        emit LogProposalSubmit(_name, _symbol, msg.sender, hashIndex);
    }

     
    function approveProposal(
        bytes32 _hashIndex,
        address _token
    )
    external
    onlyOwner
    returns (bool)
    {
        Creator memory c = rolodex[_hashIndex];
        nameDoesNotExist(c.name);
        symbolDoesNotExist(c.symbol);
        rolodex[_hashIndex].token = _token;
        rolodex[_hashIndex].approved = true;
        nameToIndex[c.name] = _hashIndex;
        symbolToIndex[c.symbol] = _hashIndex;
        emit LogProposalApprove(c.name, _token);
        return true;
    }

     

    function getIndexByName(
        string memory _name
        )
    public
    view
    returns (bytes32)
    {
        return nameToIndex[_name];
    }

    function getIndexSymbol(
        string memory _symbol
        )
    public
    view
    returns (bytes32)
    {
        return symbolToIndex[_symbol];
    }

    function getCreatorByIndex(
        bytes32 _hashIndex
    )
    external
    view
    returns (Creator memory)
    {
        return rolodex[_hashIndex];
    }



     

    function nameDoesNotExist(string memory _name) internal view {
        require(nameToIndex[_name] == 0x0, "Name already exists");
    }

    function symbolDoesNotExist(string memory _name) internal view {
        require(symbolToIndex[_name] == 0x0, "Symbol already exists");
    }
}

 
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
     
     
     
        return a / b;
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

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

     
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }


     
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender]);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        require(amount <= _balances[account]);

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender]);

         
         
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        amount);
        _burn(account, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

 



contract SocialMoney is ERC20 {

     
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256[3] memory _proportions,
        address _vestingBeneficiary,
        address _platformWallet,
        address _tokenVestingInstance
    )
    public
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        uint256 totalProportions = _proportions[0].add(_proportions[1]).add(_proportions[2]);

        _mint(_vestingBeneficiary, _proportions[0]);
        _mint(_platformWallet, _proportions[1]);
        _mint(_tokenVestingInstance, _proportions[2]);

         
        assert(totalProportions == totalSupply());
    }
}

 
contract TokenVesting is Ownable{

    using SafeMath for uint256;

    event Released(address indexed token, address vestingBeneficiary, uint256 amount);
    event LogTokenAdded(address indexed token, address vestingBeneficiary, uint256 vestingPeriodInWeeks);

    uint256 constant public WEEKS_IN_SECONDS = 1 * 7 * 24 * 60 * 60;

    struct VestingInfo {
        address vestingBeneficiary;
        uint256 releasedSupply;
        uint256 start;
        uint256 duration;
    }

    mapping(address => VestingInfo) public vestingInfo;

     
    function addToken
    (
        address _token,
        address _vestingBeneficiary,
        uint256 _vestingPeriodInWeeks
    )
    external
    onlyOwner
    {
        vestingInfo[_token] = VestingInfo({
            vestingBeneficiary : _vestingBeneficiary,
            releasedSupply : 0,
            start : now,
            duration : uint256(_vestingPeriodInWeeks).mul(WEEKS_IN_SECONDS)
        });
        emit LogTokenAdded(_token, _vestingBeneficiary, _vestingPeriodInWeeks);
    }

     

    function release
    (
        address _token
    )
    external
    {
        uint256 unreleased = releaseableAmount(_token);
        require(unreleased > 0);
        vestingInfo[_token].releasedSupply = vestingInfo[_token].releasedSupply.add(unreleased);
        bool success = ERC20(_token).transfer(vestingInfo[_token].vestingBeneficiary, unreleased);
        require(success, "transfer from vesting to beneficiary has to succeed");
        emit Released(_token, vestingInfo[_token].vestingBeneficiary, unreleased);
    }

     
    function releaseableAmount
    (
        address _token
    )
    public
    view
    returns(uint256)
    {
        return vestedAmount(_token).sub(vestingInfo[_token].releasedSupply);
    }

     

    function vestedAmount
    (
        address _token
    )
    public
    view
    returns(uint256)
    {
        VestingInfo memory info = vestingInfo[_token];
        uint256 currentBalance = ERC20(_token).balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(info.releasedSupply);
        if (now >= info.start.add(info.duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(info.start)).div(info.duration);
        }

    }


    function getVestingInfo
    (
        address _token
    )
    external
    view
    returns(VestingInfo memory)
    {
        return vestingInfo[_token];
    }


}

 
contract TokenFactory is Ownable{

    using SafeMath for uint256;

    uint8 public PLATFORM_PERCENTAGE;
    address public PLATFORM_WALLET;
    TokenVesting public TokenVestingInstance;

    event LogTokenCreated(string name, string symbol, address indexed token, address vestingBeneficiary);
    event LogPlatformPercentageChanged(uint8 oldP, uint8 newP);
    event LogPlatformWalletChanged(address oldPW, address newPW);
    event LogTokenVestingChanged(address oldTV, address newTV);
    event LogTokenFactoryMigrated(address newTokenFactory);

     
    constructor(
        address _tokenVesting,
        address _turingWallet,
        uint8 _platformPercentage
    )
    validatePercentage(_platformPercentage)
    validateAddress(_turingWallet)
    public
    {

        require(_turingWallet != address(0), "Turing Wallet address must be non zero");
        PLATFORM_WALLET = _turingWallet;
        PLATFORM_PERCENTAGE = _platformPercentage;
        if (_tokenVesting == address(0)){
            TokenVestingInstance = new TokenVesting();
        }
        else{
            TokenVestingInstance = TokenVesting(_tokenVesting);
        }

    }


     
    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint8 _initialPercentage,
        uint256 _vestingPeriodInWeeks,
        address _vestingBeneficiary

    )
    public
    onlyOwner
    returns (address token)
    {
        uint256[3] memory proportions = calculateProportions(_totalSupply, _initialPercentage);
        require(proportions[0].add(proportions[1]).add(proportions[2]) == _totalSupply,
        "The supply must be same as the proportion, sanity check.");
        SocialMoney sm = new SocialMoney(
            _name,
            _symbol,
            _decimals,
            proportions,
            _vestingBeneficiary,
            PLATFORM_WALLET,
            address(TokenVestingInstance)
        );
        TokenVestingInstance.addToken(address(sm), _vestingBeneficiary, _vestingPeriodInWeeks);
        token = address(sm);
        emit LogTokenCreated(_name, _symbol, token, _vestingBeneficiary);
    }

     
    function calculateProportions(
        uint256 _totalSupply,
        uint8 _initialPercentage
    )
    private
    view
    validateTotalPercentage(_initialPercentage)
    returns (uint256[3] memory proportions)
    {
        proportions[0] = (_totalSupply).mul(_initialPercentage).div(100);  
        proportions[1] = (_totalSupply).mul(PLATFORM_PERCENTAGE).div(100);  
        proportions[2] = (_totalSupply).sub(proportions[0]).sub(proportions[1]);  
    }



    function setPlatformPercentage(
        uint8 _newPercentage
    )
    external
    validatePercentage(_newPercentage)
    onlyOwner
    {
        emit LogPlatformPercentageChanged(PLATFORM_PERCENTAGE, _newPercentage);
        PLATFORM_PERCENTAGE = _newPercentage;
    }

    function setPlatformWallet(
        address _newPlatformWallet
    )
    external
    validateAddress(_newPlatformWallet)
    onlyOwner
    {
        emit LogPlatformWalletChanged(PLATFORM_WALLET, _newPlatformWallet);
        PLATFORM_WALLET = _newPlatformWallet;
    }

    function migrateTokenFactory(
        address _newTokenFactory
    )
    external
    onlyOwner
    {
        TokenVestingInstance.transferOwnership(_newTokenFactory);
        emit LogTokenFactoryMigrated(_newTokenFactory);
    }

    function setTokenVesting(
        address _newTokenVesting
    )
    external
    onlyOwner
    {
        require(getOwnerStatic(_newTokenVesting) == address(this), "new TokenVesting not owned by TokenFactory");
        emit LogTokenVestingChanged(address(TokenVestingInstance), address(_newTokenVesting));
        TokenVestingInstance = TokenVesting(_newTokenVesting);
    }



    modifier validatePercentage(uint8 percentage){
        require(percentage > 0 && percentage < 100);
        _;
    }

    modifier validateAddress(address addr){
        require(addr != address(0));
        _;
    }

    modifier validateTotalPercentage(uint8 _x) {
        require(PLATFORM_PERCENTAGE + _x < 100);
        _;
    }

    function getTokenVesting() external view returns (address) {
        return address(TokenVestingInstance);
    }
}


 


 
contract Manager is Ownable {

    using SafeMath for uint256;

    Registry public RegistryInstance;
    TokenFactory public TokenFactoryInstance;

    event LogTokenFactoryChanged(address oldTF, address newTF);
    event LogRegistryChanged(address oldR, address newR);
    event LogManagerMigrated(address indexed newManager);

     
    constructor(
        address _registry,
        address _tokenFactory
    )
    public
    {
        require(_registry != address(0) && _tokenFactory != address(0));
        TokenFactoryInstance = TokenFactory(_tokenFactory);
        RegistryInstance = Registry(_registry);
    }

     

    function submitProposal(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint8 _initialPercentage,
        uint256 _vestingPeriodInWeeks,
        address _vestingBeneficiary
    )
    validatePercentage(_initialPercentage)
    validateDecimals(_decimals)
    validateVestingPeriod(_vestingPeriodInWeeks)
    isInitialized()
    public
    returns (bytes32 hashIndex)
    {
        hashIndex = RegistryInstance.submitProposal(_name,_symbol,_decimals,_totalSupply,
        _initialPercentage, _vestingPeriodInWeeks, _vestingBeneficiary, msg.sender);
    }

     
    function approveProposal(
        bytes32 _hashIndex
    )
    isInitialized()
    onlyOwner
    external
    {
         
        Registry.Creator memory approvedProposal = RegistryInstance.getCreatorByIndex(_hashIndex);
        address ac = TokenFactoryInstance.createToken(
            approvedProposal.name,
            approvedProposal.symbol,
            approvedProposal.decimals,
            approvedProposal.totalSupply,
            approvedProposal.initialPercentage,
            approvedProposal.vestingPeriodInWeeks,
            approvedProposal.vestingBeneficiary
            );
        bool success = RegistryInstance.approveProposal(_hashIndex, ac);
        require(success, "Registry approve proposal has to succeed");
    }


     


    function setPlatformWallet(
        address _newPlatformWallet
    )
    onlyOwner
    isInitialized()
    external
    {
        TokenFactoryInstance.setPlatformWallet(_newPlatformWallet);
    }

    function setTokenFactoryPercentage(
        uint8 _newPercentage
    )
    onlyOwner
    validatePercentage(_newPercentage)
    isInitialized()
    external
    {
        TokenFactoryInstance.setPlatformPercentage(_newPercentage);
    }

    function setTokenFactory(
        address _newTokenFactory
    )
    onlyOwner
    external
    {

        require(getOwnerStatic(_newTokenFactory) == address(this), "new TokenFactory has to be owned by Manager");
        require(getTokenVestingStatic(_newTokenFactory) == address(TokenFactoryInstance.TokenVestingInstance()), "TokenVesting has to be the same");
        TokenFactoryInstance.migrateTokenFactory(_newTokenFactory);
        require(getOwnerStatic(getTokenVestingStatic(_newTokenFactory))== address(_newTokenFactory), "TokenFactory does not own TokenVesting");
        emit LogTokenFactoryChanged(address(TokenFactoryInstance), address(_newTokenFactory));
        TokenFactoryInstance = TokenFactory(_newTokenFactory);
    }

    function setRegistry(
        address _newRegistry
    )

    onlyOwner
    external
    {
        require(getOwnerStatic(_newRegistry) == address(this), "new Registry has to be owned by Manager");
        emit LogRegistryChanged(address(RegistryInstance), _newRegistry);
        RegistryInstance = Registry(_newRegistry);
    }

    function setTokenVesting(
        address _newTokenVesting
    )
    onlyOwner
    external
    {
        TokenFactoryInstance.setTokenVesting(_newTokenVesting);
    }

    function migrateManager(
        address _newManager
    )
    onlyOwner
    isInitialized()
    external
    {
        RegistryInstance.transferOwnership(_newManager);
        TokenFactoryInstance.transferOwnership(_newManager);
        emit LogManagerMigrated(_newManager);
    }

    modifier validatePercentage(uint8 percentage) {
        require(percentage > 0 && percentage < 100, "has to be above 0 and below 100");
        _;
    }

    modifier validateDecimals(uint8 decimals) {
        require(decimals > 0 && decimals < 18, "has to be above 0 and below 18");
        _;
    }

    modifier validateVestingPeriod(uint256 vestingPeriod) {
        require(vestingPeriod > 1, "has to be above 1");
        _;
    }

    modifier isInitialized() {
        require(initialized(), "manager not initialized");
        _;
    }

    function initialized() public view returns (bool){
        return (RegistryInstance.owner() == address(this)) &&
            (TokenFactoryInstance.owner() == address(this)) &&
            (TokenFactoryInstance.TokenVestingInstance().owner() == address(TokenFactoryInstance));
    }



}