 

 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;



 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.24;




 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

pragma solidity ^0.4.24;





 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 

pragma solidity ^0.4.24;



 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 

pragma solidity ^0.4.24;



 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

 

pragma solidity ^0.4.24;



 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 

pragma solidity ^0.4.24;





 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

 

pragma solidity ^0.4.24;



 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

 

pragma solidity 0.4.24;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 

pragma solidity 0.4.24;


 
library TokenStorageLib {

    using SafeMath for uint;

    struct TokenStorage {
        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
        uint totalSupply;
    }

     
    function addBalance(TokenStorage storage self, address to, uint amount)
        external
    {
        self.totalSupply = self.totalSupply.add(amount);
        self.balances[to] = self.balances[to].add(amount);
    }

     
    function subBalance(TokenStorage storage self, address from, uint amount)
        external
    {
        self.totalSupply = self.totalSupply.sub(amount);
        self.balances[from] = self.balances[from].sub(amount);
    }

     
    function setAllowed(TokenStorage storage self, address owner, address spender, uint amount)
        external
    {
        self.allowed[owner][spender] = amount;
    }

     
    function getSupply(TokenStorage storage self)
        external
        view
        returns (uint)
    {
        return self.totalSupply;
    }

     
    function getBalance(TokenStorage storage self, address who)
        external
        view
        returns (uint)
    {
        return self.balances[who];
    }

     
    function getAllowed(TokenStorage storage self, address owner, address spender)
        external
        view
        returns (uint)
    {
        return self.allowed[owner][spender];
    }

}

 

 

pragma solidity 0.4.24;





 
contract TokenStorage is Claimable, CanReclaimToken, NoOwner {

    using TokenStorageLib for TokenStorageLib.TokenStorage;

    TokenStorageLib.TokenStorage internal tokenStorage;

     
    function addBalance(address to, uint amount) external onlyOwner {
        tokenStorage.addBalance(to, amount);
    }

     
    function subBalance(address from, uint amount) external onlyOwner {
        tokenStorage.subBalance(from, amount);
    }

     
    function setAllowed(address owner, address spender, uint amount) external onlyOwner {
        tokenStorage.setAllowed(owner, spender, amount);
    }

     
    function getSupply() external view returns (uint) {
        return tokenStorage.getSupply();
    }

     
    function getBalance(address who) external view returns (uint) {
        return tokenStorage.getBalance(who);
    }

     
    function getAllowed(address owner, address spender)
        external
        view
        returns (uint)
    {
        return tokenStorage.getAllowed(owner, spender);
    }

}

 

 

pragma solidity 0.4.24;



 
library ERC20Lib {

    using SafeMath for uint;

     
    function transfer(TokenStorage db, address caller, address to, uint amount)
        external
        returns (bool success)
    {
        db.subBalance(caller, amount);
        db.addBalance(to, amount);
        return true;
    }

     
    function transferFrom(
        TokenStorage db,
        address caller,
        address from,
        address to,
        uint amount
    )
        external
        returns (bool success)
    {
        uint allowance = db.getAllowed(from, caller);
        db.subBalance(from, amount);
        db.addBalance(to, amount);
        db.setAllowed(from, caller, allowance.sub(amount));
        return true;
    }

     
    function approve(TokenStorage db, address caller, address spender, uint amount)
        public
        returns (bool success)
    {
        db.setAllowed(caller, spender, amount);
        return true;
    }

     
    function balanceOf(TokenStorage db, address who)
        external
        view
        returns (uint balance)
    {
        return db.getBalance(who);
    }

     
    function allowance(TokenStorage db, address owner, address spender)
        external
        view
        returns (uint remaining)
    {
        return db.getAllowed(owner, spender);
    }

}

 

 

pragma solidity 0.4.24;




 

