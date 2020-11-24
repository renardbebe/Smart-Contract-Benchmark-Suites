 

pragma solidity ^0.4.24;


 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
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


interface POUInterface {

    function totalStaked(address) external view returns(uint256);
    function numApplications(address) external view returns(uint256);

}


 




 
 



contract EIP20Interface {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

    function EIP20(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);  
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}










 
contract TokenControllerI {

     
     
    function transferAllowed(address _from, address _to)
        external
        view 
        returns (bool);
}







 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

   
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}





 
library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

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



 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
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

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
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
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}


 

contract ERC721Controllable is Ownable, ERC721BasicToken {
    TokenControllerI public controller;

     
    modifier isAllowed(address _from, address _to) {
        require(controller.transferAllowed(_from, _to), "controller must allow the transfer");
        _;
    }

     
    function setController(TokenControllerI _controller) public onlyOwner {
        require(_controller != address(0), "controller must be a valid address");
        controller = _controller;
    }

      
     
    function transferFrom(address _from, address _to, uint256 _tokenID)
        public
        isAllowed(_from, _to)
    {
        super.transferFrom(_from, _to, _tokenID);
    }
}





 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


contract StakeToken is ERC721Controllable, POUInterface {
  EIP20Interface intrinsicToken;
  uint256 nftNonce;

  using SafeMath for uint;


  function numApplications(address prover) external view returns(uint256) {
    return balanceOf(prover);
  }

  function totalStaked(address prover) external view returns(uint256) {
    return _totalStaked[prover];
  }

  mapping (address => uint256) _totalStaked;
  mapping (uint256 => uint256) public tokenStake;
  mapping (uint256 => uint256) public tokenMintedOn;
  mapping (uint256 => uint256) public tokenBurntOn;

  constructor(EIP20Interface _token) public {
    intrinsicToken = _token;
  }

  function mint(address mintedTokenOwner, uint256 stake) public returns (uint256 tokenID) {
    require(msg.sender == mintedTokenOwner, "msg.sender == mintedTokenOwner");

    nftNonce += 1;
    tokenID = nftNonce;
    tokenStake[tokenID] = stake;
    tokenMintedOn[tokenID] = block.timestamp;
    super._mint(mintedTokenOwner, tokenID);

    require(intrinsicToken.transferFrom(mintedTokenOwner, this, stake), "transferFrom");

    return tokenID;
  }

  function burn(uint256 tokenID) public {
    address burntTokenOwner = tokenOwner[tokenID];
    require(msg.sender == burntTokenOwner, "msg.sender == burntTokenOwner");  
    uint256 stake = tokenStake[tokenID];
    super._burn(burntTokenOwner, tokenID);
    tokenBurntOn[tokenID] = block.timestamp;
    require(intrinsicToken.transfer(burntTokenOwner, stake), "transfer");
  }

  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);
    _totalStaked[_from] = _totalStaked[_from].sub(tokenStake[_tokenId]);
  }

  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    _totalStaked[_to] = _totalStaked[_to].add(tokenStake[_tokenId]);
  }
}












contract CSTRegistry {
  function getGeohash(bytes32 cst) public view returns (bytes32 geohash);
  function getRadius(bytes32 cst) public view returns (uint256 radius);
  function getCreatedOn(bytes32 cst) public view returns (uint256 timestamp);
  function getDeletedOn(bytes32 cst) public view returns (uint256 timestamp);

  function isTracked(bytes32 cst) public view returns (bool);

  event TrackedToken(bytes32 cst, address indexed nftAddress, uint256 tokenID, bytes32 geohash, uint256 radius);

 


  function computeCST(address nftContract, uint256 tokenID) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenID));
  }
}


contract SignalToken is StakeToken, CSTRegistry {
  mapping (uint256 => bytes32) public tokenGeohash;
  mapping (uint256 => uint256) public tokenRadius;
  mapping (bytes32 => uint256) public cstToID;

  constructor(EIP20Interface _token) StakeToken(_token) public { }

  function mint(address, uint256) public returns (uint256) {
    revert("use mintSignal(address,uint256,bytes32,uint256) instead");
  }

  function mintSignal(address owner, uint256 stake, bytes32 geohash, uint256 radius) public returns (uint256 tokenID) {
    tokenID = super.mint(owner, stake);
    tokenGeohash[tokenID] = geohash;
    tokenRadius[tokenID] = radius;

    bytes32 cst = computeCST(address(this), tokenID);
    cstToID[cst] = tokenID;

     
     
     
     
     
    emit TrackedToken(cst, this, tokenID, geohash, radius);

    return tokenID;
  }

   
  function getGeohash(bytes32 cst) public view returns (bytes32 geohash) {
    return tokenGeohash[cstToID[cst]];
  }

  function getRadius(bytes32 cst) public view returns (uint256 radius) {
    return tokenRadius[cstToID[cst]];
  }

  function getCreatedOn(bytes32 cst) public view returns (uint256 timestamp) {
    return tokenMintedOn[cstToID[cst]];
  }

  function getDeletedOn(bytes32 cst) public view returns (uint256 timestamp) {
    return tokenBurntOn[cstToID[cst]];
  }

  function isTracked(bytes32 cst) public view returns (bool) {
    return cstToID[cst] != 0;
  }

  function name() external pure returns (string) {
    return "FOAM Signal";
  }

  function symbol() external pure returns (string) {
    return "FSX";
  }
}