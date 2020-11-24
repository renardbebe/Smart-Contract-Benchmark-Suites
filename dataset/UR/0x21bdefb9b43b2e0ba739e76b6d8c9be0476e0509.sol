 

pragma solidity ^0.5.3;

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

library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract AccessControl is Ownable, Pausable {

     
    address payable public ceoAddress;
    address payable public cfoAddress;
    address payable public cooAddress;
    address payable public cmoAddress;
    address payable public BAEFeeAddress;
    address payable public owner = msg.sender;

     
    modifier onlyCEO() {
        require(
            msg.sender == ceoAddress,
            "Only our CEO address can execute this function");
        _;
    }

     
    modifier onlyCFO() {
        require(
            msg.sender == cfoAddress,
            "Only our CFO can can ll this function");
        _;
    }

     
    modifier onlyCOO() {
        require(
            msg.sender == cooAddress,
            "Only our COO can can ll this function");
        _;
    }

     
    modifier onlyCLevelOrOwner() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == owner,
            "You need to be the owner or a Clevel @BAE to call this function"
        );
        _;
    }
    

     
     
    function setCEO(address payable _newCEO) external onlyCEO whenNotPaused {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address payable _newCFO) external onlyCLevelOrOwner whenNotPaused {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address payable _newCOO) external onlyCLevelOrOwner whenNotPaused {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }
      
     
    function setCMO(address payable _newCMO) external onlyCLevelOrOwner whenNotPaused {
        require(_newCMO != address(0));
        cmoAddress = _newCMO;
    }

    function getBAEFeeAddress() external view onlyCLevelOrOwner returns (address) {
        return BAEFeeAddress;
    }

    function setBAEFeeAddress(address payable _newAddress) public onlyCLevelOrOwner {
        BAEFeeAddress = _newAddress;
    }

     
    function pause() public onlyCLevelOrOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyCLevelOrOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract Destructible is AccessControl {

     
    function destroy() public onlyCLevelOrOwner whenPaused{
        selfdestruct(owner);
    }

     
    function destroyAndSend(address payable _recipient) public onlyCLevelOrOwner whenPaused {
        selfdestruct(_recipient);
    }
}

contract ArtShop is Destructible {
    using SafeMath for uint256;

     
    event NewArtpiece(uint pieceId, string  name, string artist);
     
    event UrlChange(uint pieceId);

     
     
    uint8 internal baeFeeLevel;
    uint8 internal royaltyFeeLevel;
    uint8 internal potFeeLevel = 5;

     
    uint32 public timeUntilAbleToTransfer = 1 hours;

     
     
     
    struct ArtpieceMetaData {
        uint8 remainingPrintings;
        uint64 basePrice;  
        uint256 dateCreatedByTheArtist;
        string notes;
        bool isFirstSale;
        bool physical;
    }

     
    struct Artpiece {
        string name;  
        string artist;  
        string thumbnailUrl;
        string mainUrl;
        string grade;
        uint64 price;  
        uint8 feeLevel;  
        uint8 baeFeeLevel;
        ArtpieceMetaData metadata;
    }

    Artpiece[] artpieces;

    mapping (uint256 => address) public numArtInAddress;
    mapping (address => uint256) public artCollection;
    mapping (uint256 => address) public artpieceApproved;

     
    modifier onlyWithGloballySetFee() {
        require(
            baeFeeLevel > 0,
            "Requires a fee level to be set up"
        );
        require(
            royaltyFeeLevel > 0,
            "Requires a an artist fee level to be set up"
        );
        _;
    }

     
     
    function setBAEFeeLevel(uint8 _newFee) public onlyCLevelOrOwner {
        baeFeeLevel = _newFee;
    }

    function setRoyaltyFeeLevel(uint8 _newFee) public onlyCLevelOrOwner {
        royaltyFeeLevel = _newFee;
    }
    
    function _createArtpiece(
        string memory _name,
        string memory _artist,
        string memory _thumbnailUrl,
        string memory _mainUrl,
        string memory _notes,
        string memory _grade,
        uint256 _dateCreatedByTheArtist,
        uint64 _price,
        uint64 _basePrice,
        uint8 _remainingPrintings,
        bool _physical
        )  
        internal
        onlyWithGloballySetFee
        whenNotPaused
        {
        
        ArtpieceMetaData memory metd = ArtpieceMetaData(
                _remainingPrintings,
                _basePrice,
                _dateCreatedByTheArtist,
                _notes,
                true,
                _physical
        ); 
            
        Artpiece memory newArtpiece = Artpiece(
            _name,
            _artist,
            _thumbnailUrl,
            _mainUrl,
            _grade,
            _price,
            royaltyFeeLevel,
            baeFeeLevel,
            metd
        );
        uint id = artpieces.push(newArtpiece) - 1;

        numArtInAddress[id] = msg.sender;
        artCollection[msg.sender] = artCollection[msg.sender].add(1);
            
        emit NewArtpiece(id, _name, _artist);
    }
}

