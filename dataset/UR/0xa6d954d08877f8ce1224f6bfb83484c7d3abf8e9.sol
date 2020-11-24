 

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

pragma solidity ^0.4.18;

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}

 

contract Composable is ERC721Token, Ownable, PullPayment, Pausable {
   
     
    uint public constant MAX_LAYERS = 100;

     
    uint256 public minCompositionFee = 0.001 ether;

     
    mapping (uint256 => uint256) public tokenIdToCompositionPrice;
    
     
    mapping (uint256 => uint256[]) public tokenIdToLayers;

     
    mapping (bytes32 => bool) public compositions;

     
    mapping (uint256 => uint256) public imageHashes;

     
    event BaseTokenCreated(uint256 tokenId);
    
     
    event CompositionTokenCreated(uint256 tokenId, uint256[] layers, address indexed owner);
    
     
    event CompositionPriceChanged(uint256 tokenId, uint256 price, address indexed owner);

     
    bool public isCompositionOnlyWithBaseLayers;
    
 

     
    function mintTo(address _to, uint256 _compositionPrice, uint256 _imageHash) public onlyOwner {
        uint256 newTokenIndex = _getNextTokenId();
        _mint(_to, newTokenIndex);
        tokenIdToLayers[newTokenIndex] = [newTokenIndex];
        require(_isUnique(tokenIdToLayers[newTokenIndex], _imageHash));
        compositions[keccak256([newTokenIndex])] = true;
        imageHashes[_imageHash] = newTokenIndex;      
        BaseTokenCreated(newTokenIndex);
        _setCompositionPrice(newTokenIndex, _compositionPrice);
    }

     
    function compose(uint256[] _tokenIds,  uint256 _imageHash) public payable whenNotPaused {
        uint256 price = getTotalCompositionPrice(_tokenIds);
        require(msg.sender != address(0) && msg.value >= price);
        require(_tokenIds.length <= MAX_LAYERS);

        uint256[] memory layers = new uint256[](MAX_LAYERS);
        uint actualSize = 0; 

        for (uint i = 0; i < _tokenIds.length; i++) { 
            uint256 compositionLayerId = _tokenIds[i];
            require(_tokenLayersExist(compositionLayerId));
            uint256[] memory inheritedLayers = tokenIdToLayers[compositionLayerId];
            if (isCompositionOnlyWithBaseLayers) { 
                require(inheritedLayers.length == 1);
            }
            require(inheritedLayers.length < MAX_LAYERS);
            for (uint j = 0; j < inheritedLayers.length; j++) { 
                require(actualSize < MAX_LAYERS);
                for (uint k = 0; k < layers.length; k++) { 
                    require(layers[k] != inheritedLayers[j]);
                    if (layers[k] == 0) { 
                        break;
                    }
                }
                layers[actualSize] = inheritedLayers[j];
                actualSize += 1;
            }
            require(ownerOf(compositionLayerId) != address(0));
            asyncSend(ownerOf(compositionLayerId), tokenIdToCompositionPrice[compositionLayerId]);
        }
    
        uint256 newTokenIndex = _getNextTokenId();
        
        tokenIdToLayers[newTokenIndex] = _trim(layers, actualSize);
        require(_isUnique(tokenIdToLayers[newTokenIndex], _imageHash));
        compositions[keccak256(tokenIdToLayers[newTokenIndex])] = true;
        imageHashes[_imageHash] = newTokenIndex;
    
        _mint(msg.sender, newTokenIndex);

        if (msg.value > price) {
            uint256 purchaseExcess = SafeMath.sub(msg.value, price);
            msg.sender.transfer(purchaseExcess);          
        }

        if (!isCompositionOnlyWithBaseLayers) { 
            _setCompositionPrice(newTokenIndex, minCompositionFee);
        }
   
        CompositionTokenCreated(newTokenIndex, tokenIdToLayers[newTokenIndex], msg.sender);
    }

     
    function getTokenLayers(uint256 _tokenId) public view returns(uint256[]) {
        return tokenIdToLayers[_tokenId];
    }

     
    function isValidComposition(uint256[] _tokenIds, uint256 _imageHash) public view returns (bool) { 
        if (isCompositionOnlyWithBaseLayers) { 
            return _isValidBaseLayersOnly(_tokenIds, _imageHash);
        } else { 
            return _isValidWithCompositions(_tokenIds, _imageHash);
        }
    }

     
    function getCompositionPrice(uint256 _tokenId) public view returns(uint256) { 
        return tokenIdToCompositionPrice[_tokenId];
    }

     
    function getTotalCompositionPrice(uint256[] _tokenIds) public view returns(uint256) {
        uint256 totalCompositionPrice = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(_tokenLayersExist(_tokenIds[i]));
            totalCompositionPrice = SafeMath.add(totalCompositionPrice, tokenIdToCompositionPrice[_tokenIds[i]]);
        }

        totalCompositionPrice = SafeMath.div(SafeMath.mul(totalCompositionPrice, 105), 100);

        return totalCompositionPrice;
    }

     
    function setCompositionPrice(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        _setCompositionPrice(_tokenId, _price);
    }

 

     
    function _isValidBaseLayersOnly(uint256[] _tokenIds, uint256 _imageHash) private view returns (bool) { 
        require(_tokenIds.length <= MAX_LAYERS);
        uint256[] memory layers = new uint256[](_tokenIds.length);

        for (uint i = 0; i < _tokenIds.length; i++) { 
            if (!_tokenLayersExist(_tokenIds[i])) {
                return false;
            }

            if (tokenIdToLayers[_tokenIds[i]].length != 1) {
                return false;
            }

            for (uint k = 0; k < layers.length; k++) { 
                if (layers[k] == tokenIdToLayers[_tokenIds[i]][0]) {
                    return false;
                }
                if (layers[k] == 0) { 
                    layers[k] = tokenIdToLayers[_tokenIds[i]][0];
                    break;
                }
            }
        }
    
        return _isUnique(layers, _imageHash);
    }

     
    function _isValidWithCompositions(uint256[] _tokenIds, uint256 _imageHash) private view returns (bool) { 
        uint256[] memory layers = new uint256[](MAX_LAYERS);
        uint actualSize = 0; 
        if (_tokenIds.length > MAX_LAYERS) { 
            return false;
        }

        for (uint i = 0; i < _tokenIds.length; i++) { 
            uint256 compositionLayerId = _tokenIds[i];
            if (!_tokenLayersExist(compositionLayerId)) { 
                return false;
            }
            uint256[] memory inheritedLayers = tokenIdToLayers[compositionLayerId];
            require(inheritedLayers.length < MAX_LAYERS);
            for (uint j = 0; j < inheritedLayers.length; j++) { 
                require(actualSize < MAX_LAYERS);
                for (uint k = 0; k < layers.length; k++) { 
                    if (layers[k] == inheritedLayers[j]) {
                        return false;
                    }
                    if (layers[k] == 0) { 
                        break;
                    }
                }
                layers[actualSize] = inheritedLayers[j];
                actualSize += 1;
            }
        }
        return _isUnique(_trim(layers, actualSize), _imageHash);
    }

     
    function _trim(uint256[] _layers, uint _size) private pure returns(uint256[]) { 
        uint256[] memory trimmedLayers = new uint256[](_size);
        for (uint i = 0; i < _size; i++) { 
            trimmedLayers[i] = _layers[i];
        }

        return trimmedLayers;
    }

     
    function _tokenLayersExist(uint256 _tokenId) private view returns (bool) { 
        return tokenIdToLayers[_tokenId].length != 0;
    }

     
    function _setCompositionPrice(uint256 _tokenId, uint256 _price) private {
        require(_price >= minCompositionFee);
        tokenIdToCompositionPrice[_tokenId] = _price;
        CompositionPriceChanged(_tokenId, _price, msg.sender);
    }

     
    function _getNextTokenId() private view returns (uint256) {
        return totalSupply().add(1); 
    }

     
    function _isUnique(uint256[] _layers, uint256 _imageHash) private view returns (bool) { 
        return compositions[keccak256(_layers)] == false && imageHashes[_imageHash] == 0;
    }

 

     
    function payout (address _to) public onlyOwner { 
        totalPayments = 0;
        _to.transfer(this.balance);
    }

     
    function setGlobalCompositionFee(uint256 _price) public onlyOwner { 
        minCompositionFee = _price;
    }
}

