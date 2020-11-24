 
contract StickerType is Controlled, TokenClaimer, ERC721Full("Status Sticker Pack Authorship","STKA") {
    using SafeMath for uint256;
    event Register(uint256 indexed packId, uint256 dataPrice, bytes contenthash, bool mintable);
    event PriceChanged(uint256 indexed packId, uint256 dataPrice);
    event MintabilityChanged(uint256 indexed packId, bool mintable);
    event ContenthashChanged(uint256 indexed packid, bytes contenthash);
    event Categorized(bytes4 indexed category, uint256 indexed packId);
    event Uncategorized(bytes4 indexed category, uint256 indexed packId);
    event Unregister(uint256 indexed packId);

    struct Pack {
        bytes4[] category;
        bool mintable;
        uint256 timestamp;
        uint256 price;  
        uint256 donate;  
        bytes contenthash;
    }

    uint256 registerFee;
    uint256 burnRate;

    mapping(uint256 => Pack) public packs;
    uint256 public packCount;  


     
    mapping(bytes4 => uint256[]) private availablePacks;  
    mapping(bytes4 => mapping(uint256 => uint256)) private availablePacksIndex;  
    mapping(uint256 => mapping(bytes4 => uint256)) private packCategoryIndex;

     
    modifier packOwner(uint256 _packId) {
        address owner = ownerOf(_packId);
        require((msg.sender == owner) || (owner != address(0) && msg.sender == controller), "Unauthorized");
        _;
    }

     
    function generatePack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category,
        address _owner,
        bytes calldata _contenthash
    )
        external
        onlyController
        returns(uint256 packId)
    {
        require(_donate <= 10000, "Bad argument, _donate cannot be more then 100.00%");
        packId = packCount++;
        _mint(_owner, packId);
        packs[packId] = Pack(new bytes4[](0), true, block.timestamp, _price, _donate, _contenthash);
        emit Register(packId, _price, _contenthash, true);
        for(uint i = 0;i < _category.length; i++){
            addAvailablePack(packId, _category[i]);
        }
    }

     
    function purgePack(uint256 _packId, uint256 _limit)
        external
        onlyController
    {
        bytes4[] memory _category = packs[_packId].category;
        uint limit;
        if(_limit == 0) {
            limit = _category.length;
        } else {
            require(_limit <= _category.length, "Bad limit");
            limit = _limit;
        }

        uint256 len = _category.length;
        if(len > 0){
            len--;
        }
        for(uint i = 0; i < limit; i++){
            removeAvailablePack(_packId, _category[len-i]);
        }

        if(packs[_packId].category.length == 0){
            _burn(ownerOf(_packId), _packId);
            delete packs[_packId];
            emit Unregister(_packId);
        }

    }

     
    function setPackContenthash(uint256 _packId, bytes calldata _contenthash)
        external
        onlyController
    {
        emit ContenthashChanged(_packId, _contenthash);
        packs[_packId].contenthash = _contenthash;
    }

     
    function claimTokens(address _token)
        external
        onlyController
    {
        withdrawBalance(_token, controller);
    }

     
    function setPackPrice(uint256 _packId, uint256 _price, uint256 _donate)
        external
        packOwner(_packId)
    {
        require(_donate <= 10000, "Bad argument, _donate cannot be more then 100.00%");
        emit PriceChanged(_packId, _price);
        packs[_packId].price = _price;
        packs[_packId].donate = _donate;
    }

     
    function addPackCategory(uint256 _packId, bytes4 _category)
        external
        packOwner(_packId)
    {
        addAvailablePack(_packId, _category);
    }

     
    function removePackCategory(uint256 _packId, bytes4 _category)
        external
        packOwner(_packId)
    {
        removeAvailablePack(_packId, _category);
    }

     
    function setPackState(uint256 _packId, bool _mintable)
        external
        packOwner(_packId)
    {
        emit MintabilityChanged(_packId, _mintable);
        packs[_packId].mintable = _mintable;
    }

     
    function getAvailablePacks(bytes4 _category)
        external
        view
        returns (uint256[] memory availableIds)
    {
        return availablePacks[_category];
    }

     
    function getCategoryLength(bytes4 _category)
        external
        view
        returns (uint256 size)
    {
        size = availablePacks[_category].length;
    }

     
    function getCategoryPack(bytes4 _category, uint256 _index)
        external
        view
        returns (uint256 packId)
    {
        packId = availablePacks[_category][_index];
    }

     
    function getPackData(uint256 _packId)
        external
        view
        returns (
            bytes4[] memory category,
            address owner,
            bool mintable,
            uint256 timestamp,
            uint256 price,
            bytes memory contenthash
        )
    {
        Pack memory pack = packs[_packId];
        return (
            pack.category,
            ownerOf(_packId),
            pack.mintable,
            pack.timestamp,
            pack.price,
            pack.contenthash
        );
    }

     
    function getPackSummary(uint256 _packId)
        external
        view
        returns (
            bytes4[] memory category,
            uint256 timestamp,
            bytes memory contenthash
        )
    {
        Pack memory pack = packs[_packId];
        return (
            pack.category,
            pack.timestamp,
            pack.contenthash
        );
    }

     
    function getPaymentData(uint256 _packId)
        external
        view
        returns (
            address owner,
            bool mintable,
            uint256 price,
            uint256 donate
        )
    {
        Pack memory pack = packs[_packId];
        return (
            ownerOf(_packId),
            pack.mintable,
            pack.price,
            pack.donate
        );
    }

     
    function addAvailablePack(uint256 _packId, bytes4 _category) private {
        require(packCategoryIndex[_packId][_category] == 0, "Duplicate categorization");
        availablePacksIndex[_category][_packId] = availablePacks[_category].push(_packId);
        packCategoryIndex[_packId][_category] = packs[_packId].category.push(_category);
        emit Categorized(_category, _packId);
    }

     
    function removeAvailablePack(uint256 _packId, bytes4 _category) private {
        uint pos = availablePacksIndex[_category][_packId];
        require(pos > 0, "Not categorized [1]");
        delete availablePacksIndex[_category][_packId];
        if(pos != availablePacks[_category].length){
            uint256 movedElement = availablePacks[_category][availablePacks[_category].length-1];  
            availablePacks[_category][pos-1] = movedElement;
            availablePacksIndex[_category][movedElement] = pos;
        }
        availablePacks[_category].length--;

        uint pos2 = packCategoryIndex[_packId][_category];
        require(pos2 > 0, "Not categorized [2]");
        delete packCategoryIndex[_packId][_category];
        if(pos2 != packs[_packId].category.length){
            bytes4 movedElement2 = packs[_packId].category[packs[_packId].category.length-1];  
            packs[_packId].category[pos2-1] = movedElement2;
            packCategoryIndex[_packId][movedElement2] = pos2;
        }
        packs[_packId].category.length--;
        emit Uncategorized(_category, _packId);

    }

}