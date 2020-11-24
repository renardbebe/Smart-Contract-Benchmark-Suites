 

pragma solidity ^0.5.10;

contract UniswapExchangeInterface {
     
    function tokenAddress() external view returns (address token);
     
    function factoryAddress() external view returns (address factory);
     
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
     
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
     
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
     
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
     
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
     
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
     
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
     
    function setup(address token_addr) external;
}

 
contract CardCore {

     
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function approve(address _approved, uint256 _tokenId) external payable;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

     
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);

     
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}




 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}



 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
interface MarbleDutchAuctionInterface {

     
    function setAuctioneerCut(
        uint256 _cut
    )
    external;

     
    function setAuctioneerDelayedCancelCut(
        uint256 _cut
    )
    external;

     
    function setNFTContract(address _nftAddress)
    external;


     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external;

     
    function createMintingAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external;

     
    function cancelAuction(
        uint256 _tokenId
    )
    external;

     
    function cancelAuctionWhenPaused(
        uint256 _tokenId
    )
    external;

     
    function bid(
        uint256 _tokenId
    )
    external
    payable;

     
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint256);

     
    function totalAuctions()
    external
    view
    returns (uint256);

     
    function tokenInAuctionByIndex(
        uint256 _index
    )
    external
    view
    returns (uint256);

     
    function tokenOfSellerByIndex(
        address _seller,
        uint256 _index
    )
    external
    view
    returns (uint256);

     
    function totalAuctionsBySeller(
        address _seller
    )
    external
    view
    returns (uint256);

     
    function isOnAuction(uint256 _tokenId)
    external
    view
    returns (bool isIndeed);

     
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt,
        bool canBeCanceled
    );

     
    function removeAuction(
        uint256 _tokenId
    )
    external;
}


contract WMCMarketplace is Ownable {

     
    using SafeMath for uint256;

     
     
     

     
     
     

    event CardPurchasedWithWMC(uint256 cardId, uint256 wmcSpent);
    event DevFeeUpdated(uint256 newDevFee);

     
     
     



     
     
     

     
    address marbleCoreAddress = 0x1d963688FE2209A98dB35C67A041524822Cf04ff;
    address marbleAuctionAddress = 0x649EfF2dC5d9c5C641260C8B9BedE4770FCCF5E7;
    address wrappedCardsAddress = 0x8AedB297FED4b6884b808ee61fAf0837713670d0;
    address uniswapExchangeAddress = 0xA0db39d28dACeC1974f2a1F6Bac7d33F37C102eC;

    uint256 devFeeInBasisPoints = 375;

     
     
     

    function buyCardWithWMC(uint256 _cardId, uint256 _maxWMCWeiToSpend) external returns (bool) {
         
        bool _WMCTransferToContract = IERC20(wrappedCardsAddress).transferFrom(msg.sender, address(this), _maxWMCWeiToSpend);
         
        require(_WMCTransferToContract, "WMC Transfer was unsuccessful");
         
        uint256 costInWei = getCurrentPrice(_cardId);
         
        uint256 tokensSold = UniswapExchangeInterface(uniswapExchangeAddress).tokenToEthSwapOutput(_computePriceWithDevFee(costInWei), _maxWMCWeiToSpend, ~uint256(0));
         
        MarbleDutchAuctionInterface(marbleAuctionAddress).bid.value(costInWei)(_cardId);
         
        bool _WMCRefundToBuyer = IERC20(wrappedCardsAddress).transfer(msg.sender, _maxWMCWeiToSpend.sub(tokensSold));
         
        require(_WMCRefundToBuyer, "Error processing WMC refund.");
         
        CardCore(marbleCoreAddress).transferFrom(address(this), msg.sender, _cardId);
         
        emit CardPurchasedWithWMC(_cardId, tokensSold);
        return true;
    }

     
    function getCurrentPrice(uint256 _cardId) public view returns (uint256) {
        return MarbleDutchAuctionInterface(marbleAuctionAddress).getCurrentPrice(_cardId);
    }

    function totalAuctions() public view returns (uint256) {
        return MarbleDutchAuctionInterface(marbleAuctionAddress).totalAuctions();
    }

    function getAuction(uint256 _tokenId) public view returns (address seller, uint256 startingPrice,
        uint256 endingPrice, uint256 duration, uint256 startedAt, bool canBeCanceled) {
        return MarbleDutchAuctionInterface(marbleAuctionAddress).getAuction(_tokenId);
    }

    function isOnAuction(uint256 _tokenId) external view returns (bool isIndeed) {
        return MarbleDutchAuctionInterface(marbleAuctionAddress).isOnAuction(_tokenId);
    }

    function tokenOfSellerByIndex(address _seller, uint256 _index) public view returns (uint256) {
        return MarbleDutchAuctionInterface(marbleAuctionAddress).tokenOfSellerByIndex(_seller, _index);
    }

    function totalAuctionsBySeller(address _seller) public view returns (uint256) {
        return MarbleDutchAuctionInterface(marbleAuctionAddress).totalAuctionsBySeller(_seller);
    }

     
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought) {
        return UniswapExchangeInterface(uniswapExchangeAddress).getEthToTokenInputPrice(eth_sold);
    }

    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold) {
        return UniswapExchangeInterface(uniswapExchangeAddress).getEthToTokenOutputPrice(tokens_bought);
    }

    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought) {
        return UniswapExchangeInterface(uniswapExchangeAddress).getTokenToEthInputPrice(tokens_sold);
    }

    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold) {
        return UniswapExchangeInterface(uniswapExchangeAddress).getTokenToEthOutputPrice(eth_bought);
    }

     
    function changeMarbleAuctionAddress(address _auctionContract) public onlyOwner returns (bool) {
        require(isContract(_auctionContract));
        marbleAuctionAddress = _auctionContract;
        return true;
    }

    function transferERC20(address _erc20Address, address _to, uint256 _value) external onlyOwner returns (bool) {
        return IERC20(_erc20Address).transfer(_to, _value);
    }

    function withdrawOwnerEarnings() external onlyOwner returns (bool) {
        msg.sender.transfer(address(this).balance);
        return true;
    }

    function updateFee(uint256 _newFee) external onlyOwner returns (bool) {
        devFeeInBasisPoints = _newFee;
        emit DevFeeUpdated(_newFee);
        return true;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    constructor() public {
        IERC20(wrappedCardsAddress).approve(uniswapExchangeAddress, ~uint256(0));
    }

    function() external payable {}

    function _computePriceWithDevFee(uint256 _costInWei) internal view returns (uint256) {
        return (_costInWei.mul(uint256(10000).add(devFeeInBasisPoints))).div(uint256(10000));
    }
}