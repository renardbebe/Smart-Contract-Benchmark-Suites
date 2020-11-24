 

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;

interface BlockchainCutiesERC1155Interface
{
    function mintNonFungibleSingleShort(uint128 _type, address _to) external;
    function mintNonFungibleSingle(uint256 _type, address _to) external;
    function mintNonFungibleShort(uint128 _type, address[] calldata _to) external;
    function mintNonFungible(uint256 _type, address[] calldata _to) external;
    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external;
    function mintFungible(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external;
    function isNonFungible(uint256 _id) external pure returns(bool);
    function ownerOf(uint256 _id) external view returns (address);
    function totalSupplyNonFungible(uint256 _type) view external returns (uint256);
    function totalSupplyNonFungibleShort(uint128 _type) view external returns (uint256);

     
    function uri(uint256 _id) external view returns (string memory);
    function proxyTransfer721(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
    function proxyTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) external;
     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}

pragma solidity ^0.5.0;


pragma solidity ^0.5.0;

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
}



 
contract Pausable is Operators {
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

pragma solidity ^0.5.0;

interface CutieGeneratorInterface
{
    function generate(uint _genome, uint16 _generation, address[] calldata _target) external;
    function generateSingle(uint _genome, uint16 _generation, address _target) external returns (uint40 babyId);
}

pragma solidity ^0.5.0;

 
interface IERC1155TokenReceiver {

     
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

     
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);

     
    function isERC1155TokenReceiver() external view returns (bytes4);
}

pragma solidity ^0.5.0;

 
contract ERC20 {

    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);
}


 
 
contract Sale is Pausable, IERC1155TokenReceiver
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

    BlockchainCutiesERC1155Interface public token1155;
    CutieGeneratorInterface public cutieGenerator;
    address public signerAddress;

    event Bid(address indexed purchaser, uint32 indexed lotId, uint value, address indexed token);
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

    function addRewardNftFixedBulk(uint32 lotId, uint128 nftType, uint128[] calldata tokenIndex) external onlyOperator
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
            uint256 price,
            uint256 left,
            uint256 expireTime,
            uint128 priceMul,
            uint128 priceAdd,
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
        price = p.price;
        left = p.leftCount;
        expireTime = p.expireTime;
        priceAdd = p.priceAdd;
        priceMul = p.priceMul;
        uint i;
        for (i = 0; i < p.rewardsToken1155.length; i++)
        {
            rewardsToken1155tokenId[i] = p.rewardsToken1155[i].tokenId;
            rewardsToken1155count[i] = p.rewardsToken1155[i].count;
        }
        for (i = 0; i < p.rewardsNftMint.length; i++)
        {
            rewardsNFTMintNftKind[i] = p.rewardsNftMint[i];
        }
        for (i = 0; i < p.rewardsNftFixed.length; i++)
        {
            rewardsNFTFixedKind[i] = p.rewardsNftFixed[i].nftKind;
            rewardsNFTFixedIndex[i] = p.rewardsNftFixed[i].tokenIndex;
        }
        for (i = 0; i < p.rewardsCutie.length; i++)
        {
            rewardsCutieGenome[i] = p.rewardsCutie[i].genome;
            rewardsCutieGeneration[i] = p.rewardsCutie[i].generation;
        }
    }

    function deleteRewards(uint32 lotId) external onlyOwner
    {
        delete lots[lotId].rewardsToken1155;
        delete lots[lotId].rewardsNftMint;
        delete lots[lotId].rewardsNftFixed;
        delete lots[lotId].rewardsCutie;
        emit LotChange(lotId);
    }

    function bidWithPlugin(uint32 lotId, uint valueForEvent, address tokenForEvent) external payable onlyOperator
    {
        _bid(lotId, valueForEvent, tokenForEvent);
    }

    function _bid(uint32 lotId, uint valueForEvent, address tokenForEvent) internal whenNotPaused
    {
        Lot storage p = lots[lotId];
        require(isAvailable(lotId), "Lot is not available");

        emit Bid(msg.sender, lotId, valueForEvent, tokenForEvent);

        p.leftCount--;
        p.price += uint128(uint256(p.price)*p.priceMul / 1000000);
        p.price += p.priceAdd;
        uint i;
        for (i = 0; i < p.rewardsToken1155.length; i++)
        {
            mintToken1155(msg.sender, p.rewardsToken1155[i]);
        }
        if (p.rewardsNftFixed.length > 0)
        {
            transferNFT(msg.sender, p.rewardsNftFixed[p.rewardsNftFixed.length-1]);
            p.rewardsNftFixed.length--;
        }

        for (i = 0; i < p.rewardsCutie.length; i++)
        {
            mintCutie(msg.sender, p.rewardsCutie[i]);
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

    function bidNative(uint32 lotId) external payable
    {
        Lot storage lot = lots[lotId];
        require(lot.price <= msg.value, "Not enough value provided");
        require(lot.lotKind == NATIVE, "Lot kind should be NATIVE");

        _bid(lotId, msg.value, address(0x0));
    }

    function bid(uint32 lotId, uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s) external payable
    {
        Lot storage lot = lots[lotId];
        require(lot.lotKind == RATE_SIGN, "Lot kind should be RATE_SIGN");

        require(isValidSignature(rate, expireAt, _v, _r, _s));
        require(expireAt >= now, "Rate sign is expired");


        uint priceInWei = rate * lot.price;
        require(priceInWei <= msg.value, "Not enough value provided");

        _bid(lotId, priceInWei, address(0x0));
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

    function withdrawERC20FromBalance(ERC20 _tokenContract) external onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(msg.sender, balance);
    }

    function withdrawERC1155FromBalance(BlockchainCutiesERC1155Interface _tokenContract, uint tokenId) external onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this), tokenId);
        _tokenContract.safeTransferFrom(address(this), msg.sender, tokenId, balance, "");
    }

    function isERC1155TokenReceiver() external view returns (bytes4) {
        return bytes4(keccak256("isERC1155TokenReceiver()"));
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external returns(bytes4)
    {
        return bytes4(keccak256("acrequcept_batch_erc1155_tokens()"));
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns(bytes4)
    {
        return bytes4(keccak256("accept_erc1155_tokens()"));
    }
}