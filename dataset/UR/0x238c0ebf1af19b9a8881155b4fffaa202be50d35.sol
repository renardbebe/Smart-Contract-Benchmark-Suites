 

pragma solidity ^0.5.2;

interface ERC721TokenReceiver {

   
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns(bytes4);
    
}

contract ICOStickers {
    using SafeMath for uint256;
    using SafeMath for int256;
    address constant internal NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
    
     
    mapping(bytes4 => bool) internal supportedInterfaces;
    
     
    address[] internal idToOwner;
    address[] internal idToApprovals;
    mapping (address => uint256) internal ownerToNFTokenCount;
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    
     
    string constant public name = "0xchan ICO Stickers";
    string constant public symbol = "ZCIS";
    
     
    string constant internal uriStart = "https://0xchan.net/stickers/obj_properties/";
    uint256[] public tokenProperty;
    address[] public originalTokenOwner;
    address internal badgeGiver;
    address internal owner;
    address internal newOwner;
    
    
     
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
    
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }
    
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || getApproved(_tokenId) == msg.sender
            || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }
    
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != NULL_ADDRESS);
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyBadgeGiver {
        require(msg.sender == badgeGiver);
        _;
    }
    
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true;  
        supportedInterfaces[0x80ac58cd] = true;  
        supportedInterfaces[0x5b5e139f] = true;  
        supportedInterfaces[0x780e9d63] = true;  
        
        owner = msg.sender;
        badgeGiver = msg.sender;
    }
    
     
    function setNewOwner(address o) public onlyOwner {
        newOwner = o;
    }
    
    function acceptNewOwner() public {
        require(msg.sender == newOwner);
        owner = msg.sender;
    }
    
    function revokeOwnership() public onlyOwner {
        owner = NULL_ADDRESS;
        newOwner = NULL_ADDRESS;
    }
    
	function setBadgeGiver(address g) public onlyOwner {
	    badgeGiver = g;
	}
    
    function giveSticker(address _to, uint256 _property) public onlyBadgeGiver {
        require(_to != NULL_ADDRESS);
        uint256 _tokenId = tokenProperty.length;
        
        idToOwner.length ++;
        idToApprovals.length ++;
        tokenProperty.length ++;
        originalTokenOwner.length ++;
        
        addNFToken(_to, _tokenId);
        tokenProperty[_tokenId] = _property;
        originalTokenOwner[_tokenId] = _to;
    
        emit Transfer(NULL_ADDRESS, _to, _tokenId);
    }
    
     
    
    function totalSupply() external view returns(uint256) {
        return tokenProperty.length;
    }
    
    function tokenOfOwnerByIndex(uint256 _tokenId) external view returns(address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != NULL_ADDRESS);
    }
    
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < tokenProperty.length);
        return _index;
    }
    
     
    
    function tokenURI(uint256 _tokenId) validNFToken(_tokenId) public view returns (string memory)
    {
        return concatStrings(uriStart, uint256ToString(_tokenId));
    }
    
     
    
    function balanceOf(address _owner) external view returns(uint256) {
        require(_owner != NULL_ADDRESS);
        return ownerToNFTokenCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) external view returns(address _owner){
        _owner = idToOwner[_tokenId];
        require(_owner != NULL_ADDRESS);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    function supportsInterface(bytes4 _interfaceID) external view returns(bool) {
        return supportedInterfaces[_interfaceID];
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != NULL_ADDRESS);
        _transfer(_to, _tokenId);
    }
    
    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        
        idToApprovals[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }
    
    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != NULL_ADDRESS);
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function getApproved(uint256 _tokenId) public view validNFToken(_tokenId) returns (address){
        return idToApprovals[_tokenId];
    }
    
    function isApprovedForAll(address _owner, address _operator) external view returns(bool) {
        require(_owner != NULL_ADDRESS);
        require(_operator != NULL_ADDRESS);
        return ownerToOperators[_owner][_operator];
    }
    
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) internal canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != NULL_ADDRESS);
        
        _transfer(_to, _tokenId);
        
        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }
    
    function _transfer(address _to, uint256 _tokenId) private {
        address from = idToOwner[_tokenId];
        clearApproval(_tokenId);
        removeNFToken(from, _tokenId);
        addNFToken(_to, _tokenId);
        emit Transfer(from, _to, _tokenId);
    }
    
    function clearApproval(uint256 _tokenId) private {
        if(idToApprovals[_tokenId] != NULL_ADDRESS){
            delete idToApprovals[_tokenId];
        }
    }

    function removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        assert(ownerToNFTokenCount[_from] > 0);
        ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
        delete idToOwner[_tokenId];
    }

    function addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == NULL_ADDRESS);
        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
    }
    
     
    function isContract(address _addr) internal view returns(bool) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length>0);
    }
    
     
    function amountOfZeros(uint256 num, uint256 base) public pure returns(uint256){
        uint256 result = 0;
        num /= base;
        while (num > 0){
            num /= base;
            result += 1;
        }
        return result;
    }
    
    function uint256ToString(uint256 num) public pure returns(string memory){
        if (num == 0){
            return "0";
        }
        uint256 numLen = amountOfZeros(num, 10) + 1;
        bytes memory result = new bytes(numLen);
        while(num != 0){
            numLen -= 1;
            result[numLen] = byte(uint8((num - (num / 10 * 10)) + 48));
            num /= 10;
        }
        return string(result);
    }
    
    function concatStrings(string memory str1, string memory str2) public pure returns (string memory){
        uint256 str1Len = bytes(str1).length;
        uint256 str2Len = bytes(str2).length;
        uint256 resultLen = str1Len + str1Len;
        bytes memory result = new bytes(resultLen);
        uint256 i;
        
        for (i = 0; i < str1Len; i += 1){
            result[i] = bytes(str1)[i];
        }
        for (i = 0; i < str2Len; i += 1){
            result[i + str1Len] = bytes(str2)[i];
        }
        return string(result);
    }
}

 
library SafeMath {
    
     
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if (a == 0 || b == 0) {
           return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
         
         
        return a / b;
    }
    
     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
    
     
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    
     
    function sub(int256 a, int256 b) internal pure returns(int256 c) {
        c = a - b;
        assert(c <= a);
        return c;
    }
    
     
    function add(int256 a, int256 b) internal pure returns(int256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}