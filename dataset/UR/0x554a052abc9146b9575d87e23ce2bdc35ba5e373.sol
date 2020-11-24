 

 

pragma solidity ^0.5.2;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.2;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.2;


 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity 0.5.4;


interface IIssuer {
    event Issued(address indexed payee, uint amount);
    event Claimed(address indexed payee, uint amount);
    event FinishedIssuing(address indexed issuer);

    function issue(address payee, uint amount) external;
    function claim() external;
    function airdrop(address payee, uint amount) external;
    function isRunning() external view returns (bool);
}

 

pragma solidity 0.5.4;


 
 
interface IERC1594 {
     
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

     
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

     
    function redeem(uint256 _value, bytes calldata _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

     
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;
    function isIssuable() external view returns (bool);

     
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (bool, byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (bool, byte, bytes32);
}

 

pragma solidity 0.5.4;


interface IHasIssuership {
    event IssuershipTransferred(address indexed from, address indexed to);

    function transferIssuership(address newIssuer) external;
}

 

pragma solidity 0.5.4;



 
contract IssuerStaffRole {
    using Roles for Roles.Role;

    event IssuerStaffAdded(address indexed account);
    event IssuerStaffRemoved(address indexed account);

    Roles.Role internal _issuerStaffs;

    modifier onlyIssuerStaff() {
        require(isIssuerStaff(msg.sender), "Only IssuerStaffs can execute this function.");
        _;
    }

    constructor() internal {
        _addIssuerStaff(msg.sender);
    }

    function isIssuerStaff(address account) public view returns (bool) {
        return _issuerStaffs.has(account);
    }

    function addIssuerStaff(address account) public onlyIssuerStaff {
        _addIssuerStaff(account);
    }

    function renounceIssuerStaff() public {
        _removeIssuerStaff(msg.sender);
    }

    function _addIssuerStaff(address account) internal {
        _issuerStaffs.add(account);
        emit IssuerStaffAdded(account);
    }

    function _removeIssuerStaff(address account) internal {
        _issuerStaffs.remove(account);
        emit IssuerStaffRemoved(account);
    }
}

 

pragma solidity 0.5.4;









 
contract Issuer is IIssuer, IHasIssuership, IssuerStaffRole, Ownable, Pausable, ReentrancyGuard {
    struct Claim {
        address issuer;
        ClaimState status;
        uint amount;
    }

    enum ClaimState { NONE, ISSUED, CLAIMED }
    mapping(address => Claim) public claims;

    bool public isRunning = true;
    IERC1594 public token;  

    event Issued(address indexed payee, address indexed issuer, uint amount);
    event Claimed(address indexed payee, uint amount);

     
    modifier whenRunning() {
        require(isRunning, "Issuer contract has stopped running.");
        _;
    }    

     
    modifier atState(address _payee, ClaimState _state) {
        Claim storage c = claims[_payee];
        require(c.status == _state, "Invalid claim source state.");
        _;
    }

     
    modifier notAtState(address _payee, ClaimState _state) {
        Claim storage c = claims[_payee];
        require(c.status != _state, "Invalid claim source state.");
        _;
    }

    constructor(IERC1594 _token) public {
        token = _token;
    }

     
    function transferIssuership(address _newIssuer) 
        external onlyOwner whenRunning 
    {
        require(_newIssuer != address(0), "New Issuer cannot be zero address.");
        isRunning = false;
        IHasIssuership t = IHasIssuership(address(token));
        t.transferIssuership(_newIssuer);
    }

     
    function issue(address _payee, uint _amount) 
        external onlyIssuerStaff whenRunning whenNotPaused notAtState(_payee, ClaimState.CLAIMED) 
    {
        require(_payee != address(0), "Payee must not be a zero address.");
        require(_payee != msg.sender, "Issuers cannot issue for themselves");
        require(_amount > 0, "Claim amount must be positive.");
        claims[_payee] = Claim({
            status: ClaimState.ISSUED,
            amount: _amount,
            issuer: msg.sender
        });
        emit Issued(_payee, msg.sender, _amount);
    }

     
    function claim() 
        external whenRunning whenNotPaused atState(msg.sender, ClaimState.ISSUED) 
    {
        address payee = msg.sender;
        Claim storage c = claims[payee];
        c.status = ClaimState.CLAIMED;  
        emit Claimed(payee, c.amount);

        token.issue(payee, c.amount, "");  
    }

     
    function airdrop(address _payee, uint _amount) 
        external onlyIssuerStaff whenRunning whenNotPaused atState(_payee, ClaimState.NONE) nonReentrant 
    {
        require(_payee != address(0), "Payee must not be a zero address.");
        require(_payee != msg.sender, "Issuers cannot airdrop for themselves");
        require(_amount > 0, "Claim amount must be positive.");
        claims[_payee] = Claim({
            status: ClaimState.CLAIMED,
            amount: _amount,
            issuer: msg.sender
        });
        emit Claimed(_payee, _amount);

        token.issue(_payee, _amount, "");  
    }
}