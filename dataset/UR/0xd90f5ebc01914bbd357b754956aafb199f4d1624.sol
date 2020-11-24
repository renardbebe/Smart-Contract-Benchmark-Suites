 

pragma solidity ^0.4.24;

 
contract GeneSynthesisInterface {
     
    function isGeneSynthesis() public pure returns (bool);

     
    function synthGenes(uint256 gene1, uint256 gene2) public returns (uint256);
}

 
contract KydyAccessControl {
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}

contract ERC165Interface {
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC165 is ERC165Interface {
     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 
 
contract ERC721Basic is ERC165 {
     

     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    function balanceOf(address _owner) public view returns (uint256);

     
    function ownerOf(uint256 _tokenId) public view returns (address);

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;

     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

     
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

     
    function approve(address _approved, uint256 _tokenId) external;

     
    function setApprovalForAll(address _operator, bool _approved) external;

     
    function getApproved(uint256 _tokenId) public view returns (address);

     
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

     

     
     
    
     

     
    function name() external view returns (string _name);

     
    function symbol() external view returns (string _symbol);

     
    function tokenURI(uint256 _tokenId) external view returns (string);

     
     

     

     
    function totalSupply() public view returns (uint256);
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
contract KydyBase is KydyAccessControl, ERC721Basic {
    using SafeMath for uint256;
    using Address for address;

     

     
    event Created(address indexed owner, uint256 kydyId, uint256 yinId, uint256 yangId, uint256 genes);

     

     
    struct Kydy {
         
        uint256 genes;

         
        uint64 createdTime;

         
        uint64 rechargeEndBlock;

         
        uint32 yinId;
        uint32 yangId;

         
        uint32 synthesizingWithId;

         
         
        uint16 rechargeIndex;

         
         
        uint16 generation;
    }

     

     
    uint32[14] public recharges = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days)
    ];

     
    uint256 public secondsPerBlock = 15;

     

     
    Kydy[] kydys;

     
    mapping (uint256 => address) internal kydyIndexToOwner;

     
    mapping (address => uint256) internal ownershipTokenCount;

     
    mapping (uint256 => address) internal kydyIndexToApproved;

     
    mapping (uint256 => address) internal synthesizeAllowedToAddress;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = kydyIndexToOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return kydyIndexToApproved[tokenId];
    }

     
    function getSynthesizeApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId));
        return synthesizeAllowedToAddress[tokenId];
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function setApprovalForAll(address to, bool approved) external {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
         
        kydyIndexToOwner[_tokenId] = _to;

        ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
         
        delete synthesizeAllowedToAddress[_tokenId];
         
        delete kydyIndexToApproved[_tokenId];

         
        emit Transfer(_from, _to, _tokenId);
    }

     
    function _exists(uint256 _tokenId) internal view returns (bool) {
        address owner = kydyIndexToOwner[_tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
         
         
         
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

     
    function _addTokenTo(address _to, uint256 _tokenId) internal {
         
        require(kydyIndexToOwner[_tokenId] == address(0));
         
        kydyIndexToOwner[_tokenId] = _to;
         
        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
    }

     
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
         
        require(ownerOf(_tokenId) == _from);
         
        ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
         
        kydyIndexToOwner[_tokenId] = address(0);
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        require(!_exists(_tokenId));
        _addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

     
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (kydyIndexToApproved[_tokenId] != address(0)) {
            kydyIndexToApproved[_tokenId] = address(0);
        }
        if (synthesizeAllowedToAddress[_tokenId] != address(0)) {
            synthesizeAllowedToAddress[_tokenId] = address(0);
        }
    }

     
    function _createKydy(
        uint256 _yinId,
        uint256 _yangId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_yinId == uint256(uint32(_yinId)));
        require(_yangId == uint256(uint32(_yangId)));
        require(_generation == uint256(uint16(_generation)));

         
        uint16 rechargeIndex = uint16(_generation / 2);
        if (rechargeIndex > 13) {
            rechargeIndex = 13;
        }

        Kydy memory _kyd = Kydy({
            genes: _genes,
            createdTime: uint64(now),
            rechargeEndBlock: 0,
            yinId: uint32(_yinId),
            yangId: uint32(_yangId),
            synthesizingWithId: 0,
            rechargeIndex: rechargeIndex,
            generation: uint16(_generation)
        });
        uint256 newbabyKydyId = kydys.push(_kyd) - 1;

         
        require(newbabyKydyId == uint256(uint32(newbabyKydyId)));

         
        emit Created(
            _owner,
            newbabyKydyId,
            uint256(_kyd.yinId),
            uint256(_kyd.yangId),
            _kyd.genes
        );

         
        _mint(_owner, newbabyKydyId);

        return newbabyKydyId;
    }

     
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < recharges[0]);
        secondsPerBlock = secs;
    }
}

 
contract ERC721TokenReceiver {
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns (bytes4);
}

 

