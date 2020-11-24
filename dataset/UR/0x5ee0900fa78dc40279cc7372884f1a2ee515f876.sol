 

pragma solidity ^0.5.10;

 
contract OwnableDelegateProxy { }
contract ProxyRegistry { mapping(address => OwnableDelegateProxy) public proxies;}

 
interface NxcInterface { function transfer(address _to, uint256 _value) external returns(bool);
	function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
	function totalSupply() external view returns(uint256);}
 
 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract tokenSpender { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public;
    }

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
contract ERC165 is IERC165 {
     
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

     
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
         
         
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

library Strings {
   
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string memory) {
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
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }
}

contract IProxyContractForMetaTxs {
 
 

  function updateWhitelist(address _account, bool _value) public returns(bool);
  
  event UpdateWhitelist(address _account, bool _value);
   
  
  function () external payable;
  
  event Received (address indexed sender, uint value);

  function getHash(address signer, address destination, uint value, bytes memory data, address rewardToken, uint rewardAmount) public view returns(bytes32);
  
   
  function forward(bytes memory sig, address signer, address destination, uint value, bytes memory data, address rewardToken, uint rewardAmount) public;
  
   
  event Forwarded (bytes sig, address signer, address destination, uint value, bytes data,address rewardToken, uint rewardAmount,bytes32 _hash);

   
   
   
  function executeCall(address to, uint256 value, bytes memory data) internal returns (bool success);

   
   
  function signerIsWhitelisted(bytes32 _hash, bytes memory _signature) internal view returns (bool);
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
interface Factory {
   
  function name() external view returns (string memory);

   
  function symbol() external view returns (string memory);

   
  function numOptions() external view returns (uint256);

   
  function canMint(uint256 _optionId) external view returns (bool);

   
  function tokenURI(uint256 _optionId) external view returns (string memory);

   
  function supportsFactoryInterface() external view returns (bool);

   
  function mint(uint256 _optionId, address _toAddress) external;
}

contract IProxyContractForBurn {
    function setnxcAddress(address new_address) public;
    function burnNxCtoMintAssets(uint256 nbOfAsset, string[] memory keys, string[] memory values) public view returns (uint256);
}

library Helpers {
  function parseBytesToStringArr(bytes memory b, uint256 globalOffset) internal pure returns (string[] memory)
  {
	uint256 nbOfStrings = sliceUint(b, globalOffset);
	string[] memory stringArr = new string[](nbOfStrings);
	
	uint256[] memory offsetArr = new uint256[](nbOfStrings);
	uint256[] memory stringLengths = new uint256[](nbOfStrings);
	
	for (uint256 i = 0; i < nbOfStrings; i++)
	{
		offsetArr[i] = sliceUint(b, globalOffset + 32 + 32 * i);
	}
	
	for (uint256 i = 0; i < nbOfStrings; i++)
	{
		stringLengths[i] = sliceUint(b, globalOffset + 32 + offsetArr[i]);
		require(stringLengths[i] <= 32);  

		stringArr[i] = bytes32ToString(bytesToBytes32(b, globalOffset + 64 + offsetArr[i]),stringLengths[i]);
	}
	
	return stringArr;
  }  
  
	function bytesToBytes32(bytes memory b, uint offset) internal pure returns (bytes32) {
	  bytes32 out;

	  for (uint i = 0; i < 32; i++) {
		out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
	  }
	  return out;
	}
	
    function uintToBytes32(uint v) internal pure returns (bytes32 ret) {
    if (v == 0) {
        ret = '0';
    }
    else {
        while (v > 0) {
            ret = bytes32(uint(ret) / (2 ** 8));
            ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
            v /= 10;
        }
    }
    return ret;
    }
    
    function bytes32ToString(bytes32 data) internal pure returns (string memory) {
		bytes memory bytesString = new bytes(32);
		for (uint j=0; j<32; j++) {
			byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
			if (char != 0) {
				bytesString[j] = char;
			}
		}
		return string(bytesString);
	}
	
    function bytes32ToString(bytes32 data, uint _length) internal pure returns (string memory) {
		bytes memory bytesString = new bytes(_length);
		for (uint j=0; j<_length; j++) {
			byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
			if (char != 0) {
				bytesString[j] = char;
			}
		}
		return string(bytesString);
	}
	
	function bytesToUint(bytes memory b)  internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint256(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

    function sliceUint(bytes memory bs, uint start) internal pure returns (uint) {
    require(bs.length >= start + 32, "slicing out of range");
    uint x;
    assembly {
        x := mload(add(bs, add(0x20, start)))
    }
    return x;
	}
    
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    string memory ab = new string(_ba.length + _bb.length);
    bytes memory babc = bytes(ab);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
    for (uint i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
    return string(babc); }
	
	function uint256ArrayConcat(uint256[] memory _a, uint256[] memory _b) internal pure returns (uint256[] memory)
	{
		uint256[] memory _c = new uint256[](_a.length + _b.length);
		
		for (uint256 i=0; i < _a.length; i++) {
            _c[i] = _a[i];
        }
		for (uint256 i=0; i < _b.length; i++) {
            _c[_a.length+i] = _b[i];
        }
		
		return _c;
	}
}

 
contract MultiSigOwnable {

    uint256 private nbApprovalsNeeded;
    address[] private ownerList;
    
    bytes4[] private functionSignatureHashList;
    bytes32 private Current_functionCallHash;
    bytes private Current_functionCall;
    bytes4 private Current_functionSig;
    
    address[] private Current_Approvals;

    event MultiSigOwnerTransactionCleared(bytes4 FuncSelector);
    
    modifier onlyMultiSigOwners() {
      require(msg.sender == address(this));
    
      bytes4 funcSelector;
      bytes memory msg_data = msg.data;
      assembly {
              funcSelector := mload(add(msg_data, 32))
          }
          
      if(!isRegistered(funcSelector))
      {
        registerMultiOwnableFunction(funcSelector);
      }
      
      _;
    }
    
    constructor (uint256 _nbApprovalsNeeded, address[] memory _ownerList) internal {
      require(_ownerList.length >= 1);
      require(_nbApprovalsNeeded >=1);
      
      for (uint256 i = 0; i < _ownerList.length; i++)
      {
          if(!isInOwnerList(_ownerList[i]))
          {
              ownerList.push(_ownerList[i]);
          }
      }
      
      nbApprovalsNeeded = _nbApprovalsNeeded;
      }
    
    function isInOwnerList(address _sender) view public returns (bool)	{
      
      for (uint256 i = 0; i < ownerList.length; i++)
      {
        if (_sender == ownerList[i])
          return true;
      }
      return false;	
    }
    
    function addOwnerToList(address _addOwner) public onlyMultiSigOwners() {
      ownerList.push(_addOwner);
    }
    
    function updateApprovalsNeeded(uint256 _nbApprovalsNeeded) public onlyMultiSigOwners() {
      nbApprovalsNeeded = _nbApprovalsNeeded;
    }
    
    function isInApprovalList(address _sender) view internal returns (bool) {
      
      for (uint256 i = 0; i < Current_Approvals.length; i++)
      {
        if (_sender == Current_Approvals[i])
          return true;
      }
      return false;	
    }
    
    function registerMultiOwnableFunction(bytes4 _functionSignatureHash) public
    {
      functionSignatureHashList.push(_functionSignatureHash);
    }
    
    function removeOwner(address _ownerToRemove) public onlyMultiSigOwners() {
        require(isInOwnerList(_ownerToRemove), "Remove owner - Not in owner list");
      
        bool _ownerToRemoveFound = false;
      
        for (uint256 i = 0; i < ownerList.length - 1; i++)
      {
        if (ownerList[i] == _ownerToRemove)
        {
          _ownerToRemoveFound = true;
        }
        if (_ownerToRemoveFound)
        {
          ownerList[i] = ownerList[i+1];
        }
      }
      ownerList.length--;
    }
    
    function initialCall(bytes memory functionCall) public returns (bytes32) {
      require(isInOwnerList(msg.sender), "Initial call - Not in owner list");
      
      Current_functionCallHash = keccak256(functionCall);
      Current_functionCall = functionCall;
      
      delete Current_Approvals;

      Current_Approvals.push(msg.sender);
      
      bytes4 funcSelector;

      assembly {
        funcSelector := mload(add(functionCall, 32))
      }
          
      Current_functionSig = funcSelector;
        
      
      if(nbApprovalsNeeded == 1)
      {
        address(this).call(functionCall);
        
        if (!isRegistered(funcSelector))
        {
          revert("initialCall - Called a function without the onlyMultiSigOwners modifier");
        }
        
        emit MultiSigOwnerTransactionCleared(funcSelector);
      }
      
      return Current_functionCallHash;
    }
    
    function isRegistered(bytes4 _functionSignatureHash) public view returns (bool) {

      for (uint256 i = 0; i < functionSignatureHashList.length; i++)
      {
        if (functionSignatureHashList[i] == _functionSignatureHash)
        {
          return true;
        }
      }
      return false;
    }
    
    function approve_tx(bytes32 _callDataHash) public {
      require(isInOwnerList(msg.sender), "Approve - Not in owner list");
        require(!isInApprovalList(msg.sender));
    
      if (_callDataHash == Current_functionCallHash)
      {
        Current_Approvals.push(msg.sender);
      }
      
      if (Current_Approvals.length >= nbApprovalsNeeded)
      {
        address(this).call(Current_functionCall);
        
        if (!isRegistered(Current_functionSig))
        {
          revert("approve - Called a function without the onlyMultiSigOwners modifier");
        }
        
        emit MultiSigOwnerTransactionCleared(Current_functionSig);
      }
    }
}

interface IProxyForKYCWhitelist {
	function isWhitelisted(address _addr) external view returns (bool);
}

contract ProxyForKYCWhitelistEveryoneIsWhitelisted is IProxyForKYCWhitelist {
	
	 
	function isWhitelisted(address _addr) public view returns (bool)
	{
		return true;
	}
}

contract ProxyForKYCWhitelistOnlySpecifiedPeopleAreWhitelisted is IProxyForKYCWhitelist, MultiSigOwnable {
  mapping(address => bool) whitelisted;

  constructor (uint256 nbApprovalsNeeded, address[] memory _ownerList) MultiSigOwnable(nbApprovalsNeeded, _ownerList) public
  {
    for (uint256 i = 0; i < _ownerList.length; i++)
    {
      whitelisted[_ownerList[i]] = true;
    }
  }

	function setWhitelistedStatus(address _addr, bool whitelisted_status) public onlyMultiSigOwners() {
    whitelisted[_addr] = whitelisted_status;
  }
  
	function setNWhitelistedStatus(address[] memory _addresses, bool whitelisted_status) public onlyMultiSigOwners() {
    for (uint256 i = 0; i < _addresses.length; i++)
    {
      whitelisted[_addresses[i]] = whitelisted_status;
    }
  }

	function isWhitelisted(address _addr) public view returns (bool)
	{
		return whitelisted[_addr];
	}
}

 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 
library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

 
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

contract NFT_Factory is Factory, Ownable, MultiSigOwnable {
  using Strings for string;

  address payable nftAddress;
  address public listingAddress;
  
  address public proxyRegistryAddress;
  address public proxyContractForBurnAddress;
  address public proxyContractForMetatxsAddress;
  mapping(uint256 => uint256) public nbAssetMaxPerOptionID;
  mapping(uint256 => uint256) public nbAssetPerOptionID;
  mapping(uint256 => address) public minterForOptionID;
  mapping(uint256 => address) public addressForUGCForOptionID;
  mapping(uint256 => uint256) public tokenIDsToNonUniqueTokenID;

  address public nexiumAddress;
  string public baseURI;
  uint256 NUM_OPTIONS;
  
  struct KeyValue {
	uint256 _index;
	string _key;
	string _value;}
  
  mapping (uint256 => KeyValue[]) public KeyValueArrayOptionID;
  mapping (uint256 => mapping(string => KeyValue)) public KeyValueMappingOptionID;
  mapping (uint256 => KeyValue[]) public KeyValueArrayOptionIDOnCreation;
  mapping (uint256 => mapping(string => KeyValue)) public KeyValueMappingOptionIDOnCreation;
  mapping (uint256 => KeyValue[]) public KeyValueArrayTokenID;
  mapping (uint256 => mapping(string => KeyValue)) public KeyValueMappingTokenID;
  
  mapping(uint256 => address) whitelistContractAddresses;
  address public defaultWhitelistContractAddresses;
  mapping(uint256 => uint256[]) public bundlesDefinition;
  mapping(uint256 => bool) public isBundle;
	
  event NewAssetCreated(address minter, uint256 optionID, uint256 nbAssetMintedMax);
  event NewAssetMinted(address minter, address _to, uint256 optionID, uint256 tokenID);
  
  constructor(address _proxyRegistryAddress, address payable _nftAddress, address _listingAddress, string memory _baseURI, address _proxyContractForBurnAddress, address _proxyContractForMetatxsAddress, address _nexiumAddress, address _defaultWhitelistContractAddresses, uint256 _nbApprovalNeeded, address[] memory _ownerList) 
	Ownable() MultiSigOwnable(_nbApprovalNeeded, _ownerList) public {
	proxyContractForBurnAddress =  _proxyContractForBurnAddress;
    proxyContractForMetatxsAddress = _proxyContractForMetatxsAddress;
	proxyRegistryAddress = _proxyRegistryAddress;
    nftAddress = _nftAddress;
	baseURI = _baseURI;    
	listingAddress = _listingAddress;
	nexiumAddress = _nexiumAddress;
	NUM_OPTIONS = 0;
	defaultWhitelistContractAddresses = _defaultWhitelistContractAddresses;
  }
  
  function setProxyContractForBurnAddress (address _new_address) public onlyMultiSigOwners() {
      proxyContractForBurnAddress = _new_address;
  }
  
  function setdefaultWhitelistContractAddresses (address _new_address) public onlyMultiSigOwners() {
      defaultWhitelistContractAddresses = _new_address;
  }
  
  function setProxyContractForMetatxsAddress (address _new_address) public onlyMultiSigOwners() {
      proxyContractForMetatxsAddress = _new_address;
  }
  
  function setnftAddress (address payable _new_address) public onlyMultiSigOwners() {
      nftAddress = _new_address;
  }
  
   function setnxcAddress(address _new_address) public onlyMultiSigOwners() {
		nexiumAddress = _new_address;
  }
	
  function setlistingAddress (address _new_address) public onlyMultiSigOwners() {
      listingAddress = _new_address;
  }
    
  function setbaseURI (string memory _new_baseURI) public onlyMultiSigOwners() {
      baseURI = _new_baseURI;
  }
 
  function name() external view returns (string memory) {
    return "B2E NFT Sale";
  }

  function symbol() external view returns (string memory) {
    return "B2ENFTS";
  }

  function supportsFactoryInterface() public view returns (bool) {
    return true;
  }

  function numOptions() public view returns (uint256) {
    return NUM_OPTIONS;
  }

  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public  {
	   require(_token == nexiumAddress);
	   require(_extraData.length >= 4);  
	   
	    bytes4 funcSelector = 0x0;
	    
        if (_extraData.length == 0) {
            funcSelector = 0x0;
        }

        assembly {
            funcSelector := mload(add(_extraData, 32))
        }
        
        if (funcSelector == bytes4(keccak256("createNewOptionID(uint256,address)")))
        {
			revert("Please put empty keys and values args");
			 
        }
		else if (funcSelector == bytes4(keccak256("createNewOptionID(uint256,address,string[],string[])")))
		{

			 
			
			uint256 nbOfAsset = Helpers.sliceUint(_extraData, 4);
			address _minter = address(Helpers.sliceUint(_extraData, 36));
			
			uint256 keysOffset = Helpers.sliceUint(_extraData, 68) + 4;  
			uint256 valuesOffset = Helpers.sliceUint(_extraData, 100) + 4;
			
			uint256 nbOfKeys = Helpers.sliceUint(_extraData, keysOffset);
			uint256 nbOfValues = Helpers.sliceUint(_extraData, valuesOffset);
			
			require(nbOfValues == nbOfKeys);
			
			string[] memory keys = Helpers.parseBytesToStringArr(_extraData, keysOffset);
			string[] memory values = Helpers.parseBytesToStringArr(_extraData, valuesOffset);
			
			createNewOptionID(nbOfAsset, _minter, keys, values);
			
			require(_value >= CallProxyForNxCBurn(nbOfAsset, keys, values), "Not enough NXC!");
        }
        else
        {
            revert("Unknown function called through receiveApproval");
        }
		
		NxcInterface nexiumContract = NxcInterface(address(nexiumAddress));
		if(!nexiumContract.transferFrom(_from, address(this), _value))
		{
			revert("notEnoughNxCSent");
		}
			
	    return;
  }

   

    function CallProxyForNxCBurn(uint256 nbOfAsset, string[] memory keys, string[] memory values) public view returns (uint256) {
		
      ProxyContractForBurn _proxyContractForBurn = ProxyContractForBurn(proxyContractForBurnAddress);
      
      uint256 nbNxCToBurn = _proxyContractForBurn.burnNxCtoMintAssets(nbOfAsset, keys, values);
	    
      return nbNxCToBurn;
  }
 

     
  function createNewOptionID(uint256 nbAssetMaxToMint, address _minter, string[] memory keys, string[] memory values) internal {
  
      uint256 _optionID = NUM_OPTIONS;
      require(nbAssetMaxPerOptionID[_optionID] == 0);
      
	  nbAssetPerOptionID[_optionID] = 0;
      nbAssetMaxPerOptionID[_optionID] = nbAssetMaxToMint;
	  minterForOptionID[_optionID] = _minter;

		require(keys.length == values.length);
		
		for (uint256 i = 0; i < keys.length; i++)
		{
			string memory _key = keys[i];
			string memory _value = values[i];
		
		
		    KeyValue memory keyValueForThisKey = KeyValueMappingOptionIDOnCreation[_optionID][_key];

			uint256 index;
			KeyValue memory newKeyValue;
			
			 
			if (bytes(keyValueForThisKey._key).length == 0)
			{
			  index = KeyValueArrayOptionIDOnCreation[_optionID].length;
			  newKeyValue = KeyValue(index, _key, _value);
			  KeyValueArrayOptionIDOnCreation[_optionID].push(newKeyValue);
			}	
			else
			{
			  index = keyValueForThisKey._index;
			  newKeyValue = KeyValue(index, _key, _value);
			  KeyValueArrayOptionIDOnCreation[_optionID][index] = newKeyValue;
			}
			
			KeyValueMappingOptionIDOnCreation[_optionID][_key] = newKeyValue;
		}
    
      
	  emit NewAssetCreated(_minter, _optionID, nbAssetMaxToMint);
	  
	  whitelistContractAddresses[_optionID] = defaultWhitelistContractAddresses;
	  
      NUM_OPTIONS = NUM_OPTIONS + 1;
  }
  
  function setWhitelistContractAddressForOptionID(uint256 _optionID, address _new_address) public {
	require(msg.sender == minterForOptionID[_optionID]);
	
	whitelistContractAddresses[_optionID] = _new_address;
  }
  
  
   function transferMintership(uint256 _optionID, address _new_minter) public {
	require(msg.sender == minterForOptionID[_optionID]);
	minterForOptionID[_optionID] = _new_minter;
  }
  
   function ownerOf(uint256 _optionID) public view returns (address) {
	return minterForOptionID[_optionID];
	 
  }
  
  function mintWithTokenURI(uint256 _optionId, address _toAddress, uint256 _category, string calldata _tokenURI) external returns (uint256)
  {
	uint256 tokenID = this.mintCat(_optionId, _toAddress, _category);
	
    NFT_Token itemContract = NFT_Token(nftAddress);

	itemContract.setTokenURI(tokenID, _tokenURI);
  }
  
	 
  function setOptionIdPropriety(uint256 _optionID, string memory _key, string memory _value) public
  {
    require(msg.sender == minterForOptionID[_optionID]);
    require(bytes(_key).length > 0);
    
    KeyValue memory keyValueForThisKey = KeyValueMappingOptionID[_optionID][_key];

    uint256 index;
    KeyValue memory newKeyValue;
    
     
    if (bytes(keyValueForThisKey._key).length == 0)
    {
      index = KeyValueArrayOptionID[_optionID].length;
      newKeyValue = KeyValue(index, _key, _value);
      KeyValueArrayOptionID[_optionID].push(newKeyValue);
    }	
    else
    {
      index = keyValueForThisKey._index;
      newKeyValue = KeyValue(index, _key, _value);
      KeyValueArrayOptionID[_optionID][index] = newKeyValue;
    }
    
    KeyValueMappingOptionID[_optionID][_key] = newKeyValue;
  }

  function deleteOptionIdPropriety(uint256 _optionID, string memory _key) public
  {
    require(msg.sender == minterForOptionID[_optionID]);

    KeyValue memory keyValueForThisKey = KeyValueMappingOptionID[_optionID][_key];

    uint256 index = keyValueForThisKey._index;
    uint256 length = KeyValueArrayOptionID[_optionID].length;
    
    KeyValueArrayOptionID[_optionID][index] = KeyValueArrayOptionID[_optionID][length-1];
    delete KeyValueArrayOptionID[_optionID][length-1];
    delete KeyValueMappingOptionID[_optionID][_key];
  }

  function setTokenIdPropriety(uint256 _TokenID, string memory _key, string memory _value) public
  {	
    NFT_Token itemContract = NFT_Token(nftAddress);
    
    uint256 _optionId = itemContract.itemTypes(_TokenID);
    require(msg.sender == minterForOptionID[_optionId]);
    
    require(bytes(_key).length > 0);
      
    KeyValue memory keyValueForThisKey = KeyValueMappingTokenID[_TokenID][_key];

    uint256 index;
    KeyValue memory newKeyValue;
    
     
    
    if (bytes(keyValueForThisKey._key).length == 0)
    {
      index = KeyValueArrayTokenID[_TokenID].length;
      newKeyValue = KeyValue(index, _key, _value);
      KeyValueArrayTokenID[_TokenID].push(newKeyValue);
    }	
    else
    {
      index = keyValueForThisKey._index;
      newKeyValue = KeyValue(index, _key, _value);
      KeyValueArrayTokenID[_TokenID][index] = newKeyValue;
    }
    
    KeyValueMappingTokenID[_TokenID][_key] = newKeyValue;
  }

  function deleteTokenIdPropriety(uint256 _TokenID, string memory _key) public
  {
    NFT_Token itemContract = NFT_Token(nftAddress);
    
    uint256 _optionId = itemContract.itemTypes(_TokenID);
    require(msg.sender == minterForOptionID[_optionId]);

    KeyValue memory keyValueForThisKey = KeyValueMappingTokenID[_TokenID][_key];

    uint256 index = keyValueForThisKey._index;
    uint256 length = KeyValueArrayTokenID[_TokenID].length;
    
    KeyValueArrayTokenID[_TokenID][index] = KeyValueArrayTokenID[_TokenID][length-1];
    delete KeyValueArrayTokenID[_TokenID][length-1];
    delete KeyValueMappingTokenID[_TokenID][_key];
  }

  function setTokenURI(uint256 tokenID, string memory _tokenURI) public
    {
      NFT_Token itemContract = NFT_Token(nftAddress);
      
      uint256 optionID = itemContract.itemTypes(tokenID);
      
    require(msg.sender == minterForOptionID[optionID]);
    
    itemContract.setTokenURI(tokenID, _tokenURI);
    }

    function setUGCAddress(uint256 _optionId, address _new_address) public {
      require(msg.sender == minterForOptionID[_optionId]);
      
      addressForUGCForOptionID[_optionId] = _new_address;
    }
 
  function tokenURI(uint256 _optionId) external view returns (string memory) {
      return Helpers.strConcat(
                              baseURI,
                              Helpers.strConcat(Helpers.bytes32ToString(Helpers.uintToBytes32(_optionId)), "/")
              );
    }
   
  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    mint(_tokenId, _to);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    if (owner() == _owner && _owner == _operator) {
      return true;
    }

    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (owner() == _owner && address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return false;
  }
  
    function mint(uint256 _optionId, address _toAddress) public {
		  
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		require(address(proxyRegistry.proxies(minterForOptionID[_optionId])) == msg.sender || minterForOptionID[_optionId] == msg.sender);
		  
		this.mintCat(_optionId, _toAddress, 0);
    }
    
    function MintN(uint256 _optionId, uint256 N, address _to, uint256 _cat) external returns (uint256[] memory) {
      require(msg.sender == minterForOptionID[_optionId], "msg.sender isn't minter for the asset");
      
      uint256[] memory currentTokenIds = new uint256[](N);
      for (uint256 i = 0; i < N; i++)
      {
        uint256 new_tokenID = this.mintCat(_optionId, _to, _cat);
        currentTokenIds[i] = new_tokenID;
      }
      return currentTokenIds;
    }
	
	
	function DefineBundle(uint256 optionID, uint256[] memory optionIDList) public 
	{
		require(minterForOptionID[optionID] == msg.sender);
		for (uint256 i = 0; i < optionIDList.length; i++)
		{
			require(minterForOptionID[optionIDList[i]] == msg.sender);
		}
		bundlesDefinition[optionID] = optionIDList;
		isBundle[optionID] = true;
	}
	
    function mintCat(uint256 _optionId, address _toAddress, uint256 _category) external returns (uint256) {
		require(this.canMint(_optionId), "Not available for minting");
		require(msg.sender == minterForOptionID[_optionId] || msg.sender == address(this), "msg.sender isn't minter for the asset (mint(3)");

		 
		IProxyForKYCWhitelist _ProxyForKYCWhitelistContract = IProxyForKYCWhitelist(whitelistContractAddresses[_optionId]);
		require(_ProxyForKYCWhitelistContract.isWhitelisted(_toAddress));

		nbAssetPerOptionID[_optionId] = nbAssetPerOptionID[_optionId] + 1;
		uint256 _tokenID = 0;
		
		 
		if(isBundle[_optionId])
		{
			for (uint i = 0; i < bundlesDefinition[_optionId].length; i++)
			{
				this.mintCat(bundlesDefinition[_optionId][i], _toAddress,0);
			}
		}
		else	 
		{
			NFT_Token itemContract = NFT_Token(nftAddress);
			bytes4 _functionSignatureHash = bytes4(keccak256("mintTo(address,uint256,uint256)"));
			bytes memory _extraData = abi.encodeWithSelector(_functionSignatureHash,_toAddress, _optionId, _category);
			 itemContract.initialCall(_extraData);
			_tokenID = itemContract.totalSupply();
			tokenIDsToNonUniqueTokenID[_tokenID] = nbAssetPerOptionID[_optionId];
			
			emit NewAssetMinted(msg.sender, _toAddress, _optionId, _tokenID);		
		}
		
		return _tokenID;
    }

    function canMint(uint256 _optionId) external view returns (bool) {
        
      bool isOptionAvailable = (_optionId <= NUM_OPTIONS);
      bool enoughNxCBurned = (nbAssetMaxPerOptionID[_optionId] > nbAssetPerOptionID[_optionId]);

      return (isOptionAvailable && enoughNxCBurned);
    }
}

contract ProxyContractForMetaTxs is IProxyContractForMetaTxs {}

 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    returns(bytes4);
}

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
     
    mapping(address => uint256[]) private _ownedTokens;

     
    mapping(uint256 => uint256) private _ownedTokensIndex;

     
    uint256[] private _allTokens;

     
    mapping(uint256 => uint256) private _allTokensIndex;

     
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

     
    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

     
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

     
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

     
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
         
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

     
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
	
	function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

     
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

     
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

     
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

         
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;  
            _ownedTokensIndex[lastTokenId] = tokenIndex;  
        }

         
        _ownedTokens[from].length--;

         
         
    }

     
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

         
         
         
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;  
        _allTokensIndex[lastTokenId] = tokenIndex;  

         
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
     
    string private _name;

     
    string private _symbol;

     
    mapping(uint256 => string) private _tokenURIs;

     
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

     
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
    }
}

 
contract TradeableERC721Token is ERC721Full, Ownable, MultiSigOwnable {
  using Strings for string;

   
  mapping (uint256 => uint256) public itemTypes;
  mapping (uint256 => uint256) public itemCategory;

	address proxyRegistryAddress;
  
  constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) ERC721Full(_name, _symbol) public 
  { 
	proxyRegistryAddress = _proxyRegistryAddress;  
  }

   
	
  function mintTo(address _to, uint256 _itemType, uint256 _itemCategory) onlyMultiSigOwners() public {
  
    uint256 newTokenId = _getNextTokenId();
    _mint(_to, newTokenId);
    itemTypes[newTokenId] = _itemType;
    
    itemCategory[newTokenId] = _itemCategory;
    
  }

   
  function _getNextTokenId() private view returns (uint256) {
    return totalSupply().add(1);
  }

  function baseTokenURI() public pure returns (string memory) {
    return "";
  }

  function tokenURI(uint256 _tokenId) public view returns (string memory) {
    return Strings.strConcat(
        baseTokenURI(),
        Strings.uint2str(itemTypes[_tokenId]),
        "/",
        Strings.uint2str(_tokenId)
    );
  }
  
   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
     
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }
}

 
contract NFT_Token is TradeableERC721Token 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

     
    constructor (address _proxyRegistryAddress, string memory name, string memory symbol, string memory uri_prefix, address _NexiumAddress, address _FactoryAddress, uint256 _nbApprovalNeeded, address[] memory _ownerList) 
    TradeableERC721Token("LTR Item", "LTRI", _proxyRegistryAddress)
    Ownable() MultiSigOwnable(_nbApprovalNeeded, _ownerList) public {
        NexiumAddress = _NexiumAddress;
        FactoryAddress = _FactoryAddress;
        _name = name;
        _symbol = symbol;
        _uri_prefix = uri_prefix;
		_route = "";
        _total_supply = 0;
        _last_id = 0;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

   

  function setnexiumAddress (address _new_address) public onlyMultiSigOwners() {
      NexiumAddress = _new_address;
  }
  
  function setfactoryAddress (address _new_address) public onlyMultiSigOwners() {
      FactoryAddress = _new_address;
  }

   

	function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public {

	    require(_token == NexiumAddress);
	    require(_extraData.length == 32);

	    uint256 tokenId = Helpers.bytesToUint(_extraData);

	    NxcInterface nexiumContract = NxcInterface(NexiumAddress);

	    if(nexiumContract.transferFrom(_from, address(this), _value) == false)
	    {
	        revert();
	    }
	    
	    NexiumPerTokenId[tokenId] = NexiumPerTokenId[tokenId].add(_value);

	    return;
	}

	function recoverNexium(uint256 _valueToRecover, uint256 tokenId) public {

		require(msg.sender == ownerOf(tokenId), "You need to own the asset");
		require(NexiumPerTokenId[tokenId] >= _valueToRecover);

	    NxcInterface nexiumContract = NxcInterface(NexiumAddress);

	    NexiumPerTokenId[tokenId] = NexiumPerTokenId[tokenId].sub(_valueToRecover);
	    
	    if(nexiumContract.transfer(msg.sender, _valueToRecover) == false)
	    {
	        revert();
	    }
	}

	function receiveETH (uint256 tokenId) public payable returns (bool) {
	    EtherPerTokenId[tokenId] = EtherPerTokenId[tokenId].add(msg.value);

	    return true;
	}

	function recoverETH(uint256 tokenId, uint256 _valueToRecover) public returns (bool) {

		require(msg.sender == ownerOf(tokenId), "You need to own the asset");
		require(EtherPerTokenId[tokenId] >= _valueToRecover);

	    EtherPerTokenId[tokenId] = EtherPerTokenId[tokenId].sub(_valueToRecover);
	    if(msg.sender.send(_valueToRecover) == true)
	    {
	        return true;
	    }
	    else
	    {
	        revert();
	    }
	}

   

   
	mapping(uint256 => uint256[]) groupMapping;

	function groupAssets(uint256[] memory tokenIds) public returns (uint256) {

	    uint256 tokenId = totalSupply().add(1);
        _mint(msg.sender, tokenId);

	    for (uint256 i = 0; i < tokenIds.length; i++) {
	          transferFrom(msg.sender, address(this), tokenIds[i]);
	    }

	    groupMapping[tokenId] = tokenIds;

		emit Grouping(msg.sender, tokenId);

	    return tokenId;
	}

	function ungroupAssets(uint256 tokenId) public returns (uint256[] memory) {
        
        require(ownerOf(tokenId) == msg.sender);
        require(groupMapping[tokenId].length > 0);
        
        uint256[] memory retValue = new uint256[](groupMapping[tokenId].length);
        
        for (uint256 i = 0; i < groupMapping[tokenId].length; i++) {
	          this.transferFrom(address(this), msg.sender, groupMapping[tokenId][i]);
	          retValue[i] = groupMapping[tokenId][i];
	    } 
	    
	    groupMapping[tokenId].length = 0;
        
         
        _burn(msg.sender, tokenId);

		emit Ungrouping(msg.sender, tokenId);
	
        return retValue;
	}

	function getGroupContent(uint256 tokenId) public view returns (uint256[] memory)
	{
		uint256[] memory currentArray;
			
		if (!isGroup(tokenId))
		{
			currentArray = new uint256[](1);
			currentArray[0] = tokenId;
		}
		else
		{

			for (uint256 i = 0; i < groupMapping[tokenId].length; i++)
			{
				currentArray = Helpers.uint256ArrayConcat(currentArray, getGroupContent(groupMapping[tokenId][i]));
			}
		}
		return currentArray;
	}
	
	function getGroupContentFirstLevel(uint256 tokenId) public view returns (uint256[] memory)
	{
		uint256[] memory currentArray;
			
		if (!isGroup(tokenId))
		{
			currentArray = new uint256[](1);
			currentArray[0] = tokenId;
		}
		else
		{
			currentArray = groupMapping[tokenId];
			
		}
		return currentArray;
	}
	
	function isGroup(uint256 tokenId) internal view returns (bool) {
	    return (groupMapping[tokenId].length == 0);
	}

   

   

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

   

   

     
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId));
		
		bytes memory TokenURIAsBytes = bytes(tokenURIs[tokenId]); 
 
		if (TokenURIAsBytes.length == 0)
		{
		    return 	Helpers.strConcat(
						Helpers.strConcat(
                            Helpers.strConcat(
								_uri_prefix, 
								_route),
                            Helpers.strConcat(
								Helpers.bytes32ToString(Helpers.uintToBytes32(itemTypes[tokenId])), 
								"/")),
						Helpers.strConcat(
							Helpers.bytes32ToString(Helpers.uintToBytes32(tokenId)), 
							"/"));
		}
		else
		{
			return tokenURIs[tokenId];
		}
    }
	
    function setURI_Prefix(string memory _new_uri_prefix) public onlyMultiSigOwners() returns (bool) {
        _uri_prefix = _new_uri_prefix;
        return true;
    }
	
    function setRoute(string memory _new_route) public onlyMultiSigOwners() returns (bool) {
        _route = _new_route;
        return true;
    }
	
	 
	function setTokenURI(uint256 tokenID, string memory _tokenURI) public returns (bool) {
		require(msg.sender == FactoryAddress);
		
		tokenURIs[tokenID] = _tokenURI;
		return true;
	}

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);
    }

   


   
  
	 
	
    address payable ProxyContractForMetaTxsAddress;

    function setProxyContractForMetaTxsAddress(address payable _newAddress) public onlyMultiSigOwners() returns (bool) {
        ProxyContractForMetaTxsAddress = _newAddress;
    }

	  function updateWhitelist(address _account, bool _value) public returns(bool)
	  {
		ProxyContractForMetaTxs _proxy_contract_MetaTx = ProxyContractForMetaTxs(ProxyContractForMetaTxsAddress);
		return _proxy_contract_MetaTx.updateWhitelist(_account, _value);
	  }
	  
	  event UpdateWhitelist(address _account, bool _value);
	  	  
	  function () external payable
	  {
		ProxyContractForMetaTxsAddress.call.value(msg.value)("");
	  }
	  
	  event Received (address indexed sender, uint value);

	  function getHash(address signer, address destination, uint value, bytes memory data, address rewardToken, uint rewardAmount) public view returns(bytes32)
	  {
	  	ProxyContractForMetaTxs _proxy_contract_MetaTx = ProxyContractForMetaTxs(ProxyContractForMetaTxsAddress);
		return _proxy_contract_MetaTx.getHash(signer, destination, value, data, rewardToken, rewardAmount);
	  }
	  
	   
	  function forward(bytes memory sig, address signer, address destination, uint value, bytes memory data, address rewardToken, uint rewardAmount) public
	  {
	  	ProxyContractForMetaTxs _proxy_contract_MetaTx = ProxyContractForMetaTxs(ProxyContractForMetaTxsAddress);
		return _proxy_contract_MetaTx.forward(sig, signer, destination, value, data, rewardToken, rewardAmount);
	  }
	  
	   
	  event Forwarded (bytes sig, address signer, address destination, uint value, bytes data,address rewardToken, uint rewardAmount,bytes32 _hash);
	
   
}

