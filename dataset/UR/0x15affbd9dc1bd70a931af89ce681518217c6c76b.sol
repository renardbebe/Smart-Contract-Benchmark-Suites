 

pragma solidity ^0.4.24;

 



 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

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

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
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

   
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

   
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

   
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

     
     
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
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
}


contract StarCoin is Ownable, StandardToken {
    using SafeMath for uint;
    address gateway;
    string public name = "EtherPornStars Coin";
    string public symbol = "EPS";
    uint8 public decimals = 18;
    mapping (uint8 => address) public studioContracts;
    mapping (address => bool) public isMinter;
    event Withdrawal(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    modifier onlyMinters {
      require(msg.sender == owner || isMinter[msg.sender]);
      _;
    }

    constructor () public {
  }
   
    function setGateway(address _gateway) external onlyOwner {
        gateway = _gateway;
    }


    function _mintTokens(address _user, uint256 _amount) private {
        require(_user != 0x0);
        balances[_user] = balances[_user].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        emit Transfer(address(this), _user, _amount);
    }

    function rewardTokens(address _user, uint256 _tokens) external   { 
        require(msg.sender == owner || isMinter[msg.sender]);
        _mintTokens(_user, _tokens);
    }
    function buyStudioStake(address _user, uint256 _tokens) external   { 
        require(msg.sender == owner || isMinter[msg.sender]);
        _burn(_user, _tokens);
    }
    function transferFromStudio(
      address _from,
      address _to,
      uint256 _value
    )
      external
      returns (bool)
    {
      require(msg.sender == owner || isMinter[msg.sender]);
      require(_value <= balances[_from]);
      require(_to != address(0));

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }

    function() payable public {
         
    }

    function accountAuth(uint256  ) external {
         
    }

    function burn(uint256 _amount) external {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Burn(msg.sender, _amount);
    }

    function withdrawBalance(uint _amount) external {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        uint ethexchange = _amount.div(2);
        msg.sender.transfer(ethexchange);
    }

    function setIsMinter(address _address, bool _value) external onlyOwner {
        isMinter[_address] = _value;
    }

    function depositToGateway(uint256 amount) external {
        transfer(gateway, amount);
    }
}

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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





contract StarLogicInterface {
    function isTransferAllowed(address _from, address _to, uint256 _tokenId) public view returns (bool);
}




 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

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

   
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_account) }
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

   
  function _exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
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






 