library MintableTokenLib {

    using SafeMath for uint;

     
    function mint(
        TokenStorage db,
        address to,
        uint amount
    )
        external
        returns (bool)
    {
        db.addBalance(to, amount);
        return true;
    }

     
    function burn(
        TokenStorage db,
        address from,
        uint amount
    )
        public
        returns (bool)
    {
        db.subBalance(from, amount);
        return true;
    }

     
    function burn(
        TokenStorage db,
        address from,
        uint amount,
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (bool)
    {
        require(
            ecrecover(h, v, r, s) == from,
            "signature/hash does not match"
        );
        return burn(db, from, amount);
    }

}

 

 

pragma solidity 0.4.24;

 
interface IValidator {

     
    event Decision(address indexed from, address indexed to, uint amount, bool valid);

     
    function validate(address from, address to, uint amount) external returns (bool valid);

}

 

 

pragma solidity 0.4.24;




 
library SmartTokenLib {

    using ERC20Lib for TokenStorage;
    using MintableTokenLib for TokenStorage;

    struct SmartStorage {
        IValidator validator;
    }

     
    event Recovered(address indexed from, address indexed to, uint amount);

     
    event Validator(address indexed old, address indexed current);

     
    function setValidator(SmartStorage storage self, address validator)
        external
    {
        emit Validator(self.validator, validator);
        self.validator = IValidator(validator);
    }


     
    function validate(SmartStorage storage self, address from, address to, uint amount)
        external
        returns (bool valid)
    {
        return self.validator.validate(from, to, amount);
    }

     
    function recover(
        TokenStorage token,
        address from,
        address to,
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint)
    {
        require(
            ecrecover(h, v, r, s) == from,
            "signature/hash does not recover from address"
        );
        uint amount = token.balanceOf(from);
        token.burn(from, amount);
        token.mint(to, amount);
        emit Recovered(from, to, amount);
        return amount;
    }

     
    function getValidator(SmartStorage storage self)
        external
        view
        returns (address)
    {
        return address(self.validator);
    }

}

 

pragma solidity ^0.4.24;



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
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
}

 

pragma solidity ^0.4.24;


 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

 

 

pragma solidity 0.4.24;

 
interface IERC677Recipient {

     
    function onTokenTransfer(address from, uint256 amount, bytes data) external returns (bool);

}

 

 

pragma solidity 0.4.24;





 
library ERC677Lib {

    using ERC20Lib for TokenStorage;
    using AddressUtils for address;

     
    function transferAndCall(
        TokenStorage db,
        address caller,
        address to,
        uint256 amount,
        bytes data
    )
        external
        returns (bool)
    {
        require(
            db.transfer(caller, to, amount), 
            "unable to transfer"
        );
        if (to.isContract()) {
            IERC677Recipient recipient = IERC677Recipient(to);
            require(
                recipient.onTokenTransfer(caller, amount, data),
                "token handler returns false"
            );
        }
        return true;
    }

}

 

 

