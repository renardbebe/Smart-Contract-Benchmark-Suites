 

pragma solidity ^0.4.24;

 
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

pragma solidity ^0.4.24;

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

pragma solidity ^0.4.24;


 
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

pragma solidity ^0.4.24;

 
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

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

pragma solidity ^0.4.24;


 
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

pragma solidity ^0.4.24;






 
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

pragma solidity ^0.4.24;


 
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

pragma solidity ^0.4.24;




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

pragma solidity ^0.4.24;


 
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

pragma solidity ^0.4.24;




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
   
  string private _name;

   
  string private _symbol;

   
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

     
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return _name;
  }

   
  function symbol() external view returns (string) {
    return _symbol;
  }

   
  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

   
  function _setTokenURI(uint256 tokenId, string uri) internal {
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

pragma solidity ^0.4.24;




 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

pragma solidity ^0.4.24;



contract CryptoMotors is Ownable, ERC721Full {
    string public name = "CryptoMotors";
    string public symbol = "CM";
    
    event CryptoMotorCreated(address receiver, uint cryptoMotorId, string uri);
    event CryptoMotorTransferred(address from, address to, uint cryptoMotorId, string uri);
    event CryptoMotorUriChanged(uint cryptoMotorId, string uri);
    event CryptoMotorDnaChanged(uint cryptoMotorId, string dna);
     

    struct CryptoMotor {
        string dna;
        uint32 level;
        uint32 readyTime;
        uint32 winCount;
        uint32 lossCount;
        address designerWallet;
    }

    CryptoMotor[] public cryptoMotors;

    constructor() ERC721Full(name, symbol) public { }

     
    function create(address owner, string _uri, string _dna, address _designerWallet) public onlyOwner returns (uint) {
        uint id = cryptoMotors.push(CryptoMotor(_dna, 1, uint32(now + 1 days), 0, 0, _designerWallet)) - 1;
        _mint(owner, id);
        _setTokenURI(id, _uri);
        emit CryptoMotorCreated(owner, id, _uri);
        return id;
    }

    function setTokenURI(uint256 _cryptoMotorId, string _uri) public onlyOwner {
        _setTokenURI(_cryptoMotorId, _uri);
        emit CryptoMotorUriChanged(_cryptoMotorId, _uri);
    }
    
    function setCryptoMotorDna(uint _cryptoMotorId, string _dna) public onlyOwner {
        CryptoMotor storage cm = cryptoMotors[_cryptoMotorId];
        cm.dna = _dna;
        emit CryptoMotorDnaChanged(_cryptoMotorId, _dna);
    }

    function setAttributes(uint256 _cryptoMotorId, uint32 _level, uint32 _readyTime, uint32 _winCount, uint32 _lossCount) public onlyOwner {
        CryptoMotor storage cm = cryptoMotors[_cryptoMotorId];
        cm.level = _level;
        cm.readyTime = _readyTime;
        cm.winCount = _winCount;
        cm.lossCount = _lossCount;
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

     
    function getDesignerWallet(uint256 _cryptoMotorId) public view returns (address) {
        return cryptoMotors[_cryptoMotorId].designerWallet;
    }

    function setApprovalsForAll(address[] _addresses, bool approved) public {
        for(uint i; i < _addresses.length; i++) {
            setApprovalForAll(_addresses[i], approved);
        }
    }

}

pragma solidity ^0.4.24;



contract CryptoMotorsMarketV1 is Ownable {
    
    CryptoMotors token;

    event CryptoMotorForSale(uint cryptoMotorId, uint startPrice, uint endPrice, uint duration, address seller);
    event CryptoMotorSold(uint cryptoMotorId, uint priceSold, address seller, address buyer);
    event CryptoMotorSaleCancelled(uint cryptoMotorId, address seller);
    event CryptoMotorSaleFinished(uint cryptoMotorId, address seller);
    event CryptoMotorGift(uint cryptoMotorId, address from, address to);
    
     
    uint8 SECONDS_PER_BLOCK = 15;

    uint16 public ownerCutPercentage;
    uint16 public designerCutPercentage;
    
    mapping (uint => Sale) cryptoMotorToSale;

    struct Sale {
        address seller;
        uint cryptoMotorId;
        uint startPrice;
        uint endPrice;
        uint startBlock;
        uint endBlock;
        uint duration;
        bool exists;
    }

    constructor(address _cryptoMotorsToken) public { 
        token = CryptoMotors(_cryptoMotorsToken);
    }

     

    modifier cryptoMotorForSale(uint _cryptoMotorId) {
        require(cryptoMotorToSale[_cryptoMotorId].exists == true, "The car is not for auction");
        _;
    }

    modifier cryptoMotorNotForSale(uint _cryptoMotorId) {
        require(cryptoMotorToSale[_cryptoMotorId].exists == false, "The car is on auction");
        _;
    }

    function setOwnerCut(uint16 _ownerCutPercentage) public onlyOwner {
        ownerCutPercentage = _ownerCutPercentage;
    }

    function setDesignerCut(uint16 _designerCutPercentage) public onlyOwner {
        designerCutPercentage = _designerCutPercentage;
    }

    function sendGift(uint _cryptoMotorId, address _account) public cryptoMotorNotForSale(_cryptoMotorId) {
        require(token.isApprovedForAll(msg.sender, address(this)), "This contract needs approval from the owner to operate with his cars");
        require(token.ownerOf(_cryptoMotorId) == msg.sender, "Only the owner can send the car as a gift");
        token.safeTransferFrom(msg.sender, _account, _cryptoMotorId);
        emit CryptoMotorGift(_cryptoMotorId, msg.sender, _account);
    }

     
    function createSale(uint _cryptoMotorId, uint _startPrice, uint _endPrice, uint _duration) public cryptoMotorNotForSale(_cryptoMotorId) {
        require(token.isApprovedForAll(msg.sender, address(this)), "This contract needs approval from the owner to operate with his cars");
        require(token.ownerOf(_cryptoMotorId) == msg.sender, "Only the owner can create an auction for the car");

        if (_startPrice > _endPrice) {
            require(_endPrice >= 10000000000000, "Minimum end price must be above 10000000000000 wei");
        } else {
            require(_startPrice >= 10000000000000, "Minimum start price must be above 10000000000000 wei");
        }

        if (_duration != 0 || _startPrice != _endPrice) {
            require(_duration >= 86400 && _duration <= 7776000, "Auction duration must be between 1 and 90 days");
        }

        Sale storage sale = cryptoMotorToSale[_cryptoMotorId];
        sale.seller = msg.sender;
        sale.cryptoMotorId = _cryptoMotorId;
        sale.startPrice = _startPrice;
        sale.endPrice = _endPrice;
        sale.startBlock = block.number;
        sale.endBlock = block.number + (_duration / SECONDS_PER_BLOCK);
        sale.duration = _duration;
        sale.exists = true;

        emit CryptoMotorForSale(_cryptoMotorId, _startPrice, _endPrice, _duration, msg.sender);
    }

    function buy(uint _cryptoMotorId) public payable cryptoMotorForSale(_cryptoMotorId) {
        Sale storage sale = cryptoMotorToSale[_cryptoMotorId];
        
        require(msg.sender != sale.seller, "Cant bid on your own sale");

        if (sale.duration != 0) {
            require(block.number > sale.startBlock && block.number < sale.endBlock, "Sale has finished already");
        }

        uint256 price = _currentPrice(sale);
        address seller = sale.seller;

        require(msg.value >= price, "Ether sent is not enough for the current price");
        
        uint256 sellerCut = msg.value;

        delete cryptoMotorToSale[_cryptoMotorId];

        if (sale.startPrice == sale.endPrice && msg.value > price) {
            uint refund = msg.value - price;
            sellerCut = price;
            msg.sender.transfer(refund);
        }

        if (seller == owner()) {
            address designerWallet = token.getDesignerWallet(_cryptoMotorId);
            uint256 designerCut = sellerCut * designerCutPercentage / 10000;
            designerWallet.transfer(designerCut);
        } else {
            uint256 ownerCut = sellerCut * ownerCutPercentage / 10000;
            sellerCut = sellerCut - ownerCut;
            seller.transfer(sellerCut);
        }

        token.safeTransferFrom(seller, msg.sender, _cryptoMotorId);
        
        emit CryptoMotorSold(_cryptoMotorId, msg.value, seller, msg.sender);
    }

    function _currentPrice(Sale storage _sale) internal view returns (uint256) {
        if (_sale.startPrice == _sale.endPrice) {
            return _sale.startPrice;
        }

        uint256 secondsPassed = 0;

        if (block.number > _sale.startBlock) {
            secondsPassed = (block.number - _sale.startBlock) * SECONDS_PER_BLOCK;
        }

        int256 priceChange = (int256(_sale.endPrice) - int256(_sale.startPrice)) * int256(secondsPassed) / int256(_sale.duration);
        
        return uint256(int256(_sale.startPrice) + priceChange);
    }

    function getCurrentPrice(uint _cryptoMotorId) public cryptoMotorForSale(_cryptoMotorId) view returns (uint256) {
        return _currentPrice(cryptoMotorToSale[_cryptoMotorId]);
    }

    function finishSale(uint _cryptoMotorId) public cryptoMotorForSale(_cryptoMotorId) {
        require(token.ownerOf(_cryptoMotorId) == msg.sender, "Only the owner can finish the sale");
        Sale memory sale = cryptoMotorToSale[_cryptoMotorId];
        require(block.number > sale.endBlock, "Sale has not finished yet");
        delete cryptoMotorToSale[_cryptoMotorId];
        emit CryptoMotorSaleFinished(_cryptoMotorId, msg.sender);
    }

    function cancelSale(uint _cryptoMotorId) public cryptoMotorForSale(_cryptoMotorId) {
        require(token.ownerOf(_cryptoMotorId) == msg.sender, "Only the owner can cancel the sale");
        Sale memory sale = cryptoMotorToSale[_cryptoMotorId];
        require(block.number > sale.startBlock && block.number < sale.endBlock, "Sale has finished already");
        delete cryptoMotorToSale[_cryptoMotorId];
        emit CryptoMotorSaleCancelled(_cryptoMotorId, msg.sender);
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

     
    function _changeStartBlock(uint _cryptoMotorId, uint _startBlock) public onlyOwner {
        Sale storage sale = cryptoMotorToSale[_cryptoMotorId];
        sale.startBlock = _startBlock;
    }
    
    function _changeEndBlock(uint _cryptoMotorId, uint _endBlock) public onlyOwner {
        Sale storage sale = cryptoMotorToSale[_cryptoMotorId];
        sale.endBlock = _endBlock;
    }
     
}