 

pragma solidity ^0.4.21;

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
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

 

contract Serialize {
    using SafeMath for uint256;
    function addAddress(uint _offst, bytes memory _output, address _input) internal pure returns(uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(20);
    }

    function addUint(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(32);
    }

    function addUint8(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(1);
    }

    function addUint16(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(2);
    }

    function addUint64(uint _offst, bytes memory _output, uint _input) internal pure returns (uint _offset) {
      assembly {
        mstore(add(_output, _offst), _input)
      }
      return _offst.sub(8);
    }

    function getAddress(uint _offst, bytes memory _input) internal pure returns (address _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(20));
    }

    function getUint(uint _offst, bytes memory _input) internal pure returns (uint _output, uint _offset) {
      assembly {
          _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(32));
    }

    function getUint8(uint _offst, bytes memory _input) internal pure returns (uint8 _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(1));
    }

    function getUint16(uint _offst, bytes memory _input) internal pure returns (uint16 _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(2));
    }

    function getUint64(uint _offst, bytes memory _input) internal pure returns (uint64 _output, uint _offset) {
      assembly {
        _output := mload(add(_input, _offst))
      }
      return (_output, _offst.sub(8));
    }
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

 

 
contract ERC721BasicToken is ERC721Basic, Pausable {
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

  function transferBatch(address _from, address _to, uint[] _tokenIds) public {
    require(_from != address(0));
    require(_to != address(0));

    for(uint i=0; i<_tokenIds.length; i++) {
      require(isApprovedOrOwner(msg.sender, _tokenIds[i]));
      clearApproval(_from,  _tokenIds[i]);
      removeTokenFrom(_from, _tokenIds[i]);
      addTokenTo(_to, _tokenIds[i]);

      emit Transfer(_from, _to, _tokenIds[i]);
    }
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

   
  function addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused{
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

 

 
contract GirlBasicToken is ERC721BasicToken, Serialize {

  event CreateGirl(address owner, uint256 tokenID, uint256 genes, uint64 birthTime, uint64 cooldownEndTime, uint16 starLevel);
  event CoolDown(uint256 tokenId, uint64 cooldownEndTime);
  event GirlUpgrade(uint256 tokenId, uint64 starLevel);

  struct Girl{
     
    uint genes;

     
    uint64 birthTime;

     
    uint64 cooldownEndTime;
     
    uint16 starLevel;
  }

  Girl[] girls;


  function totalSupply() public view returns (uint256) {
    return girls.length;
  }

  function getGirlGene(uint _index) public view returns (uint) {
    return girls[_index].genes;
  }

  function getGirlBirthTime(uint _index) public view returns (uint64) {
    return girls[_index].birthTime;
  }

  function getGirlCoolDownEndTime(uint _index) public view returns (uint64) {
    return girls[_index].cooldownEndTime;
  }

  function getGirlStarLevel(uint _index) public view returns (uint16) {
    return girls[_index].starLevel;
  }

  function isNotCoolDown(uint _girlId) public view returns(bool) {
    return uint64(now) > girls[_girlId].cooldownEndTime;
  }

  function _createGirl(
      uint _genes,
      address _owner,
      uint16 _starLevel
  ) internal returns (uint){
      Girl memory _girl = Girl({
          genes:_genes,
          birthTime:uint64(now),
          cooldownEndTime:0,
          starLevel:_starLevel
      });
      uint256 girlId = girls.push(_girl) - 1;
      _mint(_owner, girlId);
      emit CreateGirl(_owner, girlId, _genes, _girl.birthTime, _girl.cooldownEndTime, _girl.starLevel);
      return girlId;
  }

  function _setCoolDownTime(uint _tokenId, uint _coolDownTime) internal {
    girls[_tokenId].cooldownEndTime = uint64(now.add(_coolDownTime));
    emit CoolDown(_tokenId, girls[_tokenId].cooldownEndTime);
  }

  function _LevelUp(uint _tokenId) internal {
    require(girls[_tokenId].starLevel < 65535);
    girls[_tokenId].starLevel = girls[_tokenId].starLevel + 1;
    emit GirlUpgrade(_tokenId, girls[_tokenId].starLevel);
  }

   
   
   
  uint8 constant public GIRLBUFFERSIZE = 50;   

  struct HashLockContract {
    address sender;
    address receiver;
    uint tokenId;
    bytes32 hashlock;
    uint timelock;
    bytes32 secret;
    States state;
    bytes extraData;
  }

  enum States {
    INVALID,
    OPEN,
    CLOSED,
    REFUNDED
  }

  mapping (bytes32 => HashLockContract) private contracts;

  modifier contractExists(bytes32 _contractId) {
    require(_contractExists(_contractId));
    _;
  }

  modifier hashlockMatches(bytes32 _contractId, bytes32 _secret) {
    require(contracts[_contractId].hashlock == keccak256(_secret));
    _;
  }

  modifier closable(bytes32 _contractId) {
    require(contracts[_contractId].state == States.OPEN);
    require(contracts[_contractId].timelock > now);
    _;
  }

  modifier refundable(bytes32 _contractId) {
    require(contracts[_contractId].state == States.OPEN);
    require(contracts[_contractId].timelock <= now);
    _;
  }

  event NewHashLockContract (
    bytes32 indexed contractId,
    address indexed sender,
    address indexed receiver,
    uint tokenId,
    bytes32 hashlock,
    uint timelock,
    bytes extraData
  );

  event SwapClosed(bytes32 indexed contractId);
  event SwapRefunded(bytes32 indexed contractId);

  function open (
    address _receiver,
    bytes32 _hashlock,
    uint _duration,
    uint _tokenId
  ) public
    onlyOwnerOf(_tokenId)
    returns (bytes32 contractId)
  {
    uint _timelock = now.add(_duration);

     
    bytes memory _extraData = new bytes(GIRLBUFFERSIZE);
    uint offset = GIRLBUFFERSIZE;

    offset = addUint16(offset, _extraData, girls[_tokenId].starLevel);
    offset = addUint64(offset, _extraData, girls[_tokenId].cooldownEndTime);
    offset = addUint64(offset, _extraData, girls[_tokenId].birthTime);
    offset = addUint(offset, _extraData, girls[_tokenId].genes);

    contractId = keccak256 (
      msg.sender,
      _receiver,
      _tokenId,
      _hashlock,
      _timelock,
      _extraData
    );

     
    require(!_contractExists(contractId));

     
     
    clearApproval(msg.sender, _tokenId);
    removeTokenFrom(msg.sender, _tokenId);
    addTokenTo(address(this), _tokenId);


    contracts[contractId] = HashLockContract(
      msg.sender,
      _receiver,
      _tokenId,
      _hashlock,
      _timelock,
      0x0,
      States.OPEN,
      _extraData
    );

    emit NewHashLockContract(contractId, msg.sender, _receiver, _tokenId, _hashlock, _timelock, _extraData);
  }

  function close(bytes32 _contractId, bytes32 _secret)
    public
    contractExists(_contractId)
    hashlockMatches(_contractId, _secret)
    closable(_contractId)
    returns (bool)
  {
    HashLockContract storage c = contracts[_contractId];
    c.secret = _secret;
    c.state = States.CLOSED;

     
     
    removeTokenFrom(address(this), c.tokenId);
    addTokenTo(c.receiver, c.tokenId);

    emit SwapClosed(_contractId);
    return true;
  }

  function refund(bytes32 _contractId)
    public
    contractExists(_contractId)
    refundable(_contractId)
    returns (bool)
  {
    HashLockContract storage c = contracts[_contractId];
    c.state = States.REFUNDED;

     
     
    removeTokenFrom(address(this), c.tokenId);
    addTokenTo(c.sender, c.tokenId);


    emit SwapRefunded(_contractId);
    return true;
  }

  function _contractExists(bytes32 _contractId) internal view returns (bool exists) {
    exists = (contracts[_contractId].sender != address(0));
  }

  function checkContract(bytes32 _contractId)
    public
    view
    contractExists(_contractId)
    returns (
      address sender,
      address receiver,
      uint amount,
      bytes32 hashlock,
      uint timelock,
      bytes32 secret,
      bytes extraData
    )
  {
    HashLockContract memory c = contracts[_contractId];
    return (
      c.sender,
      c.receiver,
      c.tokenId,
      c.hashlock,
      c.timelock,
      c.secret,
      c.extraData
    );
  }


}

 

contract AccessControl is Ownable{
    address CFO;
     

    modifier onlyCFO{
        require(msg.sender == CFO);
        _;
    }

    function setCFO(address _newCFO)public onlyOwner {
        CFO = _newCFO;
    }

     

}

 

 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    GirlBasicToken public girlBasicToken;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
    function() external {}


     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (girlBasicToken.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
     
     
     
     

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        girlBasicToken.safeTransferFrom(address(this), _receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

     
     
     
     
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
         
         
         
         
         
        if (_secondsPassed >= _duration) {
             
             
            return _endingPrice;
        } else {
             
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

     
     
    function _computeCut(uint256 _price) internal view returns (uint256) {
         
         
         
         
         
        return _price * ownerCut / 10000;
    }

}

 

 
contract ClockAuction is Pausable, ClockAuctionBase, AccessControl {

     
     
     
     
     
     
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        GirlBasicToken candidateContract = GirlBasicToken(_nftAddress);
         
        girlBasicToken = candidateContract;
    }

    function withDrawBalance(uint256 amount) public onlyCFO {
      require(address(this).balance >= amount);
      CFO.transfer(amount);
    }


     
     
     
    function bid(uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
         
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    function setOwnerCut(uint _cut) public onlyOwner {
      ownerCut  = _cut;
    }

}

 

contract GenesFactory{
    function mixGenes(uint256 gene1, uint gene2) public returns(uint256);
    function getPerson(uint256 genes) public pure returns (uint256 person);
    function getRace(uint256 genes) public pure returns (uint256);
    function getRarity(uint256 genes) public pure returns (uint256);
    function getBaseStrengthenPoint(uint256 genesMain,uint256 genesSub) public pure returns (uint256);

    function getCanBorn(uint256 genes) public pure returns (uint256 canBorn,uint256 cooldown);
}

 

contract GirlAuction is Serialize, ERC721Receiver, ClockAuction {

  event GirlAuctionCreated(address sender, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);


  constructor(address _nftAddr, uint256 _cut) public
        ClockAuction(_nftAddr, _cut) {}
   
   
   
   
   

  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4) {

    require(msg.sender == address(girlBasicToken));

    uint _startingPrice;
    uint _endingPrice;
    uint _duration;

    uint offset = 96;
    (_startingPrice, offset) = getUint(offset, _data);
    (_endingPrice, offset) = getUint(offset, _data);
    (_duration, offset) = getUint(offset, _data);

    require(_startingPrice > _endingPrice);
    require(girlBasicToken.isNotCoolDown(_tokenId));


    emit GirlAuctionCreated(_from, _tokenId, _startingPrice, _endingPrice, _duration);


    require(_startingPrice <= 340282366920938463463374607431768211455);
    require(_endingPrice <= 340282366920938463463374607431768211455);
    require(_duration <= 18446744073709551615);

    Auction memory auction = Auction(
        _from,
        uint128(_startingPrice),
        uint128(_endingPrice),
        uint64(_duration),
        uint64(now)
    );
    _addAuction(_tokenId, auction);

    return ERC721_RECEIVED;
  }




}