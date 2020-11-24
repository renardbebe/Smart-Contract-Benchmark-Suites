 

pragma solidity 0.4.24;

 
 
 
 
 
 
 


 
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

 
contract SafeMath2 {

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
}
}


contract RUNEToken is SafeMath2
{
    
     
    string  public name = "Rune";
    string  public symbol  = "RUNE";
    uint256   public decimals  = 18;
    uint256 public totalSupply  = 1000000000 * (10 ** decimals);

     
    mapping( address => uint256 ) balances_;
    mapping( address => mapping(address => uint256) ) allowances_;
    
     
    function RUNEToken() public {
            balances_[msg.sender] = totalSupply;
                emit Transfer( address(0), msg.sender, totalSupply );
        }

    function() public payable { revert(); }  
    
     
    event Approval( address indexed owner,
                    address indexed spender,
                    uint value );

    event Transfer( address indexed from,
                    address indexed to,
                    uint256 value );


     
    function balanceOf( address owner ) public constant returns (uint) {
        return balances_[owner];
    }

     
    function approve( address spender, uint256 value ) public
    returns (bool success)
    {
        allowances_[msg.sender][spender] = value;
        emit Approval( msg.sender, spender, value );
        return true;
    }
    
     
    function safeApprove( address _spender,
                            uint256 _currentValue,
                            uint256 _value ) public
                            returns (bool success) {

         
         

        if (allowances_[msg.sender][_spender] == _currentValue)
        return approve(_spender, _value);

        return false;
    }

     
    function allowance( address owner, address spender ) public constant
    returns (uint256 remaining)
    {
        return allowances_[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool success)
    {
        bytes memory empty;  
        _transfer( msg.sender, to, value, empty );
        return true;
    }

     
    function transferFrom( address from, address to, uint256 value ) public
    returns (bool success)
    {
        require( value <= allowances_[from][msg.sender] );

        allowances_[from][msg.sender] -= value;
        bytes memory empty;
        _transfer( from, to, value, empty );

        return true;
    }

     
    function transfer( address to,
                        uint value,
                        bytes data,
                        string custom_fallback ) public returns (bool success)
    {
        _transfer( msg.sender, to, value, data );

        if ( isContract(to) )
        {
        ContractReceiver rx = ContractReceiver( to );
        require( address(rx).call.value(0)(bytes4(keccak256(custom_fallback)),
                msg.sender,
                value,
                data) );
        }

        return true;
    }

     
    function transfer( address to, uint value, bytes data ) public
    returns (bool success)
    {
        if (isContract(to)) {
        return transferToContract( to, value, data );
        }

        _transfer( msg.sender, to, value, data );
        return true;
    }

     
    function transferToContract( address to, uint value, bytes data ) private
    returns (bool success)
    {
        _transfer( msg.sender, to, value, data );

        ContractReceiver rx = ContractReceiver(to);
        rx.tokenFallback( msg.sender, value, data );

        return true;
    }

     
    function isContract( address _addr ) private constant returns (bool)
    {
        uint length;
        assembly { length := extcodesize(_addr) }
        return (length > 0);
    }

    function _transfer( address from,
                        address to,
                        uint value,
                        bytes data ) internal
    {
        require( to != 0x0 );
        require( balances_[from] >= value );
        require( balances_[to] + value > balances_[to] );  

        balances_[from] -= value;
        balances_[to] += value;

         
        bytes memory empty;
        empty = data;
        emit Transfer( from, to, value );  
    }
    
    
         
    event Burn( address indexed from, uint256 value );
    
         
    function burn( uint256 value ) public
    returns (bool success)
    {
        require( balances_[msg.sender] >= value );
        balances_[msg.sender] -= value;
        totalSupply -= value;

        emit Burn( msg.sender, value );
        return true;
    }

     
    function burnFrom( address from, uint256 value ) public
    returns (bool success)
    {
        require( balances_[from] >= value );
        require( value <= allowances_[from][msg.sender] );

        balances_[from] -= value;
        allowances_[from][msg.sender] -= value;
        totalSupply -= value;

        emit Burn( from, value );
        return true;
    }
  
  
}




 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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


 
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
   

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



contract THORChain721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  bytes4 retval;
  bool reverts;

  constructor(bytes4 _retval, bool _reverts) public {
    retval = _retval;
    reverts = _reverts;
  }

  event Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data,
    uint256 _gas
  );

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4)
  {
    require(!reverts);
    emit Received(
      _operator,
      _from,
      _tokenId,
      _data,
      gasleft()
    );
    return retval;
  }
}



 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


 
