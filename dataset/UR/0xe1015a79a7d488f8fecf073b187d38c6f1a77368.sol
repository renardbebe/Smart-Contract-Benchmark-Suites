 

pragma solidity ^0.4.19;

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) external;
  function setApprovalForAll(address _to, bool _approved) external;
  function getApproved(uint256 _tokenId) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

 
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

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

library Strings {
   
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}


 
 
 
interface ERC721Metadata   {
     
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
}

contract ERC721SlimToken is Ownable, ERC721, ERC165, ERC721Metadata {
  using SafeMath for uint256;

  string public constant NAME = "EtherLoot";
  string public constant SYMBOL = "ETLT";
  string public tokenMetadataBaseURI = "http://api.etherloot.moonshadowgames.com/tokenmetadata/";

  struct AddressAndTokenIndex {
    address owner;
    uint32 tokenIndex;
  }

  mapping (uint256 => AddressAndTokenIndex) private tokenOwnerAndTokensIndex;

  mapping (address => uint256[]) private ownedTokens;

  mapping (uint256 => address) private tokenApprovals;

  mapping (address => mapping (address => bool)) private operatorApprovals;

  mapping (address => bool) private approvedContractAddresses;

  bool approvedContractsFinalized = false;

  function implementsERC721() external pure returns (bool) {
    return true;
  }



  function supportsInterface(
    bytes4 interfaceID)
    external view returns (bool)
  {
    return
      interfaceID == this.supportsInterface.selector ||  
      interfaceID == 0x5b5e139f ||  
      interfaceID == 0x6466353c;  
  }

  function name() external pure returns (string) {
    return NAME;
  }

  function symbol() external pure returns (string) {
    return SYMBOL;
  }

  function setTokenMetadataBaseURI(string _tokenMetadataBaseURI) external onlyOwner {
    tokenMetadataBaseURI = _tokenMetadataBaseURI;
  }

  function tokenURI(uint256 tokenId)
    external
    view
    returns (string infoUrl)
  {
    return Strings.strConcat(
      tokenMetadataBaseURI,
      Strings.uint2str(tokenId));
  }

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender, "not owner");
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0), "null owner");
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner), "invalid index");
    return ownedTokens[_owner][_index];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address _owner = tokenOwnerAndTokensIndex[_tokenId].owner;
    require(_owner != address(0), "invalid owner");
    return _owner;
  }

  function exists(uint256 _tokenId) public view returns (bool) {
    address _owner = tokenOwnerAndTokensIndex[_tokenId].owner;
    return (_owner != address(0));
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function isSenderApprovedFor(uint256 _tokenId) internal view returns (bool) {
    return
      ownerOf(_tokenId) == msg.sender ||
      isSpecificallyApprovedFor(msg.sender, _tokenId) ||
      isApprovedForAll(ownerOf(_tokenId), msg.sender);
  }

   
  function isSpecificallyApprovedFor(address _asker, uint256 _tokenId) internal view returns (bool) {
    return getApproved(_tokenId) == _asker;
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transfer(address _to, uint256 _tokenId)
    external
    onlyOwnerOf(_tokenId)
  {
    _clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId)
    external
    onlyOwnerOf(_tokenId)
  {
    address _owner = ownerOf(_tokenId);
    require(_to != _owner, "already owns");
    if (getApproved(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(_owner, _to, _tokenId);
    }
  }

   
  function setApprovalForAll(address _to, bool _approved)
    external
  {
    if(_approved) {
      approveAll(_to);
    } else {
      disapproveAll(_to);
    }
  }

   
  function approveAll(address _to)
    public
  {
    require(_to != msg.sender, "cant approve yourself");
    require(_to != address(0), "invalid owner");
    operatorApprovals[msg.sender][_to] = true;
    emit ApprovalForAll(msg.sender, _to, true);
  }

   
  function disapproveAll(address _to)
    public
  {
    require(_to != msg.sender, "cant unapprove yourself");
    delete operatorApprovals[msg.sender][_to];
    emit ApprovalForAll(msg.sender, _to, false);
  }

   
  function takeOwnership(uint256 _tokenId)
   external
  {
    require(isSenderApprovedFor(_tokenId), "not approved");
    _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    address tokenOwner = ownerOf(_tokenId);
    require(isSenderApprovedFor(_tokenId) || 
      (approvedContractAddresses[msg.sender] && tokenOwner == tx.origin), "not an approved sender");
    require(tokenOwner == _from, "wrong owner");
    _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    require(_to != address(0), "invalid target address");
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
      bytes4 tokenReceiverResponse = ERC721TokenReceiver(_to).onERC721Received.gas(50000)(
        _from, _tokenId, _data
      );
      require(tokenReceiverResponse == bytes4(keccak256("onERC721Received(address,uint256,bytes)")), "invalid receiver respononse");
    }
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
  {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function addApprovedContractAddress(address contractAddress) public onlyOwner
  {
    require(!approvedContractsFinalized);
    approvedContractAddresses[contractAddress] = true;
  }

   
  function removeApprovedContractAddress(address contractAddress) public onlyOwner
  {
    require(!approvedContractsFinalized);
    approvedContractAddresses[contractAddress] = false;
  }

   
  function finalizeApprovedContracts() public onlyOwner {
    approvedContractsFinalized = true;
  }

   
  function mint(address _to, uint256 _tokenId) public {
    require(
      approvedContractAddresses[msg.sender] ||
      msg.sender == owner, "minter not approved"
    );
    _mint(_to, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0), "invalid target address");
    require(tokenOwnerAndTokensIndex[_tokenId].owner == address(0), "token already exists");
    _addToken(_to, _tokenId);
    emit Transfer(0x0, _to, _tokenId);
  }

   
  function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0), "invalid target address");
    require(_to != ownerOf(_tokenId), "already owns");
    require(ownerOf(_tokenId) == _from, "wrong owner");

    _clearApproval(_from, _tokenId);
    _removeToken(_from, _tokenId);
    _addToken(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

   
  function _clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner, "wrong owner");
    if (tokenApprovals[_tokenId] != 0) {
      tokenApprovals[_tokenId] = 0;
      emit Approval(_owner, 0, _tokenId);
    }
  }

   
  function _addToken(address _to, uint256 _tokenId) private {
    uint256 newTokenIndex = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);

     
    require(newTokenIndex == uint256(uint32(newTokenIndex)), "overflow");

    tokenOwnerAndTokensIndex[_tokenId] = AddressAndTokenIndex({owner: _to, tokenIndex: uint32(newTokenIndex)});
  }

   
  function _removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from, "wrong owner");

    uint256 tokenIndex = tokenOwnerAndTokensIndex[_tokenId].tokenIndex;
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;

    ownedTokens[_from].length--;
    tokenOwnerAndTokensIndex[lastToken] = AddressAndTokenIndex({owner: _from, tokenIndex: uint32(tokenIndex)});
  }

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}