contract Helpers is ArtShop {
    
         
    modifier onlyOwnerOf(uint _artpieceId) {
        require(msg.sender == numArtInAddress[_artpieceId]);
        _;
    }
    
     
     
    modifier onlyBeforeFirstSale(uint _tokenId) {
        (,,,,bool isFirstSale,) = getArtpieceMeta(_tokenId);
        require(isFirstSale == true);
        _;
    }

    event Printed(uint indexed _id, uint256 indexed _time);
    
    function getArtpieceData(uint _id) public view returns(string memory name, string memory artist, string memory thumbnailUrl, string memory grade, uint64 price) {
        return (
            artpieces[_id].name, 
            artpieces[_id].artist, 
            artpieces[_id].thumbnailUrl, 
            artpieces[_id].grade,
            artpieces[_id].price 
        );
    }
    
    function getArtpieceFeeLevels(uint _id) public view returns(uint8, uint8) {
        return (
            artpieces[_id].feeLevel,
            artpieces[_id].baeFeeLevel
        );
    }
    
    function getArtpieceMeta(uint _id) public view returns(uint8, uint64, uint256, string memory, bool, bool) {
        return (
            artpieces[_id].metadata.remainingPrintings, 
            artpieces[_id].metadata.basePrice, 
            artpieces[_id].metadata.dateCreatedByTheArtist, 
            artpieces[_id].metadata.notes, 
            artpieces[_id].metadata.isFirstSale, 
            artpieces[_id].metadata.physical
        );
    }
    
    function getMainUrl(uint _id) public view onlyOwnerOf(_id) returns(string memory) {
        return artpieces[_id].mainUrl;
    }

    function setArtpieceName(uint _id, string memory _name) public onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].name = _name;
    }

    function setArtist(uint _id, string memory _artist) public onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].artist = _artist;
    }

    function setThumbnailUrl(uint _id, string memory _newThumbnailUrl) public onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].thumbnailUrl = _newThumbnailUrl;
    }

     
    function setMainUrl(uint _id, string memory _newUrl) public onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].mainUrl = _newUrl;
        emit UrlChange(_id);
    }

    function setGrade(uint _id, string memory _grade) public onlyCLevelOrOwner whenNotPaused returns (bool success) {
        artpieces[_id].grade = _grade;
        return true;
    }

    function setPrice(uint _id, uint64 _price) public onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].price = _price;
    }

    function setArtpieceBAEFee(uint _id, uint8 _newFee) public onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].baeFeeLevel = _newFee;
    }

    function setArtpieceRoyaltyFeeLevel(uint _id, uint8 _newFee) public onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].feeLevel = _newFee;
    }

    function setRemainingPrintings(uint _id, uint8 _remainingPrintings) internal onlyCLevelOrOwner whenNotPaused {
        artpieces[_id].metadata.remainingPrintings = _remainingPrintings;
    }
    
    function setBasePrice(uint _id, uint64 _basePrice) public onlyCLevelOrOwner {
        artpieces[_id].metadata.basePrice = _basePrice;
    }

    function setDateCreateByArtist(uint _id, uint256 _dateCreatedByTheArtist) public onlyCLevelOrOwner {
        artpieces[_id].metadata.dateCreatedByTheArtist = _dateCreatedByTheArtist;
    }

    function setNotes(uint _id, string memory _notes) public onlyCLevelOrOwner {
        artpieces[_id].metadata.notes = _notes;
    }

    function setIsPhysical(uint _id, bool _physical) public onlyCLevelOrOwner {
        artpieces[_id].metadata.physical = _physical;
    }
    
    function getArtpiecesByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](artCollection[_owner]);
        uint counter = 0;

        for ( uint i = 0; i < artpieces.length; i++ ) {
            if (numArtInAddress[i] == _owner) {
                result[counter] = i;
                counter = counter.add(1);
            }
        }

        return result;
    }
}

