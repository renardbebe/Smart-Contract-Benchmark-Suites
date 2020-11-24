 

pragma solidity ^0.4.23;

 

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }   
        return size > 0;
    }
}


 
contract Ownable {
    
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function owned(uint256 _tokenId) public view returns (bool _owned);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
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
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}


pragma solidity ^0.4.21;


 
contract ERC721Receiver {
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

     
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}



 
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

     
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

     
    mapping (uint256 => address) internal tokenOwner;

     
    mapping (uint256 => address) internal tokenApprovals;

     
    mapping (address => uint256) internal ownedTokensCount;

     
    mapping (address => mapping (address => bool)) internal operatorApprovals;

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

     
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
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

     
    function owned(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

     
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

     
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

     
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

     
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
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
        canTransfer(_tokenId)
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
        canTransfer(_tokenId)
    {
        transferFrom(_from, _to, _tokenId);
         
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

     
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

     
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
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
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}


 
contract ERC721Token is ERC721, ERC721BasicToken {

     
    string internal name_;

     
    string internal symbol_;

     
    uint256 internal totalSupply_;

     
    mapping (address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

     
    mapping(uint256 => string) internal tokenURIs;

     
    constructor(string _name, string _symbol, uint256 _totalSupply) public {
        name_ = _name;
        symbol_ = _symbol;
        totalSupply_ = _totalSupply;
    }

     
    function name() public view returns (string) {
        return name_;
    }

     
    function symbol() public view returns (string) {
        return symbol_;
    }

     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(owned(_tokenId));
        return tokenURIs[_tokenId];
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(owned(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return _index;
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
        ownedTokens[_from][lastTokenIndex] = 0;
         
         
         

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }
}

contract ERC165 {

    bytes4 constant ERC165InterfaceId = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant ERC721InterfaceId = 0x80ac58cd;
    bytes4 constant ERC721EnumerableInterfaceId = 0x780e9d63;
    bytes4 constant ERC721MetadataInterfaceId = 0x5b5e139f;
    bytes4 constant ERC721TokenReceiverInterfaceId = 0xf0b9e5ba;

     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
            ((interfaceID == ERC165InterfaceId) ||
            (interfaceID == ERC721InterfaceId) ||
            (interfaceID == ERC721EnumerableInterfaceId) ||
            (interfaceID == ERC721MetadataInterfaceId) ||
            (interfaceID == ERC721TokenReceiverInterfaceId));
    }
}

contract StarCards is Ownable, ERC721Token, ERC165 {

     
    string constant public dataset_md5checksum = "696fa8ba0f25d6d6f8391e37251736bc";
    string constant public dataset_sha256checksum = "ba3178b5d13ec7b05cf3ebaae2be797cc0eb6756eac455426f2b1d70f17cefae";

     
    string public databaseDownloadUrl = "ftp://starcards.my/starCardsDataset.json";
    
    uint256 constant public editionSize = 345;
    uint256 constant public minimumBid = 0.001 ether;
    uint256 constant public timeBetweenEditions = 1 days;
    uint256 constant public initializationDelay = 3 days;

    struct ReleaseAuction {
        Bid highestBid;
        uint additionalTime;
        bool completed;
    }

    struct Bid {
        uint value;
        uint timePlaced;
        address bidder;
    }

    event NewBid(uint id, uint value, uint timePlaced, address bidder);

    mapping(address => uint) public pendingWithdrawals;
    mapping(uint => ReleaseAuction) releaseAuctions;

    uint256 public contractInitializationTime;

    constructor() ERC721Token("Star Cards", "STAR", 586155) public payable {
        owner = msg.sender;
        contractInitializationTime = now + initializationDelay;
    }

    function setDatabaseDownloadUrl(string url) public onlyOwner {
        databaseDownloadUrl = url;
    }

    function getCurrentEdition() public view returns (uint256) {
        uint256 secondsSinceContractInitialization = SafeMath.sub(now, contractInitializationTime);
        return SafeMath.div(secondsSinceContractInitialization, timeBetweenEditions);
    }

    function getEditionReleaseTime(uint edition) public view returns (uint256) {
        return SafeMath.add(contractInitializationTime, (SafeMath.mul(edition, timeBetweenEditions)));
    }

    function getEdition(uint id) public view onlyValidTokenIds(id) returns (uint256) {
        return SafeMath.div(id, editionSize);
    }

    function isReleased(uint id) public view onlyValidTokenIds(id) returns (bool) {
        return getEdition(id) <= getCurrentEdition();
    }

    function getReleaseAuctionEndTime(uint id) public view onlyValidTokenIds(id) returns (uint) {
        uint256 timeFromRelease = SafeMath.add(timeBetweenEditions, releaseAuctions[id].additionalTime);
        return SafeMath.add(getEditionReleaseTime(getEdition(id)), timeFromRelease);
    }

    function releaseAuctionEnded(uint id) public view onlyValidTokenIds(id) returns (bool) {
        return (isReleased(id) && (getReleaseAuctionEndTime(id) < now));
    }

    function getHighestBidder(uint id) public view onlyValidTokenIds(id) returns (address) {
        return releaseAuctions[id].highestBid.bidder;
    }

    function getHighestBid(uint id) public view onlyValidTokenIds(id) returns (uint) {
        return releaseAuctions[id].highestBid.value;
    }

    function getAdditionalTime(uint id) public view onlyValidTokenIds(id) returns (uint) {
        return releaseAuctions[id].additionalTime;
    }

    function getRemainingTime(uint id) public view onlyValidTokenIds(id) returns (uint) {
        uint endTime = getReleaseAuctionEndTime(id);
        if (endTime > now) {
            return SafeMath.sub(endTime, now);
        } else {
            return 0;
        }
    }

    function getAllTokens(address owner) public view returns (uint[]) {
        uint size = ownedTokens[owner].length;
        uint[] memory result = new uint[](size);
        for (uint i = 0; i < size; i++) {
            result[i] = ownedTokens[owner][i];
        }
        return result;
    }

     
    function completeReleaseAuction(uint id) payable external onlyReleasedTokens(id) {

        require(releaseAuctionEnded(id));

        ReleaseAuction storage auction = releaseAuctions[id];

        require(!auction.completed);

        address newOwner;
        uint payout;

        if (auction.highestBid.bidder == address(0)) {
            require(msg.value >= minimumBid);
            newOwner = msg.sender;
            payout = msg.value;
        } else {
            newOwner = auction.highestBid.bidder;
            payout = auction.highestBid.value;
        }

        addTokenTo(newOwner, id);

        pendingWithdrawals[owner] = SafeMath.add(pendingWithdrawals[owner], payout);

        auction.completed = true;
    }

     
    function placeBid(uint id) payable external onlyReleasedTokens(id) {

        require(!releaseAuctionEnded(id));  

        ReleaseAuction storage auction = releaseAuctions[id];

         
        require(msg.value >= auction.highestBid.value + minimumBid);

         
        auction.additionalTime = SafeMath.add(auction.additionalTime, timeBetweenEditions - getRemainingTime(id));

         
        if (auction.highestBid.bidder != address(0)) {
            pendingWithdrawals[auction.highestBid.bidder] = SafeMath.add(pendingWithdrawals[auction.highestBid.bidder], auction.highestBid.value);
        }

         
        auction.highestBid = Bid(msg.value, now, msg.sender);

        emit NewBid(id, msg.value, now, msg.sender);
    }

     
    function withdraw() external returns (bool) {
        uint amount = pendingWithdrawals[msg.sender];
        if (amount > 0) {
             
             
             
            pendingWithdrawals[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                 
                pendingWithdrawals[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

     
    modifier onlyReleasedTokens(uint id) {
        require(isReleased(id));
        _;
    }

     
    modifier onlyValidTokenIds(uint id) {
        require(id < totalSupply());
        _;
    }
  
    function() external payable {
        revert();
    }
}