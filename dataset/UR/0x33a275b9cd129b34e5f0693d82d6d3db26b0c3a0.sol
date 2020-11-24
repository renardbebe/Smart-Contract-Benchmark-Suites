 

pragma solidity ^0.4.18;


contract InterfaceContentCreatorUniverse {
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function priceOf(uint256 _tokenId) public view returns (uint256 price);
  function getNextPrice(uint price, uint _tokenId) public pure returns (uint);
  function lastSubTokenBuyerOf(uint tokenId) public view returns(address);
  function lastSubTokenCreatorOf(uint tokenId) public view returns(address);

   
  function createCollectible(uint256 tokenId, uint256 _price, address creator, address owner) external ;
}

contract InterfaceYCC {
  function payForUpgrade(address user, uint price) external  returns (bool success);
  function mintCoinsForOldCollectibles(address to, uint256 amount, address universeOwner) external  returns (bool success);
  function tradePreToken(uint price, address buyer, address seller, uint burnPercent, address universeOwner) external;
  function payoutForMining(address user, uint amount) external;
  uint256 public totalSupply;
}

contract InterfaceMining {
  function createMineForToken(uint tokenId, uint level, uint xp, uint nextLevelBreak, uint blocknumber) external;
  function payoutMining(uint tokenId, address owner, address newOwner) external;
  function levelUpMining(uint tokenId) external;
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

contract Owned {
   
  address public ceoAddress;
  address public cooAddress;
  address private newCeoAddress;
  address private newCooAddress;


  function Owned() public {
      ceoAddress = msg.sender;
      cooAddress = msg.sender;
  }

   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    newCeoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    newCooAddress = _newCOO;
  }

  function acceptCeoOwnership() public {
      require(msg.sender == newCeoAddress);
      require(address(0) != newCeoAddress);
      ceoAddress = newCeoAddress;
      newCeoAddress = address(0);
  }

  function acceptCooOwnership() public {
      require(msg.sender == newCooAddress);
      require(address(0) != newCooAddress);
      cooAddress = newCooAddress;
      newCooAddress = address(0);
  }

  mapping (address => bool) public youCollectContracts;
  function addYouCollectContract(address contractAddress, bool active) public onlyCOO {
    youCollectContracts[contractAddress] = active;
  }
  modifier onlyYCC() {
    require(youCollectContracts[msg.sender]);
    _;
  }

  InterfaceYCC ycc;
  InterfaceContentCreatorUniverse yct;
  InterfaceMining ycm;
  function setMainYouCollectContractAddresses(address yccContract, address yctContract, address ycmContract, address[] otherContracts) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    yct = InterfaceContentCreatorUniverse(yctContract);
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[yccContract] = true;
    youCollectContracts[yctContract] = true;
    youCollectContracts[ycmContract] = true;
    for (uint16 index = 0; index < otherContracts.length; index++) {
      youCollectContracts[otherContracts[index]] = true;
    }
  }
  function setYccContractAddress(address yccContract) public onlyCOO {
    ycc = InterfaceYCC(yccContract);
    youCollectContracts[yccContract] = true;
  }
  function setYctContractAddress(address yctContract) public onlyCOO {
    yct = InterfaceContentCreatorUniverse(yctContract);
    youCollectContracts[yctContract] = true;
  }
  function setYcmContractAddress(address ycmContract) public onlyCOO {
    ycm = InterfaceMining(ycmContract);
    youCollectContracts[ycmContract] = true;
  }

}

contract TransferInterfaceERC721YC {
  function transferToken(address to, uint256 tokenId) public returns (bool success);
}
contract TransferInterfaceERC20 {
  function transfer(address to, uint tokens) public returns (bool success);
}

 
 
 
 
