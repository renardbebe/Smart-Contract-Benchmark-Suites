 

 

pragma solidity >=0.4.24 <0.6.0;


 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;




 
contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string name, string symbol, uint8 decimals) public initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

 

pragma solidity ^0.4.24;

contract Administrators {
    mapping (address => bool) public isAdministrator;

    event AdministratorChanged(address user, bool isAdministrator);

    constructor() public {
        isAdministrator[msg.sender] = true;
    }

    modifier onlyAdministrators() {
        require(isAdministrator[msg.sender]);
        _;
    }

    function setAdministrator(address user, bool _isAdministrator) public onlyAdministrators {
        require(user != msg.sender);
        require(isAdministrator[user] != _isAdministrator);
        isAdministrator[user] = _isAdministrator;
        emit AdministratorChanged(user, _isAdministrator);
    }
}

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;





 
contract ERC20 is Initializable, IERC20 {
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
    _transfer(msg.sender, to, value);
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
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
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

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

   
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
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

  uint256[50] private ______gap;
}

 

pragma solidity ^0.4.24;

 
interface IERC1594 {

     
    function transferWithData(address _to, uint256 _value, bytes _data) public;
    function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) public;

     
    function isIssuable() external view returns (bool);
    function issue(address _tokenHolder, uint256 _value, bytes _data) external;

     
    function redeem(uint256 _value, bytes _data) external;
    function redeemFrom(address _tokenHolder, uint256 _value, bytes _data) external;

     
    function canTransfer(address _to, uint256 _value, bytes _data) external view returns (byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes _data) external view returns (byte, bytes32);

     
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);
}

 

 
 

interface IERC1644 {

     
    function isControllable() external view returns (bool);
    function controllerTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _operatorData) external;
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes _data, bytes _operatorData) external;

     
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
}

 

pragma solidity ^0.4.24;


 
contract Ownable is Initializable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  function initialize(address sender) public initializer {
    _owner = sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
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

  uint256[50] private ______gap;
}

 

pragma solidity ^0.4.25;



contract Whitelist is Initializable, Ownable {

  mapping(address => bool) private whitelist;
  bool public debugMode;

  function initialize() initializer public {
    Ownable.initialize(msg.sender);
    debugMode = true;
  }

  function isWhitelisted(address user) public view returns (bool) {
    return debugMode || whitelist[user];
  }

  function setWhitelisted(address user, bool _isWhitelisted) onlyOwner public {
    whitelist[user] = _isWhitelisted;
  }

  function toggleDebugMode() public onlyOwner {
    debugMode = !debugMode;
  }
}

 

pragma solidity ^0.4.24;






contract SecurityToken is IERC1594, IERC1644, ERC20, Administrators {
     
    byte private constant STATUS_DISALLOWED = 0x10;
    byte private constant STATUS_ALLOWED = 0x11;

    Whitelist public whitelist;

    constructor(address _whitelist) internal {
        whitelist = Whitelist(_whitelist);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(whitelist.isWhitelisted(to), "transfer must be allowed");
        return ERC20.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(whitelist.isWhitelisted(to), "transfer must be allowed");
        return ERC20.transferFrom(from, to, value);
    }

    function transferWithData(address _to, uint256 _value, bytes) public {
        transfer(_to, _value);
    }

    function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) public {
        transferFrom(_from, _to, _value);
    }

    function isControllable() external view returns (bool) {
        return true;
    }

    function controllerTransfer(address _from, address _to, uint256 _value, bytes _data, bytes _operatorData) onlyAdministrators external {
        ERC20._transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    function controllerRedeem(address _tokenHolder, uint256 _value, bytes _data, bytes _operatorData) onlyAdministrators external {
        revert("Redeeming is not enabled");
    }


     
    function isIssuable() external view returns (bool) {
        return false;
    }
    function issue(address _tokenHolder, uint256 _value, bytes _data) external {
        revert("Issuing is not enabled");
    }

     
    function redeem(uint256 _value, bytes _data) external {
        revert("Redeeming is not enabled");
    }
    function redeemFrom(address _tokenHolder, uint256 _value, bytes _data) external {
        revert("Redeeming is not enabled");
    }

     
    function canTransfer(address _to, uint256 _value, bytes) external view returns (byte, bytes32) {
        byte status = whitelist.isWhitelisted(_to) ? STATUS_ALLOWED : STATUS_DISALLOWED;
        return (status, 0x0);
    }
    function canTransferFrom(address _from, address _to, uint256 _value, bytes) external view returns (byte, bytes32) {
        byte status = whitelist.isWhitelisted(_to)  ? STATUS_ALLOWED : STATUS_DISALLOWED;
        return (status, 0x0);
    }
}

 

pragma solidity ^0.4.24;





