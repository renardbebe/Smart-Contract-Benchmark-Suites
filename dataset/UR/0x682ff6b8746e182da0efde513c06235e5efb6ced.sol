 

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
    function exists(uint256 _tokenId) public view returns (bool _exists);

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

 

 
library AddressUtils {

     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
        assembly { size := extcodesize(addr) }   
        return size > 0;
    }

}

 

 
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

     
    mapping (address => uint256[]) internal ownedTokens;

     
    mapping(uint256 => uint256) internal ownedTokensIndex;

     
    uint256[] internal allTokens;

     
    mapping(uint256 => uint256) internal allTokensIndex;

     
    mapping(uint256 => string) internal tokenURIs;

     
    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }

     
    function name() public view returns (string) {
        return name_;
    }

     
    function symbol() public view returns (string) {
        return symbol_;
    }

     
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
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

     
    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
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

     
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

}

 
 
contract FYouToken is Ownable, ERC721Token {
    using SafeMath for uint256;


    modifier onlyTwoMil() {
        require(fYouTokens < 2000001);
        _;
    }

    struct Graffiti {
        bool exists;
        string message;
        string infoUrlOrIPFSHash;
    }


    mapping(uint256 => Graffiti) private tokenGraffiti;

    uint256 private fYouTokens;

    constructor() public ERC721Token("F You Token", "FYT") {

    }

     
    uint256 private fee = 1;
    
     
    function fYou(address _schmuck, string _clearTextMessageJustToBeSuperClear, string _infoUrlOrIPFSHash) external payable onlyTwoMil {
        require(_schmuck != address(0) && msg.value == (fee * (1 finney)));

        _fYou(_schmuck, fYouTokens, _clearTextMessageJustToBeSuperClear, _infoUrlOrIPFSHash);
        fYouTokens = fYouTokens + 1;
        feesAvailableForWithdraw = feesAvailableForWithdraw.add(msg.value);
    }

     
    function giantFYou(address _to, uint256 _numTokens) external payable onlyTwoMil {
        require(_to != address(0) && _numTokens > 0 && _numTokens < 11 && msg.value == (fee.mul(_numTokens) * (1 finney)));
        uint tokensCount = _numTokens.add(fYouTokens);
        require(allTokens.length < 2000001 && tokensCount < 2000001);
        for (uint256 i = 0; i < _numTokens; i++) {
        _fYou(_to, (fYouTokens + i), '', '');
        }
        fYouTokens = tokensCount;
        feesAvailableForWithdraw = feesAvailableForWithdraw.add(msg.value);
    }

     
    function paintGraffiti(uint256 _tokenId, string _clearTextMessageJustToBeSuperClear, string _infoUrlOrIPFSHash) external onlyOwnerOf(_tokenId) {
        _addGraffiti(_tokenId, _clearTextMessageJustToBeSuperClear, _infoUrlOrIPFSHash);
    }

    function _fYou(address _to, uint _tokenId, string _clearTextMessageJustToBeSuperClear, string _infoUrlOrIPFSHash) internal {
        _addGraffiti(_tokenId, _clearTextMessageJustToBeSuperClear, _infoUrlOrIPFSHash);
        _mint(_to, _tokenId);
    }

    function _addGraffiti(uint256 _tokenId, string _clearTextMessageJustToBeSuperClear, string _infoUrlOrIPFSHash) private {
         
        require(tokenGraffiti[_tokenId].exists == false);
        bytes memory msgSize = bytes(_clearTextMessageJustToBeSuperClear);
        bytes memory urlSize = bytes(_infoUrlOrIPFSHash);
        if (urlSize.length > 0 || msgSize.length > 0) {
            tokenGraffiti[_tokenId] = Graffiti(true, _clearTextMessageJustToBeSuperClear, _infoUrlOrIPFSHash);
        }
    }

    function tokenMetadata(uint256 _tokenId) external constant returns (string infoUrlOrIPFSHash) {
        return tokenGraffiti[_tokenId].infoUrlOrIPFSHash;
    }

    function getGraffiti(uint256 _tokenId) external constant returns (string message, string infoUrlOrIPFSHash) {
        Graffiti memory graffiti = tokenGraffiti[_tokenId];
        return (graffiti.message, graffiti.infoUrlOrIPFSHash);
    }

    function tokensOf(address _owner) external view returns(uint256[]) {
        return ownedTokens[_owner];
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    uint256 private feesAvailableForWithdraw;

    function getFeesAvailableForWithdraw() external view onlyOwner returns (uint256) {
        return feesAvailableForWithdraw;
    }

    function withdrawFees(address _to, uint256 _amount) external onlyOwner {
         
        require(_amount <= feesAvailableForWithdraw);
         
        feesAvailableForWithdraw = feesAvailableForWithdraw.sub(_amount);
        _to.transfer(_amount);
    }
}