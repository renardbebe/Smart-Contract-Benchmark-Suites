 

pragma solidity ^ 0.4.19;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
 
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    function ownerOf(uint256 _tokenId) external view returns(address _owner);

     
    function supportsInterface(bytes4 _interfaceID) external view returns(bool);

    function totalSupply() public view returns(uint256 total);

    function balanceOf(address _owner) public view returns(uint256 _balance);
}

contract AnimecardAccessControl {
     
    event ContractFork(address newContract);

     
     
     
     
    address public ceoAddress;
    address public cfoAddress;
    address public animatorAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyAnimator() {
        require(msg.sender == animatorAddress);
        _;
    }

     
    modifier onlyCLevel() {
        require(
            msg.sender == animatorAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
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

     
     
    function setAnimator(address _newAnimator) external onlyCEO {
        require(_newAnimator != address(0));

        animatorAddress = _newAnimator;
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

     
     
    function destroy() onlyCEO public {
        selfdestruct(ceoAddress);
    }

    function destroyAndSend(address _recipient) onlyCEO public {
        selfdestruct(_recipient);
    }
}

contract AnimecardBase is AnimecardAccessControl {
    using SafeMath
    for uint256;

     

     
    struct Animecard {
         
        string characterName;
         
        string studioName;

         
        string characterImageUrl;
         
        string characterImageHash;
         
        uint64 creationTime;
    }


     
     
    event Birth(address owner, uint256 tokenId, string cardName, string studio);
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
     
    event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 price, address prevOwner, address owner, string cardName);

     
     
     
    Animecard[] animecards;

     
    mapping(uint256 => address) public animecardToOwner;

     
     
    mapping(address => uint256) public ownerAnimecardCount;

     
     
     
    mapping(uint256 => address) public animecardToApproved;

     
    mapping(uint256 => uint256) public animecardToPrice;

     
    mapping(uint256 => uint256) public animecardPrevPrice;

     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
         
        ownerAnimecardCount[_to]++;
        animecardToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
             
            ownerAnimecardCount[_from]--;
             
            delete animecardToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function _createAnimecard(
        string _characterName,
        string _studioName,
        string _characterImageUrl,
        string _characterImageHash,
        uint256 _price,
        address _owner
    )
    internal
    returns(uint) {

        Animecard memory _animecard = Animecard({
            characterName: _characterName,
            studioName: _studioName,
            characterImageUrl: _characterImageUrl,
            characterImageHash: _characterImageHash,
            creationTime: uint64(now)
        });
        uint256 newAnimecardId = animecards.push(_animecard);
        newAnimecardId = newAnimecardId.sub(1);

         
        Birth(
            _owner,
            newAnimecardId,
            _animecard.characterName,
            _animecard.studioName
        );

         
        animecardToPrice[newAnimecardId] = _price;

         
        _transfer(0, _owner, newAnimecardId);

        return newAnimecardId;

    }
}

contract AnimecardPricing is AnimecardBase {

     
     
    uint256 private constant first_step_limit = 0.05 ether;
    uint256 private constant second_step_limit = 0.5 ether;
    uint256 private constant third_step_limit = 2.0 ether;
    uint256 private constant fourth_step_limit = 5.0 ether;


     
    uint256 public platformFee = 50;  

     
    function setPlatformFee(uint256 _val) external onlyAnimator {
        platformFee = _val;
    }

     
    function computeNextPrice(uint256 _salePrice)
    internal
    pure
    returns(uint256) {
        if (_salePrice < first_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 200), 100);
        } else if (_salePrice < second_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 135), 100);
        } else if (_salePrice < third_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 125), 100);
        } else if (_salePrice < fourth_step_limit) {
            return SafeMath.div(SafeMath.mul(_salePrice, 120), 100);
        } else {
            return SafeMath.div(SafeMath.mul(_salePrice, 115), 100);
        }
    }

     
     
    function computePayment(
        uint256 _tokenId,
        uint256 _salePrice)
    internal
    view
    returns(uint256) {
        uint256 prevSalePrice = animecardPrevPrice[_tokenId];

        uint256 profit = _salePrice - prevSalePrice;

        uint256 ownerCut = SafeMath.sub(100, platformFee);
        uint256 ownerProfitShare = SafeMath.div(SafeMath.mul(profit, ownerCut), 100);

        return prevSalePrice + ownerProfitShare;
    }
}

