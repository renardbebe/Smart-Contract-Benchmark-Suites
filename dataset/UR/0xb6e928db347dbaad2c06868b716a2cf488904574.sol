 

pragma solidity ^0.4.23;

 

 
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

 

 
 
 
contract Acceptable is Ownable {
    address public sender;

     
    modifier onlyAcceptable {
        require(msg.sender == sender);
        _;
    }

     
     
    function setAcceptable(address _sender) public onlyOwner {
        sender = _sender;
    }
}

 

 
 
 
contract ExchangeBase is Acceptable {
    struct Exchange {
        address owner;
        uint256 tokenId;
        uint8 kind;
        uint128 weight;
        uint64 createdAt;
    }

    Exchange[] exchanges;

    mapping(uint256 => Exchange) tokenIdToExchange;

    event ExchangeCreated(
        uint256 indexed id,
        address owner,
        uint256 ownerTokenId,
        uint256 ownerTokenGene,
        uint256 ownerTokenKind,
        uint256 ownerTokenWeight,
        uint256 kind,
        uint256 weight,
        uint256 createdAt
    );
    event ExchangeRemoved(uint256 indexed id, uint256 removedAt);

    function create(
        address _owner,
        uint256 _ownerTokenId,
        uint256 _ownerTokenGene,
        uint256 _ownerTokenKind,
        uint256 _ownerTokenWeight,
        uint256 _kind,
        uint256 _weight,
        uint256 _createdAt
    ) public onlyAcceptable returns(uint256) {
        require(!isOnExchange(_ownerTokenId));
        require(_ownerTokenWeight > 0);
        require(_weight > 0);
        require(_createdAt > 0);
        require(_weight <= 1384277343750);

        Exchange memory _exchange = Exchange({
            owner: _owner,
            tokenId: _ownerTokenId,
            kind: uint8(_kind),
            weight: uint128(_weight),
            createdAt: uint64(_createdAt)
            });
        uint256 _id = exchanges.push(_exchange) - 1;
        tokenIdToExchange[_ownerTokenId] = _exchange;
        emit ExchangeCreated(
            _id,
            _owner,
            _ownerTokenId,
            _ownerTokenGene,
            _ownerTokenKind,
            _ownerTokenWeight,
            _kind,
            _weight,
            _createdAt
        );
        return _id;
    }

    function remove(uint256 _id) public onlyAcceptable {
        require(isOnExchangeById(_id));

        Exchange memory _exchange = exchanges[_id];
        delete tokenIdToExchange[_exchange.tokenId];
        delete exchanges[_id];

        emit ExchangeRemoved(_id, now);
    }

    function getExchange(uint256 _id) public view returns(
        address owner,
        uint256 tokenId,
        uint256 kind,
        uint256 weight,
        uint256 createdAt
    ) {
        require(isOnExchangeById(_id));

        Exchange memory _exchange = exchanges[_id];
        owner = _exchange.owner;
        tokenId = _exchange.tokenId;
        kind = _exchange.kind;
        weight = _exchange.weight;
        createdAt = _exchange.createdAt;
    }

    function getTokenId(uint256 _id) public view returns(uint256) {
        require(isOnExchangeById(_id));

        Exchange memory _exchange = exchanges[_id];
        return _exchange.tokenId;
    }

    function ownerOf(uint256 _id) public view returns(address) {
        require(isOnExchangeById(_id));

        return exchanges[_id].owner;
    }

    function isOnExchange(uint256 _tokenId) public view returns(bool) {
        return tokenIdToExchange[_tokenId].createdAt > 0;
    }

    function isOnExchangeById(uint256 _id) public view returns(bool) {
        return (_id < exchanges.length) && (exchanges[_id].createdAt > 0);
    }
}