pragma solidity 0.4.24;








 
contract StandardController is Pausable, Destructible, Claimable {

    using ERC20Lib for TokenStorage;
    using ERC677Lib for TokenStorage;

    TokenStorage internal token;
    address internal frontend;

    string public name;
    string public symbol;
    uint public decimals = 18;

     
    event Frontend(address indexed old, address indexed current);

     
    event Storage(address indexed old, address indexed current);

     
    modifier guarded(address caller) {
        require(
            msg.sender == caller || msg.sender == frontend,
            "either caller must be sender or calling via frontend"
        );
        _;
    }

     
    constructor(address storage_, uint initialSupply, address frontend_) public {
        require(
            storage_ == 0x0 || initialSupply == 0,
            "either a token storage must be initialized or no initial supply"
        );
        if (storage_ == 0x0) {
            token = new TokenStorage();
            token.addBalance(msg.sender, initialSupply);
        } else {
            token = TokenStorage(storage_);
        }
        frontend = frontend_;
    }

     
    function avoidBlackholes(address to) internal view {
        require(to != 0x0, "must not send to 0x0");
        require(to != address(this), "must not send to controller");
        require(to != address(token), "must not send to token storage");
        require(to != frontend, "must not send to frontend");
    }

     
    function getFrontend() external view returns (address) {
        return frontend;
    }

     
    function getStorage() external view returns (address) {
        return address(token);
    }

     
    function setFrontend(address frontend_) public onlyOwner {
        emit Frontend(frontend, frontend_);
        frontend = frontend_;
    }

     
    function setStorage(address storage_) external onlyOwner {
        emit Storage(address(token), storage_);
        token = TokenStorage(storage_);
    }

     
    function transferStorageOwnership(address newOwner) public onlyOwner {
        token.transferOwnership(newOwner);
    }

     
    function claimStorageOwnership() public onlyOwner {
        token.claimOwnership();
    }

     
    function transfer_withCaller(address caller, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        avoidBlackholes(to);
        return token.transfer(caller, to, amount);
    }

     
    function transferFrom_withCaller(address caller, address from, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        avoidBlackholes(to);
        return token.transferFrom(caller, from, to, amount);
    }

     
    function approve_withCaller(address caller, address spender, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        return token.approve(caller, spender, amount);
    }

     
    function transferAndCall_withCaller(
        address caller,
        address to,
        uint256 amount,
        bytes data
    )
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        avoidBlackholes(to);
        return token.transferAndCall(caller, to, amount, data);
    }

     
    function totalSupply() external view returns (uint) {
        return token.getSupply();
    }

     
    function balanceOf(address who) external view returns (uint) {
        return token.getBalance(who);
    }

     
    function allowance(address owner, address spender) external view returns (uint) {
        return token.allowance(owner, spender);
    }

}

 

pragma solidity ^0.4.24;


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 

pragma solidity 0.4.24;


 
contract SystemRole {

    using Roles for Roles.Role;
    Roles.Role private systemAccounts;

     
    event SystemAccountAdded(address indexed account);

     
    event SystemAccountRemoved(address indexed account);

     
    modifier onlySystemAccounts() {
        require(isSystemAccount(msg.sender));
        _;
    }

     
    modifier onlySystemAccount(address account) {
        require(
            isSystemAccount(account),
            "must be a system account"
        );
        _;
    }

     
    constructor() internal {}

     
    function isSystemAccount(address account) public view returns (bool) {
        return systemAccounts.has(account);
    }

     
    function addSystemAccount(address account) public {
        systemAccounts.add(account);
        emit SystemAccountAdded(account);
    }

     
    function removeSystemAccount(address account) public {
        systemAccounts.remove(account);
        emit SystemAccountRemoved(account);
    }

}

 

 

pragma solidity 0.4.24;




 
contract MintableController is SystemRole, StandardController {

    using MintableTokenLib for TokenStorage;

     
    constructor(address storage_, uint initialSupply, address frontend_)
        public
        StandardController(storage_, initialSupply, frontend_)
    { }

     
    function addSystemAccount(address account) public onlyOwner {
        super.addSystemAccount(account);
    }

     
    function removeSystemAccount(address account) public onlyOwner {
        super.removeSystemAccount(account);
    }

     
    function mintTo_withCaller(address caller, address to, uint amount)
        public
        guarded(caller)
        onlySystemAccount(caller)
        returns (bool)
    {
        avoidBlackholes(to);
        return token.mint(to, amount);
    }

     
    function burnFrom_withCaller(address caller, address from, uint amount, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        public
        guarded(caller)
        onlySystemAccount(caller)
        returns (bool)
    {
        return token.burn(from, amount, h, v, r, s);
    }

}

 

 

pragma solidity 0.4.24;




 
contract SmartController is MintableController {

    using SmartTokenLib for SmartTokenLib.SmartStorage;

    SmartTokenLib.SmartStorage internal smartToken;

    bytes3 public ticker;
    uint constant public INITIAL_SUPPLY = 0;

     
    constructor(address storage_, address validator, bytes3 ticker_, address frontend_)
        public
        MintableController(storage_, INITIAL_SUPPLY, frontend_)
    {
        require(validator != 0x0, "validator cannot be the null address");
        smartToken.setValidator(validator);
        ticker = ticker_;
    }

     
    function setValidator(address validator) external onlySystemAccounts {
        smartToken.setValidator(validator);
    }

     
    function recover_withCaller(address caller, address from, address to, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        external
        guarded(caller)
        onlySystemAccount(caller)
        returns (uint)
    {
        avoidBlackholes(to);
        return SmartTokenLib.recover(token, from, to, h, v, r, s);
    }

     
    function transfer_withCaller(address caller, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(caller, to, amount), "transfer request not valid");
        return super.transfer_withCaller(caller, to, amount);
    }

     
    function transferFrom_withCaller(address caller, address from, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(from, to, amount), "transferFrom request not valid");
        return super.transferFrom_withCaller(caller, from, to, amount);
    }

     
    function transferAndCall_withCaller(
        address caller,
        address to,
        uint256 amount,
        bytes data
    )
        public
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(caller, to, amount), "transferAndCall request not valid");
        return super.transferAndCall_withCaller(caller, to, amount, data);
    }

     
    function getValidator() external view returns (address) {
        return smartToken.getValidator();
    }

}

 

 