contract AnimecardOwnership is AnimecardPricing, ERC721 {
     
    string public constant NAME = "CryptoAnime";
     
     
    string public constant SYMBOL = "ANM";

    bytes4 public constant INTERFACE_SIGNATURE_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 public constant INTERFACE_SIGNATURE_ERC721 =
        bytes4(keccak256("name()")) ^
        bytes4(keccak256("symbol()")) ^
        bytes4(keccak256("totalSupply()")) ^
        bytes4(keccak256("balanceOf(address)")) ^
        bytes4(keccak256("ownerOf(uint256)")) ^
        bytes4(keccak256("approve(address,uint256)")) ^
        bytes4(keccak256("transfer(address,uint256)")) ^
        bytes4(keccak256("transferFrom(address,address,uint256)")) ^
        bytes4(keccak256("tokensOfOwner(address)")) ^
        bytes4(keccak256("tokenMetadata(uint256,string)"));

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

     
     
     
    function supportsInterface(bytes4 _interfaceID)
    external
    view
    returns(bool) {
        return ((_interfaceID == INTERFACE_SIGNATURE_ERC165) || (_interfaceID == INTERFACE_SIGNATURE_ERC721));
    }

     
    function name() external pure returns(string) {
        return NAME;
    }

     
    function symbol() external pure returns(string) {
        return SYMBOL;
    }

     
     
    function totalSupply() public view returns(uint) {
        return animecards.length;
    }

     
     
     
    function balanceOf(address _owner)
    public
    view
    returns(uint256 count) {
        return ownerAnimecardCount[_owner];
    }

     
     
    function ownerOf(uint256 _tokenId)
    external
    view
    returns(address _owner) {
        _owner = animecardToOwner[_tokenId];
        require(_owner != address(0));
    }

     
     
     
     
     
     
    function approve(address _to, uint256 _tokenId)
    external
    whenNotPaused {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function transfer(address _to, uint256 _tokenId)
    external
    whenNotPaused {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));
         

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId)
    external
    whenNotPaused {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));

         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function tokensOfOwner(address _owner)
    external
    view
    returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalAnimecards = totalSupply();
            uint256 resultIndex = 0;

            uint256 animecardId;
            for (animecardId = 0; animecardId <= totalAnimecards; animecardId++) {
                if (animecardToOwner[animecardId] == _owner) {
                    result[resultIndex] = animecardId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId)
    internal
    view
    returns(bool) {
        return animecardToOwner[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        animecardToApproved[_tokenId] = _approved;
    }

     
     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId)
    internal
    view
    returns(bool) {
        return animecardToApproved[_tokenId] == _claimant;
    }

     
    function _addressNotNull(address _to) internal pure returns(bool) {
        return _to != address(0);
    }

}

contract AnimecardSale is AnimecardOwnership {

     
    function purchase(uint256 _tokenId)
    public
    payable
    whenNotPaused {
        address newOwner = msg.sender;
        address oldOwner = animecardToOwner[_tokenId];
        uint256 salePrice = animecardToPrice[_tokenId];

         
        require(oldOwner != newOwner);

         
        require(_addressNotNull(newOwner));

         
        require(msg.value >= salePrice);

        uint256 payment = uint256(computePayment(_tokenId, salePrice));
        uint256 purchaseExcess = SafeMath.sub(msg.value, salePrice);

         
        animecardPrevPrice[_tokenId] = animecardToPrice[_tokenId];
        animecardToPrice[_tokenId] = computeNextPrice(salePrice);

         
        _transfer(oldOwner, newOwner, _tokenId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

        TokenSold(_tokenId, salePrice, animecardToPrice[_tokenId], oldOwner, newOwner, animecards[_tokenId].characterName);

         
        msg.sender.transfer(purchaseExcess);
    }

    function priceOf(uint256 _tokenId)
    public
    view
    returns(uint256 price) {
        return animecardToPrice[_tokenId];
    }


}

contract AnimecardMinting is AnimecardSale {
     
     
     

     
    function createAnimecard(
        string _characterName,
        string _studioName,
        string _characterImageUrl,
        string _characterImageHash,
        uint256 _price
    )
    public
    onlyAnimator
    returns(uint) {
        uint256 animecardId = _createAnimecard(
            _characterName, _studioName,
            _characterImageUrl, _characterImageHash,
            _price, address(this)
        );

        return animecardId;
    }
}

 
contract AnimecardCore is AnimecardMinting {
     
     
    address public newContractAddress;

    function AnimecardCore() public {
         
        paused = true;

         
        ceoAddress = msg.sender;

         
        animatorAddress = msg.sender;
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address)
    external
    onlyCEO
    whenPaused {
        newContractAddress = _v2Address;
        ContractFork(_v2Address);
    }

     
     
     
     
     
    function withdrawBalance(address _to) external onlyCFO {
         
        if (_to == address(0)) {
            cfoAddress.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

     
     
    function getAnimecard(uint256 _tokenId)
    external
    view
    returns(
        string characterName,
        string studioName,
        string characterImageUrl,
        string characterImageHash,
        uint256 sellingPrice,
        address owner) {
        Animecard storage animecard = animecards[_tokenId];
        characterName = animecard.characterName;
        studioName = animecard.studioName;
        characterImageUrl = animecard.characterImageUrl;
        characterImageHash = animecard.characterImageHash;
        sellingPrice = animecardToPrice[_tokenId];
        owner = animecardToOwner[_tokenId];
    }


     
     
     
     
     
    function unpause()
    public
    onlyCEO
    whenPaused {
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function () external payable {}
}