contract BAEToken is PausableToken, AccessControl  {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);
   
    string public constant name = "BAEToken";
    string public constant symbol = "BAE";
    uint public constant decimals = 6;
    uint public currentAmount = 0;  
    uint public totalAllocated = 0;
    bool public mintingFinished = false;
    uint256 public currentIndex = 0;

     
    mapping(uint => address) public holderAddresses;

     
    constructor() public {
        totalSupply_ = 0;
    }

    modifier validDestination(address _to)
    {
        require(_to != address(0x0));
        require(_to != address(this)); 
        _;
    }

    modifier canMint() {
        require(
            !mintingFinished,
            "Still minting."
        );
        _;
    }

    modifier hasMintPermission() {
        require(
            msg.sender == owner,
            "Message sender is not owner."
        );
        _;
    }

    modifier onlyWhenNotMinting() {
        require(
            mintingFinished == false,
            "Minting needs to be stopped to execute this function"
        );
        _;
    }

     
    function getName() public pure returns (string memory) {
        return name;
    }

     
    function getSymbol() public pure returns (string memory) {
        return symbol;
    }

     
    function getTotalSupply() public view returns (uint) {
        return totalSupply_;
    }

     
    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

     
    function getUserBalance(address _userAddress) public view onlyCLevelOrOwner returns(uint) {
        return balances[_userAddress];
    }
    
     
    function burn(address _who, uint256 _value) public onlyCEO whenNotPaused {
        require(
            _value <= balances[_who],
            "Value is smaller than the value the account in balances has"
        );
         
         

         
        totalSupply_ = totalSupply_.sub(_value);
        totalAllocated = totalAllocated.sub(_value);
        balances[_who] = balances[_who].sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

     
    function mint(
        address _to,
        uint256 _amount
    )
    public
    canMint
    onlyCLevelOrOwner
    whenNotPaused
    returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        totalAllocated = totalAllocated.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() 
    public 
    onlyCEO
    canMint
    whenNotPaused
    returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }


     
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
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
    bytes memory data
  )
    public;
}

contract IERC721Metadata is IERC721 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 tokenId) public view returns (string memory);
}

contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  )
    public
    returns(bytes4);
}

contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
}

contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal _supportedInterfaces;

   
  constructor()
    public
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
    bytes memory _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
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

   
  function _clearApproval(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
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

   
  function _checkAndCallSafeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
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
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
   
  string internal _name;

   
  string internal _symbol;

   
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

     
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string memory) {
    return _name;
  }

   
  function symbol() external view returns (string memory) {
    return _symbol;
  }

   
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

   
  function _setTokenURI(uint256 tokenId, string memory uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
   
  mapping(address => uint256[]) private _ownedTokens;

   
  mapping(uint256 => uint256) private _ownedTokensIndex;

   
  uint256[] private _allTokens;

   
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
   

   
  constructor() public {
     
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

   
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

   
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

   
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

     
     
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
     
    _ownedTokens[from].length--;

     
     
     

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
    }
}

