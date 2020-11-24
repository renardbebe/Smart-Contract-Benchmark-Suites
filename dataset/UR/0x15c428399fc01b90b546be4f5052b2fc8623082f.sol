 

pragma solidity ^0.4.24;


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
 
contract Operator is Ownable {
    address[] public operators;

    uint public MAX_OPS = 20;  

    mapping(address => bool) public isOperator;

    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

     
    modifier onlyOperator() {
        require(
            isOperator[msg.sender] || msg.sender == owner,
            "Permission denied. Must be an operator or the owner."
        );
        _;
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
contract Pausable is Operator {

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

  modifier whenNotFreeze(address _target) {
    require(_target != address(0));
    require(!frozenAccount[_target]);
    _;
  }

  function isFrozen(address _target) external view returns (bool) {
    require(_target != address(0));
    return frozenAccount[_target];
  }

  function doPause() external  whenNotPaused onlyOwner {
    isPaused = true;
  }

  function doUnpause() external  whenPaused onlyOwner {
    isPaused = false;
  }

  function freezeAccount(address _target, bool _freeze) public onlyOwner {
    require(_target != address(0));
    frozenAccount[_target] = _freeze;
    emit FrozenFunds(_target, _freeze);
  }

}

interface ERC998ERC721TopDown {
    event ReceivedChild(address indexed _from, uint256 indexed _tokenId, address indexed _childContract, uint256 _childTokenId);
    event TransferChild(uint256 indexed tokenId, address indexed _to, address indexed _childContract, uint256 _childTokenId);

    function rootOwnerOf(uint256 _tokenId) external view returns (bytes32 rootOwner);
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 rootOwner);
    function ownerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 parentTokenOwner, uint256 parentTokenId);
    function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns (bytes4);
    function transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external;
    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external;
    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId, bytes _data) external;
    function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes _data) external;
     
     
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external;
}

interface ERC998ERC721TopDownEnumerable {
    function totalChildContracts(uint256 _tokenId) external view returns (uint256);
    function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract);
    function totalChildTokens(uint256 _tokenId, address _childContract) external view returns (uint256);
    function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId);
}

interface ERC998ERC20TopDown {
    event ReceivedERC20(address indexed _from, uint256 indexed _tokenId, address indexed _erc20Contract, uint256 _value);
    event TransferERC20(uint256 indexed _tokenId, address indexed _to, address indexed _erc20Contract, uint256 _value);

    function tokenFallback(address _from, uint256 _value, bytes _data) external;
    function balanceOfERC20(uint256 _tokenId, address __erc20Contract) external view returns (uint256);
    function transferERC20(uint256 _tokenId, address _to, address _erc20Contract, uint256 _value) external;
    function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external;
    function getERC20(address _from, uint256 _tokenId, address _erc20Contract, uint256 _value) external;

}

interface ERC998ERC20TopDownEnumerable {
    function totalERC20Contracts(uint256 _tokenId) external view returns (uint256);
    function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address);
}

interface ERC20AndERC223 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function transfer(address to, uint value) external returns (bool success);
    function transfer(address to, uint value, bytes data) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

interface ERC998ERC721BottomUp {
    function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId, bytes _data) external;
}

