 

 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity >0.5.0;


 
contract Ownable is Context {
     
    bool private _initialized;
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _initialized = true;
        emit OwnershipTransferred(address(0), msgSender);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    
     
    function setupOwnership() public {
        require(!_initialized, "Ownable: already initialized");
        
        address msgSender = _msgSender();
        emit OwnershipTransferred(address(0), msgSender);
        _owner = msgSender;
        _initialized = true;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.5;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

 

pragma solidity ^0.5.0;


 
library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC165 is IERC165 {
     
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

     
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
         
         
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.0;








 
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

     
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

     
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

 

pragma solidity ^0.5.0;


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity >0.5.0;






contract ERC721WithMessage is Context, ERC165, ERC721, IERC721Metadata, Ownable {
    struct Message {
      string content;
      bool encrypted;
    }

     
    string private _name;

     
    string private _symbol;

     
    string private _tokenURI;

     
    mapping(uint256 => Message) private _tokenMessages;

     
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

     
    function initialize(string memory name, string memory symbol, string memory tokenURI) public onlyOwner {
        _name = name;
        _symbol = symbol;
        _tokenURI = tokenURI;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenURI;
    }
    
     
    function tokenMessage(uint256 tokenId) external view returns (string memory, bool) {
        Message storage message = _tokenMessages[tokenId];
        return (message.content, message.encrypted);
    }
    
     
    function mintWithMessage(address to, uint256 tokenId, string memory message, bool encrypted) public onlyOwner returns (bool) {
        _mint(to, tokenId);
        _tokenMessages[tokenId] = Message(message, encrypted);
        return true;
    }
}

 

pragma solidity >0.5.0;
pragma experimental ABIEncoderV2;



contract Cardma is Ownable {
     
    struct Card {
        address cardAddress;
        string name;
        string author;
        string description;
        string imageURI;
        uint256 price;    
        uint256 count;    
        uint256 limit;    
    }
    
    struct SentCard {
        address senderAddress;
        address keyAddress;
        uint256 cardIndex;
        uint256 tokenId;
        uint256 giftAmount;
        uint256 timestamp;
        bool claimed;
    }

    struct ReadableCard {
        address keyAddress;
        string imageURI;
        string message;
        bool encrypted;
        uint256 giftAmount;
        uint256 timestamp;
        bool claimed;
    }

     
    Card[] private _cards;
    mapping(address => SentCard) private _sentCards;
    mapping(address => address[]) private _sentCardsFromUser;
    mapping(address => address[]) private _receivedCardsForUser;

    address private _cardFactoryAddress;
    uint256 private _revenue;
    
     
    function createCardContract()
        internal
        returns (address result)
    {
        bytes20 factoryAddress = bytes20(_cardFactoryAddress);

         
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), factoryAddress)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
    
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

     
    modifier checkSignature(
        address keyAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        require(
            _sentCards[keyAddress].senderAddress == _msgSender() ||
                keyAddress == ecrecover(getPersonalChallenge(), v, r, s),
            "Cardma: invalid signature"
        );
        _;
    }

     
    modifier checkIndex(uint256 cardIndex) {
        require(cardIndex < _cards.length, "Cardma: card index out of range");
        _;
    }
    
     
    function setupCardFactory(address cardFactoryAddress)
        public
        onlyOwner
    {
        _cardFactoryAddress = cardFactoryAddress;
    }
     
    function addCard(
        string memory name,
        string memory author,
        string memory description,
        string memory imageURI,
        string memory tokenURI,
        uint256 price,
        uint256 limit
    )
        public
        onlyOwner
    {
        require(_cardFactoryAddress != address(0), "Cardma: card factory not set");
        
        uint256 cardIndex = _cards.length;
        address cardAddress = createCardContract();
        ERC721WithMessage cardContract = ERC721WithMessage(cardAddress);
        cardContract.setupOwnership();
        cardContract.initialize(
            name,
            string((abi.encodePacked("CM-", uint2str(cardIndex)))),
            tokenURI
        );
        _cards.push(Card(
            cardAddress,
            name,
            author,
            description,
            imageURI,
            price,
            0,
            limit
        ));
    }
    
    function updateCardPrice(
        uint256 cardIndex,
        uint256 price
    )
        public
        onlyOwner
        checkIndex(cardIndex)
    {
        _cards[cardIndex].price = price;
    }

    function claimAllRevenue()
        public
        onlyOwner
    {
        _msgSender().transfer(_revenue);
        _revenue = 0;
    }

    function getRevenue()
        public
        view
        returns (uint256 revenue)
    {
        return _revenue;
    }
    
     
     
    function()
        external
        payable
    {
    }

    function getPersonalChallenge()
        public
        view
        returns (bytes32 challenge)
    {
        return keccak256(abi.encodePacked(
            "portto - make blockchain simple",
            _msgSender()
        ));
    }

    function getCard(uint256 cardIndex)
        public
        view
        checkIndex(cardIndex)
        returns (Card memory card)
    {
        return _cards[cardIndex];
    }
    
    function getCards()
        public
        view
        returns (Card[] memory cards)
    {
        return _cards;
    }
    
    function sendCard(
        address keyAddress,
        uint256 cardIndex,
        string memory message,
        bool encrypted
    )
        public
        payable
        checkIndex(cardIndex)
    {
        Card storage card = _cards[cardIndex];

         
        require(_sentCards[keyAddress].keyAddress == address(0), "Cardma: same keyAddress exists");

         
        require(card.limit == 0 || card.count < card.limit, "Cardma: desired card has been sold out");

         
        require(msg.value >= card.price, "Cardma: cannot afford the card");
        _revenue += card.price;

        uint256 tokenId = card.count;
         
        ERC721WithMessage(card.cardAddress).mintWithMessage(
            address(this),  
            tokenId,
            message,
            encrypted
        );

         
        address senderAddress = _msgSender();
        SentCard memory sentCard = SentCard(
            senderAddress,
            keyAddress,
            cardIndex,
            tokenId,
            msg.value - card.price,
            block.timestamp,
            false
        );

         
        _sentCards[keyAddress] = sentCard;
        _sentCardsFromUser[senderAddress].push(keyAddress);
        card.count += 1;
    }

    function readCard(address keyAddress)
        public
        view
        returns (ReadableCard memory card)
    {
        SentCard storage sentCard = _sentCards[keyAddress];
        Card storage card = _cards[sentCard.cardIndex];

        (string memory message, bool encrypted) = ERC721WithMessage(card.cardAddress).tokenMessage(sentCard.tokenId);

        return ReadableCard(
            keyAddress,
            card.imageURI,
            message,
            encrypted,
            sentCard.giftAmount,
            sentCard.timestamp,
            sentCard.claimed
        );
    }

    function claimCard(
        address keyAddress,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        checkSignature(keyAddress, v, r, s)
    {
        address payable msgSender = _msgSender();
        SentCard storage sentCard = _sentCards[keyAddress];
        Card storage card = _cards[sentCard.cardIndex];

         
        require(!sentCard.claimed, "Cardma: card already claimed");

         
        ERC721WithMessage(card.cardAddress)
            .safeTransferFrom(
                address(this),
                msgSender,
                sentCard.tokenId
            );

         
        msgSender.transfer(sentCard.giftAmount);
        _receivedCardsForUser[msgSender].push(keyAddress);
        sentCard.claimed = true;
    }

    function getMySentCards()
        public
        view
        returns (ReadableCard[] memory sentCards)
    {
        address[] storage sentCardsFromUser = _sentCardsFromUser[_msgSender()];
        ReadableCard[] memory sentCards = new ReadableCard[](sentCardsFromUser.length);

        for(uint i = 0; i < sentCardsFromUser.length; i++) {
            sentCards[i] = readCard(sentCardsFromUser[i]);
        }

        return sentCards;
    }

    function getMyReceivedCards()
        public
        view
        returns (ReadableCard[] memory receivedCards)
    {
        address[] storage receivedCardsForUser = _receivedCardsForUser[_msgSender()];
        ReadableCard[] memory receivedCards = new ReadableCard[](receivedCardsForUser.length);

        for(uint i = 0; i < receivedCardsForUser.length; i++) {
            receivedCards[i] = readCard(receivedCardsForUser[i]);
        }

        return receivedCards;
    }
}