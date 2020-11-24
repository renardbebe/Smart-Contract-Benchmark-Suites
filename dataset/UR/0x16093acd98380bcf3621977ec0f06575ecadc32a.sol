 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


contract Activatable {
    bool public activated;

    modifier whenActivated {
        require(activated);
        _;
    }

    modifier whenNotActivated {
        require(!activated);
        _;
    }

    function activate() public returns (bool) {
        activated = true;
        return true;
    }
}



 
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






 
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


contract Contract is Ownable, SupportsInterfaceWithLookup {
     
    bytes4 public constant InterfaceId_Contract = 0x6125ede5;

    Template public template;

    constructor(address _owner) public {
        require(_owner != address(0));

        template = Template(msg.sender);
        owner = _owner;

        _registerInterface(InterfaceId_Contract);
    }
}







contract Strategy is Contract, Activatable {
     
    bytes4 public constant InterfaceId_Strategy = 0x6e301925;

    constructor(address _owner) public Contract(_owner) {
        _registerInterface(InterfaceId_Strategy);
    }

    function activate() onlyOwner public returns (bool) {
        return super.activate();
    }
}



contract SaleStrategy is Strategy {
     
    bytes4 public constant InterfaceId_SaleStrategy = 0x04c8123d;

    Sale public sale;

    constructor(address _owner, Sale _sale) public Strategy(_owner) {
        sale = _sale;

        _registerInterface(InterfaceId_SaleStrategy);
    }

    modifier whenSaleActivated {
        require(sale.activated());
        _;
    }

    modifier whenSaleNotActivated {
        require(!sale.activated());
        _;
    }

    function activate() whenSaleNotActivated public returns (bool) {
        return super.activate();
    }

    function deactivate() onlyOwner whenSaleNotActivated public returns (bool) {
        activated = false;
        return true;
    }

    function started() public view returns (bool);

    function successful() public view returns (bool);

    function finished() public view returns (bool);
}



 
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





 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}









 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}







 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}





 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}



 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}




 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

     
     
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
     
    ownedTokens[_from].length--;

     
     
     

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}






 
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















 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
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

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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

}




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}






 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}


contract Boost is MintableToken, DetailedERC20("Boost", "BST", 18) {
}














 
contract Template is Ownable, SupportsInterfaceWithLookup {
     
    bytes4 public constant InterfaceId_Template = 0xd48445ff;

    mapping(string => string) nameOfLocale;
    mapping(string => string) descriptionOfLocale;
     
    bytes32 public bytecodeHash;
     
    uint public price;
     
    address public beneficiary;

     
    event Instantiated(address indexed creator, address indexed contractAddress);

     
    constructor(
        bytes32 _bytecodeHash,
        uint _price,
        address _beneficiary
    ) public {
        bytecodeHash = _bytecodeHash;
        price = _price;
        beneficiary = _beneficiary;
        if (price > 0) {
            require(beneficiary != address(0));
        }

        _registerInterface(InterfaceId_Template);
    }

     
    function name(string _locale) public view returns (string) {
        return nameOfLocale[_locale];
    }

     
    function description(string _locale) public view returns (string) {
        return descriptionOfLocale[_locale];
    }

     
    function setNameAndDescription(string _locale, string _name, string _description) public onlyOwner {
        nameOfLocale[_locale] = _name;
        descriptionOfLocale[_locale] = _description;
    }

     
    function instantiate(bytes _bytecode, bytes _args) public payable returns (address contractAddress) {
        require(bytecodeHash == keccak256(_bytecode));
        bytes memory calldata = abi.encodePacked(_bytecode, _args);
        assembly {
            contractAddress := create(0, add(calldata, 0x20), mload(calldata))
        }
        if (contractAddress == address(0)) {
            revert("Cannot instantiate contract");
        } else {
            Contract c = Contract(contractAddress);
             
            require(c.supportsInterface(0x01ffc9a7));
             
            require(c.supportsInterface(0x6125ede5));

            if (price > 0) {
                require(msg.value == price);
                beneficiary.transfer(msg.value);
            }
            emit Instantiated(msg.sender, contractAddress);
        }
    }
}