contract ComposableTopDown is Pausable, ERC721, ERC998ERC721TopDown, ERC998ERC721TopDownEnumerable,
ERC998ERC20TopDown, ERC998ERC20TopDownEnumerable {
     
     
    bytes32 constant ERC998_MAGIC_VALUE = 0xcd740db5;

     
    mapping(uint256 => address) internal tokenIdToTokenOwner;

     
    mapping(address => mapping(uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;

     
    mapping(address => uint256) internal tokenOwnerToTokenCount;

     
    mapping(address => mapping(address => bool)) internal tokenOwnerToOperators;


     

  function _mint(address _to,uint256 _tokenId) internal whenNotPaused {
    tokenIdToTokenOwner[_tokenId] = _to;
    tokenOwnerToTokenCount[_to]++;
    emit Transfer(address(0), _to, _tokenId);
  }

     
     
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
     
    bytes4 constant ERC721_RECEIVED_NEW = 0x150b7a02;

     
     
     

    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(_addr)}
        return size > 0;
    }

    function rootOwnerOf(uint256 _tokenId) public view returns (bytes32 rootOwner) {
        return rootOwnerOfChild(address(0), _tokenId);
    }

     
     
     
     
     
     
    function rootOwnerOfChild(address _childContract, uint256 _childTokenId) public view returns (bytes32 rootOwner) {
        address rootOwnerAddress;
        if (_childContract != address(0)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(_childContract, _childTokenId);
        }
        else {
            rootOwnerAddress = tokenIdToTokenOwner[_childTokenId];
        }
         
        while (rootOwnerAddress == address(this)) {
            (rootOwnerAddress, _childTokenId) = _ownerOfChild(rootOwnerAddress, _childTokenId);
        }

        bool callSuccess;
        bytes memory calldata;
         
        calldata = abi.encodeWithSelector(0xed81cdda, address(this), _childTokenId);
        assembly {
            callSuccess := staticcall(gas, rootOwnerAddress, add(calldata, 0x20), mload(calldata), calldata, 0x20)
            if callSuccess {
                rootOwner := mload(calldata)
            }
        }
        if(callSuccess == true && rootOwner >> 224 == ERC998_MAGIC_VALUE) {
             
            return rootOwner;
        }
        else {
             
             
             
            return ERC998_MAGIC_VALUE << 224 | bytes32(rootOwnerAddress);
        }
    }


     

    function ownerOf(uint256 _tokenId) public view returns (address tokenOwner) {
        tokenOwner = tokenIdToTokenOwner[_tokenId];
        require(tokenOwner != address(0));
        return tokenOwner;
    }

    function balanceOf(address _tokenOwner) external view returns (uint256) {
        require(_tokenOwner != address(0));
        return tokenOwnerToTokenCount[_tokenOwner];
    }

    function approve(address _approved, uint256 _tokenId) external whenNotPaused {
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender]);
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
        emit Approval(rootOwner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address)  {
        address rootOwner = address(rootOwnerOf(_tokenId));
        return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external whenNotPaused {
        require(_operator != address(0));
        tokenOwnerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool)  {
        require(_owner != address(0));
        require(_operator != address(0));
        return tokenOwnerToOperators[_owner][_operator];
    }


    function _transferFrom(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
        require(_from != address(0));
        require(tokenIdToTokenOwner[_tokenId] == _from);
        require(_to != address(0));
        require(!frozenAccount[_from]);                  
        require(!frozenAccount[_to]); 
        if(msg.sender != _from) {
            bytes32 rootOwner;
            bool callSuccess;
             
            bytes memory calldata = abi.encodeWithSelector(0xed81cdda, address(this), _tokenId);
            assembly {
                callSuccess := staticcall(gas, _from, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    rootOwner := mload(calldata)
                }
            }
            if(callSuccess == true) {
                require(rootOwner >> 224 != ERC998_MAGIC_VALUE, "Token is child of other top down composable");
            }
            require(tokenOwnerToOperators[_from][msg.sender] ||
            rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId] == msg.sender);
        }

         
        if (rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId] != address(0)) {
            delete rootOwnerAndTokenIdToApprovedAddress[_from][_tokenId];
            emit Approval(_from, address(0), _tokenId);
        }

         
        if (_from != _to) {
            assert(tokenOwnerToTokenCount[_from] > 0);
            tokenOwnerToTokenCount[_from]--;
            tokenIdToTokenOwner[_tokenId] = _to;
            tokenOwnerToTokenCount[_to]++;
        }
        emit Transfer(_from, _to, _tokenId);

    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
            require(retval == ERC721_RECEIVED_OLD);
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _transferFrom(_from, _to, _tokenId);
        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == ERC721_RECEIVED_OLD);
        }
    }

     
     
     

     
    mapping(uint256 => address[]) internal childContracts;

     
    mapping(uint256 => mapping(address => uint256)) internal childContractIndex;

     
    mapping(uint256 => mapping(address => uint256[])) internal childTokens;

     
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal childTokenIndex;

     
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;


    function _removeChild(uint256 _tokenId, address _childContract, uint256 _childTokenId) internal whenNotPaused {
        uint256 tokenIndex = childTokenIndex[_tokenId][_childContract][_childTokenId];
        require(tokenIndex != 0, "Child token not owned by token.");

         
        uint256 lastTokenIndex = childTokens[_tokenId][_childContract].length - 1;
        uint256 lastToken = childTokens[_tokenId][_childContract][lastTokenIndex];
         
            childTokens[_tokenId][_childContract][tokenIndex - 1] = lastToken;
            childTokenIndex[_tokenId][_childContract][lastToken] = tokenIndex;
         
        childTokens[_tokenId][_childContract].length--;
        delete childTokenIndex[_tokenId][_childContract][_childTokenId];
        delete childTokenOwner[_childContract][_childTokenId];

         
        if (lastTokenIndex == 0) {
            uint256 lastContractIndex = childContracts[_tokenId].length - 1;
            address lastContract = childContracts[_tokenId][lastContractIndex];
            if (_childContract != lastContract) {
                uint256 contractIndex = childContractIndex[_tokenId][_childContract];
                childContracts[_tokenId][contractIndex] = lastContract;
                childContractIndex[_tokenId][lastContract] = contractIndex;
            }
            childContracts[_tokenId].length--;
            delete childContractIndex[_tokenId][_childContract];
        }
    }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId);
    }

    function safeTransferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId, bytes _data) external {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
        ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId, _data); 
    }

    function transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) external {
        _transferChild(_fromTokenId, _to, _childContract, _childTokenId);
         
         
         
         
        bytes memory calldata = abi.encodeWithSelector(0x095ea7b3, this, _childTokenId);
        assembly {
            let success := call(gas, _childContract, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
        }
        ERC721(_childContract).transferFrom(this, _to, _childTokenId);
    }

    function _transferChild(uint256 _fromTokenId, address _to, address _childContract, uint256 _childTokenId) internal {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId > 0 || childTokenIndex[tokenId][_childContract][_childTokenId] > 0);
        require(tokenId == _fromTokenId);
        require(_to != address(0));
        address rootOwner = address(rootOwnerOf(tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender);
        _removeChild(tokenId, _childContract, _childTokenId);
        emit TransferChild(_fromTokenId, _to, _childContract, _childTokenId);
    }

    function transferChildToParent(uint256 _fromTokenId, address _toContract, uint256 _toTokenId, address _childContract, uint256 _childTokenId, bytes _data) external {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        require(tokenId > 0 || childTokenIndex[tokenId][_childContract][_childTokenId] > 0);
        require(tokenId == _fromTokenId);
        require(_toContract != address(0));
        address rootOwner = address(rootOwnerOf(tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender);
        _removeChild(_fromTokenId, _childContract, _childTokenId);
        ERC998ERC721BottomUp(_childContract).transferToParent(address(this), _toContract, _toTokenId, _childTokenId, _data);
        emit TransferChild(_fromTokenId, _toContract, _childContract, _childTokenId);
    }


     
    function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external {
        _receiveChild(_from, _tokenId, _childContract, _childTokenId);
        require(_from == msg.sender ||
        ERC721(_childContract).isApprovedForAll(_from, msg.sender) ||
        ERC721(_childContract).getApproved(_childTokenId) == msg.sender);
        ERC721(_childContract).transferFrom(_from, this, _childTokenId);
    }

    function onERC721Received(address _from, uint256 _childTokenId, bytes _data) external returns (bytes4) {
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
         
        uint256 tokenId;
        assembly {tokenId := calldataload(132)}
        if (_data.length < 32) {
            tokenId = tokenId >> 256 - _data.length * 8;
        }
        _receiveChild(_from, tokenId, msg.sender, _childTokenId);
        require(ERC721(msg.sender).ownerOf(_childTokenId) != address(0), "Child token not owned.");
        return ERC721_RECEIVED_OLD;
    }

    function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns (bytes4) {
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
         
        uint256 tokenId;
        assembly {tokenId := calldataload(164)}
        if (_data.length < 32) {
            tokenId = tokenId >> 256 - _data.length * 8;
        }
        _receiveChild(_from, tokenId, msg.sender, _childTokenId);
        require(ERC721(msg.sender).ownerOf(_childTokenId) != address(0), "Child token not owned.");
        return ERC721_RECEIVED_NEW;
    }

    function _receiveChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) internal whenNotPaused {
        require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
        require(childTokenIndex[_tokenId][_childContract][_childTokenId] == 0, "Cannot receive child token because it has already been received.");
        uint256 childTokensLength = childTokens[_tokenId][_childContract].length;
        if (childTokensLength == 0) {
            childContractIndex[_tokenId][_childContract] = childContracts[_tokenId].length;
            childContracts[_tokenId].push(_childContract);
        }
        childTokens[_tokenId][_childContract].push(_childTokenId);
        childTokenIndex[_tokenId][_childContract][_childTokenId] = childTokensLength + 1;
        childTokenOwner[_childContract][_childTokenId] = _tokenId;
        emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
    }

    function _ownerOfChild(address _childContract, uint256 _childTokenId) internal view returns (address parentTokenOwner, uint256 parentTokenId) {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId > 0 || childTokenIndex[parentTokenId][_childContract][_childTokenId] > 0);
        return (tokenIdToTokenOwner[parentTokenId], parentTokenId);
    }

    function ownerOfChild(address _childContract, uint256 _childTokenId) external view returns (bytes32 parentTokenOwner, uint256 parentTokenId) {
        parentTokenId = childTokenOwner[_childContract][_childTokenId];
        require(parentTokenId > 0 || childTokenIndex[parentTokenId][_childContract][_childTokenId] > 0);
        return (ERC998_MAGIC_VALUE << 224 | bytes32(tokenIdToTokenOwner[parentTokenId]), parentTokenId);
    }

    function childExists(address _childContract, uint256 _childTokenId) external view returns (bool) {
        uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
        return childTokenIndex[tokenId][_childContract][_childTokenId] != 0;
    }

    function totalChildContracts(uint256 _tokenId) external view returns (uint256) {
        return childContracts[_tokenId].length;
    }

    function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract) {
        require(_index < childContracts[_tokenId].length, "Contract address does not exist for this token and index.");
        return childContracts[_tokenId][_index];
    }

    function totalChildTokens(uint256 _tokenId, address _childContract) external view returns (uint256) {
        return childTokens[_tokenId][_childContract].length;
    }

    function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId) {
        require(_index < childTokens[_tokenId][_childContract].length, "Token does not own a child token at contract address and index.");
        return childTokens[_tokenId][_childContract][_index];
    }

     
     
     

     
    mapping(uint256 => address[]) erc20Contracts;

     
    mapping(uint256 => mapping(address => uint256)) erc20ContractIndex;

     
    mapping(uint256 => mapping(address => uint256)) erc20Balances;

    function balanceOfERC20(uint256 _tokenId, address _erc20Contract) external view returns (uint256) {
        return erc20Balances[_tokenId][_erc20Contract];
    }

    function removeERC20(uint256 _tokenId, address _erc20Contract, uint256 _value) private {
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        require(erc20Balance >= _value, "Not enough token available to transfer.");
        uint256 newERC20Balance = erc20Balance - _value;
        erc20Balances[_tokenId][_erc20Contract] = newERC20Balance;
        if (newERC20Balance == 0) {
            uint256 lastContractIndex = erc20Contracts[_tokenId].length - 1;
            address lastContract = erc20Contracts[_tokenId][lastContractIndex];
            if (_erc20Contract != lastContract) {
                uint256 contractIndex = erc20ContractIndex[_tokenId][_erc20Contract];
                erc20Contracts[_tokenId][contractIndex] = lastContract;
                erc20ContractIndex[_tokenId][lastContract] = contractIndex;
            }
            erc20Contracts[_tokenId].length--;
            delete erc20ContractIndex[_tokenId][_erc20Contract];
        }
    }


    function transferERC20(uint256 _tokenId, address _to, address _erc20Contract, uint256 _value) external {
        require(_to != address(0));
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender);
        removeERC20(_tokenId, _erc20Contract, _value);
        require(ERC20AndERC223(_erc20Contract).transfer(_to, _value), "ERC20 transfer failed.");
        emit TransferERC20(_tokenId, _to, _erc20Contract, _value);
    }

     
    function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external {
        require(_to != address(0));
        address rootOwner = address(rootOwnerOf(_tokenId));
        require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
        rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender);
        removeERC20(_tokenId, _erc223Contract, _value);
        require(ERC20AndERC223(_erc223Contract).transfer(_to, _value, _data), "ERC223 transfer failed.");
        emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
    }

     
    function getERC20(address _from, uint256 _tokenId, address _erc20Contract, uint256 _value) public {
        bool allowed = _from == msg.sender;
        if (!allowed) {
            uint256 remaining;
             
            bytes memory calldata = abi.encodeWithSelector(0xdd62ed3e, _from, msg.sender);
            bool callSuccess;
            assembly {
                callSuccess := staticcall(gas, _erc20Contract, add(calldata, 0x20), mload(calldata), calldata, 0x20)
                if callSuccess {
                    remaining := mload(calldata)
                }
            }
            require(callSuccess, "call to allowance failed");
            require(remaining >= _value, "Value greater than remaining");
            allowed = true;
        }
        require(allowed, "not allowed to getERC20");
        erc20Received(_from, _tokenId, _erc20Contract, _value);
        require(ERC20AndERC223(_erc20Contract).transferFrom(_from, this, _value), "ERC20 transfer failed.");
    }

    function erc20Received(address _from, uint256 _tokenId, address _erc20Contract, uint256 _value) private {
        require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        if (erc20Balance == 0) {
            erc20ContractIndex[_tokenId][_erc20Contract] = erc20Contracts[_tokenId].length;
            erc20Contracts[_tokenId].push(_erc20Contract);
        }
        erc20Balances[_tokenId][_erc20Contract] += _value;
        emit ReceivedERC20(_from, _tokenId, _erc20Contract, _value);
    }

     
    function tokenFallback(address _from, uint256 _value, bytes _data) external {
        require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the token to.");
        require(isContract(msg.sender), "msg.sender is not a contract");
         
         
        uint256 tokenId;
        assembly {
            tokenId := calldataload(132)
        }
        if (_data.length < 32) {
            tokenId = tokenId >> 256 - _data.length * 8;
        }
         
        erc20Received(_from, tokenId, msg.sender, _value);
    }


    function erc20ContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address) {
        require(_index < erc20Contracts[_tokenId].length, "Contract address does not exist for this token and index.");
        return erc20Contracts[_tokenId][_index];
    }

    function totalERC20Contracts(uint256 _tokenId) external view returns (uint256) {
        return erc20Contracts[_tokenId].length;
    }
}

