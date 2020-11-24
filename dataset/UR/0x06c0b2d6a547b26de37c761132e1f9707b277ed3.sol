 

pragma solidity 0.4.21;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

}

 

 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
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
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}

 

 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
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

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
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
    canTransfer(_tokenId)
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
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
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
      emit Approval(_owner, address(0), _tokenId);
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

 
contract ERC721Token is ERC721, ERC721BasicToken {
   
  string internal name_;

   
  string internal symbol_;

   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
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
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

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

 

contract IWasFirstServiceToken is StandardToken, Ownable {

    string public constant NAME = "IWasFirstServiceToken";  
    string public constant SYMBOL = "IWF";  
    uint8 public constant DECIMALS = 18;  

    uint256 public constant INITIAL_SUPPLY = 10000000 * (10 ** uint256(DECIMALS));
    address fungibleTokenAddress;
    address shareTokenAddress;

     
    function IWasFirstServiceToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
       emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function getFungibleTokenAddress() public view returns (address) {
        return fungibleTokenAddress;
    }

    function setFungibleTokenAddress(address _address) onlyOwner() public {
        require(fungibleTokenAddress == address(0));
        fungibleTokenAddress = _address;
    }

    function getShareTokenAddress() public view returns (address) {
        return shareTokenAddress;
    }

    function setShareTokenAddress(address _address) onlyOwner() public {
        require(shareTokenAddress == address(0));
        shareTokenAddress = _address;
    }

    function transferByRelatedToken(address _from, address _to, uint256 _value) public returns (bool) {
        require(msg.sender == fungibleTokenAddress || msg.sender == shareTokenAddress);
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}

 

contract IWasFirstFungibleToken is ERC721Token("IWasFirstFungible", "IWX"), Ownable {

    struct TokenMetaData {
        uint creationTime;
        string creatorMetadataJson;
    }
    address _serviceTokenAddress;
    address _shareTokenAddress;
    mapping (uint256 => string) internal tokenHash;
    mapping (string => uint256) internal tokenIdOfHash;
    uint256 internal tokenIdSeq = 1;
    mapping (uint256 => TokenMetaData[]) internal tokenMetaData;
    
    function hashExists(string hash) public view returns (bool) {
        return tokenIdOfHash[hash] != 0;
    }

    function mint(string hash, string creatorMetadataJson) external {
        require(!hashExists(hash));
        uint256 currentTokenId = tokenIdSeq;
        tokenIdSeq = tokenIdSeq + 1;
        IWasFirstServiceToken serviceToken = IWasFirstServiceToken(_serviceTokenAddress);
        serviceToken.transferByRelatedToken(msg.sender, _shareTokenAddress, 10 ** uint256(serviceToken.DECIMALS()));
        tokenHash[currentTokenId] = hash;
        tokenIdOfHash[hash] = currentTokenId;
        tokenMetaData[currentTokenId].push(TokenMetaData(now, creatorMetadataJson));
        super._mint(msg.sender, currentTokenId);
    }

    function getTokenCreationTime(string hash) public view returns(uint) {
        require(hashExists(hash));
        uint length = tokenMetaData[tokenIdOfHash[hash]].length;
        return tokenMetaData[tokenIdOfHash[hash]][length-1].creationTime;
    }

    function getCreatorMetadata(string hash) public view returns(string) {
        require(hashExists(hash));
        uint length = tokenMetaData[tokenIdOfHash[hash]].length;
        return tokenMetaData[tokenIdOfHash[hash]][length-1].creatorMetadataJson;
    }

    function getMetadataHistoryLength(string hash) public view returns(uint) {
        if(hashExists(hash)) {
            return tokenMetaData[tokenIdOfHash[hash]].length;
        } else {
            return 0;
        }
    }

    function getCreationDateOfHistoricalMetadata(string hash, uint index) public view returns(uint) {
        require(hashExists(hash));
        return tokenMetaData[tokenIdOfHash[hash]][index].creationTime;
    }

    function getCreatorMetadataOfHistoricalMetadata(string hash, uint index) public view returns(string) {
        require(hashExists(hash));
        return tokenMetaData[tokenIdOfHash[hash]][index].creatorMetadataJson;
    }

    function updateMetadata(string hash, string creatorMetadataJson) public {
        require(hashExists(hash));
        require(ownerOf(tokenIdOfHash[hash]) == msg.sender);
        tokenMetaData[tokenIdOfHash[hash]].push(TokenMetaData(now, creatorMetadataJson));
    }

    function getTokenIdByHash(string hash) public view returns(uint256) {
        require(hashExists(hash));
        return tokenIdOfHash[hash];
    }

    function getHashByTokenId(uint256 tokenId) public view returns(string) {
        require(exists(tokenId));
        return tokenHash[tokenId];
    }

    function getNumberOfTokens() public view returns(uint) {
        return allTokens.length;
    }

    function setServiceTokenAddress(address serviceTokenAdress) onlyOwner() public {
        require(_serviceTokenAddress == address(0));
        _serviceTokenAddress = serviceTokenAdress;
    }

    function getServiceTokenAddress() public view returns(address) {
        return _serviceTokenAddress;
    }

    function setShareTokenAddress(address shareTokenAdress) onlyOwner() public {
        require(_shareTokenAddress == address(0));
        _shareTokenAddress = shareTokenAdress;
    }

    function getShareTokenAddress() public view returns(address) {
        return _shareTokenAddress;
    }
}

 

contract IWasFirstShareToken is StandardToken, Ownable{

    struct TxState {
        uint256 numOfServiceTokenWei;
        uint256 userBalance;
    }

    string public constant NAME = "IWasFirstShareToken";  
    string public constant SYMBOL = "XWF";  
    uint8 public constant DECIMALS = 12;  

    uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(DECIMALS));
    address fungibleTokenAddress;
    address _serviceTokenAddress;
    mapping (address => TxState[]) internal txStates;
    event Withdraw(address to, uint256 value);

	function IWasFirstShareToken() public {
		totalSupply_ = INITIAL_SUPPLY;
		balances[msg.sender] = INITIAL_SUPPLY;
        txStates[msg.sender].push(TxState(0, INITIAL_SUPPLY));
		emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
	}
    function getFungibleTokenAddress() public view returns (address) {
        return fungibleTokenAddress;
    }

    function setFungibleTokenAddress(address _address) onlyOwner() public {
        require(fungibleTokenAddress == address(0));
        fungibleTokenAddress = _address;
    }

    function setServiceTokenAddress(address serviceTokenAdress) onlyOwner() public {
        require(_serviceTokenAddress == address(0));
        _serviceTokenAddress = serviceTokenAdress;
    }

    function getServiceTokenAddress() public view returns(address) {
        return _serviceTokenAddress;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        super.transfer(_to, _value);
        uint serviceTokenWei = this.getCurrentNumberOfUsedServiceTokenWei();
        txStates[msg.sender].push(TxState(serviceTokenWei, balances[msg.sender]));
        txStates[_to].push(TxState(serviceTokenWei, balances[_to]));
        return true;
    }

    function getWithdrawAmount(address _address) public view returns(uint256) {
        TxState[] storage states = txStates[_address];
        uint256 withdrawAmount = 0;
        if(states.length == 0) {
            return 0;
        }
        for(uint i=0; i < states.length-1; i++) {
           withdrawAmount += (states[i+1].numOfServiceTokenWei - states[i].numOfServiceTokenWei)*states[i].userBalance/INITIAL_SUPPLY;
        }
        withdrawAmount += (this.getCurrentNumberOfUsedServiceTokenWei() - states[states.length-1].numOfServiceTokenWei)*states[states.length-1].userBalance/INITIAL_SUPPLY;
        return withdrawAmount;
    }

    function withdraw() external {
        uint256 _value = getWithdrawAmount(msg.sender);
        IWasFirstServiceToken serviceToken = IWasFirstServiceToken(_serviceTokenAddress);
        require(_value <= serviceToken.balanceOf(address(this)));
        
        delete txStates[msg.sender];
        serviceToken.transferByRelatedToken(address(this), msg.sender, _value);

        emit Withdraw(msg.sender, _value);
    }

    function getCurrentNumberOfUsedServiceTokenWei() external view returns(uint) {
        IWasFirstFungibleToken fToken = IWasFirstFungibleToken(fungibleTokenAddress);
        return fToken.getNumberOfTokens()*(10**18);
    }
}