 

pragma solidity ^0.5.0;
 
 
 
 
 
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

interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library AddressUtils {

   
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

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

library RecordKeeping {
    struct priceRecord {
        uint256 price;
        address owner;
        uint256 timestamp;

    }
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
    bytes memory _data 
  )
    public;
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

contract Withdrawable  is Ownable {
    
     
     
     
     
     
     
     

    event BalanceChanged(address indexed _owner, int256 _change,  uint256 _balance, uint8 _changeType);
  
    mapping (address => uint256) internal pendingWithdrawals;
  
     
    uint256 internal totalPendingAmount;

    function _deposit(address addressToDeposit, uint256 amount, uint8 changeType) internal{      
        if (amount > 0) {
            _depositWithoutEvent(addressToDeposit, amount);
            emit BalanceChanged(addressToDeposit, int256(amount), pendingWithdrawals[addressToDeposit], changeType);
        }
    }

    function _depositWithoutEvent(address addressToDeposit, uint256 amount) internal{
        pendingWithdrawals[addressToDeposit] += amount;
        totalPendingAmount += amount;       
    }

    function getBalance(address addressToCheck) public view returns (uint256){
        return pendingWithdrawals[addressToCheck];
    }

    function withdrawOwnFund(address payable recipient_address) public {
        require(msg.sender==recipient_address);

        uint amount = pendingWithdrawals[recipient_address];
        require(amount > 0);
         
         
        pendingWithdrawals[recipient_address] = 0;
        totalPendingAmount -= amount;
        recipient_address.transfer(amount);
        emit BalanceChanged(recipient_address, -1 * int256(amount),  0, 0);
    }

    function checkAvailableContractBalance() public view returns (uint256){
        if (address(this).balance > totalPendingAmount){
            return address(this).balance - totalPendingAmount;
        } else{
            return 0;
        }
    }
    function withdrawContractFund(address payable recipient_address) public onlyOwner  {
        uint256 amountToWithdraw = checkAvailableContractBalance();
        if (amountToWithdraw > 0){
            recipient_address.transfer(amountToWithdraw);
        }
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
    bytes memory _data
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
    bytes memory _data
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
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string memory);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
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

contract ERC721WithState is ERC721BasicToken {
    mapping (uint256 => uint8) internal tokenState;

    event TokenStateSet(uint256 indexed _tokenId,  uint8 _state);

    function setTokenState(uint256  _tokenId,  uint8 _state) public  {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        require(exists(_tokenId)); 
        tokenState[_tokenId] = _state;      
        emit TokenStateSet(_tokenId, _state);
    }

    function getTokenState(uint256  _tokenId) public view returns (uint8){
        require(exists(_tokenId));
        return tokenState[_tokenId];
    } 


}
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

   
  constructor(string memory _name, string memory _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string memory) {
    return name_;
  }

   
  function symbol() external view returns (string memory) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string memory) {
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

   
  function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

contract RetroArt is ERC721Token, Ownable, Withdrawable, ERC721WithState {
    
    address public stemTokenContractAddress; 
    uint256 public currentPrice;
    uint256 constant initiailPrice = 0.03 ether;
     
     
    uint public priceRate = 10;
    uint public slowDownRate = 7;
     
     
     
     
    uint public profitCommission = 500;

     
     
     
    uint public referralCommission = 3000;

     
     
     
     
    uint public sharePercentage = 3000;

     
    uint public numberOfShares = 10;

    string public uriPrefix ="";


     
    mapping (uint256 => string) internal tokenTitles;
    mapping (uint256 => RecordKeeping.priceRecord) internal initialPriceRecords;
    mapping (uint256 => RecordKeeping.priceRecord) internal lastPriceRecords;
    mapping (uint256 => uint256) internal currentTokenPrices;


    event AssetAcquired(address indexed _owner, uint256 indexed _tokenId, string  _title, uint256 _price);
    event TokenPriceSet(uint256 indexed _tokenId,  uint256 _price);
    event TokenBrought(address indexed _from, address indexed _to, uint256 indexed _tokenId, uint256 _price);
    event PriceRateChanged(uint _priceRate);
    event SlowDownRateChanged(uint _slowDownRate);
    event ProfitCommissionChanged(uint _profitCommission);
    event MintPriceChanged(uint256 _price);
    event SharePercentageChanged(uint _sharePercentage);
    event NumberOfSharesChanged(uint _numberOfShares);
    event ReferralCommissionChanged(uint _referralCommission);
    event Burn(address indexed _owner, uint256 _tokenId);

   

    bytes4 private constant InterfaceId_RetroArt = 0x94fb30be;
     

    address[] internal auctionContractAddresses;
 
   

    function tokenTitle(uint256 _tokenId) public view returns (string memory) {
        require(exists(_tokenId));
        return tokenTitles[_tokenId];
    }
    function lastPriceOf(uint256 _tokenId) public view returns (uint256) {
        require(exists(_tokenId));
        return  lastPriceRecords[_tokenId].price;
    }   

    function lastTransactionTimeOf(uint256 _tokenId) public view returns (uint256) {
        require(exists(_tokenId));
        return  lastPriceRecords[_tokenId].timestamp;
    }

    function firstPriceOf(uint256 _tokenId) public view returns (uint256) {
        require(exists(_tokenId));
        return  initialPriceRecords[_tokenId].price;
    }   
    function creatorOf(uint256 _tokenId) public view returns (address) {
        require(exists(_tokenId));
        return  initialPriceRecords[_tokenId].owner;
    }
    function firstTransactionTimeOf(uint256 _tokenId) public view returns (uint256) {
        require(exists(_tokenId));
        return  initialPriceRecords[_tokenId].timestamp;
    }
    
  
     
    function lastHistoryOf(uint256 _tokenId) internal view returns (RecordKeeping.priceRecord storage) {
        require(exists(_tokenId));
        return lastPriceRecords[_tokenId];
    }

    function firstHistoryOf(uint256 _tokenId) internal view returns (RecordKeeping.priceRecord storage) {
        require(exists(_tokenId)); 
        return   initialPriceRecords[_tokenId];
    }

    function setPriceRate(uint _priceRate) public onlyOwner {
        priceRate = _priceRate;
        emit PriceRateChanged(priceRate);
    }

    function setSlowDownRate(uint _slowDownRate) public onlyOwner {
        slowDownRate = _slowDownRate;
        emit SlowDownRateChanged(slowDownRate);
    }
 
    function setprofitCommission(uint _profitCommission) public onlyOwner {
        require(_profitCommission <= 10000);
        profitCommission = _profitCommission;
        emit ProfitCommissionChanged(profitCommission);
    }

    function setSharePercentage(uint _sharePercentage) public onlyOwner  {
        require(_sharePercentage <= 10000);
        sharePercentage = _sharePercentage;
        emit SharePercentageChanged(sharePercentage);
    }

    function setNumberOfShares(uint _numberOfShares) public onlyOwner  {
        numberOfShares = _numberOfShares;
        emit NumberOfSharesChanged(numberOfShares);
    }

    function setReferralCommission(uint _referralCommission) public onlyOwner  {
        require(_referralCommission <= 10000);
        referralCommission = _referralCommission;
        emit ReferralCommissionChanged(referralCommission);
    }

    function setUriPrefix(string memory _uri) public onlyOwner  {
       uriPrefix = _uri;
    }
  
     
     
     

    constructor(string memory _name, string memory _symbol , address _stemTokenAddress) 
        ERC721Token(_name, _symbol) Ownable() public {
       
        currentPrice = initiailPrice;
        stemTokenContractAddress = _stemTokenAddress;
        _registerInterface(InterfaceId_RetroArt);
    }

    function getAllAssets() public view returns (uint256[] memory){
        return allTokens;
    }

    function getAllAssetsForSale() public view returns  (uint256[] memory){
      
        uint arrayLength = allTokens.length;
        uint forSaleCount = 0;
        for (uint i = 0; i<arrayLength; i++) {
            if (currentTokenPrices[allTokens[i]] > 0) {
                forSaleCount++;              
            }
        }
        
        uint256[] memory tokensForSale = new uint256[](forSaleCount);

        uint j = 0;
        for (uint i = 0; i<arrayLength; i++) {
            if (currentTokenPrices[allTokens[i]] > 0) {                
                tokensForSale[j] = allTokens[i];
                j++;
            }
        }

        return tokensForSale;
    }

    function getAssetsForSale(address _owner) public view returns (uint256[] memory) {
      
        uint arrayLength = allTokens.length;
        uint forSaleCount = 0;
        for (uint i = 0; i<arrayLength; i++) {
            if (currentTokenPrices[allTokens[i]] > 0 && tokenOwner[allTokens[i]] == _owner) {
                forSaleCount++;              
            }
        }
        
        uint256[] memory tokensForSale = new uint256[](forSaleCount);

        uint j = 0;
        for (uint i = 0; i<arrayLength; i++) {
            if (currentTokenPrices[allTokens[i]] > 0 && tokenOwner[allTokens[i]] == _owner) {                
                tokensForSale[j] = allTokens[i];
                j++;
            }
        }

        return tokensForSale;
    }

    function getAssetsByState(uint8 _state) public view returns (uint256[] memory){
        
        uint arrayLength = allTokens.length;
        uint matchCount = 0;
        for (uint i = 0; i<arrayLength; i++) {
            if (tokenState[allTokens[i]] == _state) {
                matchCount++;              
            }
        }
        
        uint256[] memory matchedTokens = new uint256[](matchCount);

        uint j = 0;
        for (uint i = 0; i<arrayLength; i++) {
            if (tokenState[allTokens[i]] == _state) {                
                matchedTokens[j] = allTokens[i];
                j++;
            }
        }

        return matchedTokens;
    }
      

    function acquireAsset(uint256 _tokenId, string memory _title) public payable{
        acquireAssetWithReferral(_tokenId, _title, address(0));
    }

    function acquireAssetFromStemToken(address _tokenOwner, uint256 _tokenId, string calldata _title) external {     
         require(msg.sender == stemTokenContractAddress);
        _acquireAsset(_tokenId, _title, _tokenOwner, 0);
    }

    function acquireAssetWithReferral(uint256 _tokenId, string memory _title, address referralAddress) public payable{
        require(msg.value >= currentPrice);
        
        uint totalShares = numberOfShares;
        if (referralAddress != address(0)) totalShares++;

        uint numberOfTokens = allTokens.length;
     
        if (numberOfTokens > 0 && sharePercentage > 0) {

            uint256 perShareValue = 0;
            uint256 totalShareValue = msg.value * sharePercentage / 10000 ;

            if (totalShares > numberOfTokens) {
                               
                if (referralAddress != address(0)) 
                    perShareValue = totalShareValue / (numberOfTokens + 1);
                else
                    perShareValue = totalShareValue / numberOfTokens;
            
                for (uint i = 0; i < numberOfTokens; i++) {
                     
                    if (numberOfTokens > 100) {
                        _depositWithoutEvent(tokenOwner[allTokens[i]], perShareValue);
                    }else{
                        _deposit(tokenOwner[allTokens[i]], perShareValue, 2);
                    }
                }
                
            }else{
               
                if (referralAddress != address(0)) 
                    perShareValue = totalShareValue / (totalShares + 1);
                else
                    perShareValue = totalShareValue / totalShares;
              
                uint[] memory randomArray = random(numberOfShares);

                for (uint i = 0; i < numberOfShares; i++) {
                    uint index = randomArray[i] % numberOfTokens;

                    if (numberOfShares > 100) {
                        _depositWithoutEvent(tokenOwner[allTokens[index]], perShareValue);
                    }else{
                        _deposit(tokenOwner[allTokens[index]], perShareValue, 2);
                    }
                }
            }
                    
            if (referralAddress != address(0) && perShareValue > 0) _deposit(referralAddress, perShareValue, 5);

        }

        _acquireAsset(_tokenId, _title, msg.sender, msg.value);
     
    }

    function _acquireAsset(uint256 _tokenId, string memory _title, address _purchaser, uint256 _value) internal {
        
        currentPrice = CalculateNextPrice();
        _mint(_purchaser, _tokenId);        
      
        tokenTitles[_tokenId] = _title;
       
        RecordKeeping.priceRecord memory pr = RecordKeeping.priceRecord(_value, _purchaser, block.timestamp);
        initialPriceRecords[_tokenId] = pr;
        lastPriceRecords[_tokenId] = pr;     

        emit AssetAcquired(_purchaser,_tokenId, _title, _value);
        emit TokenBrought(address(0), _purchaser, _tokenId, _value);
        emit MintPriceChanged(currentPrice);
    }

    function CalculateNextPrice() public view returns (uint256){      
        return currentPrice + currentPrice * slowDownRate / ( priceRate * (allTokens.length + 2));
    }

    function tokensOf(address _owner) public view returns (uint256[] memory){
        return ownedTokens[_owner];
    }

    function _buyTokenFromWithReferral(address _from, address _to, uint256 _tokenId, address referralAddress, address _depositTo) internal {
        require(currentTokenPrices[_tokenId] != 0);
        require(msg.value >= currentTokenPrices[_tokenId]);
        
        tokenApprovals[_tokenId] = _to;
        safeTransferFrom(_from,_to,_tokenId);

        uint256 valueTransferToOwner = msg.value;
        uint256 lastRecordPrice = lastPriceRecords[_tokenId].price;
        if (msg.value >  lastRecordPrice){
            uint256 profit = msg.value - lastRecordPrice;           
            uint256 commission = profit * profitCommission / 10000;
            valueTransferToOwner = msg.value - commission;
            if (referralAddress != address(0)){
                _deposit(referralAddress, commission * referralCommission / 10000, 5);
            }           
        }
        
        if (valueTransferToOwner > 0) _deposit(_depositTo, valueTransferToOwner, 1);
        writePriceRecordForAssetSold(_depositTo, msg.sender, _tokenId, msg.value);
        
    }

    function buyTokenFromWithReferral(address _from, address _to, uint256 _tokenId, address referralAddress) public payable {
        _buyTokenFromWithReferral(_from, _to, _tokenId, referralAddress, _from);        
    }

    function buyTokenFrom(address _from, address _to, uint256 _tokenId) public payable {
        buyTokenFromWithReferral(_from, _to, _tokenId, address(0));        
    }   

    function writePriceRecordForAssetSold(address _from, address _to, uint256 _tokenId, uint256 _value) internal {
       RecordKeeping.priceRecord memory pr = RecordKeeping.priceRecord(_value, _to, block.timestamp);
       lastPriceRecords[_tokenId] = pr;
       
       tokenApprovals[_tokenId] = address(0);
       currentTokenPrices[_tokenId] = 0;
       emit TokenBrought(_from, _to, _tokenId, _value);       
    }

    function recordAuctionPriceRecord(address _from, address _to, uint256 _tokenId, uint256 _value)
       external {

       require(findAuctionContractIndex(msg.sender) >= 0);  
       writePriceRecordForAssetSold(_from, _to, _tokenId, _value);

    }

    function setTokenPrice(uint256 _tokenId, uint256 _newPrice) public  {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        currentTokenPrices[_tokenId] = _newPrice;
        emit TokenPriceSet(_tokenId, _newPrice);
    }

    function getTokenPrice(uint256 _tokenId)  public view returns(uint256) {
        return currentTokenPrices[_tokenId];
    }

    function random(uint num) private view returns (uint[] memory) {
        
        uint base = uint(keccak256(abi.encodePacked(block.difficulty, now, tokenOwner[allTokens[allTokens.length-1]])));
        uint[] memory randomNumbers = new uint[](num);
        
        for (uint i = 0; i<num; i++) {
            randomNumbers[i] = base;
            base = base * 2 ** 3;
        }
        return  randomNumbers;
        
    }


    function getAsset(uint256 _tokenId)  external
        view
        returns
    (
        string memory title,            
        address owner,     
        address creator,      
        uint256 currentTokenPrice,
        uint256 lastPrice,
        uint256 initialPrice,
        uint256 lastDate,
        uint256 createdDate
    ) {
        require(exists(_tokenId));
        RecordKeeping.priceRecord memory lastPriceRecord = lastPriceRecords[_tokenId];
        RecordKeeping.priceRecord memory initialPriceRecord = initialPriceRecords[_tokenId];

        return (
             
            tokenTitles[_tokenId],        
            tokenOwner[_tokenId],   
            initialPriceRecord.owner,           
            currentTokenPrices[_tokenId],      
            lastPriceRecord.price,           
            initialPriceRecord.price,
            lastPriceRecord.timestamp,
            initialPriceRecord.timestamp
        );
    }

    function getAssetUpdatedInfo(uint256 _tokenId) external
        view
        returns
    (         
        address owner, 
        address approvedAddress,
        uint256 currentTokenPrice,
        uint256 lastPrice,      
        uint256 lastDate
      
    ) {
        require(exists(_tokenId));
        RecordKeeping.priceRecord memory lastPriceRecord = lastPriceRecords[_tokenId];
     
        return (
            tokenOwner[_tokenId],   
            tokenApprovals[_tokenId],  
            currentTokenPrices[_tokenId],      
            lastPriceRecord.price,   
            lastPriceRecord.timestamp           
        );
    }

    function getAssetStaticInfo(uint256 _tokenId)  external
        view
        returns
    (
        string memory title,            
        string memory tokenURI,    
        address creator,            
        uint256 initialPrice,       
        uint256 createdDate
    ) {
        require(exists(_tokenId));      
        RecordKeeping.priceRecord memory initialPriceRecord = initialPriceRecords[_tokenId];

        return (
             
            tokenTitles[_tokenId],        
            tokenURIs[_tokenId],
            initialPriceRecord.owner,
            initialPriceRecord.price,         
            initialPriceRecord.timestamp
        );
         
    }

    function burnExchangeToken(address _tokenOwner, uint256 _tokenId) external  {
        require(msg.sender == stemTokenContractAddress);       
        _burn(_tokenOwner, _tokenId);       
        emit Burn(_tokenOwner, _tokenId);
    }

    function findAuctionContractIndex(address _addressToFind) public view returns (int)  {
        
        for (int i = 0; i < int(auctionContractAddresses.length); i++){
            if (auctionContractAddresses[uint256(i)] == _addressToFind){
                return i;
            }
        }
        return -1;
    }

    function addAuctionContractAddress(address _auctionContractAddress) public onlyOwner {
        require(findAuctionContractIndex(_auctionContractAddress) == -1);
        auctionContractAddresses.push(_auctionContractAddress);
    }

    function removeAuctionContractAddress(address _auctionContractAddress) public onlyOwner {
        int index = findAuctionContractIndex(_auctionContractAddress);
        require(index >= 0);        

        for (uint i = uint(index); i < auctionContractAddresses.length-1; i++){
            auctionContractAddresses[i] = auctionContractAddresses[i+1];         
        }
        auctionContractAddresses.length--;
    }

    function setStemTokenContractAddress(address _stemTokenContractAddress) public onlyOwner {        
        stemTokenContractAddress = _stemTokenContractAddress;
    }          
   

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(exists(_tokenId));   
        return string(abi.encodePacked(uriPrefix, uint256ToString(_tokenId)));

    }
     
    function amountOfZeros(uint256 num, uint256 base) public pure returns(uint256){
        uint256 result = 0;
        num /= base;
        while (num > 0){
            num /= base;
            result += 1;
        }
        return result;
    }

      function uint256ToString(uint256 num) public pure returns(string memory){
        if (num == 0){
            return "0";
        }
        uint256 numLen = amountOfZeros(num, 10) + 1;
        bytes memory result = new bytes(numLen);
        while(num != 0){
            numLen -= 1;
            result[numLen] = byte(uint8((num - (num / 10 * 10)) + 48));
            num /= 10;
        }
        return string(result);
    }

     
     
     
     
    
     
     
     
     
     
     
     
     

     

     
     

     

     

     
     

     
     

               

     
     
}


contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract StemToken is CappedToken, StandardBurnableToken {
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint256 _cap) CappedToken(_cap)  public {
        name = _name;
        symbol = _symbol;
        decimals = 0;    
    }
}
contract RetroArtStemToken is StemToken {    

    address public retroArtAddress;

    constructor(string memory _name, string memory _symbol, uint256 _cap) StemToken(_name, _symbol, _cap )  public {
        
    }

  
    function setRetroArtAddress(address _retroArtAddress) public onlyOwner {        
        retroArtAddress = _retroArtAddress;
    }

    function sellback(uint256 _tokenId) public {
     
        RetroArt retroArt = RetroArt(retroArtAddress);
        require(retroArt.ownerOf(_tokenId) == msg.sender);
        retroArt.burnExchangeToken(msg.sender, _tokenId);
        totalSupply_ = totalSupply_.add(1);
        balances[msg.sender] = balances[msg.sender].add(1);
        emit Mint(msg.sender, 1);
        emit Transfer(address(0), msg.sender, 1);
    }

     
     
     
    function acquireAssetForOther(uint256 _tokenId, string memory _title, address _tokenOwner) public {
        require(balanceOf(msg.sender) >= 1);           
        _burn(msg.sender, uint256(1));
        RetroArt retroArt = RetroArt(retroArtAddress);
        retroArt.acquireAssetFromStemToken(_tokenOwner, _tokenId, _title);
    }

    function acquireAsset(uint256 _tokenId, string memory _title) public {
        acquireAssetForOther(_tokenId, _title, msg.sender);
    }

}