contract YouCollectBase is Owned {
  using SafeMath for uint256;

  event RedButton(uint value, uint totalSupply);

   
  function payout(address _to) public onlyCLevel {
    _payout(_to, this.balance);
  }
  function payout(address _to, uint amount) public onlyCLevel {
    if (amount>this.balance)
      amount = this.balance;
    _payout(_to, amount);
  }
  function _payout(address _to, uint amount) private {
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }

   
   
   
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyCEO returns (bool success) {
      return TransferInterfaceERC20(tokenAddress).transfer(ceoAddress, tokens);
  }
}

 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC721YC is YouCollectBase {
   
   

     
    string public constant NAME = "YouCollectTokens";
    string public constant SYMBOL = "YCT";
    uint256[] public tokens;

     
     
    mapping (uint256 => address) public tokenIndexToOwner;

     
     
     
    mapping (uint256 => address) public tokenIndexToApproved;

     
    mapping (uint256 => uint256) public tokenIndexToPrice;

     
     
    event Birth(uint256 tokenId, uint256 startPrice);
     
    event TokenSold(uint256 indexed tokenId, uint256 price, address prevOwner, address winner);
     
    event Transfer(address indexed from, address indexed to, uint256 tokenId);
     
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

     
     
     
     
     
     
    function approveToken(
      address _to,
      uint256 _tokenId
    ) public returns (bool) {
       
      require(_ownsToken(msg.sender, _tokenId));

      tokenIndexToApproved[_tokenId] = _to;

      Approval(msg.sender, _to, _tokenId);
      return true;
    }


    function getTotalSupply() public view returns (uint) {
      return tokens.length;
    }

    function implementsERC721() public pure returns (bool) {
      return true;
    }


     
     
     
    function ownerOf(uint256 _tokenId)
      public
      view
      returns (address owner)
    {
      owner = tokenIndexToOwner[_tokenId];
    }


    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
      price = tokenIndexToPrice[_tokenId];
    }


     
     
     
    function takeOwnership(uint256 _tokenId) public {
      address newOwner = msg.sender;
      address oldOwner = tokenIndexToOwner[_tokenId];

       
      require(newOwner != address(0));

       
      require(_approved(newOwner, _tokenId));

      _transfer(oldOwner, newOwner, _tokenId);
    }

     
     
     
     
    function transfer(
      address _to,
      uint256 _tokenId
    ) public returns (bool) {
      require(_ownsToken(msg.sender, _tokenId));
      _transfer(msg.sender, _to, _tokenId);
      return true;
    }

     
     
     
     
     
    function transferFrom(
      address _from,
      address _to,
      uint256 _tokenId
    ) public returns (bool) {
      require(_ownsToken(_from, _tokenId));
      require(_approved(_to, _tokenId));

      _transfer(_from, _to, _tokenId);
      return true;
    }


     
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
      return tokenIndexToApproved[_tokenId] == _to;
    }

     
    function _ownsToken(address claimant, uint256 _tokenId) internal view returns (bool) {
      return claimant == tokenIndexToOwner[_tokenId];
    }
     
    function changeTokenPrice(uint256 newPrice, uint256 _tokenId) external onlyYCC {
      tokenIndexToPrice[_tokenId] = newPrice;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 result) {
        uint256 totalTokens = tokens.length;
        uint256 tokenIndex;
        uint256 tokenId;
        result = 0;
        for (tokenIndex = 0; tokenIndex < totalTokens; tokenIndex++) {
          tokenId = tokens[tokenIndex];
          if (tokenIndexToOwner[tokenId] == _owner) {
            result++;
          }
        }
        return result;
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
       
      tokenIndexToOwner[_tokenId] = _to;

       
      if (_from != address(0)) {
         
        delete tokenIndexToApproved[_tokenId];
      }

       
      Transfer(_from, _to, _tokenId);
    }


     
     
     
     
     
    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
           
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 totalTokens = getTotalSupply();
        uint256 resultIndex = 0;

        uint256 tokenIndex;
        uint256 tokenId;
        for (tokenIndex = 0; tokenIndex < totalTokens; tokenIndex++) {
          tokenId = tokens[tokenIndex];
          if (tokenIndexToOwner[tokenId] == _owner) {
            result[resultIndex] = tokenId;
            resultIndex = resultIndex.add(1);
          }
        }
        return result;
      }
    }


       
       

       
       
       
       
       
       


     
    function getTokenIds() public view returns(uint256[]) {
      return tokens;
    }

   
   
   
}

