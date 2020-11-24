 

pragma solidity ^0.4.24; 
interface ERC165 {
   
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
interface ERC721Enumerable   {
     
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

 
interface ERC721Metadata   {
   
  function name() external view returns (string _name);

   
  function symbol() external view returns (string _symbol);

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string);
}

 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
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

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}
 
library UrlStr {
  
   
   
  function generateUrl(string url,uint256 _tokenId) internal pure returns (string _url){
    _url = url;
    bytes memory _tokenURIBytes = bytes(_url);
    uint256 base_len = _tokenURIBytes.length - 1;
    _tokenURIBytes[base_len - 7] = byte(48 + _tokenId / 10000000 % 10);
    _tokenURIBytes[base_len - 6] = byte(48 + _tokenId / 1000000 % 10);
    _tokenURIBytes[base_len - 5] = byte(48 + _tokenId / 100000 % 10);
    _tokenURIBytes[base_len - 4] = byte(48 + _tokenId / 10000 % 10);
    _tokenURIBytes[base_len - 3] = byte(48 + _tokenId / 1000 % 10);
    _tokenURIBytes[base_len - 2] = byte(48 + _tokenId / 100 % 10);
    _tokenURIBytes[base_len - 1] = byte(48 + _tokenId / 10 % 10);
    _tokenURIBytes[base_len - 0] = byte(48 + _tokenId / 1 % 10);
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

 
contract Operator is Ownable {
    address[] public operators;

    uint public MAX_OPS = 20;  

    mapping(address => bool) public isOperator;

    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

     
    modifier onlyOperator() {
        require(
            isOperator[msg.sender] || msg.sender == owner,
            "Permission denied. Must be an operator or the owner."
        );
        _;
    }

     
    function addOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "Invalid new operator address."
        );

         
        require(
            !isOperator[_newOperator],
            "New operator exists."
        );

         
        require(
            operators.length < MAX_OPS,
            "Overflow."
        );

        operators.push(_newOperator);
        isOperator[_newOperator] = true;

        emit OperatorAdded(_newOperator);
    }

     
    function removeOperator(address _operator) public onlyOwner {
         
        require(
            operators.length > 0,
            "No operator."
        );

         
        require(
            isOperator[_operator],
            "Not an operator."
        );

         
         
         
        address lastOperator = operators[operators.length - 1];
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                operators[i] = lastOperator;
            }
        }
        operators.length -= 1;  

        isOperator[_operator] = false;
        emit OperatorRemoved(_operator);
    }

     
    function removeAllOps() public onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            isOperator[operators[i]] = false;
        }
        operators.length = 0;
    }
}
 
contract Pausable is Operator {

  event FrozenFunds(address target, bool frozen);

  bool public isPaused = false;
  
  mapping(address => bool)  frozenAccount;

  modifier whenNotPaused {
    require(!isPaused);
    _;
  }

  modifier whenPaused {
    require(isPaused);
    _;  
  }

  modifier whenNotFreeze(address _target) {
    require(_target != address(0));
    require(!frozenAccount[_target]);
    _;
  }

  function isFrozen(address _target) external view returns (bool) {
    require(_target != address(0));
    return frozenAccount[_target];
  }

  function doPause() external  whenNotPaused onlyOwner {
    isPaused = true;
  }

  function doUnpause() external  whenPaused onlyOwner {
    isPaused = false;
  }

  function freezeAccount(address _target, bool _freeze) public onlyOwner {
    require(_target != address(0));
    frozenAccount[_target] = _freeze;
    emit FrozenFunds(_target, _freeze);
  }

}

contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721, Pausable{

  bytes4 public constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 public constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(_ownerOf(_tokenId) == msg.sender,"This token not owned by this address");
    _;
  }
  
  function _ownerOf(uint256 _tokenId) internal view returns(address) {
    address _owner = tokenOwner[_tokenId];
    require(_owner != address(0),"Token not exist");
    return _owner;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId), "This address have no permisstion");
    _;
  }

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
    _registerInterface(ERC721_RECEIVED);
  }

   
  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) external view returns (address) {
    return _ownerOf(_tokenId);
  }

   
  function exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) external whenNotPaused {
    address _owner = _ownerOf(_tokenId);
    require(_to != _owner);
    require(msg.sender == _owner || operatorApprovals[_owner][msg.sender]);

    tokenApprovals[_tokenId] = _to;
    emit Approval(_owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) external view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) external whenNotPaused {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
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
    external
    canTransfer(_tokenId)
  {
    _transfer(_from,_to,_tokenId);
  }


  function _transfer(
    address _from,
    address _to,
    uint256 _tokenId) internal {
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
    external
    canTransfer(_tokenId)
  {
     
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function _safeTransferFrom( 
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data) internal {
    _transfer(_from, _to, _tokenId);
       
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    external
    canTransfer(_tokenId)
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
   
  }

   
  function isApprovedOrOwner (
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address _owner = _ownerOf(_tokenId);
     
     
     
    return (
      _spender == _owner ||
      tokenApprovals[_tokenId] == _spender ||
      operatorApprovals[_owner][_spender]
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

   
  function clearApproval(address _owner, uint256 _tokenId) internal whenNotPaused {
    require(_ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    require(tokenOwner[_tokenId] == address(0));
    require(!frozenAccount[_to]);  
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused {
    require(_ownerOf(_tokenId) == _from);
    require(!frozenAccount[_from]);  
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
    bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}
 
contract ERC721ExtendToken is ERC721BasicToken, ERC721Enumerable, ERC721Metadata {

  using UrlStr for string;

  bytes4 public constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 public constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   
  string internal BASE_URL = "https://www.bitguild.com/bitizens/api/lambo/getCarInfo/00000000";

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

  function updateBaseURI(string _url) external onlyOwner {
    BASE_URL = _url;
  }
  
   
  constructor() public {
     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return "Bitizen Lambo";
  }

   
  function symbol() external view returns (string) {
    return "LAMBO";
  }

   
  function tokenURI(uint256 _tokenId) external view returns (string) {
    require(exists(_tokenId));
    return BASE_URL.generateUrl(_tokenId);
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(address(0)!=_owner);
    require(_index < ownedTokensCount[_owner]);
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

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

interface BitizenCarService {
  function isBurnedCar(uint256 _carId) external view returns (bool);
  function getOwnerCars(address _owner) external view returns(uint256[]);
  function getBurnedCarIdByIndex(uint256 _index) external view returns (uint256);
  function getCarInfo(uint256 _carId) external view returns(string, uint8, uint8);
  function createCar(address _owner, string _foundBy, uint8 _type, uint8 _ext) external returns(uint256);
  function updateCar(uint256 _carId, string _newFoundBy, uint8 _newType, uint8 _ext) external;
  function burnCar(address _owner, uint256 _carId) external;
}

contract BitizenCarToken is ERC721ExtendToken {
  
  enum CarHandleType{CREATE_CAR, UPDATE_CAR, BURN_CAR}

  event TransferStateChanged(address indexed _owner, bool _state);
  
  event CarHandleEvent(address indexed _owner, uint256 indexed _carId, CarHandleType _type);

  struct BitizenCar{
    string foundBy;  
    uint8 carType;   
    uint8 ext;       
  }
 
   
  uint256 internal carIndex = 0;

   
  mapping (uint256 => BitizenCar) carInfos;

   
  uint256[] internal burnedCars;

   
  mapping(uint256 => bool) internal isBurned;

   
  bool public carTransferState = false;

  modifier validCar(uint256 _carId) {
    require(_carId > 0 && _carId <= carIndex, "invalid car");
    _;
  }

  function changeTransferState(bool _newState) public onlyOwner {
    if(carTransferState == _newState) return;
    carTransferState = _newState;
    emit TransferStateChanged(owner, carTransferState);
  }

  function isBurnedCar(uint256 _carId) external view validCar(_carId) returns (bool) {
    return isBurned[_carId];
  }

  function getBurnedCarCount() external view returns (uint256) {
    return burnedCars.length;
  }

  function getBurnedCarIdByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnedCars.length, "out of boundary");
    return burnedCars[_index];
  }

  function getCarInfo(uint256 _carId) external view validCar(_carId) returns(string, uint8, uint8)  {
    BitizenCar storage car = carInfos[_carId];
    return(car.foundBy, car.carType, car.ext);
  }

  function getOwnerCars(address _owner) external view onlyOperator returns(uint256[]) {
    require(_owner != address(0));
    return ownedTokens[_owner];
  }

  function createCar(address _owner, string _foundBy, uint8 _type, uint8 _ext) external onlyOperator returns(uint256) {
    require(_owner != address(0));
    BitizenCar memory car = BitizenCar(_foundBy, _type, _ext);
    uint256 carId = ++carIndex;
    carInfos[carId] = car;
    _mint(_owner, carId);
    emit CarHandleEvent(_owner, carId, CarHandleType.CREATE_CAR);
    return carId;
  }

  function updateCar(uint256 _carId, string _newFoundBy, uint8 _type, uint8 _ext) external onlyOperator {
    require(exists(_carId));
    BitizenCar storage car = carInfos[_carId];
    car.foundBy = _newFoundBy;
    car.carType = _type;
    car.ext = _ext;
    emit CarHandleEvent(_ownerOf(_carId), _carId, CarHandleType.UPDATE_CAR);
  }

  function burnCar(address _owner, uint256 _carId) external onlyOperator {
    burnedCars.push(_carId);
    isBurned[_carId] = true;
    _burn(_owner, _carId);
    emit CarHandleEvent(_owner, _carId, CarHandleType.BURN_CAR);
  }

   
   
  function _transfer(address _from,address _to,uint256 _tokenId) internal {
    require(carTransferState == true, "not allown transfer at current time");
    super._transfer(_from, _to, _tokenId);
  }
  
  function () public payable {
    revert();
  }
}