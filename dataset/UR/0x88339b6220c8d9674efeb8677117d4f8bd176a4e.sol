 

pragma solidity 0.4.24;

contract Cryptopixel {

     
    string constant public name = "CryptoPixel";
     
  	string constant public symbol = "CPX";


    using SafeMath for uint256;

     
     
     
     
    uint256 public totalSupply;
     
    address[limitChrt] internal artworkGroup;
     
    uint constant private limitChrt = 52;
     
    address constant private creatorAddr = 0x174B3C5f95c9F27Da6758C8Ca941b8FFbD01d330;

    
     
    mapping(uint => address) internal tokenIdToOwner;
    mapping(address => uint[]) internal listOfOwnerTokens;
    mapping(uint => string) internal referencedMetadata;
    
     
    event Minted(address indexed _to, uint256 indexed _tokenId);

     
    modifier onlyNonexistentToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] == address(0));
        _;
    }


     
     
     
     
    function ownerOf(uint256 _tokenId) public view returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }
    
     
    function totalSupply() public view returns (uint256 _totalSupply)
    {
        return totalSupply;
    }
    
     
    function balanceOf(address _owner) public view returns (uint _balance)
    {
        return listOfOwnerTokens[_owner].length;
    }

     
    function tokenMetadata(uint _tokenId) public view returns (string _metadata)
    {
        return referencedMetadata[_tokenId];
    }
    
     
    function getArtworkGroup() public view returns (address[limitChrt]) {
        return artworkGroup;
    }
    
    
     
     
     
     
    function mintWithMetadata(address _owner, uint256 _tokenId, string _metadata) public onlyNonexistentToken (_tokenId)
    {
        require(totalSupply < limitChrt);
        require(creatorAddr == _owner);
        
        _setTokenOwner(_tokenId, _owner);
        _addTokenToOwnersList(_owner, _tokenId);
        _insertTokenMetadata(_tokenId, _metadata);

        artworkGroup[_tokenId] = _owner;
        totalSupply = totalSupply.add(1);
        emit Minted(_owner, _tokenId);
    }

     
    function group(address _owner, uint _tokenId) public returns (uint) {
        require(_tokenId >= 0 && _tokenId <= limitChrt);
        artworkGroup[_tokenId] = _owner;    
        return _tokenId;
    }

    
     
     
     
    function _setTokenOwner(uint _tokenId, address _owner) internal
    {
        tokenIdToOwner[_tokenId] = _owner;
    }

    function _addTokenToOwnersList(address _owner, uint _tokenId) internal
    {
        listOfOwnerTokens[_owner].push(_tokenId);
    }

    function _insertTokenMetadata(uint _tokenId, string _metadata) internal
    {
        referencedMetadata[_tokenId] = _metadata;
    }
    
}

 
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