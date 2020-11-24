 

 

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;


 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

 

pragma solidity ^0.5.0;


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity ^0.5.0;




 
contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
     
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
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

 

 
pragma solidity ^0.5.0;


contract OracleRequest {

    uint256 public EUR_WEI;  

    uint256 public lastUpdate;  

    function ETH_EUR() public view returns (uint256);  

    function ETH_EURCENT() public view returns (uint256);  

}

 

pragma solidity ^0.5.0;


contract PricingStrategy {

    function adjustPrice(uint256 oldprice, uint256 remainingPieces) public view returns (uint256);  

}

 

 
pragma solidity ^0.5.0;




contract Last100PricingStrategy is PricingStrategy {

     
    function adjustPrice(uint256 _oldPrice, uint256 _remainingPieces) public view returns (uint256){
        if (_remainingPieces < 100) {
            return _oldPrice * 110 / 100;
        } else {
            return _oldPrice;
        }
    }
}

 

 
pragma solidity ^0.5.0;








contract OnChainShop is IERC721Receiver {
    using SafeMath for uint256;

    IERC721Full internal cryptostamp;
    OracleRequest internal oracle;
    PricingStrategy internal pricingStrategy;

    address payable public beneficiary;
    address public shippingControl;
    address public tokenAssignmentControl;

    uint256 public priceEurCent;

    bool internal _isOpen = true;

    enum Status{
        Initial,
        Sold,
        ShippingSubmitted,
        ShippingConfirmed
    }

    event AssetSold(address indexed buyer, uint256 indexed tokenId, uint256 priceWei);
    event ShippingSubmitted(address indexed owner, uint256 indexed tokenId, string deliveryInfo);
    event ShippingFailed(address indexed owner, uint256 indexed tokenId, string reason);
    event ShippingConfirmed(address indexed owner, uint256 indexed tokenId);

    mapping(uint256 => Status) public deliveryStatus;

    constructor(OracleRequest _oracle,
        uint256 _priceEurCent,
        address payable _beneficiary,
        address _shippingControl,
        address _tokenAssignmentControl)
    public
    {
        oracle = _oracle;
        require(address(oracle) != address(0x0), "You need to provide an actual Oracle contract.");
        beneficiary = _beneficiary;
        require(address(beneficiary) != address(0x0), "You need to provide an actual beneficiary address.");
        tokenAssignmentControl = _tokenAssignmentControl;
        require(address(tokenAssignmentControl) != address(0x0), "You need to provide an actual tokenAssignmentControl address.");
        shippingControl = _shippingControl;
        require(address(shippingControl) != address(0x0), "You need to provide an actual shippingControl address.");
        priceEurCent = _priceEurCent;
        require(priceEurCent > 0, "You need to provide a non-zero price.");
        pricingStrategy = new Last100PricingStrategy();
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the current benefinicary can call this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyShippingControl() {
        require(msg.sender == shippingControl, "shippingControl key required for this function.");
        _;
    }

    modifier requireOpen() {
        require(isOpen() == true, "This call only works when the shop is open.");
        _;
    }

    modifier requireCryptostamp() {
        require(address(cryptostamp) != address(0x0), "You need to provide an actual Cryptostamp contract.");
        _;
    }

     

    function setCryptostamp(IERC721Full _newCryptostamp)
    public
    onlyBeneficiary
    {
        require(address(_newCryptostamp) != address(0x0), "You need to provide an actual Cryptostamp contract.");
        cryptostamp = _newCryptostamp;
    }

    function setPrice(uint256 _newPriceEurCent)
    public
    onlyBeneficiary
    {
        require(_newPriceEurCent > 0, "You need to provide a non-zero price.");
        priceEurCent = _newPriceEurCent;
    }

    function setBeneficiary(address payable _newBeneficiary)
    public
    onlyBeneficiary
    {
        beneficiary = _newBeneficiary;
    }

    function setOracle(OracleRequest _newOracle)
    public
    onlyBeneficiary
    {
        require(address(_newOracle) != address(0x0), "You need to provide an actual Oracle contract.");
        oracle = _newOracle;
    }

    function setPricingStrategy(PricingStrategy _newPricingStrategy)
    public
    onlyBeneficiary
    {
        require(address(_newPricingStrategy) != address(0x0), "You need to provide an actual PricingStrategy contract.");
        pricingStrategy = _newPricingStrategy;
    }

    function openShop()
    public
    onlyBeneficiary
    requireCryptostamp
    {
        _isOpen = true;
    }

    function closeShop()
    public
    onlyBeneficiary
    {
        _isOpen = false;
    }

     

     
    function isOpen()
    public view
    requireCryptostamp
    returns (bool)
    {
        return _isOpen;
    }

     
     
    function priceWei()
    public view
    returns (uint256)
    {
        return priceEurCent.mul(oracle.EUR_WEI()).div(100);
    }

     
    function()
    external payable
    requireOpen
    {
         
        uint256 curPriceWei = priceWei();
         
        uint256 remaining = cryptostamp.balanceOf(address(this));
        priceEurCent = pricingStrategy.adjustPrice(priceEurCent, remaining);

        require(msg.value >= curPriceWei, "You need to send enough currency to actually pay the item.");
         
        beneficiary.transfer(curPriceWei);
         
        uint256 tokenId = cryptostamp.tokenOfOwnerByIndex(address(this), 0);
        cryptostamp.safeTransferFrom(address(this), msg.sender, tokenId);
        emit AssetSold(msg.sender, tokenId, curPriceWei);
        deliveryStatus[tokenId] = Status.Sold;

         
        if (msg.value > curPriceWei) {
            msg.sender.transfer(msg.value.sub(curPriceWei));
        }
    }

     

     
     
    function shipToMe(string memory _deliveryInfo, uint256 _tokenId)
    public
    requireOpen
    {
        require(cryptostamp.ownerOf(_tokenId) == msg.sender, "You can only request shipping for your own tokens.");
        require(deliveryStatus[_tokenId] == Status.Sold, "Shipping was already requested for this token or it was not sold by this shop.");
        emit ShippingSubmitted(msg.sender, _tokenId, _deliveryInfo);
        deliveryStatus[_tokenId] = Status.ShippingSubmitted;
    }

     
    function confirmShipping(uint256 _tokenId)
    public
    onlyShippingControl
    requireCryptostamp
    {
        deliveryStatus[_tokenId] = Status.ShippingConfirmed;
        emit ShippingConfirmed(cryptostamp.ownerOf(_tokenId), _tokenId);
    }

     
    function rejectShipping(uint256 _tokenId, string memory _reason)
    public
    onlyShippingControl
    requireCryptostamp
    {
        deliveryStatus[_tokenId] = Status.Sold;
        emit ShippingFailed(cryptostamp.ownerOf(_tokenId), _tokenId, _reason);
    }

     

     
     
     
     
     
    function onERC721Received(address  , address _from, uint256  , bytes memory  )
    public
    requireCryptostamp
    returns (bytes4)
    {
        require(_from == beneficiary, "Only the current benefinicary can send assets to the shop.");
        return this.onERC721Received.selector;
    }

     
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }
}