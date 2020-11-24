 

pragma solidity 0.4.24;

 

 
contract ERC165 {

   
  bytes4 constant INTERFACE_ERC165 = 0x01ffc9a7;

   
  function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
    return _interfaceID == INTERFACE_ERC165;
  }
}

 

 
contract ERC721Basic {
   
   
   
   
   
   
   
   
   
  bytes4 constant INTERFACE_ERC721 = 0x80ac58cd;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool indexed _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);

   
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId) public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId) public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data) public;
}

 

 
contract ERC721Enumerable is ERC721Basic {
   
   
   
  bytes4 constant INTERFACE_ERC721_ENUMERABLE = 0x780e9d63;

  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
   
   
   
  bytes4 constant INTERFACE_ERC721_METADATA = 0x5b5e139f;

  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
contract ProxyOwnable {
  address public proxyOwner;

  event ProxyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    proxyOwner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == proxyOwner);
    _;
  }

   
  function transferProxyOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));

    emit ProxyOwnershipTransferred(proxyOwner, _newOwner);

    proxyOwner = _newOwner;
  }
}

 

 
contract CodexRecordProxy is ProxyOwnable {
  event Upgraded(string version, address indexed implementation);

  string public version;
  address public implementation;

  constructor(address _implementation) public {
    upgradeTo("1", _implementation);
  }

   
  function () payable public {
    address _implementation = implementation;

     
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _implementation, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

   
  function name() external view returns (string) {
    ERC721Metadata tokenMetadata = ERC721Metadata(implementation);

    return tokenMetadata.name();
  }

   
  function symbol() external view returns (string) {
    ERC721Metadata tokenMetadata = ERC721Metadata(implementation);

    return tokenMetadata.symbol();
  }

   
  function upgradeTo(string _version, address _implementation) public onlyOwner {
    require(
      keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(version)),
      "The version cannot be the same");

    require(
      _implementation != implementation,
      "The implementation cannot be the same");

    require(
      _implementation != address(0),
      "The implementation cannot be the 0 address");

    version = _version;
    implementation = _implementation;

    emit Upgraded(version, implementation);
  }
}