library Strings {
     
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

 
contract KydyOwnership is KydyBase {
    using Strings for string;

     
    string public constant _name = "Dyverse";
    string public constant _symbol = "KYDY";

     
    string internal tokenURIBase = "http://testapi.dyver.se/api/KydyMetadata/";

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
     

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
     

    bytes4 private constant _InterfaceId_ERC721Metadata = 0x5b5e139f;
     

    constructor() public {
        _registerInterface(_InterfaceId_ERC165);
         
        _registerInterface(_InterfaceId_ERC721);
         
        _registerInterface(_InterfaceId_ERC721Metadata);
    }

     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return kydyIndexToOwner[_tokenId] == _claimant;
    }

     
    function _approve(uint256 _tokenId, address _approved) internal {
        kydyIndexToApproved[_tokenId] = _approved;
    }

     
    function rescueLostKydy(uint256 _kydyId, address _recipient) external onlyCOO whenNotPaused {
        require(_owns(this, _kydyId));
        _transfer(this, _recipient, _kydyId);
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownershipTokenCount[_owner];
    }

     
    function approve(address to, uint256 tokenId) external whenNotPaused {
        address owner = ownerOf(tokenId);
        require(to != owner);
         
         
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

         
        _approve(tokenId, to);

         
        emit Approval(owner, to, tokenId);
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
         
        require(_isApprovedOrOwner(msg.sender, tokenId));
         
        require(to != address(0));

         
        _clearApproval(from, tokenId);
         
        _removeTokenFrom(from, tokenId);
         
        _addTokenTo(to, tokenId);

         
        emit Transfer(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
         
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
         
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

     
    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }

        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
    
     
    function name() external view returns (string) {
        return _name;
    }

     
    function symbol() external view returns (string) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string) {
        require(_exists(tokenId));
        return Strings.strConcat(
            tokenURIBase,
            Strings.uint2str(tokenId)
        );
    }

     
    function totalSupply() public view returns (uint256) {
        return kydys.length - 1;
    }

     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalKydys = totalSupply();
            uint256 resultIndex = 0;

             
            uint256 kydyId;

            for (kydyId = 1; kydyId <= totalKydys; kydyId++) {
                if (kydyIndexToOwner[kydyId] == _owner) {
                    result[resultIndex] = kydyId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

 
contract KydySynthesis is KydyOwnership {

     
    event Creating(address owner, uint256 yinId, uint256 yangId, uint256 rechargeEndBlock);

     
    uint256 public autoCreationFee = 14 finney;

     
    uint256 public creatingKydys;

     
    GeneSynthesisInterface public geneSynthesis;

     
    function setGeneSynthesisAddress(address _address) external onlyCEO {
        GeneSynthesisInterface candidateContract = GeneSynthesisInterface(_address);

         
        require(candidateContract.isGeneSynthesis());

         
        geneSynthesis = candidateContract;
    }

     
    function _isReadyToSynthesize(Kydy _kyd) internal view returns (bool) {
         
        return (_kyd.synthesizingWithId == 0) && (_kyd.rechargeEndBlock <= uint64(block.number));
    }

     
    function _isSynthesizingAllowed(uint256 _yangId, uint256 _yinId) internal view returns (bool) {
        address yinOwner = kydyIndexToOwner[_yinId];
        address yangOwner = kydyIndexToOwner[_yangId];

        return (yinOwner == yangOwner || synthesizeAllowedToAddress[_yangId] == yinOwner);
    }

     
    function _triggerRecharge(Kydy storage _kyd) internal {
         
        _kyd.rechargeEndBlock = uint64((recharges[_kyd.rechargeIndex] / secondsPerBlock) + block.number);

         
        if (_kyd.rechargeIndex < 12) {
            _kyd.rechargeIndex += 1;
        }
    }

     
    function approveSynthesizing(address _address, uint256 _yangId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _yangId));
        synthesizeAllowedToAddress[_yangId] = _address;
    }

     
    function setAutoCreationFee(uint256 value) external onlyCOO {
        autoCreationFee = value;
    }

     
    function _isReadyToBringKydyHome(Kydy _yin) private view returns (bool) {
        return (_yin.synthesizingWithId != 0) && (_yin.rechargeEndBlock <= uint64(block.number));
    }

     
    function isReadyToSynthesize(uint256 _kydyId)
        public
        view
        returns (bool)
    {
        require(_kydyId > 0);
        Kydy storage kyd = kydys[_kydyId];
        return _isReadyToSynthesize(kyd);
    }

     
    function isCreating(uint256 _kydyId)
        public
        view
        returns (bool)
    {
        require(_kydyId > 0);

        return kydys[_kydyId].synthesizingWithId != 0;
    }

     
    function _isValidCouple(
        Kydy storage _yin,
        uint256 _yinId,
        Kydy storage _yang,
        uint256 _yangId
    )
        private
        view
        returns(bool)
    {
         
        if (_yinId == _yangId) {
            return false;
        }

         
        if (_yin.yinId == _yangId || _yin.yangId == _yangId) {
            return false;
        }
        if (_yang.yinId == _yinId || _yang.yangId == _yinId) {
            return false;
        }

         
        if (_yang.yinId == 0 || _yin.yinId == 0) {
            return true;
        }

         
        if (_yang.yinId == _yin.yinId || _yang.yinId == _yin.yangId) {
            return false;
        }
        if (_yang.yangId == _yin.yinId || _yang.yangId == _yin.yangId) {
            return false;
        }
        return true;
    }

     
    function _canSynthesizeWithViaAuction(uint256 _yinId, uint256 _yangId)
        internal
        view
        returns (bool)
    {
        Kydy storage yin = kydys[_yinId];
        Kydy storage yang = kydys[_yangId];
        return _isValidCouple(yin, _yinId, yang, _yangId);
    }

     
    function canSynthesizeWith(uint256 _yinId, uint256 _yangId)
        external
        view
        returns(bool)
    {
        require(_yinId > 0);
        require(_yangId > 0);
        Kydy storage yin = kydys[_yinId];
        Kydy storage yang = kydys[_yangId];
        return _isValidCouple(yin, _yinId, yang, _yangId) &&
            _isSynthesizingAllowed(_yangId, _yinId);
    }

     
    function _synthesizeWith(uint256 _yinId, uint256 _yangId) internal {
        Kydy storage yang = kydys[_yangId];
        Kydy storage yin = kydys[_yinId];

         
        yin.synthesizingWithId = uint32(_yangId);

         
        _triggerRecharge(yang);
        _triggerRecharge(yin);

         
        delete synthesizeAllowedToAddress[_yinId];
        delete synthesizeAllowedToAddress[_yangId];

         
        creatingKydys++;

         
        emit Creating(kydyIndexToOwner[_yinId], _yinId, _yangId, yin.rechargeEndBlock);
    }

     
    function synthesizeWithAuto(uint256 _yinId, uint256 _yangId)
        external
        payable
        whenNotPaused
    {
         
        require(msg.value >= autoCreationFee);

         
        require(_owns(msg.sender, _yinId));

         
        require(_isSynthesizingAllowed(_yangId, _yinId));

         
        Kydy storage yin = kydys[_yinId];

         
        require(_isReadyToSynthesize(yin));

         
        Kydy storage yang = kydys[_yangId];

         
        require(_isReadyToSynthesize(yang));

         
        require(_isValidCouple(
            yin,
            _yinId,
            yang,
            _yangId
        ));

         
        _synthesizeWith(_yinId, _yangId);

    }

     
    function bringKydyHome(uint256 _yinId)
        external
        whenNotPaused
        returns(uint256)
    {
         
        Kydy storage yin = kydys[_yinId];

         
        require(yin.createdTime != 0);

         
        require(_isReadyToBringKydyHome(yin));

         
        uint256 yangId = yin.synthesizingWithId;
        Kydy storage yang = kydys[yangId];

         
        uint16 parentGen = yin.generation;
        if (yang.generation > yin.generation) {
            parentGen = yang.generation;
        }

         
        uint256 childGenes = geneSynthesis.synthGenes(yin.genes, yang.genes);

         
        address owner = kydyIndexToOwner[_yinId];
        uint256 kydyId = _createKydy(_yinId, yin.synthesizingWithId, parentGen + 1, childGenes, owner);

         
        delete yin.synthesizingWithId;

         
        creatingKydys--;

         
        msg.sender.transfer(autoCreationFee);

         
        return kydyId;
    }
}

contract ERC721Holder is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

 
contract AuctionBase is ERC721Holder {
    using SafeMath for uint256;

     
    struct Auction {
         
        address seller;
         
        uint128 price;
         
         
        uint64 startedAt;
    }

     
    ERC721Basic public nonFungibleContract;

     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 price);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address bidder);
    event AuctionCanceled(uint256 tokenId);

     
    function() external {}

     
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= (2**64 - 1));
        _;
    }

     
    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value <= (2**128 - 1));
        _;
    }

     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(_owner, this, _tokenId);
    }

     
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(this, _receiver, _tokenId);
    }

     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.price)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCanceled(_tokenId);
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
            uint256 sellerProceeds = price.sub(auctioneerCut);

            seller.transfer(sellerProceeds);
        }

         
        uint256 bidExcess = _bidAmount - price;

         
        msg.sender.transfer(bidExcess);

         
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
        return _auction.price;
    }

     
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
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

 
contract Auction is Pausable, AuctionBase {

     
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(address(this).balance);
    }

     
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        whenNotPaused
        canBeStoredWith128Bits(_price)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

     
    function cancelAuction(uint256 _tokenId, address _seller)
        external
    {
         
         
         
         
        require(msg.sender == address(nonFungibleContract));
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(_seller == seller);
        _cancelAuction(_tokenId, seller);
    }

     
    function cancelAuctionWhenPaused(uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 price,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.price,
            auction.startedAt
        );
    }

     
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}

 
contract SynthesizingAuction is Auction {

     
    bool public isSynthesizingAuction = true;

     
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        nonFungibleContract = candidateContract;
    }

     
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        canBeStoredWith128Bits(_price)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
         
        _bid(_tokenId, msg.value);
         
         
        _transfer(seller, _tokenId);
    }
}

 
contract SaleAuction is Auction {

     
    bool public isSaleAuction = true;

     
    uint256[5] public lastGen0SalePrices;
    
     
    uint256 public gen0SaleCount;

     
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        nonFungibleContract = candidateContract;
    }

     
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        canBeStoredWith128Bits(_price)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

     
    function bid(uint256 _tokenId)
        external
        payable
    {
         
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        if (seller == address(nonFungibleContract)) {
             
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

     
    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum = sum.add(lastGen0SalePrices[i]);
        }
        return sum / 5;
    }
}

 
contract KydyAuction is KydySynthesis {

     
    SaleAuction public saleAuction;

     
    SynthesizingAuction public synthesizingAuction;

     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleAuction candidateContract = SaleAuction(_address);

         
        require(candidateContract.isSaleAuction());

         
        saleAuction = candidateContract;
    }

     
    function setSynthesizingAuctionAddress(address _address) external onlyCEO {
        SynthesizingAuction candidateContract = SynthesizingAuction(_address);

        require(candidateContract.isSynthesizingAuction());

        synthesizingAuction = candidateContract;
    }

     
    function createSaleAuction(
        uint256 _kydyId,
        uint256 _price
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _kydyId));
        require(!isCreating(_kydyId));
        _approve(_kydyId, saleAuction);
 
        saleAuction.createAuction(
            _kydyId,
            _price,
            msg.sender
        );
    }

     
    function createSynthesizingAuction(
        uint256 _kydyId,
        uint256 _price
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _kydyId));
        require(isReadyToSynthesize(_kydyId));
        _approve(_kydyId, synthesizingAuction);

        synthesizingAuction.createAuction(
            _kydyId,
            _price,
            msg.sender
        );
    }

     
    function bidOnSynthesizingAuction(
        uint256 _yangId,
        uint256 _yinId
    )
        external
        payable
        whenNotPaused
    {
        require(_owns(msg.sender, _yinId));
        require(isReadyToSynthesize(_yinId));
        require(_canSynthesizeWithViaAuction(_yinId, _yangId));

        uint256 currentPrice = synthesizingAuction.getCurrentPrice(_yangId);

        require (msg.value >= currentPrice + autoCreationFee);

        synthesizingAuction.bid.value(msg.value - autoCreationFee)(_yangId);

        _synthesizeWith(uint32(_yinId), uint32(_yangId));
    }

     
    function cancelSaleAuction(
        uint256 _kydyId
    )
        external
        whenNotPaused
    {
         
        require(_owns(saleAuction, _kydyId));
         
        (address seller,,) = saleAuction.getAuction(_kydyId);
         
        require(msg.sender == seller);
         
        saleAuction.cancelAuction(_kydyId, msg.sender);
    }

     
    function cancelSynthesizingAuction(
        uint256 _kydyId
    )
        external
        whenNotPaused
    {
        require(_owns(synthesizingAuction, _kydyId));
        (address seller,,) = synthesizingAuction.getAuction(_kydyId);
        require(msg.sender == seller);
        synthesizingAuction.cancelAuction(_kydyId, msg.sender);
    }

     
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        synthesizingAuction.withdrawBalance();
    }
}

 
contract KydyMinting is KydyAuction {

     
    uint256 public constant promoCreationLimit = 888;
    uint256 public constant gen0CreationLimit = 8888;

    uint256 public constant gen0StartingPrice = 10 finney;

     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

     
    function createPromoKydy(uint256 _genes, address _owner) external onlyCOO {
        address kydyOwner = _owner;
        if (kydyOwner == address(0)) {
            kydyOwner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);

        promoCreatedCount++;
        _createKydy(0, 0, 0, _genes, kydyOwner);
    }

     
    function createGen0Auction(uint256 _genes) external onlyCOO {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 kydyId = _createKydy(0, 0, 0, _genes, address(this));
        _approve(kydyId, saleAuction);

        saleAuction.createAuction(
            kydyId,
            _computeNextGen0Price(),
            address(this)
        );

        gen0CreatedCount++;
    }

     
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 averagePrice = saleAuction.averageGen0SalePrice();

         
        require(averagePrice == uint256(uint128(averagePrice)));

        uint256 nextPrice = averagePrice.add(averagePrice / 2);

         
         
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}

