 

pragma solidity ^0.4.23;

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



 
contract PausableOperators is Operators {
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

pragma solidity ^0.4.23;

interface CutieGeneratorInterface
{
    function generate(uint _genome, uint16 _generation, address[] _target) external;
    function generateSingle(uint _genome, uint16 _generation, address _target) external returns (uint40 babyId);
}

pragma solidity ^0.4.23;

 
interface IERC1155TokenReceiver {

     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);

     
    function onERC1155BatchReceived(address _operator, address _from, uint256[] _ids, uint256[] _values, bytes _data) external returns(bytes4);

     
    function isERC1155TokenReceiver() external view returns (bytes4);
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


 
 
contract Presale is PresaleInterface, PausableOperators, IERC1155TokenReceiver
{
    struct RewardToken1155
    {
        uint tokenId;
        uint count;
    }

    struct RewardNFT
    {
        uint128 nftKind;
        uint128 tokenIndex;
    }

    struct RewardCutie
    {
        uint genome;
        uint16 generation;
    }

    uint32 constant RATE_SIGN = 0;
    uint32 constant NATIVE = 1;

    struct Lot
    {
        RewardToken1155[] rewardsToken1155;  
        uint128[] rewardsNftMint;  
        RewardNFT[] rewardsNftFixed;  
        RewardCutie[] rewardsCutie;  
        uint128 price;
        uint128 leftCount;
        uint128 priceMul;
        uint128 priceAdd;
        uint32 expireTime;
        uint32 lotKind;
    }

    mapping (uint32 => Lot) public lots;

    mapping (address => uint) public referrers;

    BlockchainCutiesERC1155Interface public token1155;
    CutieGeneratorInterface public cutieGenerator;
    address public signerAddress;

    event Bid(address indexed purchaser, uint32 indexed lotId, uint value, address indexed token);
    event BidReferrer(address indexed purchaser, uint32 indexed lotId, uint value, address token, address indexed referrer);
    event LotChange(uint32 indexed lotId);

    function setToken1155(BlockchainCutiesERC1155Interface _token1155) onlyOwner external
    {
        token1155 = _token1155;
    }

    function setCutieGenerator(CutieGeneratorInterface _cutieGenerator) onlyOwner external
    {
        cutieGenerator = _cutieGenerator;
    }

    function setLot(uint32 lotId, uint128 price, uint128 count, uint32 expireTime, uint128 priceMul, uint128 priceAdd, uint32 lotKind) external onlyOperator
    {
        delete lots[lotId];
        Lot storage lot = lots[lotId];
        lot.price = price;
        lot.leftCount = count;
        lot.expireTime = expireTime;
        lot.priceMul = priceMul;
        lot.priceAdd = priceAdd;
        lot.lotKind = lotKind;
        emit LotChange(lotId);
    }

    function setLotLeftCount(uint32 lotId, uint128 count) external onlyOperator
    {
        Lot storage lot = lots[lotId];
        lot.leftCount = count;
        emit LotChange(lotId);
    }

    function setExpireTime(uint32 lotId, uint32 expireTime) external onlyOperator
    {
        Lot storage lot = lots[lotId];
        lot.expireTime = expireTime;
        emit LotChange(lotId);
    }

    function setPrice(uint32 lotId, uint128 price) external onlyOperator
    {
        lots[lotId].price = price;
        emit LotChange(lotId);
    }

    function deleteLot(uint32 lotId) external onlyOperator
    {
        delete lots[lotId];
        emit LotChange(lotId);
    }

    function addRewardToken1155(uint32 lotId, uint tokenId, uint count) external onlyOperator
    {
        lots[lotId].rewardsToken1155.push(RewardToken1155(tokenId, count));
        emit LotChange(lotId);
    }

    function setRewardToken1155(uint32 lotId, uint tokenId, uint count) external onlyOperator
    {
        delete lots[lotId].rewardsToken1155;
        lots[lotId].rewardsToken1155.push(RewardToken1155(tokenId, count));
        emit LotChange(lotId);
    }

    function setRewardNftFixed(uint32 lotId, uint128 nftType, uint128 tokenIndex) external onlyOperator
    {
        delete lots[lotId].rewardsNftFixed;
        lots[lotId].rewardsNftFixed.push(RewardNFT(nftType, tokenIndex));
        emit LotChange(lotId);
    }

    function addRewardNftFixed(uint32 lotId, uint128 nftType, uint128 tokenIndex) external onlyOperator
    {
        lots[lotId].rewardsNftFixed.push(RewardNFT(nftType, tokenIndex));
        emit LotChange(lotId);
    }

    function addRewardNftFixedBulk(uint32 lotId, uint128 nftType, uint128[] tokenIndex) external onlyOperator
    {
        for (uint i = 0; i < tokenIndex.length; i++)
        {
            lots[lotId].rewardsNftFixed.push(RewardNFT(nftType, tokenIndex[i]));
        }
        emit LotChange(lotId);
    }

    function addRewardNftMint(uint32 lotId, uint128 nftType) external onlyOperator
    {
        lots[lotId].rewardsNftMint.push(nftType);
        emit LotChange(lotId);
    }

    function setRewardNftMint(uint32 lotId, uint128 nftType) external onlyOperator
    {
        delete lots[lotId].rewardsNftMint;
        lots[lotId].rewardsNftMint.push(nftType);
        emit LotChange(lotId);
    }

    function addRewardCutie(uint32 lotId, uint genome, uint16 generation) external onlyOperator
    {
        lots[lotId].rewardsCutie.push(RewardCutie(genome, generation));
        emit LotChange(lotId);
    }

    function setRewardCutie(uint32 lotId, uint genome, uint16 generation) external onlyOperator
    {
        delete lots[lotId].rewardsCutie;
        lots[lotId].rewardsCutie.push(RewardCutie(genome, generation));
        emit LotChange(lotId);
    }

    function isAvailable(uint32 lotId) public view returns (bool)
    {
        Lot storage lot = lots[lotId];
        return
            lot.leftCount > 0 && lot.expireTime >= now;
    }

    function getLot(uint32 lotId) external view returns (
        uint256 price,
        uint256 left,
        uint256 expireTime,
        uint256 lotKind
    )
    {
        Lot storage p = lots[lotId];
        price = p.price;
        left = p.leftCount;
        expireTime = p.expireTime;
        lotKind = p.lotKind;
    }

    function getLotRewards(uint32 lotId) external view returns (
            uint256[5] memory rewardsToken1155tokenId,
            uint256[5] memory rewardsToken1155count,
            uint256[5] memory rewardsNFTMintNftKind,
            uint256[5] memory rewardsNFTFixedKind,
            uint256[5] memory rewardsNFTFixedIndex,
            uint256[5] memory rewardsCutieGenome,
            uint256[5] memory rewardsCutieGeneration
        )
    {
        Lot storage p = lots[lotId];
        uint i;
        for (i = 0; i < p.rewardsToken1155.length; i++)
        {
            if (i >= 5) break;
            rewardsToken1155tokenId[i] = p.rewardsToken1155[i].tokenId;
            rewardsToken1155count[i] = p.rewardsToken1155[i].count;
        }
        for (i = 0; i < p.rewardsNftMint.length; i++)
        {
            if (i >= 5) break;
            rewardsNFTMintNftKind[i] = p.rewardsNftMint[i];
        }
        for (i = 0; i < p.rewardsNftFixed.length; i++)
        {
            if (i >= 5) break;
            rewardsNFTFixedKind[i] = p.rewardsNftFixed[i].nftKind;
            rewardsNFTFixedIndex[i] = p.rewardsNftFixed[i].tokenIndex;
        }
        for (i = 0; i < p.rewardsCutie.length; i++)
        {
            if (i >= 5) break;
            rewardsCutieGenome[i] = p.rewardsCutie[i].genome;
            rewardsCutieGeneration[i] = p.rewardsCutie[i].generation;
        }
    }

    function getLotNftFixedRewards(uint32 lotId) external view returns (
        uint256 rewardsNFTFixedKind,
        uint256 rewardsNFTFixedIndex
    )
    {
        Lot storage p = lots[lotId];

        if (p.rewardsNftFixed.length > 0)
        {
            rewardsNFTFixedKind = p.rewardsNftFixed[p.rewardsNftFixed.length-1].nftKind;
            rewardsNFTFixedIndex = p.rewardsNftFixed[p.rewardsNftFixed.length-1].tokenIndex;
        }
    }

    function getLotToken1155Rewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsToken1155tokenId,
        uint256[10] memory rewardsToken1155count
    )
    {
        Lot storage p = lots[lotId];
        for (uint i = 0; i < p.rewardsToken1155.length; i++)
        {
            if (i >= 10) break;
            rewardsToken1155tokenId[i] = p.rewardsToken1155[i].tokenId;
            rewardsToken1155count[i] = p.rewardsToken1155[i].count;
        }
    }

    function getLotCutieRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsCutieGenome,
        uint256[10] memory rewardsCutieGeneration
    )
    {
        Lot storage p = lots[lotId];
        for (uint i = 0; i < p.rewardsCutie.length; i++)
        {
            if (i >= 10) break;
            rewardsCutieGenome[i] = p.rewardsCutie[i].genome;
            rewardsCutieGeneration[i] = p.rewardsCutie[i].generation;
        }
    }

    function getLotNftMintRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsNFTMintNftKind
    )
    {
        Lot storage p = lots[lotId];
        for (uint i = 0; i < p.rewardsNftMint.length; i++)
        {
            if (i >= 10) break;
            rewardsNFTMintNftKind[i] = p.rewardsNftMint[i];
        }
    }

    function getLotToken1155RewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsToken1155tokenId,
        uint256 rewardsToken1155count
    )
    {
        Lot storage p = lots[lotId];
        rewardsToken1155tokenId = p.rewardsToken1155[index].tokenId;
        rewardsToken1155count = p.rewardsToken1155[index].count;
    }

    function getLotCutieRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsCutieGenome,
        uint256 rewardsCutieGeneration
    )
    {
        Lot storage p = lots[lotId];
        rewardsCutieGenome = p.rewardsCutie[index].genome;
        rewardsCutieGeneration = p.rewardsCutie[index].generation;
    }

    function getLotNftMintRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsNFTMintNftKind
    )
    {
        Lot storage p = lots[lotId];
        rewardsNFTMintNftKind = p.rewardsNftMint[index];
    }

    function getLotToken1155RewardCount(uint32 lotId) external view returns (uint)
    {
        return lots[lotId].rewardsToken1155.length;
    }
    function getLotCutieRewardCount(uint32 lotId) external view returns (uint)
    {
        return lots[lotId].rewardsCutie.length;
    }
    function getLotNftMintRewardCount(uint32 lotId) external view returns (uint)
    {
        return lots[lotId].rewardsNftMint.length;
    }

    function deleteRewards(uint32 lotId) external onlyOwner
    {
        delete lots[lotId].rewardsToken1155;
        delete lots[lotId].rewardsNftMint;
        delete lots[lotId].rewardsNftFixed;
        delete lots[lotId].rewardsCutie;
        emit LotChange(lotId);
    }

    function bidWithPlugin(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent) external payable onlyOperator
    {
        _bid(lotId, purchaser, valueForEvent, tokenForEvent, address(0x0));
    }

    function bidWithPluginReferrer(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent, address referrer) external payable onlyOperator
    {
        _bid(lotId, purchaser, valueForEvent, tokenForEvent, referrer);
    }

    function _bid(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent, address referrer) internal whenNotPaused
    {
        Lot storage p = lots[lotId];
        require(isAvailable(lotId), "Lot is not available");

        if (referrer == address(0x0))
        {
            emit BidReferrer(purchaser, lotId, valueForEvent, tokenForEvent, referrer);
        }
        else
        {
            emit Bid(purchaser, lotId, valueForEvent, tokenForEvent);
        }

        p.leftCount--;
        p.price += uint128(uint256(p.price)*p.priceMul / 1000000);
        p.price += p.priceAdd;

        issueRewards(p, purchaser);

        if (referrers[referrer] > 0)
        {
            uint referrerValue = valueForEvent * referrers[referrer] / 100;
            referrer.transfer(referrerValue);
        }
    }

    function issueRewards(Lot storage p, address purchaser) internal
    {
        uint i;
        for (i = 0; i < p.rewardsToken1155.length; i++)
        {
            mintToken1155(purchaser, p.rewardsToken1155[i]);
        }
        if (p.rewardsNftFixed.length > 0)
        {
            transferNFT(purchaser, p.rewardsNftFixed[p.rewardsNftFixed.length-1]);
            p.rewardsNftFixed.length--;
        }
        for (i = 0; i < p.rewardsNftMint.length; i++)
        {
            mintNFT(purchaser, p.rewardsNftMint[i]);
        }
        for (i = 0; i < p.rewardsCutie.length; i++)
        {
            mintCutie(purchaser, p.rewardsCutie[i]);
        }
    }

    function mintToken1155(address purchaser, RewardToken1155 storage reward) internal
    {
        token1155.mintFungibleSingle(reward.tokenId, purchaser, reward.count);
    }

    function mintNFT(address purchaser, uint128 nftKind) internal
    {
        token1155.mintNonFungibleSingleShort(nftKind, purchaser);
    }

    function transferNFT(address purchaser, RewardNFT storage reward) internal
    {
        uint tokenId = (uint256(reward.nftKind) << 128) | (1 << 255) | reward.tokenIndex;
        token1155.safeTransferFrom(address(this), purchaser, tokenId, 1, "");
    }

    function mintCutie(address purchaser, RewardCutie storage reward) internal
    {
        cutieGenerator.generateSingle(reward.genome, reward.generation, purchaser);
    }

    function destroyContract() external onlyOwner {
        require(address(this).balance == 0);
        selfdestruct(msg.sender);
    }

     
    function() external payable {
        revert();
    }

     
    function withdrawEthFromBalance(uint value) external onlyOwner
    {
        uint256 total = address(this).balance;
        if (total > value)
        {
            total = value;
        }

        msg.sender.transfer(total);
    }

    function bidNative(uint32 lotId, address referrer) external payable
    {
        Lot storage lot = lots[lotId];
        require(lot.price <= msg.value, "Not enough value provided");
        require(lot.lotKind == NATIVE, "Lot kind should be NATIVE");

        _bid(lotId, msg.sender, msg.value, address(0x0), referrer);
    }

    function bid(uint32 lotId, uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s) external payable
    {
        bidReferrer(lotId, rate, expireAt, _v, _r, _s, address(0x0));
    }

    function bidReferrer(uint32 lotId, uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s, address referrer) public payable
    {
        Lot storage lot = lots[lotId];
        require(lot.lotKind == RATE_SIGN, "Lot kind should be RATE_SIGN");

        require(isValidSignature(rate, expireAt, _v, _r, _s));
        require(expireAt >= now, "Rate sign is expired");


        uint priceInWei = rate * lot.price;
        require(priceInWei <= msg.value, "Not enough value provided");

        _bid(lotId, msg.sender, priceInWei, address(0x0), referrer);
    }

    function setSigner(address _newSigner) public onlyOwner {
        signerAddress = _newSigner;
    }

    function isValidSignature(uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s) public view returns (bool)
    {
        return getSigner(rate, expireAt, _v, _r, _s) == signerAddress;
    }

    function getSigner(uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address)
    {
        bytes32 msgHash = hashArguments(rate, expireAt);
        return ecrecover(msgHash, _v, _r, _s);
    }

     
    function hashArguments(uint rate, uint expireAt) public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(rate, expireAt));
    }

    function isERC1155TokenReceiver() external view returns (bytes4) {
        return bytes4(keccak256("isERC1155TokenReceiver()"));
    }

    function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external returns(bytes4)
    {
        return bytes4(keccak256("acrequcept_batch_erc1155_tokens()"));
    }

    function onERC1155Received(address, address, uint256, uint256, bytes) external returns(bytes4)
    {
        return bytes4(keccak256("accept_erc1155_tokens()"));
    }

     
    function setReferrer(address _address, uint _percent) external onlyOwner
    {
        require(_percent < 100);
        referrers[_address] = _percent;
    }

    function removeReferrer(address _address) external onlyOwner
    {
        delete referrers[_address];
    }

    function decreaseCount(uint32 lotId) external onlyOperator
    {
        Lot storage p = lots[lotId];
        if (p.leftCount > 0)
        {
            p.leftCount--;
        }

        emit LotChange(lotId);
    }
}