pragma solidity 0.4.24;







 
contract TokenFrontend is Destructible, Claimable, CanReclaimToken, NoOwner, IERC20 {

    SmartController internal controller;

    string public name;
    string public symbol;
    bytes3 public ticker;

     
    event Transfer(address indexed from, address indexed to, uint amount);

     
    event Transfer(address indexed from, address indexed to, uint amount, bytes data);

     
    event Approval(address indexed owner, address indexed spender, uint amount);

     
    event Controller(bytes3 indexed ticker, address indexed old, address indexed current);

     
    constructor(string name_, string symbol_, bytes3 ticker_) internal {
        name = name_;
        symbol = symbol_;
        ticker = ticker_;
    }

     
    function setController(address address_) external onlyOwner {
        require(address_ != 0x0, "controller address cannot be the null address");
        emit Controller(ticker, controller, address_);
        controller = SmartController(address_);
        require(controller.getFrontend() == address(this), "controller frontend does not point back");
        require(controller.ticker() == ticker, "ticker does not match controller ticket");
    }

     
    function transfer(address to, uint amount) external returns (bool ok) {
        ok = controller.transfer_withCaller(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
    }

     
    function transferFrom(address from, address to, uint amount) external returns (bool ok) {
        ok = controller.transferFrom_withCaller(msg.sender, from, to, amount);
        emit Transfer(from, to, amount);
    }

     
    function approve(address spender, uint amount) external returns (bool ok) {
        ok = controller.approve_withCaller(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
    }

     
    function transferAndCall(address to, uint256 amount, bytes data)
        external
        returns (bool ok)
    {
        ok = controller.transferAndCall_withCaller(msg.sender, to, amount, data);
        emit Transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount, data);
    }

     
    function mintTo(address to, uint amount)
        external
        returns (bool ok)
    {
        ok = controller.mintTo_withCaller(msg.sender, to, amount);
        emit Transfer(0x0, to, amount);
    }

     
    function burnFrom(address from, uint amount, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        external
        returns (bool ok)
    {
        ok = controller.burnFrom_withCaller(msg.sender, from, amount, h, v, r, s);
        emit Transfer(from, 0x0, amount);
    }

     
    function recover(address from, address to, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        external
        returns (uint amount)
    {
        amount = controller.recover_withCaller(msg.sender, from, to, h ,v, r, s);
        emit Transfer(from, to, amount);
    }

     
    function getController() external view returns (address) {
        return address(controller);
    }

     
    function totalSupply() external view returns (uint) {
        return controller.totalSupply();
    }

     
    function balanceOf(address who) external view returns (uint) {
        return controller.balanceOf(who);
    }

     
    function allowance(address owner, address spender) external view returns (uint) {
        return controller.allowance(owner, spender);
    }

     
    function decimals() external view returns (uint) {
        return controller.decimals();
    }

}

 

 

pragma solidity 0.4.24;


contract EUR is TokenFrontend {

    constructor()
        public
        TokenFrontend("Monerium EUR emoney", "EURe", "EUR")
    { }

}