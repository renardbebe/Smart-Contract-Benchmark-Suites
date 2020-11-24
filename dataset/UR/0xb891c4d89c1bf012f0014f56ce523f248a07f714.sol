 

pragma solidity ^0.4.24;

 
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

library UrlStr {
  
   
   
  function generateUrl(string url,uint256 _tokenId) internal pure returns (string _url){
    _url = url;
    bytes memory _tokenURIBytes = bytes(_url);
    uint256 base_len = _tokenURIBytes.length - 1;
    _tokenURIBytes[base_len - 7] = byte(48 + _tokenId / 10000000 % 10);
    _tokenURIBytes[base_len - 6] = byte(48 + _tokenId / 1000000 % 10);
    _tokenURIBytes[base_len - 5] = byte(48 + _tokenId / 100000 % 10);
    _tokenURIBytes[base_len - 4] = byte(48 + _tokenId / 10000 % 10);
    _tokenURIBytes[base_len - 3] = byte(48 + _tokenId / 1000 % 10);
    _tokenURIBytes[base_len - 2] = byte(48 + _tokenId / 100 % 10);
    _tokenURIBytes[base_len - 1] = byte(48 + _tokenId / 10 % 10);
    _tokenURIBytes[base_len - 0] = byte(48 + _tokenId / 1 % 10);
  }
}


 
interface AvatarChildService {
   
   function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res);
}

interface AvatarService {
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external;
  function createAvatar(address _owner, string _name, uint256 _dna) external  returns(uint256);
  function getMountTokenIds(address _owner,uint256 _tokenId, address _avatarItemAddress) external view returns(uint256[]); 
  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna);
  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds);
}

interface ERC165 {
  
   
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}


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


 
contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


 
contract BitGuildAccessAdmin {
  address public owner;
  address[] public operators;

  uint public MAX_OPS = 20;  

  mapping(address => bool) public isOperator;

  event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
  );
  event OperatorAdded(address operator);
  event OperatorRemoved(address operator);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyOperator {
    require(
      isOperator[msg.sender] || msg.sender == owner,
      "Permission denied. Must be an operator or the owner.");
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(
      _newOwner != address(0),
      "Invalid new owner address."
    );
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

   
  function addOperator(address _newOperator) public onlyOwner {
    require(
      _newOperator != address(0),
      "Invalid new operator address."
    );

     
    require(
      !isOperator[_newOperator],
      "New operator exists."
    );

     
    require(
      operators.length < MAX_OPS,
      "Overflow."
    );

    operators.push(_newOperator);
    isOperator[_newOperator] = true;

    emit OperatorAdded(_newOperator);
  }

   
  function removeOperator(address _operator) public onlyOwner {
     
    require(
      operators.length > 0,
      "No operator."
    );

     
    require(
      isOperator[_operator],
      "Not an operator."
    );

     
     
     
    address lastOperator = operators[operators.length - 1];
    for (uint i = 0; i < operators.length; i++) {
      if (operators[i] == _operator) {
        operators[i] = lastOperator;
      }
    }
    operators.length -= 1;  

    isOperator[_operator] = false;
    emit OperatorRemoved(_operator);
  }

   
  function removeAllOps() public onlyOwner {
    for (uint i = 0; i < operators.length; i++) {
      isOperator[operators[i]] = false;
    }
    operators.length = 0;
  } 

}


contract BitGuildAccessAdminExtend is BitGuildAccessAdmin {

  event FrozenFunds(address target, bool frozen);

  bool public isPaused = false;
  
  mapping(address => bool)  frozenAccount;

  modifier whenNotPaused {
    require(!isPaused);
    _;
  }

  modifier whenPaused {
    require(isPaused);
    _;  
  }

  function doPause() external  whenNotPaused onlyOwner {
    isPaused = true;
  }

  function doUnpause() external  whenPaused onlyOwner {
    isPaused = false;
  }

  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

}