contract Universe is ERC721YC {

  mapping (uint => address) private subTokenCreator;
  mapping (uint => address) private lastSubTokenBuyer;

  uint16 constant MAX_WORLD_INDEX = 1000;
  uint24 constant MAX_CONTINENT_INDEX = 10000000;
  uint64 constant MAX_SUBCONTINENT_INDEX = 10000000000000;
  uint64 constant MAX_COUNTRY_INDEX = 10000000000000000000;
  uint128 constant FIFTY_TOKENS_INDEX = 100000000000000000000000000000000;
  uint256 constant TRIBLE_TOKENS_INDEX = 1000000000000000000000000000000000000000000000;
  uint256 constant DOUBLE_TOKENS_INDEX = 10000000000000000000000000000000000000000000000000000000000;
  uint8 constant UNIVERSE_TOKEN_ID = 0;
  uint public minSelfBuyPrice = 10 ether;
  uint public minPriceForMiningUpgrade = 5 ether;

   
  function Universe() public {
  }

  function changePriceLimits(uint _minSelfBuyPrice, uint _minPriceForMiningUpgrade) public onlyCOO {
    minSelfBuyPrice = _minSelfBuyPrice;
    minPriceForMiningUpgrade = _minPriceForMiningUpgrade;
  }

  function getNextPrice(uint price, uint _tokenId) public pure returns (uint) {
    if (_tokenId>DOUBLE_TOKENS_INDEX)
      return price.mul(2);
    if (_tokenId>TRIBLE_TOKENS_INDEX)
      return price.mul(3);
    if (_tokenId>FIFTY_TOKENS_INDEX)
      return price.mul(3).div(2);
    if (price < 1.2 ether)
      return price.mul(200).div(91);
    if (price < 5 ether)
      return price.mul(150).div(91);
    return price.mul(120).div(91);
  }


  function buyToken(uint _tokenId) public payable {
    address oldOwner = tokenIndexToOwner[_tokenId];
    uint256 sellingPrice = tokenIndexToPrice[_tokenId];
    require(oldOwner!=msg.sender || sellingPrice > minSelfBuyPrice);
    require(msg.value >= sellingPrice);
    require(sellingPrice > 0);

    uint256 purchaseExcess = msg.value.sub(sellingPrice);
    uint256 payment = sellingPrice.mul(91).div(100);
    uint256 feeOnce = sellingPrice.sub(payment).div(9);

     
    tokenIndexToPrice[_tokenId] = getNextPrice(sellingPrice, _tokenId);
     
    tokenIndexToOwner[_tokenId] = msg.sender;
     
    delete tokenIndexToApproved[_tokenId];
     
    if (_tokenId>MAX_SUBCONTINENT_INDEX) {
      ycm.payoutMining(_tokenId, oldOwner, msg.sender);
      if (sellingPrice > minPriceForMiningUpgrade)
        ycm.levelUpMining(_tokenId);
    }

    if (_tokenId > 0) {
       
      if (tokenIndexToOwner[UNIVERSE_TOKEN_ID]!=address(0))
        tokenIndexToOwner[UNIVERSE_TOKEN_ID].transfer(feeOnce);
      if (_tokenId > MAX_WORLD_INDEX) {
         
        if (tokenIndexToOwner[_tokenId % MAX_WORLD_INDEX]!=address(0))
          tokenIndexToOwner[_tokenId % MAX_WORLD_INDEX].transfer(feeOnce);
        if (_tokenId > MAX_CONTINENT_INDEX) {
           
          if (tokenIndexToOwner[_tokenId % MAX_CONTINENT_INDEX]!=address(0))
            tokenIndexToOwner[_tokenId % MAX_CONTINENT_INDEX].transfer(feeOnce);
          if (_tokenId > MAX_SUBCONTINENT_INDEX) {
             
            if (tokenIndexToOwner[_tokenId % MAX_SUBCONTINENT_INDEX]!=address(0))
              tokenIndexToOwner[_tokenId % MAX_SUBCONTINENT_INDEX].transfer(feeOnce);
            if (_tokenId > MAX_COUNTRY_INDEX) {
               
              if (tokenIndexToOwner[_tokenId % MAX_COUNTRY_INDEX]!=address(0))
                tokenIndexToOwner[_tokenId % MAX_COUNTRY_INDEX].transfer(feeOnce);
              lastSubTokenBuyer[UNIVERSE_TOKEN_ID] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_WORLD_INDEX] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_CONTINENT_INDEX] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_SUBCONTINENT_INDEX] = msg.sender;
              lastSubTokenBuyer[_tokenId % MAX_COUNTRY_INDEX] = msg.sender;
            } else {
              if (lastSubTokenBuyer[_tokenId] != address(0))
                lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
            }
          } else {
            if (lastSubTokenBuyer[_tokenId] != address(0))
              lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
          }
        } else {
          if (lastSubTokenBuyer[_tokenId] != address(0))
            lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
        }
      } else {
        if (lastSubTokenBuyer[_tokenId] != address(0))
          lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
      }
    } else {
      if (lastSubTokenBuyer[_tokenId] != address(0))
        lastSubTokenBuyer[_tokenId].transfer(feeOnce*2);
    }
     
    if (subTokenCreator[_tokenId]!=address(0))
      subTokenCreator[_tokenId].transfer(feeOnce);
     
    if (oldOwner != address(0)) {
      oldOwner.transfer(payment);
    }

    TokenSold(_tokenId, sellingPrice, oldOwner, msg.sender);
    Transfer(oldOwner, msg.sender, _tokenId);
     
    if (purchaseExcess>0)
      msg.sender.transfer(purchaseExcess);
  }
  
   
  function createCollectible(uint256 tokenId, uint256 _price, address creator, address owner) external onlyYCC {
    tokenIndexToPrice[tokenId] = _price;
    tokenIndexToOwner[tokenId] = owner;
    subTokenCreator[tokenId] = creator;
    Birth(tokenId, _price);
    tokens.push(tokenId);
  }

  function lastSubTokenBuyerOf(uint tokenId) public view returns(address) {
    return lastSubTokenBuyer[tokenId];
  }
  function lastSubTokenCreatorOf(uint tokenId) public view returns(address) {
    return subTokenCreator[tokenId];
  }

}