contract BAE is ERC721Full, Helpers {
    using SafeMath for uint256;

     
    event Sold(uint indexed _tokenId, address _from, address _to, uint indexed _price);
    event Deleted(uint indexed _tokenId, address _from);
    event PaymentsContractChange(address _prevAddress, address _futureAddress);
    event AuctionContractChange(address _prevAddress, address _futureAddress);

    Payments public tokenInterface;
    mapping (uint => address) artTransApprovals;

   constructor() ERC721Full("BlockchainArtExchange", "BAE") public {}
    
     
    function setPaymentAddress(address payable _newAddress) public onlyCEO whenPaused {
        Payments tokenInterfaceCandidate = Payments(_newAddress);
        tokenInterface = tokenInterfaceCandidate;
    }

  function createArtpiece(
        string memory _name,
        string memory _artist,
        string memory _thumbnailUrl,
        string memory _mainUrl,
        string memory _notes,
        string memory _grade,
        uint256 _dateCreatedByTheArtist,
        uint64 _price,
        uint64 _basePrice,
        uint8 _remainingPrintings,
        bool _physical
    ) 
      public 
    {
        super._createArtpiece(_name, _artist, _thumbnailUrl, _mainUrl, _notes, _grade, _dateCreatedByTheArtist, _price, _basePrice, _remainingPrintings, _physical);
        
        _mint(msg.sender, artpieces.length - 1);
    }
  
    function calculateFees(uint _tokenId) public payable whenNotPaused returns (uint baeFee, uint royaltyFee, uint potFee) {
         
        uint baeFeeAmount = (uint(artpieces[_tokenId].baeFeeLevel) * msg.value) / 100;
        uint artistFeeAmount = (uint(artpieces[_tokenId].feeLevel) * msg.value) / 100;

         
        uint potFeeAmount = msg.value - (baeFeeAmount + artistFeeAmount);
        return (baeFeeAmount, artistFeeAmount, potFeeAmount);
    }

     
    function payFees(uint256 _baeFee, uint256 _royaltyFee, uint256 _potFee, address payable _seller) public payable whenNotPaused {
        uint totalToPay = _baeFee + _royaltyFee + _potFee;
        require(
            msg.value >= totalToPay,
            "Value must be equal or greater than the cost of the fees"
        );

        BAEFeeAddress.transfer(msg.value.sub(_baeFee));
        _seller.transfer(msg.value.sub(_royaltyFee));

         
        address(tokenInterface).transfer(msg.value);
    }
    
     
    function _postPurchase(address _from, address _to, uint256 _tokenId) internal {
        artCollection[_to] = artCollection[_to].add(1);
        artCollection[_from] = artCollection[_from].sub(1);
        numArtInAddress[_tokenId] = _to;

        if (artpieces[_tokenId].metadata.isFirstSale) {
            artpieces[_tokenId].feeLevel = uint8(96);
            artpieces[_tokenId].baeFeeLevel = uint8(3);
             
        }
        
         
        artpieces[_tokenId].metadata.isFirstSale = false;

        emit Sold(_tokenId, _from, _to, artpieces[_tokenId].price);
    }
    
    
     
    function deleteArtpiece(uint256 _tokenId) public onlyCLevelOrOwner whenNotPaused onlyBeforeFirstSale(_tokenId) returns (bool deleted) {
        address _from = numArtInAddress[_tokenId];
        delete numArtInAddress[_tokenId];
        artCollection[_from] = artCollection[_from].sub(1);
        _burn(_from, _tokenId);
        delete artpieces[_tokenId];
        emit Deleted(_tokenId, _from);
        return true;
    }

     
    function pause() public onlyCEO whenNotPaused {
        super.pause();
    }
}

