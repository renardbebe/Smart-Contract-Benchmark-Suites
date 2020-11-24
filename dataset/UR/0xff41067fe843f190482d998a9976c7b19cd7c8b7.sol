 

pragma solidity ^0.4.11;

pragma solidity ^0.4.10;
pragma solidity ^0.4.18;

pragma solidity ^0.4.18;

pragma solidity ^0.4.18;

 
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
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
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

pragma solidity ^0.4.18;


pragma solidity ^0.4.18;

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba; 

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

pragma solidity ^0.4.18;


 
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

pragma solidity ^0.4.18;

 
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
      Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }


   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    ApprovalForAll(msg.sender, _to, _approved);
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

    Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
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
    Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      Approval(_owner, address(0), _tokenId);
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

   
  function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
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

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
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


contract RareCoin is ERC721Token("RareCoin", "XRC") {
    bool[100] internal _initialized;
    address _auctionContract;

    function RareCoin(address auctionContract) public {
        _auctionContract = auctionContract;
    }

   
    function CreateToken(address owner, uint i) public {
        require(msg.sender == _auctionContract);
        require(!_initialized[i - 1]);

        _initialized[i - 1] = true;

        _mint(owner, i);
    }
}



 
contract RareCoinAuction {
    using SafeMath for uint256;

     
    uint internal _auctionEnd;

     
    bool internal _ended;

     
    address internal _beneficiary;

     
    bool internal _beneficiaryWithdrawn;

     
    uint internal _lowestBid;

     
    struct Bidder {
        uint bid;
        address bidderAddress;
    }

     
    struct BidDetails {
        uint value;
        uint lastTime;
    }

     
    mapping(address => BidDetails) internal _bidders;

     
    Bidder[100] internal _topBids;

     
    address internal _rcContract;
    bool[100] internal _coinWithdrawn;

    event NewBid(address bidder, uint amount);

    event TopThreeChanged(
        address first, uint firstBid,
        address second, uint secondBid,
        address third, uint thirdBid
    );

    event AuctionEnded(
        address first, uint firstBid,
        address second, uint secondBid,
        address third, uint thirdBid
    );

   
    function RareCoinAuction(uint biddingTime) public {
        _auctionEnd = block.number + biddingTime;
        _beneficiary = msg.sender;
    }

   
    function setRCContractAddress(address rcContractAddress) public {
        require(msg.sender == _beneficiary);
        require(_rcContract == address(0));

        _rcContract = rcContractAddress;
    }

   
    function bid() external payable {
        require(block.number < _auctionEnd);

        uint proposedBid = _bidders[msg.sender].value.add(msg.value);

         
        require(proposedBid > _lowestBid);

         
         
        uint startPos = 99;
        if (_bidders[msg.sender].value >= _lowestBid) {
             
            for (uint i = 99; i < 100; --i) {
                if (_topBids[i].bidderAddress == msg.sender) {
                    startPos = i;
                    break;
                }
            }
        }

         
        uint endPos;
        for (uint j = startPos; j < 100; --j) {
            if (j != 0 && proposedBid > _topBids[j - 1].bid) {
                _topBids[j] = _topBids[j - 1];
            } else {
                _topBids[j].bid = proposedBid;
                _topBids[j].bidderAddress = msg.sender;
                endPos = j;
                break;
            }
        }

         
        _bidders[msg.sender].value = proposedBid;
        _bidders[msg.sender].lastTime = now;

         
        _lowestBid = _topBids[99].bid;

         
        if (endPos < 3) {
            TopThreeChanged(
                _topBids[0].bidderAddress, _topBids[0].bid,
                _topBids[1].bidderAddress, _topBids[1].bid,
                _topBids[2].bidderAddress, _topBids[2].bid
            );
        }

        NewBid(msg.sender, _bidders[msg.sender].value);

    }

   
    function beneficiaryWithdraw() external {
        require(msg.sender == _beneficiary);
        require(_ended);
        require(!_beneficiaryWithdrawn);

        uint total = 0;
        for (uint i = 0; i < 100; ++i) {
            total = total.add(_topBids[i].bid);
        }

        _beneficiaryWithdrawn = true;

        _beneficiary.transfer(total);
    }

   
    function withdraw() external returns (bool) {
        require(_ended);

         
         
         
        for (uint i = 0; i < 100; ++i) {
            require(_topBids[i].bidderAddress != msg.sender);
        }

        uint amount = _bidders[msg.sender].value;
        if (amount > 0) {
            _bidders[msg.sender].value = 0;
            msg.sender.transfer(amount);
        }
        return true;
    }

   
    function withdrawToken(uint tokenNumber) external returns (bool) {
        require(_ended);
        require(!_coinWithdrawn[tokenNumber - 1]);

        _coinWithdrawn[tokenNumber - 1] = true;

        RareCoin(_rcContract).CreateToken(_topBids[tokenNumber - 1].bidderAddress, tokenNumber);

        return true;
    }

   
    function endAuction() external {
        require(block.number >= _auctionEnd);
        require(!_ended);

        _ended = true;
        AuctionEnded(
            _topBids[0].bidderAddress, _topBids[0].bid,
            _topBids[1].bidderAddress, _topBids[1].bid,
            _topBids[2].bidderAddress, _topBids[2].bid
        );
    }

   
    function getBidDetails(address _addr) external view returns (uint, uint) {
        return (_bidders[_addr].value, _bidders[_addr].lastTime);
    }

   
    function getTopBidders() external view returns (address[100]) {
        address[100] memory tempArray;

        for (uint i = 0; i < 100; ++i) {
            tempArray[i] = _topBids[i].bidderAddress;
        }

        return tempArray;
    }

   
    function getAuctionEnd() external view returns (uint) {
        return _auctionEnd;
    }

   
    function getEnded() external view returns (bool) {
        return _ended;
    }

   
    function getRareCoinAddress() external view returns (address) {
        return _rcContract;
    }
}