contract Dividends is SecurityToken {
    using SafeMath for uint256;

    uint256 private scaledDividendPerToken = 0;
    uint256 private scaledRemainder = 0;
    mapping(address => uint256) private scaledDividendBalanceOf;
    mapping(address => uint256) private scaledDividendCreditedTo;
    mapping(address => uint256) public userLastActive;

    uint256 constant RECOVERY_TIMEOUT = 180 days;
    uint256 constant SCALING = uint256(10) ** 8;

    IERC20 private _dividendToken;

    event DividendDistributed(uint totalAmount, address depositor);
    event DividendWithdrawl(address holder, uint amount);
    event DividendTokenChanged(address newToken);
    event DividendRecovered(address holder, address administrator, uint amountRecovered, uint inactivityPeriod);

    constructor(address newDividendToken) public {
        _dividendToken = IERC20(newDividendToken);
        require(_dividendToken.balanceOf(address(this)) == 0, "Requires valid ERC20 dividend token");
        emit DividendTokenChanged(_dividendToken);
    }

    function dividendToken() public view returns (address) {
        return _dividendToken;
    }

    function dividendPerToken() public view returns (uint) {
        return scaledDividendPerToken / SCALING;
    }

    function dividendBalanceOf(address account) public view returns (uint) {
        uint owed = scaledDividendPerToken.sub(scaledDividendCreditedTo[account]);
        uint scaledBalance = scaledDividendBalanceOf[account].add(balanceOf(account).mul(owed));
        return scaledBalance.div(SCALING);
    }

    function minimumDeposit() public view returns (uint256) {
        return totalSupply().div(SCALING);
    }

    function deposit(uint amount) public {
        require(amount >= minimumDeposit(), "Deposit is less than minimum deposit");
        require(_dividendToken.allowance(msg.sender, address(this)) >= amount);
        _dividendToken.transferFrom(msg.sender, address(this), amount);
        uint256 available = amount.mul(SCALING).add(scaledRemainder);
        scaledDividendPerToken = scaledDividendPerToken.add(available.div(totalSupply()));
        scaledRemainder = available % totalSupply();
        emit DividendDistributed(amount, msg.sender);
    }

    function depositPartial(uint amount) public {
        require(amount >= minimumDeposit(), "Deposit is less than minimum deposit");
        require(_dividendToken.allowance(msg.sender, address(this)) >= amount);
        _dividendToken.transferFrom(msg.sender, address(this), amount);

         
        uint totalSupplyWithoutSender = totalSupply().sub(balanceOf(msg.sender));
        uint256 available = amount.mul(SCALING).add(scaledRemainder);
        uint scaledDividendIncrease = available.div(totalSupplyWithoutSender);
        scaledDividendPerToken = scaledDividendPerToken.add(scaledDividendIncrease);
        scaledRemainder = available.mod(totalSupplyWithoutSender);

         
        scaledDividendCreditedTo[msg.sender] = scaledDividendCreditedTo[msg.sender].add(scaledDividendIncrease);
        userLastActive[msg.sender] = now;

         
        uint totalAmount = amount.add(scaledDividendIncrease.mul(balanceOf(msg.sender)) / SCALING);
        emit DividendDistributed(totalAmount, msg.sender);
    }

    function withdraw() public {
        update(msg.sender);
        uint256 amount = scaledDividendBalanceOf[msg.sender] / SCALING;
        scaledDividendBalanceOf[msg.sender] %= SCALING;
        _dividendToken.transfer(msg.sender, amount);
        emit DividendWithdrawl(msg.sender, amount);
    }


    function changeDividendToken(address newToken) public onlyAdministrators {
        IERC20 _oldToken = _dividendToken;
        IERC20 _newToken = IERC20(newToken);
        uint dividendBalance = _oldToken.balanceOf(address(this));

        _dividendToken = _newToken;
        if (dividendBalance > 0) {
            require(_newToken.allowance(msg.sender, address(this)) >= dividendBalance);

            _newToken.transferFrom(msg.sender, address(this), dividendBalance);
            _oldToken.transfer(msg.sender, dividendBalance);
        }

        emit DividendTokenChanged(newToken);
    }

    function recoverDividend(address user) public onlyAdministrators {
        uint inactivityPeriod = now - userLastActive[user];
        require(inactivityPeriod > RECOVERY_TIMEOUT, "User is active");
        uint amount = scaledDividendBalanceOf[user] / SCALING;
        scaledDividendBalanceOf[user] %= SCALING;
        _dividendToken.transfer(msg.sender, amount);
        emit DividendRecovered(user, msg.sender, amount, inactivityPeriod);
    }


    function transfer(address to, uint256 value) public returns (bool) {
        update(msg.sender);
        update(to);

        return SecurityToken.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        update(from);
        update(to);

        return SecurityToken.transferFrom(from, to, value);
    }

    function transferWithData(address _to, uint256 _value, bytes _data) public {
        update(msg.sender);
        update(_to);

        SecurityToken.transferWithData(_to, _value, _data);
    }

    function transferFromWithData(address _from, address _to, uint256 _value, bytes _data) public {
        update(_from);
        update(_to);

        SecurityToken.transferFromWithData(_from, _to, _value, _data);
    }

    function update(address account) internal {
        uint256 owed = scaledDividendPerToken - scaledDividendCreditedTo[account];
        scaledDividendBalanceOf[account] = scaledDividendBalanceOf[account].add(balanceOf(account).mul(owed));
        scaledDividendCreditedTo[account] = scaledDividendPerToken;
        userLastActive[account] = now;
    }
}

 

