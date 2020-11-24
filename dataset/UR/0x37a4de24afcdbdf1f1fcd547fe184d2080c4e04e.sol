 

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

 

 
interface IERC165 {

   
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

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

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

 

 
contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

 

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

 

 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

 

contract Referrers is Ownable {
    using SafeMath for uint256;

     
    uint public referrerBonusSale;
    uint public referrerBonusWin;
    uint public _referrerId;
     
    mapping(uint => address) public referrerToAddress;
     
    mapping(uint => uint) public ticketToReferrer;
     
    mapping(uint => uint[]) public referrerTickets;
     
    mapping(address => uint) public addressToReferrer;
    mapping(uint => uint) public totalEarnReferrer;

    constructor() public {
        referrerBonusSale = 8;
        referrerBonusWin = 2;
        _referrerId = 0;
    }

    function _setTicketReferrer(uint _tokenId, uint _referrer) internal {
        require(ticketToReferrer[_tokenId] == 0);
        ticketToReferrer[_tokenId] = _referrer;
        referrerTickets[_referrer].push(_tokenId);
    }

    function registerReferrer() public {
        require(addressToReferrer[msg.sender] == 0);
        _referrerId = _referrerId.add(1);
        addressToReferrer[msg.sender] = _referrerId;
        referrerToAddress[_referrerId] = msg.sender;
    }

    function getReferrerTickets(uint _referrer) public view returns (uint[]) {
        return referrerTickets[_referrer];
    }

     
    function setReferrerBonusWin(uint _amount) public onlyOwner {
        referrerBonusWin = _amount;
    }

    function setReferrerBonusSale(uint _amount) public onlyOwner {
        referrerBonusSale = _amount;
    }
     
}

 

library Utils {
    function pack(uint[] _data) internal pure returns(uint) {
        uint result = 0;
        for (uint i=0;i<_data.length;i++) {
            result += 2**_data[i];
        }
        return result;
    }

    function unpack(uint _data, uint _maxBallsCount) internal pure returns(uint[]) {
        uint[] memory result = new uint256[](_maxBallsCount);
        uint iPosition = 0;
        uint i = 0;
        while (_data != 0) {
            if ((_data & 1) == 1) {
                result[iPosition] = i;
                iPosition++;
            }
            i++;
            _data >>= 1;
        }
        return result;
    }

    function popcount(uint x) public pure returns(uint) {
        uint count;
        for (count=0; x > 0; count++) {
            x &= x - 1;
        }
        return count;
    }

    function getBonusAmount(uint _amount, uint _bonusPercent) internal pure returns (uint) {
        return _amount * _bonusPercent / 100;
    }

    function addr2str(address _addr) internal pure returns(string) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}

 

library Balance {
    using SafeMath for uint256;

    struct BalanceStorage {
         
        mapping(address => uint) balances;
        mapping(address => uint) totalEarn;
    }

     
    function _addBalance(BalanceStorage storage self, address _address, uint _amount) internal {
        self.balances[_address] = self.balances[_address].add(_amount);
        self.totalEarn[_address] = self.totalEarn[_address].add(_amount);
    }

    function _subBalance(BalanceStorage storage self, address _address, uint _amount) internal {
        self.balances[_address] = self.balances[_address].sub(_amount);
        self.totalEarn[_address] = self.totalEarn[_address].sub(_amount);
    }

    function _clearBalance(BalanceStorage storage self, address _address) internal {
        self.balances[_address] = 0;
    }

    function _getBalance(BalanceStorage storage self, address _address) internal view returns (uint){
        return self.balances[_address];
    }

    function _getTotalEarn(BalanceStorage storage self, address _address) internal view returns (uint){
        return self.totalEarn[_address];
    }
}

 

 
pragma solidity ^0.4.25;







contract DrawContractI {
    function ticketToDraw(uint _tokenId) public returns (uint);
    function drawNumber() public returns (uint);
    function drawTime(uint _drawNumber) public returns (uint);
    function ticketPrizes(uint _tokenId) public returns (uint);
    function registerTicket(uint _tokenId, uint[] _numbers, uint _ticketPrice, uint _ownerBonusSale, uint _referrerBonusSale, uint _drawNumber) external;
    function checkTicket(uint _tokenId) external;
    function addSuperPrize(uint _amount) external;
}

contract CryptoBall645 is ERC721Full("Crypto balls 6/45", "B645"), Ownable, Referrers {
    using Balance for Balance.BalanceStorage;
    Balance.BalanceStorage balance;

    event OwnerBonus(address indexed _to, uint _amount);
    event ReferrerBonus(address indexed _to, uint _amount);

    using SafeMath for uint256;

    uint constant public MAX_BALLS_COUNT = 6;
    uint constant public MAX_BALL_NUMBER = 45;

     
    uint public ownerBonusSale = 25;
    uint public ownerBonusWin = 0;

    uint public ticketPrice = 0.01 ether;

    uint public tokenIds = 0;
    mapping(uint => uint) public mintDate;

    DrawContractI drawContract;
    address public drawContractAddress;

    modifier onlyDrawContract() {
        require(msg.sender == drawContractAddress);
        _;
    }

    modifier allowBuyTicket() {
        require(msg.value == ticketPrice);
        _;
    }

    modifier allowBuyTicketCount(uint _drawCount) {
        require(msg.value == ticketPrice*_drawCount);
        _;
    }

    modifier allowRegisterTicket(uint[] _numbers) {
        require(_numbers.length == MAX_BALLS_COUNT);
        for (uint i = 0; i < MAX_BALLS_COUNT; i++) {
            require(_numbers[i] > 0);
            require(_numbers[i] <= MAX_BALL_NUMBER);
            for (uint t = 0; t < MAX_BALLS_COUNT; t++) {
                if (t == i) {
                    continue;
                }
                require(_numbers[t]!=_numbers[i]);
            }
        }
        _;
    }

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

     
    function setTicketPrice(uint _amount) external onlyOwner {
        ticketPrice = _amount;
    }

     
    function setOwnerBonusSale(uint _amount) external onlyOwner {
        ownerBonusSale = _amount;
    }

     
    function setOwnerBonusWin(uint _amount) external onlyOwner {
        ownerBonusWin = _amount;
    }

    function setDrawContract(address _address) public onlyOwner {
        drawContractAddress = _address;
        drawContract = DrawContractI(_address);
    }

    function burn(uint _tokenId) external onlyOwner {
        require((now - mintDate[_tokenId]) / 60 / 60 / 24 > 30);
        require(drawContract.ticketToDraw(_tokenId) == 0);
        uint _refundPrice = ticketPrice * (100 - ownerBonusSale - referrerBonusSale) / 100;
        balance._addBalance(owner(), _refundPrice);
        _burn(ownerOf(_tokenId), _tokenId);
    }

     
    function getMyTickets() public view returns (uint256[]) {
        uint _myTotalTokens = balanceOf(msg.sender);
        uint[] memory _myTokens = new uint[](_myTotalTokens);
        uint k = 0;
        for (uint i = 0; i <= totalSupply(); i++) {
            uint _myTokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (_myTokenId > 0) {
                _myTokens[k] = _myTokenId;
                k++;
                if (k >= _myTotalTokens) {
                    break;
                }
            }
        }
        return _myTokens;
    }

     
    function _buyToken(address _to, uint _referrerId) private returns (uint) {
        tokenIds = tokenIds.add(1);
        uint _tokenId = tokenIds;
        _mint(_to, _tokenId);
        transferFrom(ownerOf(_tokenId), msg.sender, _tokenId);
        mintDate[_tokenId] = now;
         
        _addOwnerBonus(ticketPrice, ownerBonusSale);
         
        if (_referrerId == 0) {
            _referrerId = addressToReferrer[owner()];
        }
        if (_referrerId > 0 && referrerToAddress[_referrerId] > 0) {
            _addReferrerBonus(_referrerId, ticketPrice, referrerBonusSale);
            _setTicketReferrer(_tokenId, _referrerId);
        }
        return _tokenId;
    }

    function() public payable {
        require(msg.value >= ticketPrice);
        uint ticketsCount = msg.value / ticketPrice;
        uint returnCount = msg.value % ticketPrice;

        if (returnCount > 0) {
            msg.sender.transfer(returnCount);
        }
        for (uint i = 1; i <= ticketsCount; i++) {
            _buyToken(msg.sender, 0);
        }
    }

     
    function buyTicket(uint _referrerId) public payable allowBuyTicket {
        _buyToken(msg.sender, _referrerId);
    }

     
    function buyAndRegisterTicket(uint _referrerId, uint[] _numbers, uint _drawCount) public payable allowBuyTicketCount(_drawCount) allowRegisterTicket(_numbers) returns (uint){
        uint _drawNumber = drawContract.drawNumber();
        for (uint i = 0; i<_drawCount; i++) {
            uint _tokenId = _buyToken(msg.sender, _referrerId);
            uint _draw = _drawNumber + i;
            drawContract.registerTicket(_tokenId, _numbers, ticketPrice, ownerBonusSale, referrerBonusSale, _draw);
        }
    }

     
    function registerTicket(uint _tokenId, uint[] _numbers, uint _drawNumber) public onlyOwnerOf(_tokenId) allowRegisterTicket(_numbers) {
         
        require(drawContract.ticketToDraw(_tokenId) == 0);
        drawContract.registerTicket(_tokenId, _numbers, ticketPrice, ownerBonusSale, referrerBonusSale, _drawNumber);
    }

    function _checkTicket(uint _tokenId, address _receiver) private returns (bool) {
        drawContract.checkTicket(_tokenId);
        uint _prize = drawContract.ticketPrizes(_tokenId);
        if (_prize > 0) {
            if (_prize == ticketPrice) {
                _buyToken(_receiver, ticketToReferrer[_tokenId]);
                balance._subBalance(owner(), ticketPrice);
            } else {
                _addPriceToBalance(_tokenId, _prize, _receiver);
            }
        }
        return true;
    }

     
    function checkTicket(uint _tokenId) public {
        require(_exists(_tokenId));
        require(_checkTicket(_tokenId, ownerOf(_tokenId)));
    }

     
    function withdrawTicketPrize(uint _tokenId) public onlyOwner {
        require(_exists(_tokenId));
        uint _ticketDraw = drawContract.ticketToDraw(_tokenId);
        require((now - drawContract.drawTime(_ticketDraw)) / 60 / 60 / 24 > 30);
        require(_checkTicket(_tokenId, owner()));
    }

    function _addPriceToBalance(uint _tokenId, uint _prizeAmount, address _receiver) private {
        uint _ownerBonus = Utils.getBonusAmount(_prizeAmount, ownerBonusWin);
        uint _referrerBonus = Utils.getBonusAmount(_prizeAmount, referrerBonusWin);
        uint _referrerId = ticketToReferrer[_tokenId];
        uint winnerPrizeAmount = _prizeAmount - _ownerBonus - _referrerBonus;
        balance._addBalance(_receiver, winnerPrizeAmount);
        _addReferrerBonus(_referrerId, winnerPrizeAmount, referrerBonusWin);
        _addOwnerBonus(winnerPrizeAmount, ownerBonusWin);
    }

     
    function getMyBalance() public view returns (uint){
        return balance._getBalance(msg.sender);
    }

     
    function withdrawMyBalance() public {
        uint _userBalance = balance._getBalance(msg.sender);
        require(_userBalance > 0);
        require(address(this).balance >= _userBalance);
        balance._clearBalance(msg.sender);
        msg.sender.transfer(_userBalance);
        emit Transfer(this, msg.sender, _userBalance);
    }

    function withdrawBalanceAmount(uint _amount) public {
        uint _userBalance = balance._getBalance(msg.sender);
        require(_userBalance > 0);
        require(_amount <= _userBalance);
        require(address(this).balance >= _amount);
        balance._subBalance(msg.sender, _amount);
        msg.sender.transfer(_amount);
        emit Transfer(this, msg.sender, _amount);
    }

    function _addReferrerBonus(uint _referrer, uint _fromAmount, uint _bonusPercent) internal {
        address _referrerAddress = referrerToAddress[_referrer];
        if (_referrerAddress == address(0)) {
            _referrerAddress = owner();
        }
        uint _amount = Utils.getBonusAmount(_fromAmount, _bonusPercent);
        if (_amount > 0) {
            balance._addBalance(_referrerAddress, _amount);
            totalEarnReferrer[_referrer] = totalEarnReferrer[_referrer].add(_amount);
            emit ReferrerBonus(_referrerAddress, _amount);
        }
    }

    function _addOwnerBonus(uint _fromAmount, uint _bonusPercent) internal {
        uint _amount = Utils.getBonusAmount(_fromAmount, _bonusPercent);
        if (_amount > 0) {
            balance._addBalance(owner(), _amount);
            emit OwnerBonus(owner(), _amount);
        }
    }

    function addBalance(address _address, uint _amount) external onlyDrawContract {
        balance._addBalance(_address, _amount);
    }

    function addSuperPrize() public payable {
        drawContract.addSuperPrize(msg.value);
    }
}