library AddressUtils {

   
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_account) }
    return size > 0;
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

   
  function _exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
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
    bytes4 retval = THORChain721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
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
    require(_exists(_tokenId));
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
    require(_exists(_tokenId));
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

contract THORChain721 is ERC721Token {
    
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor () public ERC721Token("testTC1", "testTC1") {
        owner = msg.sender;
    }

     
    function() public payable { 
        revert(); 
    }
    
    function mint(address _to, uint256 _tokenId) public onlyOwner {
        super._mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) public onlyOwner {
        super._burn(ownerOf(_tokenId), _tokenId);
    }

    function setTokenURI(uint256 _tokenId, string _uri) public onlyOwner {
        super._setTokenURI(_tokenId, _uri);
    }

    function _removeTokenFrom(address _from, uint256 _tokenId) public {
        super.removeTokenFrom(_from, _tokenId);
    }
}

contract Whitelist {

    address public owner;
    mapping(address => bool) public whitelistAdmins;
    mapping(address => bool) public whitelist;

    constructor () public {
        owner = msg.sender;
        whitelistAdmins[owner] = true;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyWhitelistAdmin () {
        require(whitelistAdmins[msg.sender], "Only whitelist admin");
        _;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return whitelist[_addr];
    }

    function addWhitelistAdmin(address _admin) public onlyOwner {
        whitelistAdmins[_admin] = true;
    }

    function removeWhitelistAdmin(address _admin) public onlyOwner {
        require(_admin != owner, "Cannot remove contract owner");
        whitelistAdmins[_admin] = false;
    }

    function whitelistAddress(address _user) public onlyWhitelistAdmin  {
        whitelist[_user] = true;
    }

    function whitelistAddresses(address[] _users) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = true;
        }
    }

    function unWhitelistAddress(address _user) public onlyWhitelistAdmin  {
        whitelist[_user] = false;
    }

    function unWhitelistAddresses(address[] _users) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = false;
        }
    }

}

