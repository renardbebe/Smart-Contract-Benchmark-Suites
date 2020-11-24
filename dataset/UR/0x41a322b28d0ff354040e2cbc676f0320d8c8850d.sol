 

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

 
 
 
interface ERC721Metadata   {
   
  function name() external pure returns (string _name);

   
  function symbol() external pure returns (string _symbol);

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string);
}


contract SupeRare is ERC721Token, Ownable, ERC721Metadata {
    using SafeMath for uint256;
    
     
    uint256 public maintainerPercentage = 30; 
    
     
    uint256 public creatorPercentage = 100; 
    
     
    mapping(uint256 => address) private tokenBidder;

     
    mapping(uint256 => uint256) private tokenCurrentBid;
    
     
    mapping(uint256 => uint256) private tokenSalePrice;

     
    mapping(uint256 => address) private tokenCreator;
  
     
    mapping(uint256 => string) private tokenToURI;
    
     
    mapping(string => uint256) private uriOriginalToken;
    
     
    mapping(uint256 => bool) private tokenSold;

     
    mapping(address => bool) private creatorWhitelist;


    event WhitelistCreator(address indexed _creator);
    event Bid(address indexed _bidder, uint256 indexed _amount, uint256 indexed _tokenId);
    event AcceptBid(address indexed _bidder, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
    event CancelBid(address indexed _bidder, uint256 indexed _amount, uint256 indexed _tokenId);
    event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 indexed _tokenId);
    event SalePriceSet(uint256 indexed _tokenId, uint256 indexed _price);

     
    modifier uniqueURI(string _uri) {
        require(uriOriginalToken[_uri] == 0);
        _;
    }

     
    modifier notOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) != msg.sender);
        _;
    }

     
    modifier onlyCreator() {
        require(creatorWhitelist[msg.sender] == true);
        _;
    }

     
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        tokenSold[_tokenId] = true;
        tokenSalePrice[_tokenId] = 0;
        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }

     
    function addNewToken(string _uri) public uniqueURI(_uri) onlyCreator {
        uint256 newId = createToken(_uri, msg.sender);
        uriOriginalToken[_uri] = newId;
    }

     
    function addNewTokenWithEditions(string _uri, uint256 _editions, uint256 _salePrice) public uniqueURI(_uri) onlyCreator {
      uint256 originalId = createToken(_uri, msg.sender);
      uriOriginalToken[_uri] = originalId;

      for (uint256 i=0; i<_editions; i++){
        uint256 newId = createToken(_uri, msg.sender);
        tokenSalePrice[newId] = _salePrice;
        SalePriceSet(newId, _salePrice);
      }
    }

     
    function bid(uint256 _tokenId) public payable notOwnerOf(_tokenId) {
        require(isGreaterBid(_tokenId));
        returnCurrentBid(_tokenId);
        tokenBidder[_tokenId] = msg.sender;
        tokenCurrentBid[_tokenId] = msg.value;
        Bid(msg.sender, msg.value, _tokenId);
    }

     
    function acceptBid(uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        uint256 currentBid = tokenCurrentBid[_tokenId];
        address currentBidder = tokenBidder[_tokenId];
        address tokenOwner = ownerOf(_tokenId);
        address creator = tokenCreator[_tokenId];
        clearApprovalAndTransfer(msg.sender, currentBidder, _tokenId);
        payout(currentBid, owner, creator, tokenOwner, _tokenId);
        clearBid(_tokenId);
        AcceptBid(currentBidder, tokenOwner, currentBid, _tokenId);
        tokenSalePrice[_tokenId] = 0;
    }
    
     
    function cancelBid(uint256 _tokenId) public {
        address bidder = tokenBidder[_tokenId];
        require(msg.sender == bidder);
        uint256 bidAmount = tokenCurrentBid[_tokenId];
        msg.sender.transfer(bidAmount);
        clearBid(_tokenId);
        CancelBid(bidder, bidAmount, _tokenId);
    }
    
     
    function buy(uint256 _tokenId) public payable notOwnerOf(_tokenId) {
        uint256 salePrice = tokenSalePrice[_tokenId];
        uint256 sentPrice = msg.value;
        address buyer = msg.sender;
        address tokenOwner = ownerOf(_tokenId);
        address creator = tokenCreator[_tokenId];
        require(salePrice > 0);
        require(sentPrice >= salePrice);
        returnCurrentBid(_tokenId);
        clearBid(_tokenId);
        clearApprovalAndTransfer(tokenOwner, buyer, _tokenId);
        payout(sentPrice, owner, creator, tokenOwner, _tokenId);
        tokenSalePrice[_tokenId] = 0;
        Sold(buyer, tokenOwner, sentPrice, _tokenId);
    }

     
    function setSalePrice(uint256 _tokenId, uint256 _salePrice) public onlyOwnerOf(_tokenId) {
        uint256 currentBid = tokenCurrentBid[_tokenId];
        require(_salePrice > currentBid);
        tokenSalePrice[_tokenId] = _salePrice;
        SalePriceSet(_tokenId, _salePrice);
    }

     
    function whitelistCreator(address _creator) public onlyOwner {
      creatorWhitelist[_creator] = true;
      WhitelistCreator(_creator);
    }
    
     
    function setMaintainerPercentage(uint256 _percentage) public onlyOwner() {
       maintainerPercentage = _percentage;
    }
    
     
    function setCreatorPercentage(uint256 _percentage) public onlyOwner() {
       creatorPercentage = _percentage;
    }
    
     
    function name() external pure returns (string _name) {
        return 'SupeRare';
    }

     
    function symbol() external pure returns (string _symbol) {
        return 'SUPR';
    }

     
    function approve(address _to, uint256 _tokenId) public {
        revert();
    }

     
    function isWhitelisted(address _creator) external view returns (bool) {
      return creatorWhitelist[_creator];
    }

     
    function tokenURI(uint256 _tokenId) external view returns (string) {
        ownerOf(_tokenId);
        return tokenToURI[_tokenId];
    }

     
    function originalTokenOfUri(string _uri) public view returns (uint256) {
        uint256 tokenId = uriOriginalToken[_uri];
        ownerOf(tokenId);
        return tokenId;
    }

     
    function currentBidDetailsOfToken(uint256 _tokenId) public view returns (uint256, address) {
        return (tokenCurrentBid[_tokenId], tokenBidder[_tokenId]);
    }

     
    function creatorOfToken(uint256 _tokenId) public view returns (address) {
        return tokenCreator[_tokenId];
    }
    
     
    function salePriceOfToken(uint256 _tokenId) public view returns (uint256) {
        return tokenSalePrice[_tokenId];
    }
    
     
    function returnCurrentBid(uint256 _tokenId) private {
        uint256 currentBid = tokenCurrentBid[_tokenId];
        address currentBidder = tokenBidder[_tokenId];
        if(currentBidder != address(0)) {
            currentBidder.transfer(currentBid);
        }
    }
    
     
    function isGreaterBid(uint256 _tokenId) private view returns (bool) {
        return msg.value > tokenCurrentBid[_tokenId];
    }
    
     
    function clearBid(uint256 _tokenId) private {
        tokenBidder[_tokenId] = address(0);
        tokenCurrentBid[_tokenId] = 0;
    }
    
     
    function payout(uint256 _val, address _maintainer, address _creator, address _tokenOwner, uint256 _tokenId) private {
        uint256 maintainerPayment;
        uint256 creatorPayment;
        uint256 ownerPayment;
        if (tokenSold[_tokenId]) {
            maintainerPayment = _val.mul(maintainerPercentage).div(1000);
            creatorPayment = _val.mul(creatorPercentage).div(1000);
            ownerPayment = _val.sub(creatorPayment).sub(maintainerPayment); 
        } else {
            maintainerPayment = 0;
            creatorPayment = _val;
            ownerPayment = 0;
            tokenSold[_tokenId] = true;
        }
        _maintainer.transfer(maintainerPayment);
        _creator.transfer(creatorPayment);
        _tokenOwner.transfer(ownerPayment);
      
    }

     
    function createToken(string _uri, address _creator) private  returns (uint256){
      uint256 newId = totalSupply() + 1;
      _mint(_creator, newId);
      tokenCreator[newId] = _creator;
      tokenToURI[newId] = _uri;
      return newId;
    }

}