interface ERC998ERC721TopDown {
  event ReceivedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
  event TransferChild(uint256 indexed tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);
   
  function tokenOwnerOf(uint256 _tokenId) external view returns (address tokenOwner, uint256 parentTokenId, uint256 isParent);
  function ownerOfChild(address _childContract, uint256 _childTokenId) external view returns (uint256 parentTokenId, uint256 isParent);
  function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns(bytes4);
  function onERC998Removed(address _operator, address _toContract, uint256 _childTokenId, bytes _data) external;
  function transferChild(address _to, address _childContract, uint256 _childTokenId) external;
  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId) external;
  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId, bytes _data) external;
   
   
  function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external;
}

interface ERC998ERC721TopDownEnumerable {
  function totalChildContracts(uint256 _tokenId) external view returns(uint256);
  function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract);
  function totalChildTokens(uint256 _tokenId, address _childContract) external view returns(uint256);
  function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId);
}

interface ERC998ERC20TopDown {
  event ReceivedERC20(address indexed _from, uint256 indexed _tokenId, address indexed _erc223Contract, uint256 _value);
  event TransferERC20(uint256 indexed _tokenId, address indexed _to, address indexed _erc223Contract, uint256 _value);

  function tokenOwnerOf(uint256 _tokenId) external view returns (address tokenOwner, uint256 parentTokenId, uint256 isParent);
  function tokenFallback(address _from, uint256 _value, bytes _data) external;
  function balanceOfERC20(uint256 _tokenId, address __erc223Contract) external view returns(uint256);
  function transferERC20(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value) external;
  function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external;
  function getERC20(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) external;

}

interface ERC998ERC20TopDownEnumerable {
  function totalERC20Contracts(uint256 _tokenId) external view returns(uint256);
  function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns(address);
}