contract Sale1 is Whitelist {
    
    using SafeMath for uint256;

    uint256 public maximumNonWhitelistAmount = 12500 * 50 ether;  

     
     
    uint256 public runeToWeiRatio = 12500;
    bool public withdrawalsAllowed = false;
    bool public tokensWithdrawn = false;
    address public owner;
    address public proceedsAddress = 0xd46cac034f44ac93049f8f1109b6b74f79b3e5e6;
    RUNEToken public RuneToken = RUNEToken(0xdEE02D94be4929d26f67B64Ada7aCf1914007F10);
    Whitelist public WhitelistContract = Whitelist(0x395Eb47d46F7fFa7Dd4b27e1B64FC6F21d5CC4C7);
    THORChain721 public ERC721Token = THORChain721(0x953d066d809dc71b8809dafb8fb55b01bc23a6e0);

    uint256 public CollectibleIndex0 = 0;
    uint256 public CollectibleIndex1 = 1;
    uint256 public CollectibleIndex2 = 2;
    uint256 public CollectibleIndex3 = 3;
    uint256 public CollectibleIndex4 = 4;
    uint256 public CollectibleIndex5 = 5;

    uint public winAmount0 = 666.666666666666666667 ether;
    uint public winAmount1 = 1333.333333333333333333 ether;
    uint public winAmount2 = 2000.0 ether;
    uint public winAmount3 = 2666.666666666666666667 ether;
    uint public winAmount4 = 3333.333333333333333333 ether;
    uint public winAmount5 = 4000.0 ether;

    mapping (uint256 => address) public collectibleAllocation;
    mapping (address => uint256) public runeAllocation;

    uint256 public totalRunePurchased;
    uint256 public totalRuneWithdrawn;

    event TokenWon(uint256 tokenId, address winner);

    modifier onlyOwner () {
        require(owner == msg.sender, "Only the owner can use this function");
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function () public payable {
        require(!tokensWithdrawn, "Tokens withdrawn. No more purchases possible.");
         
        uint runeRemaining = (RuneToken.balanceOf(this).add(totalRuneWithdrawn)).sub(totalRunePurchased);
        uint toForward = msg.value;
        uint weiToReturn = 0;
        uint purchaseAmount = msg.value * runeToWeiRatio;
        if(runeRemaining < purchaseAmount) {
            purchaseAmount = runeRemaining;
            uint price = purchaseAmount.div(runeToWeiRatio);
            weiToReturn = msg.value.sub(price);
            toForward = toForward.sub(weiToReturn);
        }

         
        uint ethBefore = totalRunePurchased.div(runeToWeiRatio);
        uint ethAfter = ethBefore.add(toForward);

        if(ethBefore <= winAmount0 && ethAfter > winAmount0) {
            collectibleAllocation[CollectibleIndex0] = msg.sender;
            emit TokenWon(CollectibleIndex0, msg.sender);
        } if(ethBefore < winAmount1 && ethAfter >= winAmount1) {
            collectibleAllocation[CollectibleIndex1] = msg.sender;
            emit TokenWon(CollectibleIndex1, msg.sender);
        } if(ethBefore < winAmount2 && ethAfter >= winAmount2) {
            collectibleAllocation[CollectibleIndex2] = msg.sender;
            emit TokenWon(CollectibleIndex2, msg.sender);
        } if(ethBefore < winAmount3 && ethAfter >= winAmount3) {
            collectibleAllocation[CollectibleIndex3] = msg.sender;
            emit TokenWon(CollectibleIndex3, msg.sender);
        } if(ethBefore < winAmount4 && ethAfter >= winAmount4) {
            collectibleAllocation[CollectibleIndex4] = msg.sender;
            emit TokenWon(CollectibleIndex4, msg.sender);
        } if(ethBefore < winAmount5 && ethAfter >= winAmount5) {
            collectibleAllocation[CollectibleIndex5] = msg.sender;
            emit TokenWon(CollectibleIndex5, msg.sender);
        } 

        runeAllocation[msg.sender] = runeAllocation[msg.sender].add(purchaseAmount);
        totalRunePurchased = totalRunePurchased.add(purchaseAmount);
         
        proceedsAddress.transfer(toForward);
        if(weiToReturn > 0) {
            address(msg.sender).transfer(weiToReturn);
        }
    }

    function setMaximumNonWhitelistAmount (uint256 _newAmount) public onlyOwner {
        maximumNonWhitelistAmount = _newAmount;
    }

    function withdrawRune () public {
        require(withdrawalsAllowed, "Withdrawals are not allowed.");
        uint256 runeToWithdraw;
        if (WhitelistContract.isWhitelisted(msg.sender)) {
            runeToWithdraw = runeAllocation[msg.sender];
        } else {
            runeToWithdraw = (
                runeAllocation[msg.sender] > maximumNonWhitelistAmount
            ) ? maximumNonWhitelistAmount : runeAllocation[msg.sender];
        }

        runeAllocation[msg.sender] = runeAllocation[msg.sender].sub(runeToWithdraw);
        totalRuneWithdrawn = totalRuneWithdrawn.add(runeToWithdraw);
        RuneToken.transfer(msg.sender, runeToWithdraw);  
        distributeCollectiblesTo(msg.sender);
    }

    function ownerWithdrawRune () public onlyOwner {
        tokensWithdrawn = true;
        RuneToken.transfer(owner, RuneToken.balanceOf(this).sub(totalRunePurchased.sub(totalRuneWithdrawn)));
    }

    function allowWithdrawals () public onlyOwner {
        withdrawalsAllowed = true;
    }

    function distributeTo (address _receiver) public onlyOwner {
        require(runeAllocation[_receiver] > 0, "Receiver has not purchased any RUNE.");
        uint balance = runeAllocation[_receiver];
        delete runeAllocation[_receiver];
        RuneToken.transfer(_receiver, balance);
        distributeCollectiblesTo(_receiver);
    }

    function distributeCollectiblesTo (address _receiver) internal {
        if(collectibleAllocation[CollectibleIndex0] == _receiver) {
            delete collectibleAllocation[CollectibleIndex0];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex0);
        } 
        if(collectibleAllocation[CollectibleIndex1] == _receiver) {
            delete collectibleAllocation[CollectibleIndex1];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex1);
        } 
        if(collectibleAllocation[CollectibleIndex2] == _receiver) {
            delete collectibleAllocation[CollectibleIndex2];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex2);
        } 
        if(collectibleAllocation[CollectibleIndex3] == _receiver) {
            delete collectibleAllocation[CollectibleIndex3];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex3);
        } 
        if(collectibleAllocation[CollectibleIndex4] == _receiver) {
            delete collectibleAllocation[CollectibleIndex4];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex4);
        } 
        if(collectibleAllocation[CollectibleIndex5] == _receiver) {
            delete collectibleAllocation[CollectibleIndex5];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex5);
        }
    }
}