 

pragma solidity ^0.4.24;

 

 
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

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 

 
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

 

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
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

 

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return name_;
  }

   
  function symbol() external view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
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
     
    ownedTokens[_from].length--;

     
     
     

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

 

contract ERC721Holder is ERC721Receiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes
  )
    public
    returns(bytes4)
  {
    return ERC721_RECEIVED;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

  function strConcat(string _a, string _b) internal pure returns (string) {
    return strConcat(_a, _b, "", "", "");
  }
}

 

 
 
 
 
 

 

 

 
 

 
 
 

pragma solidity ^0.4.8;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) constant returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier authorized(bytes4 sig) {
        assert(isAuthorized(msg.sender, sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }

    function assert(bool x) internal {
        if (!x) throw;
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
	uint	 	  wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSMath {

     

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

     


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


     

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

     

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

     

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract DSThing is DSAuth, DSNote, DSMath {
}

contract DSValue is DSThing {
    bool    has;
    bytes32 val;
    function peek() constant returns (bytes32, bool) {
        return (val,has);
    }
    function read() constant returns (bytes32) {
        var (wut, has) = peek();
        assert(has);
        return wut;
    }
    function poke(bytes32 wut) note auth {
        val = wut;
        has = true;
    }
    function void() note auth {  
        has = false;
    }
}

contract Medianizer is DSValue {
    mapping (bytes12 => address) public values;
    mapping (address => bytes12) public indexes;
    bytes12 public next = 0x1;

    uint96 public min = 0x1;

    function set(address wat) auth {
        bytes12 nextId = bytes12(uint96(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) note auth {
        if (pos == 0x0) throw;

        if (wat != 0 && indexes[wat] != 0) throw;

        indexes[values[pos]] = 0;  

        if (wat != 0) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function setMin(uint96 min_) note auth {
        if (min_ == 0x0) throw;
        min = min_;
    }

    function setNext(bytes12 next_) note auth {
        if (next_ == 0x0) throw;
        next = next_;
    }

    function unset(bytes12 pos) {
        set(pos, 0);
    }

    function unset(address wat) {
        set(indexes[wat], 0);
    }

    function poke() {
        poke(0);
    }

    function poke(bytes32) note {
        (val, has) = compute();
    }

    function compute() constant returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint96(next) - 1);
        uint96 ctr = 0;
        for (uint96 i = 1; i < uint96(next); i++) {
            if (values[bytes12(i)] != 0) {
                var (wut, wuz) = DSValue(values[bytes12(i)]).peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint96 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint96 k = ctr; k > j; k--) {
                            wuts[k] = wuts[k - 1];
                        }
                        wuts[j] = wut;
                    }
                    ctr++;
                }
            }
        }

        if (ctr < min) return (val, false);

        bytes32 value;
        if (ctr % 2 == 0) {
            uint128 val1 = uint128(wuts[(ctr / 2) - 1]);
            uint128 val2 = uint128(wuts[ctr / 2]);
            value = bytes32(wdiv(hadd(val1, val2), 2 ether));
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }

}

 

 
contract RadiCards is ERC721Token, ERC721Holder, Whitelist {
    using SafeMath for uint256;

     
    StandardToken daiContract;
    Medianizer medianizerContract;

    string public tokenBaseURI = "https://ipfs.infura.io/ipfs/";
    uint256 public tokenIdPointer = 0;

    struct Benefactor {
        address ethAddress;
        string name;
        string website;
        string logo;
    }

    struct CardDesign {
        string tokenURI;
        bool active;
        uint minted;
        uint maxQnty;  
         
        uint256 minPrice;  
    }

     
    enum Statuses { Empty, Deposited, Claimed, Cancelled }
    uint256 public EPHEMERAL_ADDRESS_FEE = 0.01 ether;
    mapping(address => uint256) public ephemeralWalletCards;  

    struct RadiCard {
        address gifter;
        string message;
        bool daiDonation;
        uint256 giftAmount;
        uint256 donationAmount;
        Statuses status;
        uint256 cardIndex;
        uint256 benefactorIndex;
    }

    mapping(uint256 => Benefactor) public benefactors;
    uint256[] internal benefactorsIndex;

    mapping(uint256 => CardDesign) public cards;
    uint256[] internal cardsIndex;

    mapping(uint256 => RadiCard) public tokenIdToRadiCardIndex;

     
    uint256 public totalGiftedInWei;
    uint256 public totalDonatedInWei;

     
    uint256 public totalGiftedInAtto;  
    uint256 public totalDonatedInAtto;

    event CardGifted(
        address indexed _to,
        uint256 indexed _benefactorIndex,
        uint256 indexed _cardIndex,
        address _from,
        uint256 _tokenId,
        bool daiDonation,
        uint256 giftAmount,
        uint256 donationAmount,
        Statuses status
    );

    event LogClaimGift(
            address indexed ephemeralAddress,
            address indexed sender,
            uint tokenId,
            address receiver,
            uint giftAmount,
        bool daiDonation
    );

    event LogCancelGift(
        address indexed ephemeralAddress,
        address indexed sender,
        uint tokenId
    );


    event BenefactorAdded(
        uint256 indexed _benefactorIndex
    );

    event CardAdded(
        uint256 indexed _cardIndex
    );

    constructor () public ERC721Token("RadiCards", "RADI") {
        addAddressToWhitelist(msg.sender);
    }

    function gift(address _to, uint256 _benefactorIndex, uint256 _cardIndex, string _message, uint256 _donationAmount, uint256 _giftAmount, bool _claimableLink) payable public returns (bool) {
        require(_to != address(0), "Must be a valid address");
        if(_donationAmount > 0){
            require(benefactors[_benefactorIndex].ethAddress != address(0), "Must specify existing benefactor");
        }

        require(bytes(cards[_cardIndex].tokenURI).length != 0, "Must specify existing card");
        require(cards[_cardIndex].active, "Must be an active card");

        Statuses _giftStatus;
        address _sentToAddress;

        if(_claimableLink){
            require(_donationAmount + _giftAmount + EPHEMERAL_ADDRESS_FEE == msg.value, "Can only request to donate and gift the amount of ether sent + Ephemeral fee");
            _giftStatus = Statuses.Deposited;
            _sentToAddress = this;
            ephemeralWalletCards[_to] = tokenIdPointer;
            _to.transfer(EPHEMERAL_ADDRESS_FEE);
        }

        else {
            require(_donationAmount + _giftAmount == msg.value,"Can only request to donate and gift the amount of ether sent");
            _giftStatus = Statuses.Claimed;
            _sentToAddress = _to;
        }

        if (cards[_cardIndex].maxQnty > 0){  
            require(cards[_cardIndex].minted < cards[_cardIndex].maxQnty, "Can't exceed maximum quantity of card type");
        }

        if(cards[_cardIndex].minPrice > 0){  
         
         
            require (getMinCardPriceInWei(_cardIndex) <= msg.value,"Must send at least the minimum amount to buy card");
        }

        tokenIdToRadiCardIndex[tokenIdPointer] = RadiCard({
            gifter: msg.sender,
            message: _message,
            daiDonation: false,
            giftAmount: _giftAmount,
            donationAmount: _donationAmount,
            status: _giftStatus,
            cardIndex: _cardIndex,
            benefactorIndex: _benefactorIndex
        });

         
         
        uint256 _tokenId = _mint(_sentToAddress, cards[_cardIndex].tokenURI);
        cards[_cardIndex].minted++;

         
        if(_donationAmount > 0){
            benefactors[_benefactorIndex].ethAddress.transfer(_donationAmount);
            totalDonatedInWei = totalDonatedInWei.add(_donationAmount);
        }
         

        if(_giftAmount > 0){
            totalGiftedInWei = totalGiftedInWei.add(_giftAmount);
         
            if(!_claimableLink){
                _sentToAddress.transfer(_giftAmount);
            }
        }
        emit CardGifted(_sentToAddress, _benefactorIndex, _cardIndex, msg.sender, _tokenId, false, _giftAmount, _donationAmount, _giftStatus);
        return true;
    }

    function giftInDai(address _to, uint256 _benefactorIndex, uint256 _cardIndex, string _message, uint256 _donationAmount, uint256 _giftAmount, bool _claimableLink) public payable returns (bool) {
        require(_to != address(0), "Must be a valid address");
        if (_donationAmount > 0){
            require(benefactors[_benefactorIndex].ethAddress != address(0), "Must specify existing benefactor");
        }

        require(bytes(cards[_cardIndex].tokenURI).length != 0, "Must specify existing card");
        require(cards[_cardIndex].active, "Must be an active card");

        require((_donationAmount + _giftAmount) <= daiContract.allowance(msg.sender, this), "Must have provided high enough alowance to Radicard contract");
        require((_donationAmount + _giftAmount) <= daiContract.balanceOf(msg.sender), "Must have enough token balance of dai to pay for donation and gift amount");

        if (cards[_cardIndex].maxQnty > 0){  
            require(cards[_cardIndex].minted < cards[_cardIndex].maxQnty, "Can't exceed maximum quantity of card type");
        }

        if(cards[_cardIndex].minPrice > 0){  
            require((_donationAmount + _giftAmount) >= cards[_cardIndex].minPrice, "The total dai sent with the transaction is less than the min price of the token");
        }

         
        Statuses _giftStatus;
        address _sentToAddress;

        if(_claimableLink){
            require(msg.value == EPHEMERAL_ADDRESS_FEE, "A claimable link was generated but not enough ephemeral ether was sent!");
            _giftStatus = Statuses.Deposited;
            _sentToAddress = this;
             
            ephemeralWalletCards[_to] = tokenIdPointer;
            _to.transfer(EPHEMERAL_ADDRESS_FEE);
        }

        else {
            _giftStatus = Statuses.Claimed;
            _sentToAddress = _to;
        }

        tokenIdToRadiCardIndex[tokenIdPointer] = RadiCard({
            gifter: msg.sender,
            message: _message,
            daiDonation: true,
            giftAmount: _giftAmount,
            donationAmount: _donationAmount,
            status: _giftStatus,
            cardIndex: _cardIndex,
            benefactorIndex: _benefactorIndex
        });

         
         
        uint256 _tokenId = _mint(_sentToAddress, cards[_cardIndex].tokenURI);

        cards[_cardIndex].minted++;

         
        if(_donationAmount > 0){
            address _benefactorAddress = benefactors[_benefactorIndex].ethAddress;
            require(daiContract.transferFrom(msg.sender, _benefactorAddress, _donationAmount),"Sending to benefactor failed");
            totalDonatedInAtto = totalDonatedInAtto.add(_donationAmount);
        }

         
         
         
        if(_giftAmount > 0){
            require(daiContract.transferFrom(msg.sender, _sentToAddress, _giftAmount),"Sending to recipient failed");
            totalGiftedInAtto = totalGiftedInAtto.add(_giftAmount);
        }

        emit CardGifted(_sentToAddress, _benefactorIndex, _cardIndex, msg.sender, _tokenId, true, _giftAmount, _donationAmount, _giftStatus);
        return true;
    }

    function _mint(address to, string tokenURI) internal returns (uint256 _tokenId) {
        uint256 tokenId = tokenIdPointer;

        super._mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        tokenIdPointer = tokenIdPointer.add(1);

        return tokenId;
    }

    function cancelGift(address _ephemeralAddress) public returns (bool) {
        uint256 tokenId = ephemeralWalletCards[_ephemeralAddress];
        require(tokenId != 0, "Can only call this function on an address that was used as an ephemeral");
        RadiCard storage card = tokenIdToRadiCardIndex[tokenId];

         
        require(card.status == Statuses.Deposited, "can only cancel gifts that are unclaimed (deposited)");

         
        require(msg.sender == card.gifter, "only the gifter of the card can cancel a gift");

         
        card.status = Statuses.Cancelled;

         
        if (card.giftAmount > 0) {
            if(card.daiDonation){
                require(daiContract.transfer(msg.sender, card.giftAmount),"Sending to recipient after cancel gift failed");
            }
            else{
                msg.sender.transfer(card.giftAmount);
            }
        }

         
         
        transferFromEscrow(msg.sender, tokenId);

         
        emit LogCancelGift(_ephemeralAddress, msg.sender, tokenId);
        return true;
    }

    function claimGift(address _receiver) public returns (bool success) {
         
        address _ephemeralAddress = msg.sender;

        uint256 tokenId = ephemeralWalletCards[_ephemeralAddress];

        require(tokenId != 0, "The calling address does not have an ephemeral card associated with it");

        RadiCard storage card = tokenIdToRadiCardIndex[tokenId];

         
        require(card.status == Statuses.Deposited, "Can only claim a gift that is unclaimed");

         
        card.status = Statuses.Claimed;

         
        transferFromEscrow(_receiver, tokenId);

         
        if (card.giftAmount > 0) {
            if(card.daiDonation){
                require(daiContract.transfer(_receiver, card.giftAmount),"Sending to recipient after cancel gift failed");
        }
            else{
                _receiver.transfer(card.giftAmount);
            }
        }

         
        emit LogClaimGift(
            _ephemeralAddress,
            card.gifter,
            tokenId,
            _receiver,
            card.giftAmount,
            card.daiDonation
        );
        return true;
    }

    function burn(uint256 _tokenId) public pure  {
        revert("Radi.Cards are censorship resistant!");
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId), "token does not exist");

        return Strings.strConcat(tokenBaseURI, tokenURIs[_tokenId]);
    }

    function tokenDetails(uint256 _tokenId)
    public view
    returns (
        address _gifter,
        string _message,
        bool _daiDonation,
        uint256 _giftAmount,
        uint256 _donationAmount,
        Statuses status,
        uint256 _cardIndex,
        uint256 _benefactorIndex
    ) {
        require(exists(_tokenId), "token does not exist");
        RadiCard memory _radiCard = tokenIdToRadiCardIndex[_tokenId];
        return (
        _radiCard.gifter,
        _radiCard.message,
        _radiCard.daiDonation,
        _radiCard.giftAmount,
        _radiCard.donationAmount,
        _radiCard.status,
        _radiCard.cardIndex,
        _radiCard.benefactorIndex
        );
    }

    function tokenBenefactor(uint256 _tokenId)
    public view
    returns (
        address _ethAddress,
        string _name,
        string _website,
        string _logo
    ) {
        require(exists(_tokenId),"Card must exist");
        RadiCard memory _radiCard = tokenIdToRadiCardIndex[_tokenId];
        Benefactor memory _benefactor = benefactors[_radiCard.benefactorIndex];
        return (
        _benefactor.ethAddress,
        _benefactor.name,
        _benefactor.website,
        _benefactor.logo
        );
    }

    function tokensOf(address _owner) public view returns (uint256[] _tokenIds) {
        return ownedTokens[_owner];
    }

    function benefactorsKeys() public view returns (uint256[] _keys) {
        return benefactorsIndex;
    }

    function cardsKeys() public view returns (uint256[] _keys) {
        return cardsIndex;
    }

    function addBenefactor(uint256 _benefactorIndex, address _ethAddress, string _name, string _website, string _logo)
    public onlyIfWhitelisted(msg.sender)
    returns (bool) {
        require(address(_ethAddress) != address(0), "Invalid address");
        require(bytes(_name).length != 0, "Invalid name");
        require(bytes(_website).length != 0, "Invalid name");
        require(bytes(_logo).length != 0, "Invalid name");

        benefactors[_benefactorIndex] = Benefactor(
            _ethAddress,
            _name,
            _website,
            _logo
        );
        benefactorsIndex.push(_benefactorIndex);

        emit BenefactorAdded(_benefactorIndex);
        return true;
    }

    function addCard(uint256 _cardIndex, string _tokenURI, bool _active, uint256 _maxQnty, uint256 _minPrice)
    public onlyIfWhitelisted(msg.sender)
    returns (bool) {
        require(bytes(_tokenURI).length != 0, "Invalid token URI");

        cards[_cardIndex] = CardDesign(
            _tokenURI,
            _active,
            0,
            _maxQnty,
            _minPrice
        );
        cardsIndex.push(_cardIndex);

        emit CardAdded(_cardIndex);
        return true;
    }

    function setTokenBaseURI(string _newBaseURI) external onlyIfWhitelisted(msg.sender) {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");

        tokenBaseURI = _newBaseURI;
    }

    function setActive(uint256 _cardIndex, bool _active) external onlyIfWhitelisted(msg.sender) {
        require(bytes(cards[_cardIndex].tokenURI).length != 0, "Must specify existing card");
        cards[_cardIndex].active = _active;
    }

    function setMaxQuantity(uint256 _cardIndex, uint256 _maxQnty) external onlyIfWhitelisted(msg.sender) {
        require(bytes(cards[_cardIndex].tokenURI).length != 0, "Must specify existing card");
        require(cards[_cardIndex].minted <= _maxQnty, "Can't set the max quantity less than the current total minted");
        cards[_cardIndex].maxQnty = _maxQnty;
    }

    function setMinPrice(uint256 _cardIndex, uint256 _minPrice) external onlyIfWhitelisted(msg.sender) {
        require(bytes(cards[_cardIndex].tokenURI).length != 0, "Must specify existing card");
        cards[_cardIndex].minPrice = _minPrice;
    }

    function setDaiContractAddress(address _daiERC20ContractAddress) external onlyIfWhitelisted(msg.sender){
        require(_daiERC20ContractAddress != address(0), "Must be a valid address");
        daiContract = StandardToken(_daiERC20ContractAddress);
    }

     
    function setMedianizerContractAddress(address _MedianizerContractAddress) external onlyIfWhitelisted(msg.sender){
        require(_MedianizerContractAddress != address(0), "Must be a valid address");
        medianizerContract = Medianizer(_MedianizerContractAddress);
    }

     
    function getEtherPrice() public view returns(uint256){
        return uint256(medianizerContract.read());
    }

     
    function getEthUsdValue(uint256 _ether) public view returns(uint256){
        return ((_ether*getEtherPrice())/(1 ether));
    }

     
    function getMinCardPriceInWei(uint256 _cardIndex) public view returns(uint256){
        return ((cards[_cardIndex].minPrice * 1 ether)/getEtherPrice());
    }
     
    function transferFromEscrow(address _recipient,uint256 _tokenId) internal{
        require(super.ownerOf(_tokenId) == address(this),"The card must be owned by the contract for it to be in escrow");
        super.clearApproval(this, _tokenId);
        super.removeTokenFrom(this, _tokenId);
        super.addTokenTo(_recipient, _tokenId);
        emit Transfer(this, _recipient, _tokenId);
    }
}