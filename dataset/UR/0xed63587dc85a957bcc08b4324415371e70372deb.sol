 

pragma solidity ^0.4.22;

 
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

contract RocsBase is Pausable {

     
    uint128 public eggPrice = 50 finney;
    function setEggPrice(uint128 _price) public onlyOwner {
        eggPrice = _price;
    }
     
    uint128 public evolvePrice = 5 finney;
    function setEvolvePrice(uint128 _price) public onlyOwner {
        evolvePrice = _price;
    }

     
    event RocCreated(address owner, uint tokenId, uint rocId);
     
    event Transfer(address from, address to, uint tokenId);
    event ItemTransfer(address from, address to, uint tokenId);

     
    struct Roc {
         
        uint rocId;
         
        string dna;
         
        uint8 marketsFlg;
    }

     
    Roc[] public rocs;

     
    mapping(uint => uint) public rocIndex;
     
    function getRocIdToTokenId(uint _rocId) public view returns (uint) {
        return rocIndex[_rocId];
    }

     
    mapping (uint => address) public rocIndexToOwner;
     
    mapping (address => uint) public ownershipTokenCount;
     
    mapping (uint => address) public rocIndexToApproved;

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to]++;
        ownershipTokenCount[_from]--;
        rocIndexToOwner[_tokenId] = _to;
         
        emit Transfer(_from, _to, _tokenId);
    }

}

 
contract ERC721 {
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function totalSupply() public view returns (uint);

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

 
 
contract RocsOwnership is RocsBase, ERC721 {

     
    string public constant name = "CryptoFeather";
    string public constant symbol = "CFE";

    bytes4 constant InterfaceSignature_ERC165 = 
    bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('totalSupply()'));

     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
         
         
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return rocIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return rocIndexToApproved[_tokenId] == _claimant;
    }

     
    function _approve(uint256 _tokenId, address _approved) internal {
        rocIndexToApproved[_tokenId] = _approved;
    }

     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
    function transfer(address _to, uint256 _tokenId) public whenNotPaused {
         
        require(_to != address(0));
         
        require(_owns(msg.sender, _tokenId));
         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_owns(msg.sender, _tokenId));
         
        _approve(_tokenId, _to);
         
        emit Approval(msg.sender, _to, _tokenId);
    }

     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) public whenNotPaused {
         
        require(_to != address(0));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return rocs.length - 1;
    }

     
     
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = rocIndexToOwner[_tokenId];
        require(owner != address(0));
    }

     
     
     
    function _escrow(address _owner, uint256 _tokenId) internal {
         
        transferFrom(_owner, this, _tokenId);
    }

}

 
contract RocsBreeding is RocsOwnership {

     
     
     
     
     
     
    function _createRoc(
        uint _rocId,
        string _dna,
        uint _marketsFlg,
        address _owner
    )
        internal
        returns (uint)
    {
        Roc memory _roc = Roc({
            rocId: _rocId,
            dna: _dna,
            marketsFlg: uint8(_marketsFlg)
        });

        uint newRocId = rocs.push(_roc) - 1;
         
        require(newRocId == uint(newRocId));
         
        emit RocCreated(_owner, newRocId, _rocId);

         
        rocIndex[_rocId] = newRocId;
        _transfer(0, _owner, newRocId);

        return newRocId;
    }

     
     
     
    function giveProduce(uint _rocId, string _dna)
        external
        payable
        whenNotPaused
        returns(uint)
    {
         
        require(msg.value >= eggPrice);
        uint createRocId = _createRoc(
            _rocId,
            _dna, 
            0, 
            msg.sender
        );
         
        uint256 bidExcess = msg.value - eggPrice;
        msg.sender.transfer(bidExcess);

        return createRocId;
    }

     
     
     
    function freeGiveProduce(uint _rocId, string _dna)
        external
        payable
        whenNotPaused
        returns(uint)
    {
         
        require(balanceOf(msg.sender) == 0);
        uint createRocId = _createRoc(
            _rocId,
            _dna, 
            0, 
            msg.sender
        );
         
        uint256 bidExcess = msg.value;
        msg.sender.transfer(bidExcess);

        return createRocId;
    }

}

 
contract RocsMarkets is RocsBreeding {

    event MarketsCreated(uint256 tokenId, uint128 marketsPrice);
    event MarketsSuccessful(uint256 tokenId, uint128 marketsPriceice, address buyer);
    event MarketsCancelled(uint256 tokenId);

     
    struct Markets {
         
        address seller;
         
        uint128 marketsPrice;
    }

     
    mapping (uint256 => Markets) tokenIdToMarkets;

     
    uint256 public ownerCut = 0;
    function setOwnerCut(uint256 _cut) public onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
    }

     
     
     
    function createRocSaleMarkets(
        uint256 _rocId,
        uint256 _marketsPrice
    )
        external
        whenNotPaused
    {
        require(_marketsPrice == uint256(uint128(_marketsPrice)));

         
        uint checkTokenId = getRocIdToTokenId(_rocId);

         
        require(_owns(msg.sender, checkTokenId));
         
        Roc memory roc = rocs[checkTokenId];
         
        require(uint8(roc.marketsFlg) == 0);
         
        _approve(checkTokenId, msg.sender);
         
        _escrow(msg.sender, checkTokenId);
        Markets memory markets = Markets(
            msg.sender,
            uint128(_marketsPrice)
        );

         
        rocs[checkTokenId].marketsFlg = 1;
        _addMarkets(checkTokenId, markets);
    }

     
     
     
     
    function _addMarkets(uint256 _tokenId, Markets _markets) internal {
        tokenIdToMarkets[_tokenId] = _markets;
        emit MarketsCreated(
            uint256(_tokenId),
            uint128(_markets.marketsPrice)
        );
    }

     
     
    function _removeMarkets(uint256 _tokenId) internal {
        delete tokenIdToMarkets[_tokenId];
    }

     
     
    function _cancelMarkets(uint256 _tokenId) internal {
        _removeMarkets(_tokenId);
        emit MarketsCancelled(_tokenId);
    }

     
     
     
     
    function cancelMarkets(uint _rocId) external {
        uint checkTokenId = getRocIdToTokenId(_rocId);
        Markets storage markets = tokenIdToMarkets[checkTokenId];
        address seller = markets.seller;
        require(msg.sender == seller);
        _cancelMarkets(checkTokenId);
        rocIndexToOwner[checkTokenId] = seller;
        rocs[checkTokenId].marketsFlg = 0;
    }

     
     
     
     
    function cancelMarketsWhenPaused(uint _rocId) whenPaused onlyOwner external {
        uint checkTokenId = getRocIdToTokenId(_rocId);
        Markets storage markets = tokenIdToMarkets[checkTokenId];
        address seller = markets.seller;
        _cancelMarkets(checkTokenId);
        rocIndexToOwner[checkTokenId] = seller;
        rocs[checkTokenId].marketsFlg = 0;
    }

     
     
     
    function bid(uint _rocId) external payable whenNotPaused {
        uint checkTokenId = getRocIdToTokenId(_rocId);
         
        Markets storage markets = tokenIdToMarkets[checkTokenId];

        uint128 sellingPrice = uint128(markets.marketsPrice);
         
         
        require(msg.value >= sellingPrice);
         
        address seller = markets.seller;

         
        _removeMarkets(checkTokenId);

        if (sellingPrice > 0) {
             
            uint128 marketseerCut = uint128(_computeCut(sellingPrice));
            uint128 sellerProceeds = sellingPrice - marketseerCut;

             
            seller.transfer(sellerProceeds);
        }

         
        msg.sender.transfer(msg.value - sellingPrice);
         
        emit MarketsSuccessful(checkTokenId, sellingPrice, msg.sender);

        _transfer(seller, msg.sender, checkTokenId);
         
        rocs[checkTokenId].marketsFlg = 0;
    }

     
     
    function _computeCut(uint128 _price) internal view returns (uint) {
        return _price * ownerCut / 10000;
    }

}

 
contract RocsCore is RocsMarkets {

     
    address public newContractAddress;

     
    function unpause() public onlyOwner whenPaused {
        require(newContractAddress == address(0));
         
        super.unpause();
    }

     
    function withdrawBalance(uint _subtractFees) external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > _subtractFees) {
            owner.transfer(balance - _subtractFees);
        }
    }

     
     
    function getRoc(uint _tokenId)
        external
        view
        returns (
        uint rocId,
        string dna,
        uint marketsFlg
    ) {
        Roc memory roc = rocs[_tokenId];
        rocId = uint(roc.rocId);
        dna = string(roc.dna);
        marketsFlg = uint(roc.marketsFlg);
    }

     
     
    function getRocrocId(uint _rocId)
        external
        view
        returns (
        uint rocId,
        string dna,
        uint marketsFlg
    ) {
        Roc memory roc = rocs[getRocIdToTokenId(_rocId)];
        rocId = uint(roc.rocId);
        dna = string(roc.dna);
        marketsFlg = uint(roc.marketsFlg);
    }

     
     
    function getMarketsRocId(uint _rocId)
        external
        view
        returns (
        address seller,
        uint marketsPrice
    ) {
        uint checkTokenId = getRocIdToTokenId(_rocId);
        Markets memory markets = tokenIdToMarkets[checkTokenId];
        seller = markets.seller;
        marketsPrice = uint(markets.marketsPrice);
    }

     
     
    function getRocIndexToOwner(uint _rocId)
        external
        view
        returns (
        address owner
    ) {
        uint checkTokenId = getRocIdToTokenId(_rocId);
        owner = rocIndexToOwner[checkTokenId];
    }

}