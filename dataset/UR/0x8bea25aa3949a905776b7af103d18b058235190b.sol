 

 
 
pragma solidity ^0.4.23;

 
 
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
 
contract ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) public;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

 
interface ERC721Metadata   {
    function name() external pure returns (string _name);
    function symbol() external pure returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

 
interface ERC721Enumerable   {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface ERC721MetadataProvider {
    function tokenURI(uint256 _tokenId) external view returns (string);
}

contract AccessAdmin {
    bool public isPaused = false;
    address public addrAdmin;  

    event AdminTransferred(address indexed preAdmin, address indexed newAdmin);

    constructor() public {
        addrAdmin = msg.sender;
    }  


    modifier onlyAdmin() {
        require(msg.sender == addrAdmin);
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused);
        _;
    }

    modifier whenPaused {
        require(isPaused);
        _;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0));
        emit AdminTransferred(addrAdmin, _newAdmin);
        addrAdmin = _newAdmin;
    }

    function doPause() external onlyAdmin whenNotPaused {
        isPaused = true;
    }

    function doUnpause() external onlyAdmin whenPaused {
        isPaused = false;
    }
}

interface TokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract ManagerToken is ERC721, ERC721Metadata, ERC721Enumerable, AccessAdmin {
     
    uint256[] public managerArray;
     
    mapping (uint256 => address) tokenIdToOwner;
     
    mapping (address => uint256[]) ownerToManagerArray;
     
    mapping (uint256 => uint256) tokenIdToOwnerIndex;
     
    mapping (uint256 => address) tokenIdToApprovals;
     
    mapping (address => mapping (address => bool)) operatorToApprovals;
     
    mapping (address => bool) safeContracts;
     