pragma experimental ABIEncoderV2;
contract NFT_B2E_Listing is MultiSigOwnable {
    
	event RegisterNewAsset(uint256 optionID, string name);
	event RegisterNewBBA(bytes32 hash, uint256 optionID);
	    
	event UpdateAsset(uint256 optionID, string name);
	event UpdateBBA(bytes32 prevhash, bytes32 newhash, uint256 optionID);
	
    address public NFTFactoryAddress;
    address payable NFTTokenAddress;

    struct TokenType {
        uint256 optionID;
        string name;
		    address minter;
    }
	
   struct BBA_Registry_entry {
       uint256 optionID;
       uint256 version;
       address creator;
       bytes32 hash;
    }
   
    mapping(bytes32 => uint256) hashToOptionId;
    mapping(uint256 => TokenType) _tokenTypes;
    mapping(uint256 => BBA_Registry_entry) BBA_Registry;
   
   constructor(address _factory, address payable _nft, uint256 _nbApprovalNeeded, address[] memory _ownerList) MultiSigOwnable(_nbApprovalNeeded, _ownerList) public {
		NFTFactoryAddress = _factory;
		NFTTokenAddress = _nft;
   }

   function setNFTFactoryAddress(address _new_address) public onlyMultiSigOwners() {
		NFTFactoryAddress = _new_address;
   }
   
   function setNFTTokenAddress(address payable _new_address) public onlyMultiSigOwners() {
		NFTTokenAddress = _new_address;
    }
    
   function newAsset(uint256 optionID, string memory name, address minter) public {
		_tokenTypes[optionID] = TokenType(optionID, name, minter);
		emit RegisterNewAsset(optionID, name);
    }
   
   function replaceAsset(uint256 optionID, string memory name, address minter) public {
		delete _tokenTypes[optionID];
		_tokenTypes[optionID] = TokenType(optionID, name, minter);
		emit UpdateAsset(optionID, name);
    }

   function query(bytes32 hash) public view returns (uint256) {
		return hashToOptionId[hash];
    }
   
    function queryBBA(uint256 optionID) public view returns (BBA_Registry_entry memory) {
		  return BBA_Registry[optionID];
    }
   
   function registerBBA(bytes32 hash, uint256 optionID) public onlyMultiSigOwners() returns (bool) {
		emit RegisterNewBBA(hash, optionID);
		
		require(hashToOptionId[hash] == 0, "BBA Already exists");
		hashToOptionId[hash] = optionID;
		
		return true;
    }
   
   function updateBBA(bytes32 prevhash, bytes32 newhash, uint256 optionID, address creator, uint256 version) public onlyMultiSigOwners() returns (bool) {
	   require(optionID == hashToOptionId[prevhash]);
	   require(creator == BBA_Registry[optionID].creator);
	   require(version == BBA_Registry[optionID].version + 1);
	   
       BBA_Registry_entry memory _bba = BBA_Registry_entry(optionID, version, creator, newhash);
       BBA_Registry[optionID] = _bba;
	   
       emit UpdateBBA(prevhash, newhash, optionID);
	   return true;
    }
   
   	function getAllTokenIds(address addr) public view returns (uint256[] memory)
	{
		NFT_Token ItemContract = NFT_Token(NFTTokenAddress);
		return ItemContract.tokensOfOwner(addr);
	}
	
	function getAllOptionIds(address addr) public view returns (uint256[] memory)
	{
		NFT_Token ItemContract = NFT_Token(NFTTokenAddress);
		
		uint256[] memory tokenIDs = ItemContract.tokensOfOwner(addr);
		
		for (uint256 i = 0; i < tokenIDs.length; i++)
		{
			uint256 currentOptionID = ItemContract.itemTypes(tokenIDs[i]);
			tokenIDs[i] = currentOptionID;
		}
		return tokenIDs;
	}
}

contract ProxyContractForBurn is IProxyContractForBurn {
	 using SafeMath for uint256;
	 
	address public nxcAddress;
			
	uint256 minimum = 100;
	uint256 divisor = 4;
	
	constructor(address _nxcAddress) public {
		nxcAddress = _nxcAddress;
	}
	
	function setnxcAddress(address new_address) public
	{
		nxcAddress = new_address;
	}
	
	function burnNxCtoMintAssets(uint256 nbOfAsset, string[] memory keys, string[] memory values) public view returns (uint256)
	{
		require (keys.length == values.length);
		
		NxcInterface nxcContract = NxcInterface(nxcAddress);
		
		uint256 nxcTotalSupply = nxcContract.totalSupply();
		
		 
	    uint256 ret = ((nbOfAsset.add(minimum)).mul((nxcTotalSupply).div(1000))).div(divisor.mul(1000000)).mul(1000);
	    
		return ret;
	}
}