contract StrategyTemplate is Template {
    constructor(
        bytes32 _bytecodeHash,
        uint _price,
        address _beneficiary
    ) public
    Template(
        _bytecodeHash,
        _price,
        _beneficiary
    ) {
    }

    function instantiate(bytes _bytecode, bytes _args) public payable returns (address contractAddress) {
        Strategy strategy = Strategy(super.instantiate(_bytecode, _args));
         
        require(strategy.supportsInterface(0x6e301925));
        return strategy;
    }
}



contract SaleStrategyTemplate is StrategyTemplate {
    constructor(
        bytes32 _bytecodeHash,
        uint _price,
        address _beneficiary
    ) public
    StrategyTemplate(
        _bytecodeHash,
        _price,
        _beneficiary
    ) {
    }

    function instantiate(bytes _bytecode, bytes _args) public payable returns (address contractAddress) {
        SaleStrategy strategy = SaleStrategy(super.instantiate(_bytecode, _args));
         
        require(strategy.supportsInterface(0x04c8123d));
        return strategy;
    }
}



contract Sale is Contract, Activatable {
    using SafeMath for uint;

     
    bytes4 public constant InterfaceId_Sale = 0x8139792d;

    string public projectName;
    string public projectSummary;
    string public projectDescription;
    string public logoUrl;
    string public coverImageUrl;
    string public websiteUrl;
    string public whitepaperUrl;
    string public name;

    uint256 public weiRaised;
    bool public withdrawn;

    SaleStrategy[] strategies;
    SaleStrategy[] activatedStrategies;
    mapping(address => uint256) paymentOfPurchaser;

    constructor(
        address _owner,
        string _projectName,
        string _name
    ) public Contract(_owner) {
        projectName = _projectName;
        name = _name;

        _registerInterface(InterfaceId_Sale);
    }

    function update(
        string _projectName,
        string _projectSummary,
        string _projectDescription,
        string _logoUrl,
        string _coverImageUrl,
        string _websiteUrl,
        string _whitepaperUrl,
        string _name
    ) public onlyOwner whenNotActivated {
        projectName = _projectName;
        projectSummary = _projectSummary;
        projectDescription = _projectDescription;
        logoUrl = _logoUrl;
        coverImageUrl = _coverImageUrl;
        websiteUrl = _websiteUrl;
        whitepaperUrl = _whitepaperUrl;
        name = _name;
    }

    function addStrategy(SaleStrategyTemplate _template, bytes _bytecode) onlyOwner whenNotActivated public payable {
         
        require(_template.supportsInterface(0x01ffc9a7));
         
        require(_template.supportsInterface(0xd48445ff));

        require(_isUniqueStrategy(_template));

        bytes memory args = abi.encode(msg.sender, address(this));
        SaleStrategy strategy = SaleStrategy(_template.instantiate.value(msg.value)(_bytecode, args));
        strategies.push(strategy);
    }

    function _isUniqueStrategy(SaleStrategyTemplate _template) private view returns (bool) {
        for (uint i = 0; i < strategies.length; i++) {
            SaleStrategy strategy = strategies[i];
            if (address(strategy.template()) == address(_template)) {
                return false;
            }
        }
        return true;
    }

    function numberOfStrategies() public view returns (uint256) {
        return strategies.length;
    }

    function strategyAt(uint256 index) public view returns (address) {
        return strategies[index];
    }

    function numberOfActivatedStrategies() public view returns (uint256) {
        return activatedStrategies.length;
    }

    function activatedStrategyAt(uint256 index) public view returns (address) {
        return activatedStrategies[index];
    }

    function activate() onlyOwner public returns (bool) {
        for (uint i = 0; i < strategies.length; i++) {
            SaleStrategy strategy = strategies[i];
            if (strategy.activated()) {
                activatedStrategies.push(strategy);
            }
        }
        return super.activate();
    }

    function started() public view returns (bool) {
        if (!activated) return false;

        bool s = false;
        for (uint i = 0; i < activatedStrategies.length; i++) {
            s = s || activatedStrategies[i].started();
        }
        return s;
    }

    function successful() public view returns (bool){
        if (!started()) return false;

        bool s = false;
        for (uint i = 0; i < activatedStrategies.length; i++) {
            s = s || activatedStrategies[i].successful();
        }
        return s;
    }

    function finished() public view returns (bool){
        if (!started()) return false;

        bool f = false;
        for (uint i = 0; i < activatedStrategies.length; i++) {
            f = f || activatedStrategies[i].finished();
        }
        return f;
    }

    function() external payable;

    function increasePaymentOf(address _purchaser, uint256 _weiAmount) internal {
        require(!finished());
        require(started());

        paymentOfPurchaser[_purchaser] = paymentOfPurchaser[_purchaser].add(_weiAmount);
        weiRaised = weiRaised.add(_weiAmount);
    }

    function paymentOf(address _purchaser) public view returns (uint256 weiAmount) {
        return paymentOfPurchaser[_purchaser];
    }

    function withdraw() onlyOwner whenActivated public returns (bool) {
        require(!withdrawn);
        require(finished());
        require(successful());

        withdrawn = true;
        msg.sender.transfer(weiRaised);

        return true;
    }

    function claimRefund() whenActivated public returns (bool) {
        require(finished());
        require(!successful());

        uint256 amount = paymentOfPurchaser[msg.sender];
        require(amount > 0);

        paymentOfPurchaser[msg.sender] = 0;
        msg.sender.transfer(amount);

        return true;
    }
}





