 

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

contract ERC721 {

     
    function approve(address _to, uint256 _tokenId) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function implementsERC721() public pure returns (bool);
    function ownerOf(uint256 _tokenId) public view returns (address addr);
    function takeOwnership(uint256 _tokenId) public;
    function totalSupply() public view returns (uint256 total);
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

     
     
     
     
     
}


contract CryptoSoccrToken is ERC721 {

     

     
    event Birth(uint256 tokenId, string name, address owner);
    event Snatch(uint256 tokenId, address oldOwner, address newOwner);

 
    event TokenSold(
        uint256 indexed tokenId,
        uint256 oldPrice,
        uint256 newPrice,
        address prevOwner,
        address indexed winner,
        string name
    );

     
     
    event Transfer(address from, address to, uint256 tokenId);

     

     
    string public constant NAME = "CryptoSoccr";
    string public constant SYMBOL = "CryptoSoccrToken";

    uint256 private startingPrice = 0.001 ether;
    uint256 private constant PROMO_CREATION_LIMIT = 5000;
    uint256 private firstStepLimit =    0.053613 ether;
    uint256 private firstStepMultiplier =    200;
    uint256 private secondStepLimit = 0.564957 ether;
    uint256 private secondStepMultiplier = 150;
    uint256 private thirdStepMultiplier = 120;

     

     
     
    mapping (uint256 => address) public playerIndexToOwner;

     
     
    mapping (address => uint256) private ownershipTokenCount;

     
     
     
    mapping (uint256 => address) public playerIndexToApproved;

     
    mapping (uint256 => uint256) private playerIndexToPrice;

     
    address public ceoAddress;

    uint256 public promoCreatedCount;

     
    struct Player {
        string name;
        uint256 internalPlayerId;
    }

    Player[] private players;

     
     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCLevel() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    function CryptoSoccrToken() public {
        ceoAddress = msg.sender;
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    ) public {
         
        require(_owns(msg.sender, _tokenId));

        playerIndexToApproved[_tokenId] = _to;

        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

     
    function createPromoPlayer(address _owner, string _name, uint256 _price, uint256 _internalPlayerId) public onlyCEO {
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        address playerOwner = _owner;
        if (playerOwner == address(0)) {
            playerOwner = ceoAddress;
        }

        if (_price <= 0) {
            _price = startingPrice;
        }

        promoCreatedCount++;
        _createPlayer(_name, playerOwner, _price, _internalPlayerId);
    }

     
    function createContractPlayer(string _name, uint256 _internalPlayerId) public onlyCEO {
        _createPlayer(_name, address(this), startingPrice, _internalPlayerId);
    }

     
     
    function getPlayer(uint256 _tokenId) public view returns (
        string playerName,
        uint256 internalPlayerId,
        uint256 sellingPrice,
        address owner
    ) {
        Player storage player = players[_tokenId];
        playerName = player.name;
        internalPlayerId = player.internalPlayerId;
        sellingPrice = playerIndexToPrice[_tokenId];
        owner = playerIndexToOwner[_tokenId];
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

     
    function name() public pure returns (string) {
        return NAME;
    }

     
     
     
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = playerIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function payout(address _to) public onlyCLevel {
        _payout(_to);
    }

     
    function purchase(uint256 _tokenId) public payable {
        address oldOwner = playerIndexToOwner[_tokenId];
        address newOwner = msg.sender;

        uint256 sellingPrice = playerIndexToPrice[_tokenId];

         
        require(oldOwner != newOwner);

         
        require(_addressNotNull(newOwner));

         
        require(msg.value >= sellingPrice);

        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 94), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

         
        if (sellingPrice < firstStepLimit) {
             
            playerIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, firstStepMultiplier), 94);
        } else if (sellingPrice < secondStepLimit) {
             
            playerIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, secondStepMultiplier), 94);
        } else {
             
            playerIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, thirdStepMultiplier), 94);
        }

        _transfer(oldOwner, newOwner, _tokenId);
        Snatch(_tokenId, oldOwner, newOwner);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);  
        }

        TokenSold(_tokenId, sellingPrice, playerIndexToPrice[_tokenId], oldOwner, newOwner, players[_tokenId].name);

        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return playerIndexToPrice[_tokenId];
    }

     
     
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

     
     
     
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = playerIndexToOwner[_tokenId];

         
        require(_addressNotNull(newOwner));

         
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

     
     
     
     
     
    function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
                 
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalPlayers = totalSupply();
            uint256 resultIndex = 0;

            uint256 playerId;
            for (playerId = 0; playerId <= totalPlayers; playerId++) {
                if (playerIndexToOwner[playerId] == _owner) {
                    result[resultIndex] = playerId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

     
     
    function totalSupply() public view returns (uint256 total) {
        return players.length;
    }

     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    ) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));

        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));

        _transfer(_from, _to, _tokenId);
    }

     
     
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }

     
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return playerIndexToApproved[_tokenId] == _to;
    }

     
    function _createPlayer(string _name, address _owner, uint256 _price, uint256 _internalPlayerId) private {
        Player memory _player = Player({
            name: _name,
            internalPlayerId: _internalPlayerId
        });
        uint256 newPlayerId = players.push(_player) - 1;

         
         
        require(newPlayerId == uint256(uint32(newPlayerId)));

        Birth(newPlayerId, _name, _owner);

        playerIndexToPrice[newPlayerId] = _price;

         
         
        _transfer(address(0), _owner, newPlayerId);
    }

     
    function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
        return claimant == playerIndexToOwner[_tokenId];
    }

     
    function _payout(address _to) private {
        if (_to == address(0)) {
            ceoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) private {
         
        ownershipTokenCount[_to]++;
         
        playerIndexToOwner[_tokenId] = _to;

         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete playerIndexToApproved[_tokenId];
        }

         
        Transfer(_from, _to, _tokenId);
    }
}