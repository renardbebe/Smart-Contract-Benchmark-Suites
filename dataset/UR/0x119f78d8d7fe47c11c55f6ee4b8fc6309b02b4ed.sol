 

pragma solidity ^0.5.1;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

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

library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "");  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "");
        return a % b;
    }
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
        require(value <= _balances[msg.sender], "");
        require(to != address(0), "");

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "");

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
        require(value <= _balances[from], "");
        require(value <= _allowed[from][msg.sender], "");
        require(to != address(0), "");

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
        require(spender != address(0), "");

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
        require(spender != address(0), "");

        _allowed[msg.sender][spender] = (
            _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "");
        require(amount <= _balances[account], "");

        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        require(amount <= _allowed[account][msg.sender], "");

         
         
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            amount);
        _burn(account, amount);
    }
}

 
contract BaseSecurityToken is ERC20 {
    
    struct Document {
        string name;
        string uri;
        bytes32 contentHash;
    }

    mapping (string => Document) private documents;

    function transfer(address to, uint256 value) public returns (bool) {
        require(checkTransferAllowed(msg.sender, to, value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(checkTransferFromAllowed(from, to, value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transferFrom(from, to, value);
    }

    function _mint(address account, uint256 amount) internal {
        require(checkMintAllowed(account, amount) == STATUS_ALLOWED, "mint must be allowed");
        ERC20._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(checkBurnAllowed(account, amount) == STATUS_ALLOWED, "burn must be allowed");
        ERC20._burn(account, amount);
    }

    function attachDocument(string calldata _name, string calldata _uri, bytes32 _contentHash) external {
        require(bytes(_name).length > 0, "name of the document must not be empty");
        require(bytes(_uri).length > 0, "external URI to the document must not be empty");
        documents[_name] = Document(_name, _uri, _contentHash);
    }
   
    function lookupDocument(string calldata _name) external view returns (string memory, bytes32) {
        Document storage doc = documents[_name];
        return (doc.uri, doc.contentHash);
    }

     
     
    byte private STATUS_ALLOWED = 0x11;

    function checkTransferAllowed(address, address, uint256) public view returns (byte) {
        return STATUS_ALLOWED;
    }
   
    function checkTransferFromAllowed(address, address, uint256) public view returns (byte) {
        return STATUS_ALLOWED;
    }
   
    function checkMintAllowed(address, uint256) public view returns (byte) {
        return STATUS_ALLOWED;
    }
   
    function checkBurnAllowed(address, uint256) public view returns (byte) {
        return STATUS_ALLOWED;
    }
}

contract LockRequestable {

         
         
        uint256 public lockRequestCount;

        constructor() public {
                lockRequestCount = 0;
        }

         
         
        function generateLockId() internal returns (bytes32 lockId) {
                return keccak256(
                abi.encodePacked(blockhash(block.number - 1), address(this), ++lockRequestCount)
                );
        }
}

contract CustodianUpgradeable is LockRequestable {

         
         
        struct CustodianChangeRequest {
                address proposedNew;
        }

         
         
        address public custodian;

         
        mapping (bytes32 => CustodianChangeRequest) public custodianChangeReqs;

        constructor(address _custodian) public LockRequestable() {
                custodian = _custodian;
        }

         
        modifier onlyCustodian {
                require(msg.sender == custodian);
                _;
        }

         
        function requestCustodianChange(address _proposedCustodian) public returns (bytes32 lockId) {
                require(_proposedCustodian != address(0));

                lockId = generateLockId();

                custodianChangeReqs[lockId] = CustodianChangeRequest({
                        proposedNew: _proposedCustodian
                });

                emit CustodianChangeRequested(lockId, msg.sender, _proposedCustodian);
        }

         
        function confirmCustodianChange(bytes32 _lockId) public onlyCustodian {
                custodian = getCustodianChangeReq(_lockId);

                delete custodianChangeReqs[_lockId];

                emit CustodianChangeConfirmed(_lockId, custodian);
        }

         
        function getCustodianChangeReq(bytes32 _lockId) private view returns (address _proposedNew) {
                CustodianChangeRequest storage changeRequest = custodianChangeReqs[_lockId];

                 
                 
                require(changeRequest.proposedNew != address(0));

                return changeRequest.proposedNew;
        }

         
        event CustodianChangeRequested(
                bytes32 _lockId,
                address _msgSender,
                address _proposedCustodian
        );

         
        event CustodianChangeConfirmed(bytes32 _lockId, address _newCustodian);
}

interface ServiceRegistry {
    function getService(string calldata _name) external view returns (address);
}

contract ServiceDiscovery {
    ServiceRegistry internal services;

    constructor(ServiceRegistry _services) public {
        services = ServiceRegistry(_services);
    }
}

contract KnowYourCustomer is CustodianUpgradeable {

    enum Status {
        none,
        passed,
        suspended
    }

    struct Customer {
        Status status;
        mapping(string => string) fields;
    }
    
    event ProviderAuthorized(address indexed _provider, string _name);
    event ProviderRemoved(address indexed _provider, string _name);
    event CustomerApproved(address indexed _customer, address indexed _provider);
    event CustomerSuspended(address indexed _customer, address indexed _provider);
    event CustomerFieldSet(address indexed _customer, address indexed _field, string _name);

    mapping(address => bool) private providers;
    mapping(address => Customer) private customers;

    constructor(address _custodian) public CustodianUpgradeable(_custodian) {
        customers[_custodian].status = Status.passed;
        customers[_custodian].fields["type"] = "custodian";
        emit CustomerApproved(_custodian, msg.sender);
        emit CustomerFieldSet(_custodian, msg.sender, "type");
    }

    function providerAuthorize(address _provider, string calldata name) external onlyCustodian {
        require(providers[_provider] == false, "provider must not exist");
        providers[_provider] = true;
         
        emit ProviderAuthorized(_provider, name);
    }

    function providerRemove(address _provider, string calldata name) external onlyCustodian {
        require(providers[_provider] == true, "provider must exist");
        delete providers[_provider];
        emit ProviderRemoved(_provider, name);
    }

    function hasWritePermissions(address _provider) external view returns (bool) {
        return _provider == custodian || providers[_provider] == true;
    }

    function getCustomerStatus(address _customer) external view returns (Status) {
        return customers[_customer].status;
    }

    function getCustomerField(address _customer, string calldata _field) external view returns (string memory) {
        return customers[_customer].fields[_field];
    }

    function approveCustomer(address _customer) external onlyAuthorized {
        Status status = customers[_customer].status;
        require(status != Status.passed, "customer must not be approved before");
        customers[_customer].status = Status.passed;
         
        emit CustomerApproved(_customer, msg.sender);
    }

    function setCustomerField(address _customer, string calldata _field, string calldata _value) external onlyAuthorized {
        Status status = customers[_customer].status;
        require(status != Status.none, "customer must have a set status");
        customers[_customer].fields[_field] = _value;
        emit CustomerFieldSet(_customer, msg.sender, _field);
    }

    function suspendCustomer(address _customer) external onlyAuthorized {
        Status status = customers[_customer].status;
        require(status != Status.suspended, "customer must be not suspended");
        customers[_customer].status = Status.suspended;
        emit CustomerSuspended(_customer, msg.sender);
    }

    modifier onlyAuthorized() {
        require(msg.sender == custodian || providers[msg.sender] == true);
        _;
    }
}

contract TokenSettingsInterface {

     
    function getTradeAllowed() public view returns (bool);
    function getMintAllowed() public view returns (bool);
    function getBurnAllowed() public view returns (bool);
    
     
    event TradeAllowedLocked(bytes32 _lockId, bool _newValue);
    event TradeAllowedConfirmed(bytes32 _lockId, bool _newValue);
    event MintAllowedLocked(bytes32 _lockId, bool _newValue);
    event MintAllowedConfirmed(bytes32 _lockId, bool _newValue);
    event BurnAllowedLocked(bytes32 _lockId, bool _newValue);
    event BurnAllowedConfirmed(bytes32 _lockId, bool _newValue);

     
    modifier onlyCustodian {
        _;
    }
}


contract _BurnAllowed is TokenSettingsInterface, LockRequestable {
     
     
     
     
     
     
     
    bool private burnAllowed = false;

    function getBurnAllowed() public view returns (bool) {
        return burnAllowed;
    }

     

    struct PendingBurnAllowed {
        bool burnAllowed;
        bool set;
    }

    mapping (bytes32 => PendingBurnAllowed) public pendingBurnAllowedMap;

    function requestBurnAllowedChange(bool _burnAllowed) public returns (bytes32 lockId) {
       require(_burnAllowed != burnAllowed);
       
       lockId = generateLockId();
       pendingBurnAllowedMap[lockId] = PendingBurnAllowed({
           burnAllowed: _burnAllowed,
           set: true
       });

       emit BurnAllowedLocked(lockId, _burnAllowed);
    }

    function confirmBurnAllowedChange(bytes32 _lockId) public onlyCustodian {
        PendingBurnAllowed storage value = pendingBurnAllowedMap[_lockId];
        require(value.set == true);
        burnAllowed = value.burnAllowed;
        emit BurnAllowedConfirmed(_lockId, value.burnAllowed);
        delete pendingBurnAllowedMap[_lockId];
    }
}


contract _MintAllowed is TokenSettingsInterface, LockRequestable {
     
     
     
     
     
     
     
    bool private mintAllowed = false;

    function getMintAllowed() public view returns (bool) {
        return mintAllowed;
    }

     

    struct PendingMintAllowed {
        bool mintAllowed;
        bool set;
    }

    mapping (bytes32 => PendingMintAllowed) public pendingMintAllowedMap;

    function requestMintAllowedChange(bool _mintAllowed) public returns (bytes32 lockId) {
       require(_mintAllowed != mintAllowed);
       
       lockId = generateLockId();
       pendingMintAllowedMap[lockId] = PendingMintAllowed({
           mintAllowed: _mintAllowed,
           set: true
       });

       emit MintAllowedLocked(lockId, _mintAllowed);
    }

    function confirmMintAllowedChange(bytes32 _lockId) public onlyCustodian {
        PendingMintAllowed storage value = pendingMintAllowedMap[_lockId];
        require(value.set == true);
        mintAllowed = value.mintAllowed;
        emit MintAllowedConfirmed(_lockId, value.mintAllowed);
        delete pendingMintAllowedMap[_lockId];
    }
}


contract _TradeAllowed is TokenSettingsInterface, LockRequestable {
     
     
     
     
     
     
     
    bool private tradeAllowed = false;

    function getTradeAllowed() public view returns (bool) {
        return tradeAllowed;
    }

     

    struct PendingTradeAllowed {
        bool tradeAllowed;
        bool set;
    }

    mapping (bytes32 => PendingTradeAllowed) public pendingTradeAllowedMap;

    function requestTradeAllowedChange(bool _tradeAllowed) public returns (bytes32 lockId) {
       require(_tradeAllowed != tradeAllowed);
       
       lockId = generateLockId();
       pendingTradeAllowedMap[lockId] = PendingTradeAllowed({
           tradeAllowed: _tradeAllowed,
           set: true
       });

       emit TradeAllowedLocked(lockId, _tradeAllowed);
    }

    function confirmTradeAllowedChange(bytes32 _lockId) public onlyCustodian {
        PendingTradeAllowed storage value = pendingTradeAllowedMap[_lockId];
        require(value.set == true);
        tradeAllowed = value.tradeAllowed;
        emit TradeAllowedConfirmed(_lockId, value.tradeAllowed);
        delete pendingTradeAllowedMap[_lockId];
    }
}

contract TokenSettings is TokenSettingsInterface, CustodianUpgradeable,
_TradeAllowed,
_MintAllowed,
_BurnAllowed
    {
    constructor(address _custodian) public CustodianUpgradeable(_custodian) {
    }
}


 
contract TokenController is CustodianUpgradeable, ServiceDiscovery {
    constructor(address _custodian, ServiceRegistry _services) public
    CustodianUpgradeable(_custodian) ServiceDiscovery(_services) {
    }

     
     
    byte private constant STATUS_ALLOWED = 0x11;

    function checkTransferAllowed(address _from, address _to, uint256) public view returns (byte) {
        require(_settings().getTradeAllowed(), "global trade must be allowed");
        require(_kyc().getCustomerStatus(_from) == KnowYourCustomer.Status.passed, "sender does not have valid KYC status");
        require(_kyc().getCustomerStatus(_to) == KnowYourCustomer.Status.passed, "recipient does not have valid KYC status");

         
         
         

        return STATUS_ALLOWED;
    }
   
    function checkTransferFromAllowed(address _from, address _to, uint256 _amount) external view returns (byte) {
        return checkTransferAllowed(_from, _to, _amount);
    }
   
    function checkMintAllowed(address _from, uint256) external view returns (byte) {
        require(_settings().getMintAllowed(), "global mint must be allowed");
        require(_kyc().getCustomerStatus(_from) == KnowYourCustomer.Status.passed, "recipient does not have valid KYC status");
        
        return STATUS_ALLOWED;
    }
   
    function checkBurnAllowed(address _from, uint256) external view returns (byte) {
        require(_settings().getBurnAllowed(), "global burn must be allowed");
        require(_kyc().getCustomerStatus(_from) == KnowYourCustomer.Status.passed, "sender does not have valid KYC status");

        return STATUS_ALLOWED;
    }

    function _settings() private view returns (TokenSettings) {
        return TokenSettings(services.getService("token/settings"));
    }

    function _kyc() private view returns (KnowYourCustomer) {
        return KnowYourCustomer(services.getService("validators/kyc"));
    }
}

contract BaRA is BaseSecurityToken, CustodianUpgradeable, ServiceDiscovery {
    
    uint public limit = 400 * 1e6;
    string public name = "Banksia BioPharm Security Token";
    string public symbol = "BaRA";
    uint8 public decimals = 0;

    constructor(address _custodian, ServiceRegistry _services,
        string memory _name, string memory _symbol, uint _limit) public 
        CustodianUpgradeable(_custodian) ServiceDiscovery(_services) {

        name = _name;
        symbol = _symbol;
        limit = _limit;
    }

    function mint(address _to, uint _amount) public onlyCustodian {
        require(_amount != 0, "check amount to mint");
        require(super.totalSupply() + _amount <= limit, "check total supply after mint");
        BaseSecurityToken._mint(_to, _amount);
    }
    
    function burn(uint _amount) public {
        require(_amount != 0, "check amount to burn");
        BaseSecurityToken._burn(msg.sender, _amount);
    }

    function checkTransferAllowed (address _from, address _to, uint256 _amount) public view returns (byte) {
        return _controller().checkTransferAllowed(_from, _to, _amount);
    }
   
    function checkTransferFromAllowed (address _from, address _to, uint256 _amount) public view returns (byte) {
        return _controller().checkTransferFromAllowed(_from, _to, _amount);
    }
   
    function checkMintAllowed (address _from, uint256 _amount) public view returns (byte) {
        return _controller().checkMintAllowed(_from, _amount);
    }
   
    function checkBurnAllowed (address _from, uint256 _amount) public view returns (byte) {
        return _controller().checkBurnAllowed(_from, _amount);
    }

    function _controller() private view returns (TokenController) {
        return TokenController(services.getService("token/controller"));
    }
}