 

pragma solidity ^0.4.24;

 
 
 
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

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
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

 
contract SupportsInterface {
     
    mapping(bytes4 => bool) internal supportedInterfaces;

     
    constructor()
    public
    {
        supportedInterfaces[0x01ffc9a7] = true;  
    }

     
    function supportsInterface(
        bytes4 _interfaceID
    )
    external
    view
    returns (bool)
    {
        return supportedInterfaces[_interfaceID];
    }

}

 
library AddressUtils {

     
    function isContract(
        address _addr
    )
    internal
    view
    returns (bool)
    {
        uint256 size;

         
        assembly { size := extcodesize(_addr) }  
        return size > 0;
    }

}

 
contract NFToken is ERC721, SupportsInterface, ERC721Metadata, ERC721Enumerable {
    using AddressUtils for address;

     
     
     

     
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

     
     
     

     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     

     
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = nft[_tokenId].owner;
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "Sender is not an authorized operator of this token");
        _;
    }

     
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = nft[_tokenId].owner;
        require(
            tokenOwner == msg.sender ||
            getApproved(_tokenId) == msg.sender || ownerToOperators[tokenOwner][msg.sender],
            "Sender does not have permission to transfer this Token");

        _;
    }

     
    modifier onlyNonZeroAddress(address toTest) {
        require(toTest != address(0), "Address must be non zero address");
        _;
    }

     
    modifier noOwnerExists(uint256 nftId) {
        require(nft[nftId].owner == address(0), "Owner must not exist for this token");
        _;
    }

     
    modifier ownerExists(uint256 nftId) {
        require(nft[nftId].owner != address(0), "Owner must exist for this token");
        _;
    }

     
     
     

     
    string nftName = "WeTrust Nifty";

     
    string nftSymbol = "SPRN";

     
    string public hostname = "https://spring.wetrust.io/shiba/";

     
    mapping (uint256 => NFT) public nft;

     
    uint256[] nftList;

     
    mapping (address => uint256[]) internal ownerToTokenList;

     
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    struct NFT {
        address owner;
        address approval;
        bytes32 traits;
        uint16 edition;
        bytes4 nftType;
        bytes32 recipientId;
        uint256 createdAt;
    }

     
     
     

     
    constructor() public {
        supportedInterfaces[0x780e9d63] = true;  
        supportedInterfaces[0x5b5e139f] = true;  
        supportedInterfaces[0x80ac58cd] = true;  
    }

     
    function balanceOf(address _owner) onlyNonZeroAddress(_owner) public view returns (uint256) {
        return ownerToTokenList[_owner].length;
    }

     
    function ownerOf(uint256 _tokenId) ownerExists(_tokenId) external view returns (address _owner) {
        return nft[_tokenId].owner;
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId)
        onlyNonZeroAddress(_to)
        canTransfer(_tokenId)
        ownerExists(_tokenId)
        external
    {

        address tokenOwner = nft[_tokenId].owner;
        require(tokenOwner == _from, "from address must be owner of tokenId");

        _transfer(_to, _tokenId);
    }

     
    function approve(address _approved, uint256 _tokenId)
        canOperate(_tokenId)
        ownerExists(_tokenId)
        external
    {

        address tokenOwner = nft[_tokenId].owner;
        require(_approved != tokenOwner, "approved address cannot be owner of the token");

        nft[_tokenId].approval = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

     
    function setApprovalForAll(address _operator, bool _approved)
        onlyNonZeroAddress(_operator)
        external
    {

        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
    function getApproved(uint256 _tokenId)
        ownerExists(_tokenId)
        public view returns (address)
    {

        return nft[_tokenId].approval;
    }

     
    function isApprovedForAll(address _owner, address _operator)
        onlyNonZeroAddress(_owner)
        onlyNonZeroAddress(_operator)
        external view returns (bool)
    {

        return ownerToOperators[_owner][_operator];
    }

     
    function getOwnedTokenList(address owner) view public returns(uint256[] tokenList) {
        return ownerToTokenList[owner];
    }

     
    function name() external view returns (string _name) {
        return nftName;
    }

     
    function symbol() external view returns (string _symbol) {
        return nftSymbol;
    }

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string) {
        return appendUintToString(hostname, _tokenId);
    }

     
     
     
    function totalSupply() external view returns (uint256) {
        return nftList.length;
    }

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < nftList.length, "index out of range");
        return nftList[_index];
    }

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < balanceOf(_owner), "index out of range");
        return ownerToTokenList[_owner][_index];
    }

     
     
     

     

    function appendUintToString(string inStr, uint v) pure internal returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory inStrb = bytes(inStr);
        bytes memory s = new bytes(inStrb.length + i);
        uint j;
        for (j = 0; j < inStrb.length; j++) {
            s[j] = inStrb[j];
        }
        for (j = 0; j < i; j++) {
            s[j + inStrb.length] = reversed[i - 1 - j];
        }
        str = string(s);
    }

     
    function _transfer(address _to, uint256 _tokenId) private {
        address from = nft[_tokenId].owner;
        clearApproval(_tokenId);

        removeNFToken(from, _tokenId);
        addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        onlyNonZeroAddress(_to)
        canTransfer(_tokenId)
        ownerExists(_tokenId)
        internal
    {
        address tokenOwner = nft[_tokenId].owner;
        require(tokenOwner == _from, "from address must be owner of tokenId");

        _transfer(_to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, "reciever contract did not return the correct return value");
        }
    }

     
    function clearApproval(uint256 _tokenId) private {
        if(nft[_tokenId].approval != address(0))
        {
            delete nft[_tokenId].approval;
        }
    }

     
    function removeNFToken(address _from, uint256 _tokenId) internal {
        require(nft[_tokenId].owner == _from, "from address must be owner of tokenId");
        uint256[] storage tokenList = ownerToTokenList[_from];
        assert(tokenList.length > 0);

        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == _tokenId) {
                tokenList[i] = tokenList[tokenList.length - 1];
                delete tokenList[tokenList.length - 1];
                tokenList.length--;
                break;
            }
        }
        delete nft[_tokenId].owner;
    }

     
    function addNFToken(address _to, uint256 _tokenId)
        noOwnerExists(_tokenId)
        internal
    {
        nft[_tokenId].owner = _to;
        ownerToTokenList[_to].push(_tokenId);
    }

}


 
contract SpringNFT is NFToken{


     
     
     
    event RecipientUpdate(bytes32 indexed recipientId, bytes32 updateId);

     
     
     

     
    modifier recipientExists(bytes32 id) {
        require(recipients[id].exists, "Recipient Must exist");
        _;
    }

     
    modifier recipientDoesNotExists(bytes32 id) {
        require(!recipients[id].exists, "Recipient Must not exists");
        _;
    }

     
    modifier onlyByWeTrustSigner() {
        require(msg.sender == wetrustSigner, "sender must be from WeTrust Signer Address");
        _;
    }

     
    modifier onlyByWeTrustManager() {
        require(msg.sender == wetrustManager, "sender must be from WeTrust Manager Address");
        _;
    }

     
    modifier onlyByWeTrustOrRecipient(bytes32 id) {
        require(msg.sender == wetrustSigner || msg.sender == recipients[id].owner, "sender must be from WeTrust or Recipient's owner address");
        _;
    }

     
    modifier onlyWhenNotPaused() {
        require(!paused, "contract is currently in paused state");
        _;
    }

     
     
     

     
    address public wetrustSigner;

     
    address public wetrustManager;

     
    bool public paused;

     
    mapping(bytes32 => Recipient) public recipients;
     
    mapping(bytes32 => Update[]) public recipientUpdates;

     
    mapping (uint256 => bytes) public nftArtistSignature;

    struct Update {
        bytes32 id;
        uint256 createdAt;
    }

    struct Recipient {
        string name;
        string url;
        address owner;
        uint256 nftCount;
        bool exists;
    }

     
     
     

     
    constructor (address signer, address manager) NFToken() public {
        wetrustSigner = signer;
        wetrustManager = manager;
    }

     

    function createNFT(
        uint256 tokenId,
        address receiver,
        bytes32 recipientId,
        bytes32 traits,
        bytes4 nftType)
        noOwnerExists(tokenId)
        onlyByWeTrustSigner
        onlyWhenNotPaused public
    {
        mint(tokenId, receiver, recipientId, traits, nftType);
    }

     
    function redeemToken(bytes signedMessage) onlyWhenNotPaused public {
        address to;
        uint256 tokenId;
        bytes4 nftType;
        bytes32 traits;
        bytes32 recipientId;
        bytes32 r;
        bytes32 s;
        byte vInByte;
        uint8 v;
        string memory prefix = "\x19Ethereum Signed Message:\n32";

        assembly {
            to := mload(add(signedMessage, 32))
            tokenId := mload(add(signedMessage, 64))
            nftType := mload(add(signedMessage, 96))  
            traits := mload(add(signedMessage, 100))
            recipientId := mload(add(signedMessage, 132))
            r := mload(add(signedMessage, 164))
            s := mload(add(signedMessage, 196))
            vInByte := mload(add(signedMessage, 228))
        }
        require(to == address(this), "This signed Message is not meant for this smart contract");
        v = uint8(vInByte);
        if (v < 27) {
            v += 27;
        }

        require(nft[tokenId].owner == address(0), "This token has been redeemed already");
        bytes32 msgHash = createRedeemMessageHash(tokenId, nftType, traits, recipientId);
        bytes32 preFixedMsgHash = keccak256(
            abi.encodePacked(
                prefix,
                msgHash
            ));

        address signer = ecrecover(preFixedMsgHash, v, r, s);

        require(signer == wetrustSigner, "WeTrust did not authorized this redeem script");
        return mint(tokenId, msg.sender, recipientId, traits, nftType);
    }

     
    function addRecipient(bytes32 recipientId, string name, string url, address owner)
        onlyByWeTrustSigner
        onlyWhenNotPaused
        recipientDoesNotExists(recipientId)
        public
    {
        require(bytes(name).length > 0, "name must not be empty string");  

        recipients[recipientId].name = name;
        recipients[recipientId].url = url;
        recipients[recipientId].owner = owner;
        recipients[recipientId].exists = true;
    }

     
    function addRecipientUpdate(bytes32 recipientId, bytes32 updateId)
        onlyWhenNotPaused
        recipientExists(recipientId)
        onlyByWeTrustOrRecipient(recipientId)
        public
    {
        recipientUpdates[recipientId].push(Update(updateId, now));
        emit RecipientUpdate(recipientId, updateId);
    }

     
    function updateRecipientInfo(bytes32 recipientId, string name, string url, address owner)
        onlyByWeTrustSigner
        onlyWhenNotPaused
        recipientExists(recipientId)
        public
    {
        require(bytes(name).length > 0, "name must not be empty string");  

        recipients[recipientId].name = name;
        recipients[recipientId].url = url;
        recipients[recipientId].owner = owner;
    }

     
    function addArtistSignature(uint256 nftId, bytes artistSignature) onlyByWeTrustSigner onlyWhenNotPaused public {
        require(nftArtistSignature[nftId].length == 0, "Artist Signature already exist for this token");  

        nftArtistSignature[nftId] = artistSignature;
    }

     
    function setPaused(bool _paused) onlyByWeTrustManager public {
        paused = _paused;
    }

     
    function changeWeTrustSigner(address newAddress) onlyWhenNotPaused onlyByWeTrustManager public {
        wetrustSigner = newAddress;
    }

     
    function getUpdateCount(bytes32 recipientId) view public returns(uint256 count) {
        return recipientUpdates[recipientId].length;
    }

     
    function createRedeemMessageHash(
        uint256 tokenId,
        bytes4 nftType,
        bytes32 traits,
        bytes32 recipientId)
        view public returns(bytes32 msgHash)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                tokenId,
                nftType,
                traits,
                recipientId
            ));
    }

     
    function determineEdition(uint256 nextNFTcount) pure public returns (uint16 edition) {
        uint256 output;
        uint256 valueWhenXisSixteen = 37601;  
        if (nextNFTcount < valueWhenXisSixteen) {
            output = (sqrt(2500 + (600 * (nextNFTcount - 1))) + 50) / 300;
        } else {
            output = ((nextNFTcount - valueWhenXisSixteen) / 5000) + 16;
        }

        if (output > 5000) {
            output = 5000;
        }

        edition = uint16(output);  
    }

     
    function setNFTContractInfo(string newHostName, string newName, string newSymbol) onlyByWeTrustManager external {
        hostname = newHostName;
        nftName = newName;
        nftSymbol = newSymbol;
    }
     
     
     

     

    function sqrt(uint x) pure internal returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

     
    function mint(uint256 tokenId, address receiver, bytes32 recipientId, bytes32 traits, bytes4 nftType)
        recipientExists(recipientId)
        internal
    {
        nft[tokenId].owner = receiver;
        nft[tokenId].traits = traits;
        nft[tokenId].recipientId = recipientId;
        nft[tokenId].nftType = nftType;
        nft[tokenId].createdAt = now;
        nft[tokenId].edition = determineEdition(recipients[recipientId].nftCount + 1);

        recipients[recipientId].nftCount++;
        ownerToTokenList[receiver].push(tokenId);

        nftList.push(tokenId);

        emit Transfer(address(0), receiver, tokenId);
    }
}