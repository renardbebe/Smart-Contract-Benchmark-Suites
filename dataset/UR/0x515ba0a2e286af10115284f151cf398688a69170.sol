 

 

pragma solidity ^0.5.2;

 
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

 

pragma solidity ^0.5.2;


 
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

 

pragma solidity 0.5.4;


interface IModerator {
    function verifyIssue(address _tokenHolder, uint256 _value, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransfer(address _from, address _to, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyTransferFrom(address _from, address _to, address _forwarder, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeem(address _sender, uint256 _amount, bytes calldata _data) external view 
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyRedeemFrom(address _sender, address _tokenHolder, uint256 _amount, bytes calldata _data) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);        

    function verifyControllerTransfer(address _controller, address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);

    function verifyControllerRedeem(address _controller, address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external view
        returns (bool allowed, byte statusCode, bytes32 applicationCode);
}

 

pragma solidity ^0.5.2;

 
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

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity 0.5.4;


interface IRewardsUpdatable {
    event NotifierUpdated(address implementation);

    function updateOnTransfer(address from, address to, uint amount) external returns (bool);
    function updateOnBurn(address account, uint amount) external returns (bool);
    function setRewardsNotifier(address notifier) external;
}

 

pragma solidity 0.5.4;



interface IRewardable {
    event RewardsUpdated(address implementation);

    function setRewards(IRewardsUpdatable rewards) external;
}

 

pragma solidity 0.5.4;







 
contract Rewardable is IRewardable, Ownable {
    using SafeMath for uint;

    IRewardsUpdatable public rewards;  

    event RewardsUpdated(address implementation);

     
    modifier updatesRewardsOnTransfer(address _from, address _to, uint _value) {
        _;
        require(rewards.updateOnTransfer(_from, _to, _value), "Rewards updateOnTransfer failed.");  
    }

     
    modifier updatesRewardsOnBurn(address _account, uint _value) {
        _;
        require(rewards.updateOnBurn(_account, _value), "Rewards updateOnBurn failed.");  
    }

     
    function setRewards(IRewardsUpdatable _rewards) external onlyOwner {
        require(address(_rewards) != address(0), "Rewards address must not be a zero address.");
        require(Address.isContract(address(_rewards)), "Address must point to a contract.");
        rewards = _rewards;
        emit RewardsUpdated(address(_rewards));
    }
}

 

pragma solidity ^0.5.2;



 
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
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

pragma solidity 0.5.4;




contract ERC20Redeemable is ERC20 {
    using SafeMath for uint256;

    uint256 public totalRedeemed;

     
    function _burn(address account, uint256 value) internal {
        totalRedeemed = totalRedeemed.add(value);  
        super._burn(account, value);
    }
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



 
contract IssuerRole {
    using Roles for Roles.Role;

    event IssuerAdded(address indexed account);
    event IssuerRemoved(address indexed account);

    Roles.Role internal _issuers;

    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "Only Issuers can execute this function.");
        _;
    }

    constructor() internal {
        _addIssuer(msg.sender);
    }

    function isIssuer(address account) public view returns (bool) {
        return _issuers.has(account);
    }

    function addIssuer(address account) public onlyIssuer {
        _addIssuer(account);
    }

    function renounceIssuer() public {
        _removeIssuer(msg.sender);
    }

    function _addIssuer(address account) internal {
        _issuers.add(account);
        emit IssuerAdded(account);
    }

    function _removeIssuer(address account) internal {
        _issuers.remove(account);
        emit IssuerRemoved(account);
    }
}

 

pragma solidity 0.5.4;



 
contract ControllerRole {
    using Roles for Roles.Role;

    event ControllerAdded(address indexed account);
    event ControllerRemoved(address indexed account);

    Roles.Role internal _controllers;

    modifier onlyController() {
        require(isController(msg.sender), "Only Controllers can execute this function.");
        _;
    }

    constructor() internal {
        _addController(msg.sender);
    }

    function isController(address account) public view returns (bool) {
        return _controllers.has(account);
    }

    function addController(address account) public onlyController {
        _addController(account);
    }

    function renounceController() public {
        _removeController(msg.sender);
    }

    function _addController(address account) internal {
        _controllers.add(account);
        emit ControllerAdded(account);
    }    

    function _removeController(address account) internal {
        _controllers.remove(account);
        emit ControllerRemoved(account);
    }
}

 

pragma solidity 0.5.4;





contract Moderated is ControllerRole {
    IModerator public moderator;  

    event ModeratorUpdated(address moderator);

    constructor(IModerator _moderator) public {
        moderator = _moderator;
    }

     
    function setModerator(IModerator _moderator) external onlyController {
        require(address(moderator) != address(0), "Moderator address must not be a zero address.");
        require(Address.isContract(address(_moderator)), "Address must point to a contract.");
        moderator = _moderator;
        emit ModeratorUpdated(address(_moderator));
    }
}

 

pragma solidity 0.5.4;








contract ERC1594 is IERC1594, IHasIssuership, Moderated, ERC20Redeemable, IssuerRole {
    bool public isIssuable = true;

    event Issued(address indexed operator, address indexed to, uint256 value, bytes data);
    event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data);
    event IssuershipTransferred(address indexed from, address indexed to);
    event IssuanceFinished();

     
    modifier whenIssuable() {
        require(isIssuable, "Issuance period has ended.");
        _;
    }

     
    function transferIssuership(address _newIssuer) public whenIssuable onlyIssuer {
        require(_newIssuer != address(0), "New Issuer cannot be zero address.");
        require(msg.sender != _newIssuer, "New Issuer cannot have the same address as the old issuer.");
        _addIssuer(_newIssuer);
        _removeIssuer(msg.sender);
        emit IssuershipTransferred(msg.sender, _newIssuer);
    }

     
    function finishIssuance() public whenIssuable onlyIssuer {
        isIssuable = false;
        emit IssuanceFinished();
    }

    function issue(address _tokenHolder, uint256 _value, bytes memory _data) public whenIssuable onlyIssuer {
        bool allowed;
        (allowed, , ) = moderator.verifyIssue(_tokenHolder, _value, _data);
        require(allowed, "Issue is not allowed.");
        _mint(_tokenHolder, _value);
        emit Issued(msg.sender, _tokenHolder, _value, _data);
    }

    function redeem(uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = moderator.verifyRedeem(msg.sender, _value, _data);
        require(allowed, "Redeem is not allowed.");

        _burn(msg.sender, _value);
        emit Redeemed(msg.sender, msg.sender, _value, _data);
    }

    function redeemFrom(address _tokenHolder, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = moderator.verifyRedeemFrom(msg.sender, _tokenHolder, _value, _data);
        require(allowed, "RedeemFrom is not allowed.");

        _burnFrom(_tokenHolder, _value);
        emit Redeemed(msg.sender, _tokenHolder, _value, _data);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        bool allowed;
        (allowed, , ) = canTransfer(_to, _value, "");
        require(allowed, "Transfer is not allowed.");

        success = super.transfer(_to, _value);
    }

    function transferWithData(address _to, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = canTransfer(_to, _value, _data);
        require(allowed, "Transfer is not allowed.");

        require(super.transfer(_to, _value), "Transfer failed.");
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        bool allowed;
        (allowed, , ) = canTransferFrom(_from, _to, _value, "");
        require(allowed, "TransferFrom is not allowed.");

        success = super.transferFrom(_from, _to, _value);
    }    

    function transferFromWithData(address _from, address _to, uint256 _value, bytes memory _data) public {
        bool allowed;
        (allowed, , ) = canTransferFrom(_from, _to, _value, _data);
        require(allowed, "TransferFrom is not allowed.");

        require(super.transferFrom(_from, _to, _value), "TransferFrom failed.");
    }

    function canTransfer(address _to, uint256 _value, bytes memory _data) public view 
        returns (bool success, byte statusCode, bytes32 applicationCode) 
    {
        return moderator.verifyTransfer(msg.sender, _to, _value, _data);
    }

    function canTransferFrom(address _from, address _to, uint256 _value, bytes memory _data) public view 
        returns (bool success, byte statusCode, bytes32 applicationCode) 
    {
        return moderator.verifyTransferFrom(_from, _to, msg.sender, _value, _data);
    }
}

 

pragma solidity 0.5.4;



 
 
interface IERC1644 {
     
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

     
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;
    function isControllable() external view returns (bool);
}

 

pragma solidity 0.5.4;







contract ERC1644 is IERC1644, Moderated, ERC20Redeemable {
    event ControllerTransfer(
        address controller,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );

    event ControllerRedemption(
        address controller,
        address indexed tokenHolder,
        uint256 value,
        bytes data,
        bytes operatorData
    );

    function controllerTransfer(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) public onlyController {
        bool allowed;
        (allowed, , ) = moderator.verifyControllerTransfer(
            msg.sender,
            _from,
            _to,
            _value,
            _data,
            _operatorData
        );
        require(allowed, "controllerTransfer is not allowed.");
        require(_value <= balanceOf(_from), "Insufficient balance.");
        _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    function controllerRedeem(
        address _tokenHolder,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) public onlyController {
        bool allowed;
        (allowed, , ) = moderator.verifyControllerRedeem(
            msg.sender,
            _tokenHolder,
            _value,
            _data,
            _operatorData
        );
        require(allowed, "controllerRedeem is not allowed.");
        require(_value <= balanceOf(_tokenHolder), "Insufficient balance.");
        _burn(_tokenHolder, _value);
        emit ControllerRedemption(msg.sender, _tokenHolder, _value, _data, _operatorData);
    }

    function isControllable() public view returns (bool) {
        return true;
    }
}

 

pragma solidity 0.5.4;





contract ERC1400 is ERC1594, ERC1644 {
    constructor(IModerator _moderator) public Moderated(_moderator) {}
}

 

pragma solidity 0.5.4;




 
contract ERC20Capped is ERC20 {
    using SafeMath for uint256;

    uint public cap;
    uint public totalMinted;

    constructor (uint _cap) public {
        require(_cap > 0, "Cap must be above zero.");
        cap = _cap;
        totalMinted = 0;
    }

     
    modifier capped(uint _newValue) {
        require(totalMinted.add(_newValue) <= cap, "Cannot mint beyond cap.");
        _;
    }

     
    function _mint(address _account, uint _value) internal capped(_value) {
        totalMinted = totalMinted.add(_value);
        super._mint(_account, _value);
    }
}

 

pragma solidity 0.5.4;







 
contract RewardableToken is ERC1400, ERC20Capped, Rewardable, Pausable {
    constructor(IModerator _moderator, uint _cap) public ERC1400(_moderator) ERC20Capped(_cap) {}

     
    function transfer(address _to, uint _value) 
        public 
        whenNotPaused
        updatesRewardsOnTransfer(msg.sender, _to, _value) returns (bool success) 
    {
        success = super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) 
        public 
        whenNotPaused
        updatesRewardsOnTransfer(_from, _to, _value) returns (bool success) 
    {
        success = super.transferFrom(_from, _to, _value);
    }

     
    function issue(address _tokenHolder, uint256 _value, bytes memory _data) 
        public 
        whenNotPaused
         
    {
        super.issue(_tokenHolder, _value, _data);
    }

    function redeem(uint256 _value, bytes memory _data) 
        public 
        whenNotPaused
        updatesRewardsOnBurn(msg.sender, _value)
    {
        super.redeem(_value, _data);
    }

    function redeemFrom(address _tokenHolder, uint256 _value, bytes memory _data) 
        public
        whenNotPaused
        updatesRewardsOnBurn(_tokenHolder, _value)
    {
        super.redeemFrom(_tokenHolder, _value, _data);
    }

     
    function controllerTransfer(address _from, address _to, uint256 _value, bytes memory _data, bytes memory _operatorData) 
        public
        updatesRewardsOnTransfer(_from, _to, _value) 
    {
        super.controllerTransfer(_from, _to, _value, _data, _operatorData);
    }

    function controllerRedeem(address _tokenHolder, uint256 _value, bytes memory _data, bytes memory _operatorData) 
        public
        updatesRewardsOnBurn(_tokenHolder, _value)
    {
        super.controllerRedeem(_tokenHolder, _value, _data, _operatorData);
    }
}

 

pragma solidity 0.5.4;





 
contract TENXToken is RewardableToken, ERC20Detailed("TenX Token", "TENX", 18) {
    constructor(IModerator _moderator, uint _cap) public RewardableToken(_moderator, _cap) {}
}