contract ERC998TopDownToken is SupportsInterfaceWithLookup, ERC721Enumerable, ERC721Metadata, ComposableTopDown {
  using UrlStr for string;
  using SafeMath for uint256;

  string internal BASE_URL = "https://www.bitguild.com/bitizens/api/avatar/getAvatar/00000000";

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   
  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
              
   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  constructor() public {
     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
    _registerInterface(bytes4(ERC998_MAGIC_VALUE));
  }

  modifier existsToken(uint256 _tokenId){
    address owner = tokenIdToTokenOwner[_tokenId];
    require(owner != address(0), "This tokenId is invalid"); 
    _;
  }

  function updateBaseURI(string _url) external onlyOwner {
    BASE_URL = _url;
  }

   
  function name() external view returns (string) {
    return "Bitizen";
  }

   
  function symbol() external view returns (string) {
    return "BTZN";
  }

   
  function tokenURI(uint256 _tokenId) external view existsToken(_tokenId) returns (string) {
    return BASE_URL.generateUrl(_tokenId);
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

   
   
  function _transferFrom(address _from, address _to, uint256 _tokenId) internal whenNotPaused {
     
    super._transferFrom(_from, _to, _tokenId);
    _addTokenTo(_to,_tokenId);
    _removeTokenFrom(_from, _tokenId);
  }
}

interface AvatarChildService {
   
   function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res);

   
   function isAvatarChild(uint256 _tokenId) external view returns(bool);
}