contract SaleTemplate is Template {
    constructor(
        bytes32 _bytecodeHash,
        uint _price,
        address _beneficiary
    ) public
    Template(
        _bytecodeHash,
        _price,
        _beneficiary
    ) {
    }

    function instantiate(bytes _bytecode, bytes _args) public payable returns (address contractAddress) {
        Sale sale = Sale(super.instantiate(_bytecode, _args));
         
        require(sale.supportsInterface(0x8139792d));
        return sale;
    }
}


contract Raiser is ERC721Token("Raiser", "RAI"), Ownable {
    using SafeMath for uint256;

    event Mint(address indexed to, uint256 tokenId);

    uint256 public constant HALVING_WEI = 21000000 * (10 ** 18);
    uint256 public constant MAX_HALVING_ERA = 20;

    Boost public boost;
    uint256 public rewardEra = 0;

    uint256 weiUntilNextHalving = HALVING_WEI;
    mapping(uint256 => Sale) saleOfTokenId;
    mapping(uint256 => string) slugOfTokenId;
    mapping(uint256 => mapping(address => uint256)) rewardedBoostsOfSomeoneOfTokenId;

    constructor(Boost _boost) public {
        boost = _boost;
    }

    function mint(string _slug, SaleTemplate _template, bytes _bytecode, bytes _args) public payable {
         
        require(_template.supportsInterface(0x01ffc9a7));
         
        require(_template.supportsInterface(0xd48445ff));

        uint256 tokenId = toTokenId(_slug);
        require(address(saleOfTokenId[tokenId]) == address(0));

        Sale sale = Sale(_template.instantiate.value(msg.value)(_bytecode, _args));
        saleOfTokenId[tokenId] = sale;
        slugOfTokenId[tokenId] = _slug;

        _mint(msg.sender, tokenId);
        emit Mint(msg.sender, tokenId);
    }

    function toTokenId(string _slug) public pure returns (uint256 tokenId) {
        bytes memory chars = bytes(_slug);
        require(chars.length > 0, "String is empty.");
        for (uint i = 0; i < _min(chars.length, 32); i++) {
            uint c = uint(chars[i]);
            require(0x61 <= c && c <= 0x7a || c == 0x2d, "String must contain only lowercase alphabets or hyphens.");
        }
        assembly {
            tokenId := mload(add(chars, 32))
        }
    }

    function slugOf(uint256 _tokenId) public view returns (string slug) {
        return slugOfTokenId[_tokenId];
    }

    function saleOf(uint256 _tokenId) public view returns (Sale sale) {
        return saleOfTokenId[_tokenId];
    }

    function claimableBoostsOf(uint256 _tokenId) public view returns (uint256 boosts, uint256 newRewardEra, uint256 newWeiUntilNextHalving) {
        if (rewardedBoostsOfSomeoneOfTokenId[_tokenId][msg.sender] > 0) {
            return (0, rewardEra, weiUntilNextHalving);
        }

        Sale sale = saleOfTokenId[_tokenId];
        require(address(sale) != address(0));
        require(sale.finished());

        uint256 weiAmount = sale.paymentOf(msg.sender);
        if (sale.owner() == msg.sender) {
            weiAmount = weiAmount.add(sale.weiRaised());
        }
        return _weiToBoosts(weiAmount);
    }

    function claimBoostsOf(uint256 _tokenId) public returns (bool) {
        (uint256 boosts, uint256 newRewardEra, uint256 newWeiUntilNextHalving) = claimableBoostsOf(_tokenId);
        rewardEra = newRewardEra;
        weiUntilNextHalving = newWeiUntilNextHalving;
        if (boosts > 0) {
            boost.mint(msg.sender, boosts);
        }
        rewardedBoostsOfSomeoneOfTokenId[_tokenId][msg.sender] = boosts;
        return true;
    }

    function rewardedBoostsOf(uint256 _tokenId) public view returns (uint256 boosts) {
        return rewardedBoostsOfSomeoneOfTokenId[_tokenId][msg.sender];
    }

    function claimableBoosts() public view returns (uint256 boosts, uint256 newRewardEra, uint256 newWeiUntilNextHalving) {
        for (uint i = 0; i < totalSupply(); i++) {
            uint256 tokenId = tokenByIndex(i);
            (uint256 b, uint256 r, uint256 w) = claimableBoostsOf(tokenId);
            boosts = boosts.add(b);
            newRewardEra = r;
            newWeiUntilNextHalving = w;
        }
    }

    function claimBoosts() public returns (bool) {
        for (uint i = 0; i < totalSupply(); i++) {
            uint256 tokenId = tokenByIndex(i);
            claimBoostsOf(tokenId);
        }
        return true;
    }

    function rewardedBoosts() public view returns (uint256 boosts) {
        for (uint i = 0; i < totalSupply(); i++) {
            uint256 tokenId = tokenByIndex(i);
            boosts = boosts.add(rewardedBoostsOf(tokenId));
        }
    }

    function boostsUntilNextHalving() public view returns (uint256) {
        (uint256 boosts,,) = _weiToBoosts(weiUntilNextHalving);
        return boosts;
    }

    function _weiToBoosts(uint256 _weiAmount) private view returns (uint256 boosts, uint256 newRewardEra, uint256 newWeiUntilNextHalving) {
        if (rewardEra > MAX_HALVING_ERA) {
            return (0, rewardEra, weiUntilNextHalving);
        }
        uint256 amount = _weiAmount;
        boosts = 0;
        newRewardEra = rewardEra;
        newWeiUntilNextHalving = weiUntilNextHalving;
        while (amount > 0) {
            uint256 a = _min(amount, weiUntilNextHalving);
            boosts = boosts.add(a.mul(2 ** (MAX_HALVING_ERA.sub(newRewardEra)).div(1000)));
            amount = amount.sub(a);
            newWeiUntilNextHalving = newWeiUntilNextHalving.sub(a);
            if (newWeiUntilNextHalving == 0) {
                newWeiUntilNextHalving = HALVING_WEI;
                newRewardEra += 1;
            }
        }
    }

    function _min(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}