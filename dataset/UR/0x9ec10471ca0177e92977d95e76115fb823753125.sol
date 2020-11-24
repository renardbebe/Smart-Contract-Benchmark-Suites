 

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
contract ERC20 {

     
     

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

     
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

     
     


    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

     
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}

pragma solidity ^0.4.23;

 
 
 
interface ERC721   {

     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


    
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

    
     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);

      
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

     
     
     
     
     
    function transfer(address _to, uint256 _cutieId) external;
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;


 
interface ERC165 {

     
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


 
interface IERC1155   {
     
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

     
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
    event URI(string _value, uint256 indexed _id);

     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;

     
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external;

     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

     
    function balanceOfBatch(address[] _owners, uint256[] _ids) external view returns (uint256[] memory);

     
    function setApprovalForAll(address _operator, bool _approved) external;

     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender]);
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    function withdrawERC20(ERC20 _tokenContract) external onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(msg.sender, balance);
    }

    function approveERC721(ERC721 _tokenContract) external onlyOwner
    {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    function approveERC1155(IERC1155 _tokenContract) external onlyOwner
    {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    function withdrawEth() external onlyOwner
    {
        if (address(this).balance > 0)
        {
            msg.sender.transfer(address(this).balance);
        }
    }
}

pragma solidity ^0.4.23;

 
 
contract MarketInterface 
{
    function withdrawEthFromBalance() external;

    function createAuction(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller) external payable;
    function createAuctionWithTokens(uint40 _cutieId, uint128 _startPrice, uint128 _endPrice, uint40 _duration, address _seller, address[] allowedTokens) external payable;

    function bid(uint40 _cutieId) external payable;

    function cancelActiveAuctionWhenPaused(uint40 _cutieId) external;

	function getAuctionInfo(uint40 _cutieId)
        external
        view
        returns
    (
        address seller,
        uint128 startPrice,
        uint128 endPrice,
        uint40 duration,
        uint40 startedAt,
        uint128 featuringFee,
        address[] allowedTokens
    );
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

 
 
 
interface ConfigInterface
{
    function isConfig() external pure returns (bool);

    function getCooldownIndexFromGeneration(uint16 _generation, uint40 _cutieId) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex, uint40 _cutieId) external view returns (uint40);
    function getCooldownIndexFromGeneration(uint16 _generation) external view returns (uint16);
    function getCooldownEndTimeFromIndex(uint16 _cooldownIndex) external view returns (uint40);

    function getCooldownIndexCount() external view returns (uint256);

    function getBabyGenFromId(uint40 _momId, uint40 _dadId) external view returns (uint16);
    function getBabyGen(uint16 _momGen, uint16 _dadGen) external pure returns (uint16);

    function getTutorialBabyGen(uint16 _dadGen) external pure returns (uint16);

    function getBreedingFee(uint40 _momId, uint40 _dadId) external view returns (uint256);
}


contract CutieCoreInterface
{
    function isCutieCore() pure public returns (bool);

    ConfigInterface public config;

    function transferFrom(address _from, address _to, uint256 _cutieId) external;
    function transfer(address _to, uint256 _cutieId) external;

    function ownerOf(uint256 _cutieId)
        external
        view
        returns (address owner);

    function getCutie(uint40 _id)
        external
        view
        returns (
        uint256 genes,
        uint40 birthTime,
        uint40 cooldownEndTime,
        uint40 momId,
        uint40 dadId,
        uint16 cooldownIndex,
        uint16 generation
    );

    function getGenes(uint40 _id)
        public
        view
        returns (
        uint256 genes
    );


    function getCooldownEndTime(uint40 _id)
        public
        view
        returns (
        uint40 cooldownEndTime
    );

    function getCooldownIndex(uint40 _id)
        public
        view
        returns (
        uint16 cooldownIndex
    );


    function getGeneration(uint40 _id)
        public
        view
        returns (
        uint16 generation
    );

    function getOptional(uint40 _id)
        public
        view
        returns (
        uint64 optional
    );


    function changeGenes(
        uint40 _cutieId,
        uint256 _genes)
        public;

    function changeCooldownEndTime(
        uint40 _cutieId,
        uint40 _cooldownEndTime)
        public;

    function changeCooldownIndex(
        uint40 _cutieId,
        uint16 _cooldownIndex)
        public;

    function changeOptional(
        uint40 _cutieId,
        uint64 _optional)
        public;

    function changeGeneration(
        uint40 _cutieId,
        uint16 _generation)
        public;

    function createSaleAuction(
        uint40 _cutieId,
        uint128 _startPrice,
        uint128 _endPrice,
        uint40 _duration
    )
    public;

    function getApproved(uint256 _tokenId) external returns (address);
    function totalSupply() view external returns (uint256);
    function createPromoCutie(uint256 _genes, address _owner) external;
    function checkOwnerAndApprove(address _claimant, uint40 _cutieId, address _pluginsContract) external view;
    function breedWith(uint40 _momId, uint40 _dadId) public payable returns (uint40);
    function getBreedingFee(uint40 _momId, uint40 _dadId) public view returns (uint256);
    function restoreCutieToAddress(uint40 _cutieId, address _recipient) external;
    function createGen0Auction(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration) external;
    function createGen0AuctionWithTokens(uint256 _genes, uint128 startPrice, uint128 endPrice, uint40 duration, address[] allowedTokens) external;
    function createPromoCutieWithGeneration(uint256 _genes, address _owner, uint16 _generation) external;
    function createPromoCutieBulk(uint256[] _genes, address _owner, uint16 _generation) external;
}

pragma solidity ^0.4.23;

 
 
interface PresaleInterface
{
    function bidWithPlugin(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent) external payable;
    function bidWithPluginReferrer(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent, address referrer) external payable;

    function getLotNftFixedRewards(uint32 lotId) external view returns (
        uint256 rewardsNFTFixedKind,
        uint256 rewardsNFTFixedIndex
    );
    function getLotToken1155Rewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsToken1155tokenId,
        uint256[10] memory rewardsToken1155count
    );
    function getLotCutieRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsCutieGenome,
        uint256[10] memory rewardsCutieGeneration
    );
    function getLotNftMintRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsNFTMintNftKind
    );

    function getLotToken1155RewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsToken1155tokenId,
        uint256 rewardsToken1155count
    );
    function getLotCutieRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsCutieGenome,
        uint256 rewardsCutieGeneration
    );
    function getLotNftMintRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsNFTMintNftKind
    );

    function getLotToken1155RewardCount(uint32 lotId) external view returns (uint);
    function getLotCutieRewardCount(uint32 lotId) external view returns (uint);
    function getLotNftMintRewardCount(uint32 lotId) external view returns (uint);

    function getLotRewards(uint32 lotId) external view returns (
        uint256[5] memory rewardsToken1155tokenId,
        uint256[5] memory rewardsToken1155count,
        uint256[5] memory rewardsNFTMintNftKind,
        uint256[5] memory rewardsNFTFixedKind,
        uint256[5] memory rewardsNFTFixedIndex,
        uint256[5] memory rewardsCutieGenome,
        uint256[5] memory rewardsCutieGeneration
    );
}

