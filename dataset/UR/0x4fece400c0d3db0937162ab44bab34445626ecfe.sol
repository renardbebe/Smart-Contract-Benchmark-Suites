 

pragma solidity ^0.4.21;

 
 
 

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

 
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
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

 
contract ERC721Receiver {
     
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

     
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;

     
     
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

     
    function exists(uint256 _tokenId) public view returns (bool) {
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

     
    function _isContract(address _user) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_user) }
        return size > 0;
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
        if (!_isContract(_to)) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }

}

contract Owned {
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function Owned() public {
        owner = msg.sender;
    }
}

contract HeroLogicInterface {
    function isTransferAllowed(address _from, address _to, uint256 _tokenId) public view returns (bool);
}

contract ETHero is Owned, ERC721, ERC721BasicToken {

    struct HeroData {
        uint16 fieldA;
        uint16 fieldB;
        uint32 fieldC;
        uint32 fieldD;
        uint32 fieldE;
        uint64 fieldF;
        uint64 fieldG;
    }

     
    string internal name_;

     
    string internal symbol_;

     
    mapping (address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

     
    uint256[] internal allTokens;

     
    mapping(uint256 => uint256) internal allTokensIndex;

     
    string public tokenUriPrefix = "https://eth.town/hero-image/";

     
    address public logicContract;

     
    uint32 public uniquenessIndex = 0;
     
    uint256 public lastTokenId = 0;

     
    mapping(address => uint256) public activeHero;

     
    mapping(uint256 => HeroData) public heroData;

     
    mapping(uint256 => uint256) public genome;

    event ActiveHeroChanged(address indexed _from, uint256 _tokenId);

    modifier onlyLogicContract {
        require(msg.sender == logicContract || msg.sender == owner);
        _;
    }

     
    function ETHero() public {
        name_ = "ETH.TOWN Hero";
        symbol_ = "HERO";
    }

     
    function setLogicContract(address _logicContract) external onlyOwner {
        logicContract = _logicContract;
    }

     
    function name() public view returns (string) {
        return name_;
    }

     
    function symbol() public view returns (string) {
        return symbol_;
    }

     
    function _isTransferAllowed(address _from, address _to, uint256 _tokenId) internal view returns (bool) {
        if (logicContract == address(0)) {
            return true;
        }

        HeroLogicInterface logic = HeroLogicInterface(logicContract);
        return logic.isTransferAllowed(_from, _to, _tokenId);
    }

     
    function _appendUintToString(string _str, uint _value) internal pure returns (string) {
        uint maxLength = 100;
        bytes memory reversed = new bytes(maxLength);
        uint i = 0;
        while (_value != 0) {
            uint remainder = _value % 10;
            _value = _value / 10;
            reversed[i++] = byte(48 + remainder);
        }
        i--;

        bytes memory inStrB = bytes(_str);
        bytes memory s = new bytes(inStrB.length + i + 1);
        uint j;
        for (j = 0; j < inStrB.length; j++) {
            s[j] = inStrB[j];
        }
        for (j = 0; j <= i; j++) {
            s[j + inStrB.length] = reversed[i - j];
        }
        return string(s);
    }

     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return _appendUintToString(tokenUriPrefix, genome[_tokenId]);
    }

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

     
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

     
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return allTokens[_index];
    }

     
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;

        if (activeHero[_to] == 0) {
            activeHero[_to] = _tokenId;
            emit ActiveHeroChanged(_to, _tokenId);
        }
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

         
        if (activeHero[_from] == _tokenId) {
            activeHero[_from] = 0;
            emit ActiveHeroChanged(_from, 0);
        }
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

     
    function mint(address _to, uint256 _tokenId) external onlyLogicContract {
        _mint(_to, _tokenId);
    }

     
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);

         
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;

         
        if (genome[_tokenId] != 0) {
            genome[_tokenId] = 0;
        }
    }

     
    function burn(address _owner, uint256 _tokenId) external onlyLogicContract {
        _burn(_owner, _tokenId);
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_isTransferAllowed(_from, _to, _tokenId));
        super.transferFrom(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId)
        public
        canTransfer(_tokenId)
    {
        require(_isTransferAllowed(_from, _to, _tokenId));
        super.safeTransferFrom(_from, _to, _tokenId);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data)
        public
        canTransfer(_tokenId)
    {
        require(_isTransferAllowed(_from, _to, _tokenId));
        super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

     
    function transfer(address _to, uint256 _tokenId) external onlyOwnerOf(_tokenId) {
        require(_isTransferAllowed(msg.sender, _to, _tokenId));
        require(_to != address(0));

        clearApproval(msg.sender, _tokenId);
        removeTokenFrom(msg.sender, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(msg.sender, _to, _tokenId);
    }

     
    function setActiveHero(uint256 _tokenId) external onlyOwnerOf(_tokenId) {
        activeHero[msg.sender] = _tokenId;
        emit ActiveHeroChanged(msg.sender, _tokenId);
    }

     
    function tokensOfOwner(address _owner) external view returns (uint256[]) {
        return ownedTokens[_owner];
    }

     
    function activeHeroGenome(address _owner) public view returns (uint256) {
        uint256 tokenId = activeHero[_owner];
        if (tokenId == 0) {
            return 0;
        }

        return genome[tokenId];
    }

     
    function incrementUniquenessIndex() external onlyLogicContract {
        uniquenessIndex ++;
    }

     
    function incrementLastTokenId() external onlyLogicContract {
        lastTokenId ++;
    }

     
    function setUniquenessIndex(uint32 _uniquenessIndex) external onlyOwner {
        uniquenessIndex = _uniquenessIndex;
    }

     
    function setLastTokenId(uint256 _lastTokenId) external onlyOwner {
        lastTokenId = _lastTokenId;
    }

     
    function setHeroData(
        uint256 _tokenId,
        uint16 _fieldA,
        uint16 _fieldB,
        uint32 _fieldC,
        uint32 _fieldD,
        uint32 _fieldE,
        uint64 _fieldF,
        uint64 _fieldG
    ) external onlyLogicContract {
        heroData[_tokenId] = HeroData(
            _fieldA,
            _fieldB,
            _fieldC,
            _fieldD,
            _fieldE,
            _fieldF,
            _fieldG
        );
    }

     
    function setGenome(uint256 _tokenId, uint256 _genome) external onlyLogicContract {
        genome[_tokenId] = _genome;
    }

     
    function forceTransfer(address _from, address _to, uint256 _tokenId) external onlyLogicContract {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

     
    function setTokenUriPrefix(string _uriPrefix) external onlyOwner {
        tokenUriPrefix = _uriPrefix;
    }


}