contract Ethmoji is Composable {
    using SafeMath for uint256;

    string public constant NAME = "Ethmoji";
    string public constant SYMBOL = "EMJ";

     
    mapping (address => uint256) public addressToAvatar;

    function Ethmoji() public { 
        isCompositionOnlyWithBaseLayers = true;
    }

     
    function mintTo(address _to, uint256 _compositionPrice, uint256 _imageHash) public onlyOwner {
        Composable.mintTo(_to, _compositionPrice, _imageHash);
        _setAvatarIfNoAvatarIsSet(_to, tokensOf(_to)[0]);
    }

     
    function compose(uint256[] _tokenIds,  uint256 _imageHash) public payable whenNotPaused {
        Composable.compose(_tokenIds, _imageHash);
        _setAvatarIfNoAvatarIsSet(msg.sender, tokensOf(msg.sender)[0]);


         
        for (uint8 i = 0; i < _tokenIds.length; i++) {
            _withdrawTo(ownerOf(_tokenIds[i]));
        }
    }

 

     
    function name() public pure returns (string) {
        return NAME;
    }

     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

     
    function setAvatar(uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        addressToAvatar[msg.sender] = _tokenId;
    }

     
    function getAvatar(address _owner) public view returns(uint256) {
        return addressToAvatar[_owner];
    }

     
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
         
        if (addressToAvatar[msg.sender] == _tokenId) {
            _removeAvatar(msg.sender);
        }

        ERC721Token.transfer(_to, _tokenId);
    }

 

     
    function _setAvatarIfNoAvatarIsSet(address _owner, uint256 _tokenId) private {
        if (addressToAvatar[_owner] == 0) {
            addressToAvatar[_owner] = _tokenId;
        }
    }

     
    function _removeAvatar(address _owner) private {
        addressToAvatar[_owner] = 0;
    }

     
    function _withdrawTo(address _payee) private {
        uint256 payment = payments[_payee];

        if (payment != 0 && this.balance >= payment) {
            totalPayments = totalPayments.sub(payment);
            payments[_payee] = 0;

            _payee.transfer(payment);
        }
    }
}