contract KydyTravelInterface {
    function balanceOfUnclaimedTT(address _user) public view returns(uint256);
    function transferTTProduction(address _from, address _to, uint256 _kydyId) public;
    function getProductionOf(address _user) public view returns (uint256);
}

 
contract KydyCore is KydyMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
    address public newContractAddress;

     
    constructor() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
         
        _createKydy(0, 0, 0, uint256(-1), address(0));
    }

     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

     
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(synthesizingAuction)
        );
    }

     
    function getKydy(uint256 _id)
        external
        view
        returns (
        bool isCreating,
        bool isReady,
        uint256 rechargeIndex,
        uint256 nextActionAt,
        uint256 synthesizingWithId,
        uint256 createdTime,
        uint256 yinId,
        uint256 yangId,
        uint256 generation,
        uint256 genes
    ) {
        Kydy storage kyd = kydys[_id];

         
        isCreating = (kyd.synthesizingWithId != 0);
        isReady = (kyd.rechargeEndBlock <= block.number);
        rechargeIndex = uint256(kyd.rechargeIndex);
        nextActionAt = uint256(kyd.rechargeEndBlock);
        synthesizingWithId = uint256(kyd.synthesizingWithId);
        createdTime = uint256(kyd.createdTime);
        yinId = uint256(kyd.yinId);
        yangId = uint256(kyd.yangId);
        generation = uint256(kyd.generation);
        genes = kyd.genes;
    }

     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(synthesizingAuction != address(0));
        require(geneSynthesis != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = address(this).balance;

         
         
        uint256 subtractFees = (creatingKydys + 1) * autoCreationFee;

        if (balance > subtractFees) {
            cfoAddress.transfer(balance - subtractFees);
        }
    }

     
    function setNewTokenURI(string _newTokenURI) external onlyCLevel {
        tokenURIBase = _newTokenURI;
    }

     
    KydyTravelInterface public travelCore;

     
    function setTravelCore(address _newTravelCore) external onlyCEO whenPaused {
        travelCore = KydyTravelInterface(_newTravelCore);
    }
}