interface ERC20AndERC223 {
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function transfer(address to, uint value) external returns (bool success);
  function transfer(address to, uint value, bytes data) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract ComposableTopDown is ERC721, ERC998ERC721TopDown, ERC998ERC721TopDownEnumerable,
                                     ERC998ERC20TopDown, ERC998ERC20TopDownEnumerable, BitGuildAccessAdminExtend{
                            
   
  uint256 constant TOKEN_OWNER_OF = 0x89885a59;
  uint256 constant OWNER_OF_CHILD = 0xeadb80b8;

   
  mapping (uint256 => address) internal tokenIdToTokenOwner;

   
  mapping (address => mapping (uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;

   
  mapping (address => uint256) internal tokenOwnerToTokenCount;

   
  mapping (address => mapping (address => bool)) internal tokenOwnerToOperators;


   
   
  bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
   
  bytes4 constant ERC721_RECEIVED_NEW = 0x150b7a02;
     
  bytes4  constant InterfaceId_ERC998 = 0x520bdcbe;
               
               
               
               
               
               
               
               




   
   
   
  
  function _mint(address _to,uint256 _tokenId) internal whenNotPaused {
    tokenIdToTokenOwner[_tokenId] = _to;
    tokenOwnerToTokenCount[_to]++;
    emit Transfer(address(0), _to, _tokenId);
  }

  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

  function tokenOwnerOf(uint256 _tokenId) external view returns (address tokenOwner, uint256 parentTokenId, uint256 isParent) {
    tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(tokenOwner != address(0));
    if(tokenOwner == address(this)) {
      (parentTokenId, isParent) = ownerOfChild(address(this), _tokenId);
    }
    else {
      bool callSuccess;
       
      bytes memory calldata = abi.encodeWithSelector(0xeadb80b8, address(this), _tokenId);
      assembly {
        callSuccess := staticcall(gas, tokenOwner, add(calldata, 0x20), mload(calldata), calldata, 0x40)
        if callSuccess {
          parentTokenId := mload(calldata)
          isParent := mload(add(calldata,0x20))
        }
      }
      if(callSuccess && isParent >> 8 == OWNER_OF_CHILD) {
        isParent = TOKEN_OWNER_OF << 8 | uint8(isParent);
      }
      else {
        isParent = TOKEN_OWNER_OF << 8;
        parentTokenId = 0;
      }
    }
    return (tokenOwner, parentTokenId, isParent);
  }

  function ownerOf(uint256 _tokenId) external view returns (address rootOwner) {
    return _ownerOf(_tokenId);
  }
  
   
  function _ownerOf(uint256 _tokenId) internal view returns (address rootOwner) {
    rootOwner = tokenIdToTokenOwner[_tokenId];
    require(rootOwner != address(0));
    uint256 isParent = 1;
    bool callSuccess;
    bytes memory calldata;
    while(uint8(isParent) > 0) {
      if(rootOwner == address(this)) {
        (_tokenId, isParent) = ownerOfChild(address(this), _tokenId);
        if(uint8(isParent) > 0) {
          rootOwner = tokenIdToTokenOwner[_tokenId];
        }
      }
      else {
        if(isContract(rootOwner)) {
           
          calldata = abi.encodeWithSelector(0x89885a59, _tokenId);
          assembly {
            callSuccess := staticcall(gas, rootOwner, add(calldata, 0x20), mload(calldata), calldata, 0x60)
            if callSuccess {
              rootOwner := mload(calldata)
              _tokenId := mload(add(calldata,0x20))
              isParent := mload(add(calldata,0x40))
            }
          }
          
          if(callSuccess == false || isParent >> 8 != TOKEN_OWNER_OF) {
             
            calldata = abi.encodeWithSelector(0x6352211e, _tokenId);
            assembly {
              callSuccess := staticcall(gas, rootOwner, add(calldata, 0x20), mload(calldata), calldata, 0x20)
              if callSuccess {
                rootOwner := mload(calldata)
              }
            }
            require(callSuccess, "rootOwnerOf failed");
            isParent = 0;
          }
        }
        else {
          isParent = 0;
        }
      }
    }
    return rootOwner;
  }

  function balanceOf(address _tokenOwner)  external view returns (uint256) {
    require(_tokenOwner != address(0));
    return tokenOwnerToTokenCount[_tokenOwner];
  }


  function approve(address _approved, uint256 _tokenId) external whenNotPaused {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    address rootOwner = _ownerOf(_tokenId);
    require(tokenOwner != address(0));
    require(
      rootOwner == msg.sender || 
      tokenOwnerToOperators[rootOwner][msg.sender] || 
      tokenOwner == msg.sender || 
      tokenOwnerToOperators[tokenOwner][msg.sender]);

    rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
    emit Approval(rootOwner, _approved, _tokenId);
  }

  function getApproved(uint256 _tokenId) external view returns (address)  {
    address rootOwner = _ownerOf(_tokenId);
    return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
  }

  function setApprovalForAll(address _operator, bool _approved) external whenNotPaused {
    require(_operator != address(0));
    tokenOwnerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function isApprovedForAll(address _owner, address _operator ) external  view returns (bool)  {
    require(_owner != address(0));
    require(_operator != address(0));
    return tokenOwnerToOperators[_owner][_operator];
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
    require(!frozenAccount[_from]);                  
    require(!frozenAccount[_to]); 
     
     
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));
    address rootOwner = _ownerOf(_tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);

     
    if(rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] != address(0)) {
      delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

     
    if(_from != _to) {
      assert(tokenOwnerToTokenCount[_from] > 0);
      tokenOwnerToTokenCount[_from]--;
      tokenIdToTokenOwner[_tokenId] = _to;
      tokenOwnerToTokenCount[_to]++;
    }
    emit Transfer(_from, _to, _tokenId);

    if(isContract(_from)) {
       
      bytes memory calldata = abi.encodeWithSelector(0x0da719ec, msg.sender, _to, _tokenId,"");
      assembly {
        let success := call(gas, _from, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
      }
    }

  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    _transfer(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
    _transfer(_from, _to, _tokenId);
    if(isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
      require(retval == ERC721_RECEIVED_OLD);
    }
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
    _transfer(_from, _to, _tokenId);
    if(isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == ERC721_RECEIVED_OLD);
    }
  }

   
   
   

   
  mapping(uint256 => address[]) internal childContracts;

   
  mapping(uint256 => mapping(address => uint256)) internal childContractIndex;

   
  mapping(uint256 => mapping(address => uint256[])) internal childTokens;

   
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal childTokenIndex;

   
  mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;

  function onERC998Removed(address _operator, address _toContract, uint256 _childTokenId, bytes _data) external {
    uint256 tokenId = childTokenOwner[msg.sender][_childTokenId];
    _removeChild(tokenId, msg.sender, _childTokenId);
  }


  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId) external {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    _removeChild(tokenId, _childContract, _childTokenId);
    ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId, bytes _data) external {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    _removeChild(tokenId, _childContract, _childTokenId);
    ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId, _data);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  function transferChild(address _to, address _childContract, uint256 _childTokenId) external {
    _transferChild(_to, _childContract,_childTokenId);
  }
 
  function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external {
    _getChild(_from, _tokenId, _childContract,_childTokenId);
  }

  function onERC721Received(address _from, uint256 _childTokenId, bytes _data) external returns(bytes4) {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
    require(isContract(msg.sender), "msg.sender is not a contract.");
     
     
    uint256 tokenId;
    assembly {
       
       
      tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
     

     

    _receiveChild(_from, tokenId, msg.sender, _childTokenId);
     
    _ownerOf(tokenId);
    return ERC721_RECEIVED_OLD;
  }


  function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns(bytes4) {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
    require(isContract(msg.sender), "msg.sender is not a contract.");
     
     
    uint256 tokenId;
    assembly {
       
      tokenId := calldataload(164)
       
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
     

     

    _receiveChild(_from, tokenId, msg.sender, _childTokenId);
     
    _ownerOf(tokenId);
    return ERC721_RECEIVED_NEW;
  }

  function _transferChild(address _to, address _childContract, uint256 _childTokenId) internal {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    _removeChild(tokenId, _childContract, _childTokenId);
     
     
     
     
    bytes memory calldata = abi.encodeWithSelector(0x095ea7b3, this, _childTokenId);
    assembly {
      let success := call(gas, _childContract, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
    }
    ERC721(_childContract).transferFrom(this, _to, _childTokenId);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

   
  function _getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    _receiveChild(_from, _tokenId, _childContract, _childTokenId);
    require(
      _from == msg.sender || ERC721(_childContract).isApprovedForAll(_from, msg.sender) ||
    ERC721(_childContract).getApproved(_childTokenId) == msg.sender);
    ERC721(_childContract).transferFrom(_from, this, _childTokenId);
     
    _ownerOf(_tokenId);
  }

  function _receiveChild(address _from,  uint256 _tokenId, address _childContract, uint256 _childTokenId) private whenNotPaused {  
    require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
    require(childTokenIndex[_tokenId][_childContract][_childTokenId] == 0, "Cannot receive child token because it has already been received.");
    uint256 childTokensLength = childTokens[_tokenId][_childContract].length;
    if(childTokensLength == 0) {
      childContractIndex[_tokenId][_childContract] = childContracts[_tokenId].length;
      childContracts[_tokenId].push(_childContract);
    }
    childTokens[_tokenId][_childContract].push(_childTokenId);
    childTokenIndex[_tokenId][_childContract][_childTokenId] = childTokensLength + 1;
    childTokenOwner[_childContract][_childTokenId] = _tokenId;
    emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
  }
  
  function _removeChild(uint256 _tokenId, address _childContract, uint256 _childTokenId) private whenNotPaused {
    uint256 tokenIndex = childTokenIndex[_tokenId][_childContract][_childTokenId];
    require(tokenIndex != 0, "Child token not owned by token.");

     
    uint256 lastTokenIndex = childTokens[_tokenId][_childContract].length-1;

    uint256 lastToken = childTokens[_tokenId][_childContract][lastTokenIndex];

     
    
    childTokens[_tokenId][_childContract][tokenIndex-1] = lastToken;
    childTokenIndex[_tokenId][_childContract][lastToken] = tokenIndex;
     
  
    childTokens[_tokenId][_childContract].length--;

    delete childTokenIndex[_tokenId][_childContract][_childTokenId];
    delete childTokenOwner[_childContract][_childTokenId];

     
    if(lastTokenIndex == 0) {
      uint256 lastContractIndex = childContracts[_tokenId].length - 1;
      address lastContract = childContracts[_tokenId][lastContractIndex];
      if(_childContract != lastContract) {
        uint256 contractIndex = childContractIndex[_tokenId][_childContract];
        childContracts[_tokenId][contractIndex] = lastContract;
        childContractIndex[_tokenId][lastContract] = contractIndex;
      }
      childContracts[_tokenId].length--;
      delete childContractIndex[_tokenId][_childContract];
    }
  }

  function ownerOfChild(address _childContract, uint256 _childTokenId) public view returns (uint256 parentTokenId, uint256 isParent) {
    parentTokenId = childTokenOwner[_childContract][_childTokenId];
    if(parentTokenId == 0 && childTokenIndex[parentTokenId][_childContract][_childTokenId] == 0) {
      return (0, OWNER_OF_CHILD << 8);
    }
    return (parentTokenId, OWNER_OF_CHILD << 8 | 1);
  }

  function childExists(address _childContract, uint256 _childTokenId) external view returns (bool) {
    uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
    return childTokenIndex[tokenId][_childContract][_childTokenId] != 0;
  }

  function totalChildContracts(uint256 _tokenId) external view returns(uint256) {
    return childContracts[_tokenId].length;
  }

  function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract) {
    require(_index < childContracts[_tokenId].length, "Contract address does not exist for this token and index.");
    return childContracts[_tokenId][_index];
  }

  function totalChildTokens(uint256 _tokenId, address _childContract) external view returns(uint256) {
    return childTokens[_tokenId][_childContract].length;
  }

  function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId) {
    require(_index < childTokens[_tokenId][_childContract].length, "Token does not own a child token at contract address and index.");
    return childTokens[_tokenId][_childContract][_index];
  }

   
   
   

   
  mapping(uint256 => address[]) erc223Contracts;

   
  mapping(uint256 => mapping(address => uint256)) erc223ContractIndex;
  
   
  mapping(uint256 => mapping(address => uint256)) erc223Balances;
  
  function balanceOfERC20(uint256 _tokenId, address _erc223Contract) external view returns(uint256) {
    return erc223Balances[_tokenId][_erc223Contract];
  }

  function removeERC223(uint256 _tokenId, address _erc223Contract, uint256 _value) private whenNotPaused {
    if(_value == 0) {
      return;
    }
    uint256 erc223Balance = erc223Balances[_tokenId][_erc223Contract];
    require(erc223Balance >= _value, "Not enough token available to transfer.");
    uint256 newERC223Balance = erc223Balance - _value;
    erc223Balances[_tokenId][_erc223Contract] = newERC223Balance;
    if(newERC223Balance == 0) {
      uint256 lastContractIndex = erc223Contracts[_tokenId].length - 1;
      address lastContract = erc223Contracts[_tokenId][lastContractIndex];
      if(_erc223Contract != lastContract) {
        uint256 contractIndex = erc223ContractIndex[_tokenId][_erc223Contract];
        erc223Contracts[_tokenId][contractIndex] = lastContract;
        erc223ContractIndex[_tokenId][lastContract] = contractIndex;
      }
      erc223Contracts[_tokenId].length--;
      delete erc223ContractIndex[_tokenId][_erc223Contract];
    }
  }
  
  
  function transferERC20(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(_tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeERC223(_tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transfer(_to, _value), "ERC20 transfer failed.");
    emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
  }
  
   
  function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(_to != address(0));
    address rootOwner = _ownerOf(_tokenId);
    require(
      rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeERC223(_tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transfer(_to, _value, _data), "ERC223 transfer failed.");
    emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
  }

   
  function getERC20(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) public {
    bool allowed = _from == msg.sender;
    if(!allowed) {
      uint256 remaining;
       
      bytes memory calldata = abi.encodeWithSelector(0xdd62ed3e,_from,msg.sender);
      bool callSuccess;
      assembly {
        callSuccess := staticcall(gas, _erc223Contract, add(calldata, 0x20), mload(calldata), calldata, 0x20)
        if callSuccess {
          remaining := mload(calldata)
        }
      }
      require(callSuccess, "call to allowance failed");
      require(remaining >= _value, "Value greater than remaining");
      allowed = true;
    }
    require(allowed, "not allowed to getERC20");
    erc223Received(_from, _tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transferFrom(_from, this, _value), "ERC20 transfer failed.");
  }

  function erc223Received(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) private {
    require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
    if(_value == 0) {
      return;
    }
    uint256 erc223Balance = erc223Balances[_tokenId][_erc223Contract];
    if(erc223Balance == 0) {
      erc223ContractIndex[_tokenId][_erc223Contract] = erc223Contracts[_tokenId].length;
      erc223Contracts[_tokenId].push(_erc223Contract);
    }
    erc223Balances[_tokenId][_erc223Contract] += _value;
    emit ReceivedERC20(_from, _tokenId, _erc223Contract, _value);
  }
  
   
  function tokenFallback(address _from, uint256 _value, bytes _data) external {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the token to.");
    require(isContract(msg.sender), "msg.sender is not a contract");
     
     
    uint256 tokenId;
    assembly {
      tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
     
    erc223Received(_from, tokenId, msg.sender, _value);
  }
  
  function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns(address) {
    require(_index < erc223Contracts[_tokenId].length, "Contract address does not exist for this token and index.");
    return erc223Contracts[_tokenId][_index];
  }
  
  function totalERC20Contracts(uint256 _tokenId) external view returns(uint256) {
    return erc223Contracts[_tokenId].length;
  }
  
}

contract ERC998TopDownToken is SupportsInterfaceWithLookup, ERC721Enumerable, ERC721Metadata, ComposableTopDown {

  using SafeMath for uint256;

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   
  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
              
   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor() public {
     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
    _registerInterface(InterfaceId_ERC998);
  }

  modifier existsToken(uint256 _tokenId){
    address owner = tokenIdToTokenOwner[_tokenId];
    require(owner != address(0), "This tokenId is invalid"); 
    _;
  }

   
  function name() external view returns (string) {
    return "Bitizen";
  }

   
  function symbol() external view returns (string) {
    return "BTZN";
  }

   
  function tokenURI(uint256 _tokenId) external view existsToken(_tokenId) returns (string) {
    return "";
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(address(0) != _owner);
    require(_index < tokenOwnerToTokenCount[_owner]);
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) existsToken(_tokenId) internal {
    tokenURIs[_tokenId] = _uri;
  }

   
  function _addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function _removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused {
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal whenNotPaused {
    super._mint(_to, _tokenId);
    _addTokenTo(_to,_tokenId);
    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
   
  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
    super._transfer(_from, _to, _tokenId);
    _addTokenTo(_to,_tokenId);
    _removeTokenFrom(_from, _tokenId);
  }
}


contract AvatarToken is ERC998TopDownToken, AvatarService {
  
  using UrlStr for string;

  event BatchMount(address indexed from, uint256 parent, address indexed childAddr, uint256[] children);
  event BatchUnmount(address indexed from, uint256 parent, address indexed childAddr, uint256[] children);
 
  struct Avatar {
     
    string name;
     
    uint256 dna;
  }

   
  string internal BASE_URL = "https://www.bitguild.com/bitizens/api/avatar/getAvatar/00000000";

  Avatar[] avatars;

  function createAvatar(address _owner, string _name, uint256 _dna) external onlyOperator returns(uint256) {
    return _createAvatar(_owner, _name, _dna);
  }

  function getMountTokenIds(address _owner, uint256 _tokenId, address _avatarItemAddress)
  external
  view 
  onlyOperator
  existsToken(_tokenId) 
  returns(uint256[]) {
    require(tokenIdToTokenOwner[_tokenId] == _owner);
    return childTokens[_tokenId][_avatarItemAddress];
  }
  
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external onlyOperator existsToken(_tokenId){
    require(_owner != address(0), "Invalid address");
    require(_owner == tokenIdToTokenOwner[_tokenId] || msg.sender == owner);
    Avatar storage avatar = avatars[allTokensIndex[_tokenId]];
    avatar.name = _name;
    avatar.dna = _dna;
  }

  function updateBaseURI(string _url) external onlyOperator {
    BASE_URL = _url;
  }

  function tokenURI(uint256 _tokenId) external view existsToken(_tokenId) returns (string) {
    return BASE_URL.generateUrl(_tokenId);
  }

  function getOwnedTokenIds(address _owner) external view returns(uint256[] _tokenIds) {
    _tokenIds = ownedTokens[_owner];
  }

  function getAvatarInfo(uint256 _tokenId) external view existsToken(_tokenId) returns(string _name, uint256 _dna) {
    Avatar storage avatar = avatars[allTokensIndex[_tokenId]];
    _name = avatar.name;
    _dna = avatar.dna;
  }

  function batchMount(address _childContract, uint256[] _childTokenIds, uint256 _tokenId) external {
    uint256 _len = _childTokenIds.length;
    require(_len > 0, "No token need to mount");
    address tokenOwner = _ownerOf(_tokenId);
    require(tokenOwner == msg.sender);
    for(uint8 i = 0; i < _len; ++i) {
      uint256 childTokenId = _childTokenIds[i];
      require(ERC721(_childContract).ownerOf(childTokenId) == tokenOwner);
      _getChild(msg.sender, _tokenId, _childContract, childTokenId);
    }
    emit BatchMount(msg.sender, _tokenId, _childContract, _childTokenIds);
  }
 
  function batchUnmount(address _childContract, uint256[] _childTokenIds, uint256 _tokenId) external {
    uint256 len = _childTokenIds.length;
    require(len > 0, "No token need to unmount");
    address tokenOwner = _ownerOf(_tokenId);
    require(tokenOwner == msg.sender);
    for(uint8 i = 0; i < len; ++i) {
      uint256 childTokenId = _childTokenIds[i];
      _transferChild(msg.sender, _childContract, childTokenId);
    }
    emit BatchUnmount(msg.sender,_tokenId,_childContract,_childTokenIds);
  }

   
  function _createAvatar(address _owner, string _name, uint256 _dna) private returns(uint256 _tokenId) {
    require(_owner != address(0));
    Avatar memory avatar = Avatar(_name, _dna);
    _tokenId = avatars.push(avatar);
    _mint(_owner, _tokenId);
  }

  function _unmountSameSocketItem(address _owner, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    uint256[] storage tokens = childTokens[_tokenId][_childContract];
    for(uint256 i = 0; i < tokens.length; ++i) {
       
      if(AvatarChildService(_childContract).compareItemSlots(tokens[i], _childTokenId)) {
         
        _transferChild(_owner, _childContract, tokens[i]);
      }
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
     
    require(tokenOwnerToTokenCount[_from] > 1);
    super._transfer(_from, _to, _tokenId);
  }

   
  function _getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal {
    _unmountSameSocketItem(_from, _tokenId, _childContract, _childTokenId);
    super._getChild(_from, _tokenId, _childContract, _childTokenId);
  }

  function () external payable {
    revert();
  }

}