contract PerishableSimpleAuction is Destructible {
    using SafeMath for uint256;

    event AuctionCreated(uint id, address seller);
    event AuctionWon(uint tokenId, address _who);
    event SellerPaid(bool success, uint amount);
    
    BAECore public baeInstance;
    bool private currentAuction;

    struct Auction {
        uint256 tokenId;
        uint256 startingPrice;
        uint256 finalPrice;
        address payable seller;
        uint8 paid;
    }

     
     
    mapping (uint => address) public winners;

     
    mapping (uint256 => Auction) public tokenIdToAuction;
    mapping (uint256 => uint256) public tokendIdToAuctionId;

     
    Auction[20] public auctions;

     
    uint public idx = 0;

     
    uint256 public baeAuctionFee = 0.01 ether;

    modifier onlyAuctionOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAuctionLord() {
        require(msg.sender == address(baeInstance));
        _;
    }
    
    constructor() public {
        paused = true;
        ceoAddress = msg.sender;
    }
    
    function setIsCurrentAuction(bool _current) external onlyCEO {
        currentAuction = _current;
    }
    
     
     
    function setBAEAddress(address payable _newAddress) public onlyAuctionOwner whenPaused {
        address currentInstance = address(baeInstance);
        BAECore candidate = BAECore(_newAddress);
        baeInstance = candidate;
        require(address(baeInstance) != address(0) && address(baeInstance) != currentInstance);
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _finalPrice,
        address payable _seller
    )
        external
        whenNotPaused
        onlyAuctionLord
    {
        if (tokendIdToAuctionId[_tokenId] != 0) {
            require(tokenIdToAuction[_tokenId].paid == 1);
        }
        require(idx <= 20);
        
        Auction memory newAuction = Auction(_tokenId, _startingPrice, _finalPrice, _seller, 0);
        auctions[idx] = newAuction;
        tokenIdToAuction[_tokenId] = newAuction; 
        tokendIdToAuctionId[_tokenId] = idx;
        idx = idx.add(1);
        
        emit AuctionCreated(idx,  _seller);
    }

     
    function hasWon(uint256 _auctionId, address _winner, uint256 _finalBidPrice) external whenNotPaused onlyAuctionLord {
        winners[auctions[_auctionId].tokenId] = _winner;
        auctions[_auctionId].finalPrice = _finalBidPrice;
        emit AuctionWon(auctions[_auctionId].tokenId, _winner);
    }

    function winnerCheckWireDetails(uint _auctionId, address _sender) external view whenNotPaused returns(address payable, uint, uint) {
         
        uint finalPrice = auctions[_auctionId].finalPrice;
        uint tokenId = auctions[_auctionId].tokenId;
        address winnerAddress = winners[tokenId];
        address payable seller = auctions[_auctionId].seller;

         
        require(_sender == winnerAddress);
        return (seller, tokenId, finalPrice);
    }
    
    function setPaid(uint _auctionId) external whenNotPaused onlyAuctionLord {
        require(auctions[_auctionId].paid == 0);
        auctions[_auctionId].paid = 1;
        emit SellerPaid(true, auctions[_auctionId].finalPrice);
    }
    
     
    function getAuctionWinnerAddress(uint _auctionId) external view whenNotPaused returns(address)  {
        return winners[auctions[_auctionId].tokenId];
    }
    
    function getFinalPrice(uint _auctionId) external view whenNotPaused returns(uint)  {
        return auctions[_auctionId].finalPrice;
    }

    function getAuctionDetails(uint _auctionId) external view whenNotPaused returns (uint, uint, uint, address, uint) {
        return (auctions[_auctionId].tokenId, auctions[_auctionId].startingPrice, auctions[_auctionId].finalPrice, auctions[_auctionId].seller, auctions[_auctionId].paid);
    }
    
    function getCurrentIndex() external view returns (uint) {
        uint val = idx - 1;
                
        if (val > 20) {
            return 0;
        }
        
        return val;
    }
    
    function getTokenIdToAuctionId(uint _tokenId) external view returns (uint) {
        return tokendIdToAuctionId[_tokenId];
    }
    
    function unpause() public onlyAuctionOwner whenPaused {
        require(address(baeInstance) != address(0));

        super.unpause();
    }
    
    function () external payable {
        revert();
    }
}