pragma solidity ^0.4.23;

interface BlockchainCutiesERC1155Interface
{
    function mintNonFungibleSingleShort(uint128 _type, address _to) external;
    function mintNonFungibleSingle(uint256 _type, address _to) external;
    function mintNonFungibleShort(uint128 _type, address[] _to) external;
    function mintNonFungible(uint256 _type, address[] _to) external;
    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external;
    function mintFungible(uint256 _id, address[] _to, uint256[] _quantities) external;
    function isNonFungible(uint256 _id) external pure returns(bool);
    function ownerOf(uint256 _id) external view returns (address);
    function totalSupplyNonFungible(uint256 _type) view external returns (uint256);
    function totalSupplyNonFungibleShort(uint128 _type) view external returns (uint256);

     
    function uri(uint256 _id) external view returns (string memory);
    function proxyTransfer721(address _from, address _to, uint256 _tokenId, bytes _data) external;
    function proxyTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) external;
     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;
}

pragma solidity ^0.4.23;

interface PluginsInterface
{
    function isPlugin(address contractAddress) external view returns(bool);
    function withdraw() external;
    function setMinSign(uint40 _newMinSignId) external;

    function runPluginOperator(
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        address _sender) external payable;
}

pragma solidity ^0.4.23;

 
interface IERC1155TokenReceiver {

     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);

     
    function onERC1155BatchReceived(address _operator, address _from, uint256[] _ids, uint256[] _values, bytes _data) external returns(bytes4);

     
    function isERC1155TokenReceiver() external view returns (bytes4);
}


 
 
 
 
 
contract FiatProxy is Operators, IERC1155TokenReceiver {

    CutieCoreInterface public core;
    PluginsInterface public plugins;
    PresaleInterface public sale;

    event OrderSuccess(uint orderId, uint value, address purchaser);

    function setup(CutieCoreInterface _core, PluginsInterface _plugins, PresaleInterface _sale) external onlyOwner
    {
        core = _core;
        plugins = _plugins;
        sale = _sale;
    }

    function deposit() external payable
    {
         
    }

    function () external payable
    {
         
    }

    function buyCutie(uint40 _orderId, uint40 _cutieId, uint _value, address _saleMarketAddress, address _purchaser) external onlyOperator
    {
        MarketInterface market = MarketInterface(_saleMarketAddress);
        market.bid.value(_value)(_cutieId);

        core.transfer(_purchaser, _cutieId);

        emit OrderSuccess(_orderId, _value, _purchaser);
    }

    function buySaleLot(uint40 _orderId, uint32 _lotId, uint _value, address _purchaser) external onlyOperator
    {
        sale.bidWithPlugin(_lotId, _purchaser, _value, address(0x0));

        emit OrderSuccess(_orderId, _value, _purchaser);
    }

    function runPlugin(
        uint40 _orderId,
        address _pluginAddress,
        uint40 _signId,
        uint40 _cutieId,
        uint128 _value,
        uint256 _parameter,
        address _purchaser) external onlyOperator
    {
        plugins.runPluginOperator.value(_value)(_pluginAddress, _signId, _cutieId, _value, _parameter, _purchaser);

        emit OrderSuccess(_orderId, _value, _purchaser);
    }

    function isERC1155TokenReceiver() external view returns (bytes4)
    {
        return bytes4(keccak256("isERC1155TokenReceiver()"));
    }

    function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external returns(bytes4)
    {
        return bytes4(keccak256("accept_batch_erc1155_tokens()"));
    }

    function onERC1155Received(address, address, uint256, uint256, bytes) external returns(bytes4)
    {
        return bytes4(keccak256("accept_erc1155_tokens()"));
    }
}