contract EtherPornStars is Ownable, SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  struct StarData {
      uint16 fieldA;
      uint16 fieldB;
      uint32 fieldC;
      uint32 fieldD;
      uint32 fieldE;
      uint64 fieldF;
      uint64 fieldG;
  }

  address public logicContractAddress;
  address public starCoinAddress;

   
  mapping(uint256 => StarData) public starData;
  mapping(uint256 => bool) public starPower;
  mapping(uint256 => uint256) public starStudio;
   
  mapping(address => uint256) public activeStar;
   
  mapping(uint8 => address) public studios;
  event ActiveStarChanged(address indexed _from, uint256 _tokenId);
   
  string internal name_;
   
  string internal symbol_;
   
  mapping(uint256 => uint256) public genome;
   
  mapping(address => uint256[]) internal ownedTokens;
   
  mapping(uint256 => uint256) internal ownedTokensIndex;
   
  uint256[] internal allTokens;
   
  mapping(uint256 => uint256) internal allTokensIndex;
   
  mapping(uint256 => string) internal tokenURIs;
    
  mapping (uint256 => uint256) inviter;
   
  event BoughtStar(address indexed buyer, uint256 _tokenId, uint8 _studioId );
   
  modifier onlyLogicContract {
    require(msg.sender == logicContractAddress || msg.sender == owner);
    _;
  }
  constructor(string _name, string _symbol, address _starCoinAddress) public {
    name_ = _name;
    symbol_ = _symbol;
    starCoinAddress = _starCoinAddress;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   


     
  function setLogicContract(address _logicContractAddress) external onlyOwner {
    logicContractAddress = _logicContractAddress;
  }

  function addStudio(uint8 _studioId, address _studioAddress) external onlyOwner {
    studios[_studioId] = _studioAddress;
}
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(_exists(_tokenId));
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
    require(_exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;

    if (activeStar[_to] == 0) {
      activeStar[_to] = _tokenId;
      emit ActiveStarChanged(_to, _tokenId);
    }
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

  function mint(address _to, uint256 _tokenId) external onlyLogicContract {
    _mint(_to, _tokenId);
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

  function burn(address _owner, uint256 _tokenId) external onlyLogicContract {
    _burn(_owner, _tokenId);
}

 
  function setStarData(
      uint256 _tokenId,
      uint16 _fieldA,
      uint16 _fieldB,
      uint32 _fieldC,
      uint32 _fieldD,
      uint32 _fieldE,
      uint64 _fieldF,
      uint64 _fieldG
  ) external onlyLogicContract {
      starData[_tokenId] = StarData(
          _fieldA,
          _fieldB,
          _fieldC,
          _fieldD,
          _fieldE,
          _fieldF,
          _fieldG
      );
  }
     
  function setGenome(uint256 _tokenId, uint256 _genome) external onlyLogicContract {
    genome[_tokenId] = _genome;
  }

  function activeStarGenome(address _owner) public view returns (uint256) {
    uint256 tokenId = activeStar[_owner];
    if (tokenId == 0) {
        return 0;
    }
    return genome[tokenId];
    }

  function setActiveStar(uint256 _tokenId) external {
    require(msg.sender == ownerOf(_tokenId));
    activeStar[msg.sender] = _tokenId;
    emit ActiveStarChanged(msg.sender, _tokenId);
    }

  function forceTransfer(address _from, address _to, uint256 _tokenId) external onlyLogicContract {
      require(_from != address(0));
      require(_to != address(0));
      removeTokenFrom(_from, _tokenId);
      addTokenTo(_to, _tokenId);
      emit Transfer(_from, _to, _tokenId);
  }
  function transfer(address _to, uint256 _tokenId) external {
    require(msg.sender == ownerOf(_tokenId));
    require(_to != address(0));
    removeTokenFrom(msg.sender, _tokenId);
    addTokenTo(_to, _tokenId);
    emit Transfer(msg.sender, _to, _tokenId);
    }
  function addrecruit(uint256 _recId, uint256 _inviterId) private {
    inviter[_recId] = _inviterId;
}
  function buyStar(uint256 _tokenId, uint8 _studioId, uint256 _inviterId) external payable {
      require(msg.value >= 0.1 ether);
      _mint(msg.sender, _tokenId);
      emit BoughtStar(msg.sender, _tokenId, _studioId);
      uint amount = msg.value;
      starCoinAddress.transfer(msg.value);
      addrecruit(_tokenId, _inviterId);
      starStudio[_tokenId] = _studioId;
      StarCoin instanceStarCoin = StarCoin(starCoinAddress);
      instanceStarCoin.rewardTokens(msg.sender, amount);
        if (_inviterId != 0) {
          recReward(amount, _inviterId);
      }
      if(_studioId == 1) {
          starPower[_tokenId] = true;
      }
    }
  function recReward(uint amount, uint256 _inviterId) private {
    StarCoin instanceStarCoin = StarCoin(starCoinAddress);
    uint i=0;
    owner = ownerOf(_inviterId);
    amount = amount/2;
    instanceStarCoin.rewardTokens(owner, amount);
    while (i < 4) {
      amount = amount/2;
      owner = ownerOf(inviter[_inviterId]);
      if(owner==address(0)){
        break;
      }
      instanceStarCoin.rewardTokens(owner, amount);
      _inviterId = inviter[_inviterId];
      i++;
    }
  }

  function myTokens()
    external
    view
    returns (
      uint256[]
    )
  {
    return ownedTokens[msg.sender];
  }
}