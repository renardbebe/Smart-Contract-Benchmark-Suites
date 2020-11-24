 

pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

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

contract IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);

    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transfer(address to, uint256 tokenId) public;

    function transferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}
contract buyNFTInterface {
    struct Price {
        address payable tokenOwner;
        uint256 Price;
        uint256 fee;
        uint isHightlight;
    }
    function getTokenPrice(address _game, uint256 _tokenId) public
    returns (address _tokenOwner, uint256 _Price, uint256 _fee, uint _isHightlight);

    function ownerOf(address _game, uint256 _tokenId) public view returns (address);

    function balanceOf() public view returns (uint256);

    function getApproved(address _game, uint256 _tokenId) public view returns (address);

    function calFee(address _game, uint256 _price) public view returns (uint256);

    function calFeeHightLight(address _game, uint256 _tokenId, uint _isHightLight) public view returns (uint256);

    function calPrice(address _game, uint256 _tokenId, uint256 _Price, uint _isHightLight) public view returns(uint256 _Need);

    function setPriceFee(address _game, uint256 _tokenId, uint256 _Price, uint _isHightLight) public payable;

    function removePrice(address _game, uint256 _tokenId) public;

    function setLimitFee(address _game, uint256 _Fee, uint256 _limitFee, uint256 _hightLightFee) public;
    function withdraw(uint256 amount) public;
    function revenue() public view returns (uint256);
    function buy(address _game, uint256 tokenId) public payable;
    function buyWithoutCheckApproved(address _game, uint256 tokenId) public payable;
    function buyFromSmartcontractViaTransfer(address _game, uint256 _tokenId) public payable;
}

contract BuyNFTProxy is Ownable {
    string[] public cryptoSymbols;
    mapping(string => address) public CryptoCurrencies;
    struct Price {
        string crypto;
        address payable tokenOwner;
        uint256 Price;
        uint256 fee;
        uint isHightlight;
    }
    constructor() public {
        CryptoCurrencies['ETH'] = address(0xEC163d78d9904C9B0FD808383BA92BE3F56f28cE);
        cryptoSymbols.push('ETH');
    }
    modifier isOwnerOf(address _game, uint256 _tokenId) {
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.ownerOf(_tokenId) == msg.sender);
        _;
    }
    function getCryptoSymbols() public view returns(string[] memory) {
        return cryptoSymbols;
    }
    function addCryptoCurrencies(string memory _crypto, address _cryptoAddress) public {
        if(CryptoCurrencies[_crypto] == address(0x0000000000000000000000000000000000000000)) cryptoSymbols.push(_crypto);
        CryptoCurrencies[_crypto] = address(_cryptoAddress);
    }
    function getTokenPrice(address _game, uint256 _tokenId) public
    returns (string memory _crypto, address _tokenOwner, uint256 _Price, uint256 _fee, uint _isHightlight){
        for(uint i = 0; i < cryptoSymbols.length; i++) {
            buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[cryptoSymbols[i]]);
            (_tokenOwner, _Price, _fee, _isHightlight) = cripto.getTokenPrice(_game, _tokenId);
            _crypto = cryptoSymbols[i];
            if(_Price > 0) break;
        }
    }
    function calFee(string memory _crypto, address _game, uint256 _price) public view returns (uint256){
        buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[_crypto]);
        return cripto.calFee(_game, _price);
    }
    function calPrice(string memory _crypto, address _game, uint256 _tokenId, uint256 _Price, uint _isHightLight) public view returns(uint256 _Need){
        buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[_crypto]);
        return cripto.calPrice(_game, _tokenId, _Price, _isHightLight);
    }
    function calFeeHightLight(string memory _crypto, address _game, uint256 _tokenId, uint _isHightLight) public view returns (uint256){
        buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[_crypto]);
        return cripto.calFeeHightLight(_game, _tokenId, _isHightLight);
    }

    function revenue(string memory _crypto) public view returns (uint256){
        buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[_crypto]);
        return cripto.revenue();
    }

    function ownerOf(string memory _crypto, address _game, uint256 _tokenId) public view returns (address) {
        buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[_crypto]);
        return cripto.ownerOf(_game, _tokenId);
    }
    function balanceOf(string memory _crypto) public view returns (uint256){
        buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[_crypto]);
        return cripto.balanceOf();
    }
    function getApproved(string memory _crypto, address _game, uint256 _tokenId) public view returns (address){
        buyNFTInterface cripto = buyNFTInterface(CryptoCurrencies[_crypto]);
        return cripto.getApproved(_game, _tokenId);
    }
}