    ERC721MetadataProvider public providerContract;

     
    event Approval
    (
        address indexed _owner, 
        address indexed _approved,
        uint256 _tokenId
    );

     
    event ApprovalForAll
    (
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

     
    event Transfer
    (
        address indexed from,
        address indexed to,
        uint256 tokenId
    );
    
    constructor() public {
        addrAdmin = msg.sender;
        managerArray.length += 1;
    }

     
     
    modifier isValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= managerArray.length, "TokenId out of range");
        require(tokenIdToOwner[_tokenId] != address(0), "Token have no owner"); 
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address owner = tokenIdToOwner[_tokenId];
        require(msg.sender == owner || msg.sender == tokenIdToApprovals[_tokenId] || operatorToApprovals[owner][msg.sender], "Can not transfer");
        _;
    }

     
    function supportsInterface(bytes4 _interfaceId) external view returns(bool) {
         
        return (_interfaceId == 0x01ffc9a7 || _interfaceId == 0x80ac58cd || _interfaceId == 0x8153916a) && (_interfaceId != 0xffffffff);
    }

    function name() public pure returns(string) {
        return "Token Tycoon Managers";
    }

    function symbol() public pure returns(string) {
        return "TTM";
    }

    function tokenURI(uint256 _tokenId) external view returns (string) {
        if (address(providerContract) == address(0)) {
            return "";
        }
        return providerContract.tokenURI(_tokenId);
    }

     
     
     
    function balanceOf(address _owner) external view returns(uint256) {
        require(_owner != address(0), "Owner is 0");
        return ownerToManagerArray[_owner].length;
    }

     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        return tokenIdToOwner[_tokenId];
    }

     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) 
        external
        whenNotPaused
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        whenNotPaused
        isValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0), "Owner is 0");
        require(_to != address(0), "Transfer target address is 0");
        require(owner == _from, "Transfer to self");
        
        _transfer(_from, _to, _tokenId);
    }

     
     
     
    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0));
        require(msg.sender == owner || operatorToApprovals[owner][msg.sender]);

        tokenIdToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

     
     
     
    function setApprovalForAll(address _operator, bool _approved) 
        external 
        whenNotPaused
    {
        operatorToApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

     
     
     
    function getApproved(uint256 _tokenId) 
        external 
        view 
        isValidToken(_tokenId) 
        returns (address) 
    {
        return tokenIdToApprovals[_tokenId];
    }

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorToApprovals[_owner][_operator];
    }

     
     
     
    function totalSupply() external view returns (uint256) {
        return managerArray.length - 1;
    }

     
     
     
    function tokenByIndex(uint256 _index) 
        external
        view 
        returns (uint256) 
    {
        require(_index < managerArray.length);
        return _index;
    }

     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) 
        external 
        view 
        returns (uint256) 
    {
        require(_owner != address(0));
        require(_index < ownerToManagerArray[_owner].length);
        return ownerToManagerArray[_owner][_index];
    }

     
     
     
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from != address(0)) {
            uint256 indexFrom = tokenIdToOwnerIndex[_tokenId];
            uint256[] storage ttmArray = ownerToManagerArray[_from];
            require(ttmArray[indexFrom] == _tokenId);

            if (indexFrom != ttmArray.length - 1) {
                uint256 lastTokenId = ttmArray[ttmArray.length - 1];
                ttmArray[indexFrom] = lastTokenId; 
                tokenIdToOwnerIndex[lastTokenId] = indexFrom;
            }
            ttmArray.length -= 1; 
            
            if (tokenIdToApprovals[_tokenId] != address(0)) {
                delete tokenIdToApprovals[_tokenId];
            }      
        }

        tokenIdToOwner[_tokenId] = _to;
        ownerToManagerArray[_to].push(_tokenId);
        tokenIdToOwnerIndex[_tokenId] = ownerToManagerArray[_to].length - 1;
        
        emit Transfer(_from != address(0) ? _from : this, _to, _tokenId);
    }

     
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
        internal
        isValidToken(_tokenId) 
        canTransfer(_tokenId)
    {
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner == _from);
        
        _transfer(_from, _to, _tokenId);

         
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
         
        require(retval == 0xf0b9e5ba);
    }
    
    function setSafeContract(address _actionAddr, bool _useful) external onlyAdmin {
        safeContracts[_actionAddr] = _useful;
    }

    function getSafeContract(address _actionAddr) external view onlyAdmin returns(bool) {
        return safeContracts[_actionAddr];
    }

    function setMetadataProvider(address _provider) external onlyAdmin {
        providerContract = ERC721MetadataProvider(_provider);
    }

    function getOwnTokens(address _owner) external view returns(uint256[]) {
        require(_owner != address(0));
        return ownerToManagerArray[_owner];
    }

    function safeGiveByContract(uint256 _tokenId, address _to) 
        external 
        whenNotPaused
    {
        require(safeContracts[msg.sender]);
         
        require(tokenIdToOwner[_tokenId] == address(this));
        require(_to != address(0));

        _transfer(address(this), _to, _tokenId);
    }

     
    function safeTransferByContract(uint256 _tokenId, address _to) 
        external
        whenNotPaused
    {
        require(safeContracts[msg.sender]);

        require(_tokenId >= 1 && _tokenId <= managerArray.length);
        address owner = tokenIdToOwner[_tokenId];
        require(owner != address(0));
        require(_to != address(0));
        require(owner != _to);

        _transfer(owner, _to, _tokenId);
    }

    function initManager(uint256 _gene, uint256 _count) external {
        require(safeContracts[msg.sender] || msg.sender == addrAdmin);
        require(_gene > 0 && _count <= 128);
        
        address owner = address(this);
        uint256[] storage ttmArray = ownerToManagerArray[owner];
        uint256 newTokenId;
        for (uint256 i = 0; i < _count; ++i) {
            newTokenId = managerArray.length;
            managerArray.push(_gene);
            tokenIdToOwner[newTokenId] = owner;
            tokenIdToOwnerIndex[newTokenId] = ttmArray.length;
            ttmArray.push(newTokenId);
            emit Transfer(address(0), owner, newTokenId);
        }
    }

    function approveAndCall(address _spender, uint256 _tokenId, bytes _extraData)
        external
        whenNotPaused
        returns (bool success) 
    {
        TokenRecipient spender = TokenRecipient(_spender);
        approve(_spender, _tokenId);
        spender.receiveApproval(msg.sender, _tokenId, this, _extraData);
        return true;
    }

    function getProtoIdByTokenId(uint256 _tokenId)
        external 
        view 
        returns(uint256 protoId) 
    {
        if (_tokenId > 0 && _tokenId < managerArray.length) {
            return managerArray[_tokenId];
        }
    }

    function getOwnerTokens(address _owner)
        external
        view 
        returns(uint256[] tokenIdArray, uint256[] protoIdArray) 
    {
        uint256[] storage ownTokens = ownerToManagerArray[_owner];
        uint256 count = ownTokens.length;
        tokenIdArray = new uint256[](count);
        protoIdArray = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            tokenIdArray[i] = ownTokens[i];
            protoIdArray[i] = managerArray[tokenIdArray[i]];
        }
    }
}