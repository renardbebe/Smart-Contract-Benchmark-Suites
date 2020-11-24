 

pragma solidity ^0.4.18;

 
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

 
contract ERC721 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );

    function balanceOf(address _owner) public view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) public view returns (address _owner);

    function transfer(address _to, uint256 _tokenId) public;

    function approve(address _to, uint256 _tokenId) public;

    function takeOwnership(uint256 _tokenId) public;
}

 

 
contract NFTKred is ERC721 {
    using SafeMath for uint256;

     
    string public name;
    string public symbol;

     
     
    uint8 public valueDecimals = 7;

     
    mapping(uint => uint) public nftBatch;
    mapping(uint => uint) public nftSequence;
    mapping(uint => uint) public nftCount;

     
     
    mapping(uint => uint256) public nftValue;

     
     

     
    mapping(uint => string) public nftName;

     
    mapping(uint => string) public nftType;

     
    mapping(uint => string) public nftURIs;

     
    mapping(uint => string) public tokenIPFSs;

     
    uint256 private totalTokens;

     
    mapping(uint256 => address) private tokenOwner;

     
    mapping(uint256 => address) private tokenApprovals;

     
    mapping(address => uint256[]) private ownedTokens;

     
    mapping(uint256 => uint256) private ownedTokensIndex;

     
    function name() external view returns (string _name) {
        return name;
    }

    function symbol() external view returns (string _symbol) {
        return symbol;
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return nftURIs[_tokenId];
    }

    function tokenIPFS(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenIPFSs[_tokenId];
    }

     
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

     
     
    constructor(
        string tokenName,
        string tokenSymbol
    ) public {
        name = tokenName;
         
        symbol = tokenSymbol;
         
    }

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokens[_owner].length;
    }

     
    function tokensOf(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function approvedFor(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

     
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }

     
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        if (approvedFor(_tokenId) != 0 || _to != 0) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

     
    function takeOwnership(uint256 _tokenId) public {
        require(isApprovedFor(msg.sender, _tokenId));
        clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

     
    function mint(
        address _to,
        uint256 _tokenId,
        uint _batch,
        uint _sequence,
        uint _count,
        uint256 _value,
        string _type,
        string _IPFS,
        string _tokenURI
    ) public  
    {
         
        require(
            msg.sender == 0x979e636D308E86A2D9cB9B2eA5986d6E2f89FcC1 ||
            msg.sender == 0x0fEB00CAe329050915035dF479Ce6DBf747b01Fd
        );
        require(_to != address(0));
        require(nftValue[_tokenId] == 0);

         
        nftBatch[_tokenId] = _batch;
        nftSequence[_tokenId] = _sequence;
        nftCount[_tokenId] = _count;

         
        nftValue[_tokenId] = _value;

         
        nftType[_tokenId] = _type;

         
        tokenIPFSs[_tokenId] = _IPFS;

         
        nftURIs[_tokenId] = _tokenURI;

        addToken(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }


     
    function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
        if (approvedFor(_tokenId) != 0) {
            clearApproval(msg.sender, _tokenId);
        }
        removeToken(msg.sender, _tokenId);
        emit Transfer(msg.sender, 0x0, _tokenId);
    }

     
    function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
        return approvedFor(_tokenId) == _owner;
    }

     
    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));
        require(ownerOf(_tokenId) == _from);

        clearApproval(_from, _tokenId);
        removeToken(_from, _tokenId);
        addToken(_to, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

     
    function clearApproval(address _owner, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _owner);
        tokenApprovals[_tokenId] = 0;
        emit Approval(_owner, 0, _tokenId);
    }

     
    function addToken(address _to, uint256 _tokenId) private {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        totalTokens = totalTokens.add(1);
    }

     
    function removeToken(address _from, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _from);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf(_from).sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        tokenOwner[_tokenId] = 0;
        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
         
         
         

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        totalTokens = totalTokens.sub(1);
    }

     
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {

        if (_interfaceID == 0xffffffff) {
            return false;
        }
        return _interfaceID == 0x01ffc9a7 ||   
               _interfaceID == 0x7c0633c6 ||   
               _interfaceID == 0x80ac58cd ||   
               _interfaceID == 0x5b5e139f;     
    }
}