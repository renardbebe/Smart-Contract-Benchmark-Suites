 

pragma solidity ^0.4.24;

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

 
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


 
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
     
    uint32 c = a / b;
     
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
     
    uint16 c = a / b;
     
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}
 
contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) private _supportedInterfaces;

   
  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

   
  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

 
contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

 
contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}


 
contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

   
   
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) private _tokenOwner;

   
  mapping (uint256 => address) private _tokenApprovals;

   
  mapping (address => uint256) private _ownedTokensCount;

   
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
   

  constructor()
    public
  {
     
    _registerInterface(_InterfaceId_ERC721);
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

   
  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

   
  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

   
  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
     
    safeTransferFrom(from, to, tokenId, "");
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

   
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

   
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
     
     
     
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

   
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

   
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}
 
 
 
interface ERC721Metadata   {
     
    function name() external view returns (string _name);

     
    function symbol() external view returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}
 
 
 
interface ERC721Enumerable   {
     
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
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
 
 
 
 

 
contract ART is Ownable, ERC721, Pausable {
    string public name = "0x415254";
    string public symbol = "ART";    
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    event NewWork(uint workId, string title, uint8 red, uint8 green, uint8 blue, string _characterrand, uint _drawing);   
    
    string public code = "<a class="__cf_email__" data-cfemail="0172414d506b77" href="/cdn-cgi/l/email-protection">[email protected]</a>*35zl";
    string public compiler = "Pyth";
    uint16 public characterQuantity = 60;
    uint public randNonce = 0;

string[] public character = [" ","!","#","$","%","'","(",")","*","+",
                            ",","-",".","/","6","7","8","9",
                            ":",";","<","=",">","?","@","A","C","D","F","H","I",
                            "L","N","O","P","S","T","U","V","X","Y",
                            "[","]","^","_","`",
                            "c","l","n","o","p","q","s","v","x","y",
                            "{","|","}","~"];

struct Art {
      string title;
      uint8 red;
      uint8 green;
      uint8 blue;
      string characterRand;
      uint drawing;
      string series;
      uint16 mixCount;
      uint16 electCount;             
    }

    Art[] public works;

    mapping (uint => address) public workToOwner;
    mapping (address => uint) ownerWorkCount;

    function setCode(string _newCode, string _newCompiler ) external onlyOwner {
        code = _newCode;
        compiler = _newCompiler;
    }

    function setCharacter(string _value, uint16 _quantity ) external onlyOwner {
        character.push(_value); 
        characterQuantity = _quantity;
    }

    function _createWork(string _title, uint8 _red, uint8 _green, uint8 _blue, string _characterRand, uint _drawing, string _series) internal whenNotPaused {
        uint id = works.push(Art(_title, _red, _green, _blue, _characterRand, _drawing, _series, 0, 0)) - 1;
        workToOwner[id] = msg.sender;
        ownerWorkCount[msg.sender] = ownerWorkCount[msg.sender].add(1);
        emit NewWork(id, _title, _red, _green, _blue, _characterRand, _drawing); 
    }

    uint workFee = 0 ether;
    uint mixWorkFee = 0 ether;

    function withdraw() external onlyOwner {
        owner().transfer(address(this).balance);
    }

    function setUpFee(uint _feecreate, uint _feemix) external onlyOwner {
        workFee = _feecreate;
        mixWorkFee = _feemix;
    } 

    function _createString(string _title) internal returns (string) {
        uint a = uint(keccak256(abi.encodePacked(_title, randNonce))) % characterQuantity;  
        uint b = uint(keccak256(abi.encodePacked(msg.sender, randNonce))) % characterQuantity;       
        uint c = uint(keccak256(abi.encodePacked(_title, msg.sender, randNonce))) % characterQuantity;
        uint d = uint(keccak256(abi.encodePacked(_title, _title, randNonce))) % characterQuantity; 
        bytes memory characterRanda = bytes(abi.encodePacked(character[a]));
        bytes memory characterRandb = bytes(abi.encodePacked(character[b]));
        bytes memory characterRandc = bytes(abi.encodePacked(character[c]));
        bytes memory characterRandd = bytes(abi.encodePacked(character[d]));
        string memory characterRand = string (abi.encodePacked("'",characterRanda,"','", characterRandb,"','", characterRandc,"','", characterRandd,"'"));
        randNonce = randNonce.add(1);
        return characterRand;
    } 
    
    function createArt( string _title) external payable whenNotPaused {
        require(msg.value == workFee);    
        uint8 red = uint8(keccak256(abi.encodePacked(_title, randNonce))) % 255;
        uint8 green= uint8(keccak256(abi.encodePacked(msg.sender, randNonce))) % 255;
        uint8 blue = uint8(keccak256(abi.encodePacked(_title, msg.sender, randNonce))) % 255;
        uint drawing = uint(keccak256(abi.encodePacked(_title)));     
        string memory characterRand =  _createString(_title);
        string memory series  = "A";
        _createWork(_title, red, green, blue, characterRand, drawing, series);
    }

    function createCustom(string _title, uint8 _red, uint8 _green, uint8 _blue, string _characterRand ) external onlyOwner { 
       uint drawing = uint(keccak256(abi.encodePacked(_title)));
       string memory series  = "B";
      _createWork(_title, _red, _green, _blue, _characterRand, drawing, series);
    }

    modifier onlyOwnerOf(uint _workId) {
      require(msg.sender == workToOwner[_workId]);
      _;
    }

    function _blendString(string _str, uint _startIndex, uint _endIndex) private pure returns (string) {
        bytes memory strBytes = bytes(_str);
        bytes memory result = new bytes(_endIndex-_startIndex);
        for(uint i = _startIndex; i < _endIndex; i++) {
            result[i-_startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _joinString (string _chrctrRands, string   _chrctrRandi) private pure returns (string) {
        string memory characterRands = _blendString(_chrctrRands, 0, 8);
        string memory characterRandi = _blendString(_chrctrRandi, 0, 7);
        string memory result = string (abi.encodePacked(string(characterRands), string(characterRandi)));
        return string(result);
    }
     
    function _blendWork(string _title, uint _workId, uint _electRed , uint _electGreen , uint _electBlue, string _electCharacterRand, uint _electDrawing ) internal  onlyOwnerOf(_workId) {
        Art storage myWork = works[_workId];
        uint8 newRed = uint8(uint(myWork.red + _electRed) / 2);
        uint8 newGreen = uint8(uint(myWork.green + _electGreen) / 2);
        uint8 newBlue = uint8(uint(myWork.blue + _electBlue) / 2);       
        uint newDrawing = uint(myWork.drawing + _electDrawing + randNonce) / 2;
        string memory newCharacterRand = _joinString(myWork.characterRand, _electCharacterRand);      
        string memory series  = "C";
        _createWork(_title, newRed, newGreen, newBlue, newCharacterRand, newDrawing, series);
    }

    function blend(string _title, uint _workId, uint _electId) external  payable onlyOwnerOf(_workId) whenNotPaused {
        require(msg.value == mixWorkFee);
        Art storage myWork = works[_workId];
        Art storage electWork = works[_electId];
        myWork.mixCount = myWork.mixCount.add(1);
        electWork.electCount = electWork.electCount.add(1);
        _blendWork(_title, _workId, electWork.red, electWork.green, electWork.blue,  electWork.characterRand, electWork.drawing );
    }

    function getWorksByOwner(address _owner) external view returns(uint[]) {
        uint[] memory result = new uint[](ownerWorkCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < works.length; i++) {
          if (workToOwner[i] == _owner) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

      

    mapping (uint => address) workApprovals;

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerWorkCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return workToOwner[_tokenId];
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private validDestination(_to) {
        ownerWorkCount[_to] = ownerWorkCount[_to].add(1);
        ownerWorkCount[_from] = ownerWorkCount[_from].sub(1);
        workToOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) validDestination(_to) {
        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) validDestination(_to) {
        workApprovals[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(workApprovals[_tokenId] == msg.sender);
        address  owner = ownerOf(_tokenId);
        _transfer(owner, msg.sender, _tokenId);
    }

    function totalSupply() public view returns (uint) {
        return works.length - 1;
    }
}