pragma solidity ^0.4.24;

 
interface IERC1643 {
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    function getDocument(bytes32 _name) external view returns (string, bytes32, uint256);
    function setDocument(bytes32 _name, string _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;
    function getAllDocuments() external view returns (bytes32[]);
}

 

pragma solidity ^0.4.24;

library Utils {
    function removeElement(bytes32[] storage list, bytes32 element) internal {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == element) {
                list[i] = list[list.length - 1];
                delete list[list.length - 1];
                list.length--;
            }
        }
    }
}

 

pragma solidity ^0.4.24;




contract Documents is Administrators, IERC1643 {

    struct Document {
        string uri;
        bytes32 documentHash;
        uint256 lastModified;
    }

    mapping (bytes32 => Document) private documents;
    bytes32[] private names;

    function getDocument(bytes32 _name) external view returns (string, bytes32, uint256) {
        return (documents[_name].uri, documents[_name].documentHash, documents[_name].lastModified);
    }

    function setDocument(bytes32 _name, string _uri, bytes32 _documentHash) external onlyAdministrators {
        require(_name.length > 0, "name of the document must not be empty");
        require(bytes(_uri).length > 0, "external URI to the document must not be empty");
        require(_documentHash.length > 0, "content hash is required, use SHA-256 when in doubt");

        if (documents[_name].lastModified == 0) {
            names.push(_name);
        }
        documents[_name] = Document(_uri, _documentHash, now);
        emit DocumentUpdated(_name, _uri, _documentHash);
    }

    function removeDocument(bytes32 _name) external onlyAdministrators {
        string memory uri = documents[_name].uri;
        bytes32 documentHash = documents[_name].documentHash;

        Utils.removeElement(names, _name);
        delete documents[_name];

        emit DocumentRemoved(_name, uri, documentHash);
    }

    function getAllDocuments() external view returns (bytes32[]) {
        return names;
    }
}

 

pragma solidity ^0.4.24;



contract Metadata is Administrators {
    mapping (bytes32 => string) private metadata;
    bytes32[] private names;

    event MetadataChanged(bytes32 name, string value);

    function getMetadata(bytes32 name) external view returns (string) {
        return metadata[name];
    }

    function setMetadata(bytes32 name, string value) external onlyAdministrators {
        if (bytes(metadata[name]).length == 0) {
            names.push(name);
        }
        if (bytes(value).length == 0) {
            Utils.removeElement(names, name);
        }

        metadata[name] = value;
        emit MetadataChanged(name, value);
    }

    function getAllMetadata() external view returns (bytes32[]) {
        return names;
    }
}

 

pragma solidity ^0.4.24;


contract IPropertyToken is IERC20 {
    function canTransfer(address _to, uint256 _value, bytes) external view returns (byte, bytes32);
    function canTransferFrom(address _from, address _to, uint256 _value, bytes) external view returns (byte, bytes32);

    function dividendToken() public view returns (address);
    function dividendPerToken() public view returns (uint);
    function dividendBalanceOf(address account) public view returns (uint);
    function deposit(uint amount) public;
    function depositPartial(uint amount) public;
    function withdraw() public;
    function changeDividendToken(address newToken) public;
    function recoverDividend(address user) public;

    function getDocument(bytes32 _name) external view returns (string, bytes32, uint256);
    function setDocument(bytes32 _name, string _uri, bytes32 _documentHash) external;
    function removeDocument(bytes32 _name) external;
    function getAllDocuments() external view returns (bytes32[]);

    function getMetadata(bytes32 name) external view returns (string);
    function setMetadata(bytes32 name, string value) external;
    function getAllMetadata() external view returns (bytes32[]);
}

 

pragma solidity ^0.4.24;








 
contract PropertyToken is IPropertyToken, ERC20Detailed, SecurityToken, Dividends, Documents, Metadata {
     
    constructor (string name, string symbol, uint supply, address whitelist, address dividendToken)
            public SecurityToken(whitelist) Dividends(dividendToken) {
        ERC20Detailed.initialize(name, symbol, 18);
        _mint(msg.sender, supply);
    }
}