interface AvatarService {
  function updateAvatarInfo(address _owner, uint256 _tokenId, string _name, uint256 _dna) external;
  function createAvatar(address _owner, string _name, uint256 _dna) external  returns(uint256);
  function getMountedChildren(address _owner,uint256 _tokenId, address _childAddress) external view returns(uint256[]); 
  function getAvatarInfo(uint256 _tokenId) external view returns (string _name, uint256 _dna);
  function getOwnedAvatars(address _owner) external view returns(uint256[] _avatars);
  function unmount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
  function mount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external;
}

contract AvatarToken is ERC998TopDownToken, AvatarService {
  
  using UrlStr for string;

  enum ChildHandleType{NULL, MOUNT, UNMOUNT}

  event ChildHandle(address indexed from, uint256 parent, address indexed childAddr, uint256[] children, ChildHandleType _type);

  event AvatarTransferStateChanged(address indexed _owner, bool _newState);

  struct Avatar {
     
    string name;
     
    uint256 dna;
  }
  
   
  uint256 internal avatarIndex = 0;
   
  mapping(uint256 => Avatar) avatars;
   
  bool public avatarTransferState = false;

  function changeAvatarTransferState(bool _newState) public onlyOwner {
	if(avatarTransferState == _newState) return;
    avatarTransferState = _newState;
    emit AvatarTransferStateChanged(owner, avatarTransferState);
  }

  function createAvatar(address _owner, string _name, uint256 _dna) external onlyOperator returns(uint256) {
    return _createAvatar(_owner, _name, _dna);
  }

  function getMountedChildren(address _owner, uint256 _avatarId, address _childAddress)
  external
  view 
  onlyOperator
  existsToken(_avatarId) 
  returns(uint256[]) {
    require(_childAddress != address(0));
    require(tokenIdToTokenOwner[_avatarId] == _owner);
    return childTokens[_avatarId][_childAddress];
  }
  
  function updateAvatarInfo(address _owner, uint256 _avatarId, string _name, uint256 _dna) external onlyOperator existsToken(_avatarId){
    require(_owner != address(0), "Invalid address");
    require(_owner == tokenIdToTokenOwner[_avatarId] || msg.sender == owner);
    Avatar storage avatar = avatars[_avatarId];
    avatar.name = _name;
    avatar.dna = _dna;
  }

  function getOwnedAvatars(address _owner) external view onlyOperator returns(uint256[] _avatars) {
    require(_owner != address(0));
    _avatars = ownedTokens[_owner];
  }

  function getAvatarInfo(uint256 _avatarId) external view existsToken(_avatarId) returns(string _name, uint256 _dna) {
    Avatar storage avatar = avatars[_avatarId];
    _name = avatar.name;
    _dna = avatar.dna;
  }

  function unmount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external onlyOperator {
    if(_children.length == 0) return;
    require(ownerOf(_avatarId) == _owner);  
    uint256[] memory mountedChildren = childTokens[_avatarId][_childContract]; 
    if (mountedChildren.length == 0) return;
    uint256[] memory unmountChildren = new uint256[](_children.length);  
    for(uint8 i = 0; i < _children.length; i++) {
      uint256 child = _children[i];
      if(_isMounted(mountedChildren, child)){  
        unmountChildren[i] = child;
        _removeChild(_avatarId, _childContract, child);
        ERC721(_childContract).transferFrom(this, _owner, child);
      }
    }
    if(unmountChildren.length > 0 ) 
      emit ChildHandle(_owner, _avatarId, _childContract, unmountChildren, ChildHandleType.UNMOUNT);
  }

  function mount(address _owner, address _childContract, uint256[] _children, uint256 _avatarId) external onlyOperator {
    if(_children.length == 0) return;
    require(ownerOf(_avatarId) == _owner);  
    for(uint8 i = 0; i < _children.length; i++) {
      uint256 child = _children[i];
      require(ERC721(_childContract).ownerOf(child) == _owner);  
      _receiveChild(_owner, _avatarId, _childContract, child);
      ERC721(_childContract).transferFrom(_owner, this, child);
    }
    emit ChildHandle(_owner, _avatarId, _childContract, _children, ChildHandleType.MOUNT);
  }

   
  function _checkChildRule(address _owner, uint256 _avatarId, address _childContract, uint256 _child) internal {
    uint256[] memory tokens = childTokens[_avatarId][_childContract];
    if (tokens.length == 0) {
      if (!AvatarChildService(_childContract).isAvatarChild(_child)) {
        revert("it can't be avatar child");
      }
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      if (AvatarChildService(_childContract).compareItemSlots(tokens[i], _child)) {
        _removeChild(_avatarId, _childContract, tokens[i]);
        ERC721(_childContract).transferFrom(this, _owner, tokens[i]);
      }
    }
  }
   
  function _isMounted(uint256[] mountedChildren, uint256 _toMountToken) private pure returns (bool) {
    for(uint8 i = 0; i < mountedChildren.length; i++) {
      if(mountedChildren[i] == _toMountToken){
        return true;
      }
    }
    return false;
  }

   
  function _createAvatar(address _owner, string _name, uint256 _dna) private returns(uint256 _avatarId) {
    require(_owner != address(0));
    Avatar memory avatar = Avatar(_name, _dna);
    _avatarId = ++avatarIndex;
    avatars[_avatarId] = avatar;
    _mint(_owner, _avatarId);
  }

   
  function _transferFrom(address _from, address _to, uint256 _avatarId) internal whenNotPaused {
     
    require(avatarTransferState == true, "current time not allown transfer avatar");
    super._transferFrom(_from, _to, _avatarId);
  }

   
  function _receiveChild(address _from, uint256 _avatarId, address _childContract, uint256 _childTokenId) internal whenNotPaused {
    _checkChildRule(_from, _avatarId, _childContract, _childTokenId);
    super._receiveChild(_from, _avatarId, _childContract, _childTokenId);
  }

  function () public payable {
    revert();
  }
}