contract BAECore is BAE {
      using SafeMath for uint256;
 
     
    PerishableSimpleAuction private instanceAuctionAddress;
    
    constructor() public {
        paused = true;
        ceoAddress = msg.sender;
    }

    function setAuctionAddress(address payable _newAddress) public onlyCEO whenPaused {
        PerishableSimpleAuction possibleAuctionInstance = PerishableSimpleAuction(_newAddress);
        instanceAuctionAddress = possibleAuctionInstance;
    }
    
     
    function createAuction(uint _tokenId, uint _startingPrice, uint _finalPrice) external whenNotPaused {
        require(ownerOf( _tokenId) == msg.sender, "You can't transfer an artpiece which is not yours");
        require(_startingPrice >= artpieces[_tokenId].metadata.basePrice);
        instanceAuctionAddress.createAuction(_tokenId, _startingPrice,_finalPrice, msg.sender);
        
         
        setApprovalForAll(owner, true);
        setApprovalForAll(ceoAddress, true);
        setApprovalForAll(cfoAddress, true);
        setApprovalForAll(cooAddress, true);
    }
    
    function getAuctionDetails(uint _auctionId) public view returns (uint) {
        (uint tokenId,,,,) = instanceAuctionAddress.getAuctionDetails(_auctionId);
        return tokenId;
    }
    
     
    function setWinnerAndPrice(uint256 _auctionId, address _winner, uint256 _finalPrice, uint256 _currentPrice) external onlyCLevelOrOwner whenNotPaused returns(bool hasWinnerInfo) 
    {   
        (uint tokenId,,,,) = instanceAuctionAddress.getAuctionDetails(_auctionId);
        require(_finalPrice >= uint256(artpieces[tokenId].metadata.basePrice));
        approve(_winner, tokenId);
        instanceAuctionAddress.hasWon(_auctionId, _winner, _finalPrice);
        tokenInterface.setFinalPriceInPounds(_currentPrice);
        return true;
    }
    
    function calculateFees(uint _tokenId, uint _fullAmount) internal view  whenNotPaused returns (uint baeFee, uint royaltyFee, uint potFee) {
         
        uint baeFeeAmount = (uint(artpieces[_tokenId].baeFeeLevel) * _fullAmount) / 100;
        uint artistFeeAmount = (uint(artpieces[_tokenId].feeLevel) * _fullAmount) / 100;

         
        uint potFeeAmount = _fullAmount - (baeFeeAmount + artistFeeAmount);
        return (baeFeeAmount, artistFeeAmount, potFeeAmount);
    }

    function payAndWithdraw(uint _auctionId) public payable {
         
        (address payable seller, uint tokenId, uint finalPrice) = instanceAuctionAddress.winnerCheckWireDetails(_auctionId, msg.sender);
        (uint baeFeeAmount, uint artistFeeAmount,) = calculateFees(tokenId, finalPrice);
        
         
        require(msg.value >= finalPrice);
        uint baeFee = msg.value.sub(baeFeeAmount);
        uint artistFee = msg.value.sub(artistFeeAmount);
        
         
        BAEFeeAddress.transfer(msg.value.sub(baeFee));
        seller.transfer(msg.value.sub(artistFee));
        address(tokenInterface).transfer(address(this).balance);
        
         
        instanceAuctionAddress.setPaid(_auctionId);
        
         
        transferFrom(seller, msg.sender, tokenId);
    }
    
    function getWinnerAddress(uint _auctionId) public view returns(address)  {
        return instanceAuctionAddress.getAuctionWinnerAddress(_auctionId);
    }
    
    function getHighestBid(uint _auctionId) public view returns(uint)  {
        return instanceAuctionAddress.getFinalPrice(_auctionId);
    }
    
    function getLatestAuctionIndex() public view returns(uint) {
        return instanceAuctionAddress.getCurrentIndex();
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        uint auctionId = instanceAuctionAddress.getTokenIdToAuctionId(_tokenId);
        (,,,,uint paid) = (instanceAuctionAddress.getAuctionDetails(auctionId));
        require(paid == 1);
        super.transferFrom(_from, _to, _tokenId);
        _postPurchase(_from, _to, _tokenId);
        
         
        tokenInterface.addToBAEHolders(_from);
    }
    
    function unpause() public onlyCEO whenPaused {
        require(ceoAddress != address(0));
        require(address(instanceAuctionAddress) != address(0));
        require(address(tokenInterface) != address(0));
        require(address(BAEFeeAddress) != address(0));

        super.unpause();
    }
    
     
    function pause() public onlyCEO whenNotPaused {
        super.pause();
    }
    
    function () external payable {}
}