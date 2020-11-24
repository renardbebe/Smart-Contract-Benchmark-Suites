 

pragma solidity 0.5.13;
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
 
contract ERC20BasicInterface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals;
}

contract BuyNFTByStableCoin is Ownable {

    using SafeMath for uint256;
    address public ceoAddress = address(0xFce92D4163AA532AA096DE8a3C4fEf9f875Bc55F);
    ERC20BasicInterface public hbwalletToken = ERC20BasicInterface(0xEc7ba74789694d0d03D458965370Dc7cF2FE75Ba);
    ERC20BasicInterface public erc20 = ERC20BasicInterface(0x6B175474E89094C44Da98b954EedeAC495271d0F);  

     
     
     
     

    uint256 public Percen = 1000;
    uint256 public hightLightFee = 5 ether;
    struct Price {
        address payable tokenOwner;
        uint256 Price;
        uint256 fee;
        uint isHightlight;
    }
    struct Game {
        mapping(uint256 => Price) tokenPrice;
        uint[] tokenIdSale;
        uint256 Fee;
        uint256 PercenDiscountOnHBWallet;
        uint256 limitHBWALLETForDiscount;
        uint256 limitFee;
    }

    mapping(address => Game) public Games;
    address[] public arrGames;
    constructor() public {
        arrGames = [
        0x06012c8cf97BEaD5deAe237070F9587f8E7A266d,
        0x1276dce965ADA590E42d62B3953dDc1DDCeB0392,
        0xE60D2325f996e197EEdDed8964227a0c6CA82D0f,
        0xECd6b4A2f82b0c9FB283A4a8a1ef5ADf555f794b,
        0xf26A23019b4699068bb54457f32dAFCF22A9D371,
        0x8c9b261Faef3b3C2e64ab5E58e04615F8c788099,
        0x6EbeAf8e8E946F0716E6533A6f2cefc83f60e8Ab,
        0x5D00d312e171Be5342067c09BaE883f9Bcb2003B,
        0xBfdE6246Df72d3ca86419628CaC46a9d2B60393C,
        0x543EcFB0d28fA40D639494957e7cBA52460F490E,
        0xF5b0A3eFB8e8E4c201e2A935F110eAaF3FFEcb8d,
        0xbc5370374FE08d699cf7fcd2e625A93BF393cCC4,
        0x31AF195dB332bc9203d758C74dF5A5C5e597cDb7,
        0x1a94fce7ef36Bc90959E206bA569a12AFBC91ca1,
        0x30a2fA3c93Fb9F93D1EFeFfd350c6A6BB62ba000,
        0x69A1d45318dE72d6Add20D4952398901E0E4a8e5,
        0x4F41d10F7E67fD16bDe916b4A6DC3Dd101C57394
        ];
        for(uint i = 0; i< arrGames.length; i++) {
            Games[arrGames[i]].Fee = 50;
            Games[arrGames[i]].PercenDiscountOnHBWallet = 25;
            Games[arrGames[i]].limitHBWALLETForDiscount = 200;
            Games[arrGames[i]].limitFee = 250 finney;
        }

         
         
         
         
         
    }

    function getTokenPrice(address _game, uint256 _tokenId) public
    returns (address _tokenOwner, uint256 _Price, uint256 _fee, uint _isHightlight) {
        IERC721 erc721Address = IERC721(_game);
        if(erc721Address.ownerOf(_tokenId) != Games[_game].tokenPrice[_tokenId].tokenOwner
        && erc721Address.ownerOf(_tokenId) != address(this)) resetPrice(_game, _tokenId);
        return (Games[_game].tokenPrice[_tokenId].tokenOwner,
        Games[_game].tokenPrice[_tokenId].Price,
        Games[_game].tokenPrice[_tokenId].fee,
        Games[_game].tokenPrice[_tokenId].isHightlight);
    }
    function getArrGames() public view returns(address[] memory){
        return arrGames;
    }
     
    modifier onlyCeoAddress() {
        require(msg.sender == ceoAddress);
        _;
    }
    modifier isOwnerOf(address _game, uint256 _tokenId) {
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.ownerOf(_tokenId) == msg.sender);
        _;
    }
    event _setPrice(address _game, uint256 _tokenId, uint256 _Price, uint _isHightLight, uint8 _type);
    event _resetPrice(address _game, uint256 _tokenId);
    function ownerOf(address _game, uint256 _tokenId) public view returns (address){
        IERC721 erc721Address = IERC721(_game);
        return erc721Address.ownerOf(_tokenId);
    }

    function balanceOf() public view returns (uint256){
        return address(this).balance;
    }

    function getApproved(address _game, uint256 _tokenId) public view returns (address){
        IERC721 erc721Address = IERC721(_game);
        return erc721Address.getApproved(_tokenId);
    }

    function setPrice(address _game, uint256 _tokenId, uint256 _price, uint256 _fee, uint _isHightLight) internal {
        Games[_game].tokenPrice[_tokenId] = Price(msg.sender, _price, _fee, _isHightLight);
        Games[_game].tokenIdSale.push(_tokenId);
        bool flag = false;
        for(uint i = 0; i< arrGames.length; i++) {
            if(arrGames[i] == _game) flag = true;
        }
        if(!flag) arrGames.push(_game);
    }

    function calFee(address _game, uint256 _price) public view returns (uint256){
        uint256 senderHBBalance = hbwalletToken.balanceOf(msg.sender);
        uint256 fee =_price.mul(Games[_game].Fee).div(Percen);
        if(senderHBBalance >= Games[_game].limitHBWALLETForDiscount) fee = _price.mul(Games[_game].PercenDiscountOnHBWallet).div(Percen);
        return fee;
    }
    function calFeeHightLight(address _game, uint256 _tokenId, uint _isHightLight) public view returns (uint256){
        uint256 _hightLightFee = 0;
        if (_isHightLight == 1 && (Games[_game].tokenPrice[_tokenId].Price == 0 || Games[_game].tokenPrice[_tokenId].isHightlight != 1)) {
            _hightLightFee = hightLightFee;
        }
        return _hightLightFee;
    }
    function calPrice(address _game, uint256 _tokenId, uint256 _Price, uint _isHightLight) public view
    returns(uint256 _Need) {
        uint256 fee;
        uint256 _hightLightFee = calFeeHightLight(_game, _tokenId, _isHightLight);
        uint256 Need;
        uint256 totalFee;
        if (Games[_game].tokenPrice[_tokenId].Price < _Price) {
            fee = calFee(_game, _Price.sub(Games[_game].tokenPrice[_tokenId].Price));
            totalFee = calFee(_game, _Price);
            if(Games[_game].tokenPrice[_tokenId].Price == 0 && fee < Games[_game].limitFee) {
                Need = Games[_game].limitFee.add(_hightLightFee);
            } else if(Games[_game].tokenPrice[_tokenId].Price > 0 && totalFee < Games[_game].limitFee) {
                Need = _hightLightFee;
            } else {
                if(totalFee.add(_hightLightFee) < Games[_game].tokenPrice[_tokenId].fee) Need = 0;
                else Need = totalFee.add(_hightLightFee).sub(Games[_game].tokenPrice[_tokenId].fee);
            }

        } else {
            Need = _hightLightFee;
        }
        return Need;
    }

    function setPriceFee(address _game, uint256 _tokenId, uint256 _price, uint _isHightLight) public isOwnerOf(_game, _tokenId) {
        require(Games[_game].tokenPrice[_tokenId].Price != _price);
        uint256 Need = calPrice(_game, _tokenId, _price, _isHightLight);
        require(erc20.transferFrom(msg.sender, address(this), Need));

        uint256 _hightLightFee = calFeeHightLight(_game, _tokenId, _isHightLight);
        uint fee;
        if (Games[_game].tokenPrice[_tokenId].Price < _price) {
            fee = calFee(_game, _price.sub(Games[_game].tokenPrice[_tokenId].Price));
            uint256 totalFee = calFee(_game, _price);
            if(Games[_game].tokenPrice[_tokenId].Price == 0 && fee < Games[_game].limitFee) {

                fee = Games[_game].limitFee;
            } else if(Games[_game].tokenPrice[_tokenId].Price > 0 && totalFee < Games[_game].limitFee) {

                fee = 0;
            } else {
                if(totalFee.add(_hightLightFee) < Games[_game].tokenPrice[_tokenId].fee) fee = 0;
                else fee = totalFee.sub(Games[_game].tokenPrice[_tokenId].fee);
            }
            fee = fee.add(Games[_game].tokenPrice[_tokenId].fee);
        } else {
            fee = Games[_game].tokenPrice[_tokenId].fee;
        }

        setPrice(_game, _tokenId, _price, fee, _isHightLight);
        emit _setPrice(_game, _tokenId, _price, _isHightLight, 1);
    }
    function removePrice(address _game, uint256 _tokenId) public isOwnerOf(_game, _tokenId){
        erc20.transfer(Games[_game].tokenPrice[_tokenId].tokenOwner, Games[_game].tokenPrice[_tokenId].fee);
        if(Games[_game].tokenPrice[_tokenId].tokenOwner == address(this)) {
            IERC721 erc721Address = IERC721(_game);
            erc721Address.transfer(Games[_game].tokenPrice[_tokenId].tokenOwner, _tokenId);
        }
        resetPrice(_game, _tokenId);
    }

    function setLimitFee(address _game, uint256 _Fee, uint256 _limitFee, uint256 _hightLightFee,
        uint256 _PercenDiscountOnHBWallet, uint256  _limitHBWALLETForDiscount) public onlyOwner {
        require(_Fee >= 0 && _limitFee >= 0 && _hightLightFee >= 0);
        Games[_game].Fee = _Fee;
        Games[_game].limitFee = _limitFee;
        Games[_game].PercenDiscountOnHBWallet = _PercenDiscountOnHBWallet;
        Games[_game].limitHBWALLETForDiscount = _limitHBWALLETForDiscount;
        hightLightFee = _hightLightFee;
    }
    function setLimitFeeAll(address[] memory _game, uint256[] memory _Fee, uint256[] memory _limitFee, uint256 _hightLightFee,
        uint256[] memory _PercenDiscountOnHBWallet, uint256[]  memory _limitHBWALLETForDiscount) public onlyOwner {
        require(_game.length == _Fee.length);
        for(uint i = 0; i < _game.length; i++){
            require(_Fee[i] >= 0 && _limitFee[i] >= 0);
            Games[_game[i]].Fee = _Fee[i];
            Games[_game[i]].limitFee = _limitFee[i];
            Games[_game[i]].PercenDiscountOnHBWallet = _PercenDiscountOnHBWallet[i];
            Games[_game[i]].limitHBWALLETForDiscount = _limitHBWALLETForDiscount[i];
        }

        hightLightFee = _hightLightFee;
    }
    function withdraw(uint256 amount) public onlyCeoAddress {
        _withdraw(amount);
    }
    function _withdraw(uint256 amount) internal {
        require(erc20.balanceOf(address(this)) >= amount);
        if(amount > 0) {
            erc20.transfer(msg.sender, amount);
        }
    }

    function cancelBusinessByGameId(address _game, uint256 _tokenId) private {
        IERC721 erc721Address = IERC721(_game);
        if (Games[_game].tokenPrice[_tokenId].tokenOwner == erc721Address.ownerOf(_tokenId)
        || Games[_game].tokenPrice[_tokenId].tokenOwner == address(this)) {

            uint256 amount = Games[_game].tokenPrice[_tokenId].fee;
            if(Games[_game].tokenPrice[_tokenId].isHightlight == 1) amount = amount.add(hightLightFee);
            if( amount > 0 && erc20.balanceOf(address(this)) >= amount) {
                erc20.transfer(Games[_game].tokenPrice[_tokenId].tokenOwner, amount);
            }
            if(Games[_game].tokenPrice[_tokenId].tokenOwner == address(this)) erc721Address.transfer(Games[_game].tokenPrice[_tokenId].tokenOwner, _tokenId);
            resetPrice(_game, _tokenId);
        }
    }

    function cancelBusinessByGame(address _game) private {
        uint256[] memory _arrTokenId = Games[_game].tokenIdSale;
        for (uint i = 0; i < _arrTokenId.length; i++) {
            cancelBusinessByGameId(_game, _arrTokenId[i]);
        }

    }
    function cancelBussiness() public onlyCeoAddress {
        for(uint j = 0; j< arrGames.length; j++) {
            address _game = arrGames[j];
            cancelBusinessByGame(_game);
        }
        _withdraw(address(this).balance);
    }

    function revenue() public view returns (uint256){
        uint256 fee;
        for(uint j = 0; j< arrGames.length; j++) {
            address _game = arrGames[j];
            IERC721 erc721Address = IERC721(arrGames[j]);
            for (uint i = 0; i < Games[_game].tokenIdSale.length; i++) {
                uint256 _tokenId = Games[_game].tokenIdSale[i];
                if (Games[_game].tokenPrice[_tokenId].tokenOwner == erc721Address.ownerOf(_tokenId)) {

                    fee = fee.add(Games[_game].tokenPrice[_tokenId].fee);
                    if(Games[_game].tokenPrice[_tokenId].isHightlight == 1) fee = fee.add(hightLightFee);
                }
            }
        }

        uint256 amount = erc20.balanceOf(address(this)).sub(fee);
        return amount;
    }

    function changeCeo(address _address) public onlyCeoAddress {
        require(_address != address(0));
        ceoAddress = _address;

    }

    function buy(address _game, uint256 tokenId) public payable {
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.getApproved(tokenId) == address(this));
        require(Games[_game].tokenPrice[tokenId].Price > 0);
        require(erc20.transferFrom(msg.sender, Games[_game].tokenPrice[tokenId].tokenOwner, Games[_game].tokenPrice[tokenId].Price));

        erc721Address.transferFrom(Games[_game].tokenPrice[tokenId].tokenOwner, msg.sender, tokenId);
        resetPrice(_game, tokenId);
    }

    function buyWithoutCheckApproved(address _game, uint256 tokenId) public payable {
        IERC721 erc721Address = IERC721(_game);
        require(Games[_game].tokenPrice[tokenId].Price > 0);
        require(erc20.transferFrom(msg.sender, Games[_game].tokenPrice[tokenId].tokenOwner, Games[_game].tokenPrice[tokenId].Price));

        erc721Address.transferFrom(Games[_game].tokenPrice[tokenId].tokenOwner, msg.sender, tokenId);
        resetPrice(_game, tokenId);
    }

    function buyFromSmartcontractViaTransfer(address _game, uint256 _tokenId) public payable {
        IERC721 erc721Address = IERC721(_game);
        require(erc721Address.ownerOf(_tokenId) == address(this));
        require(erc20.transferFrom(msg.sender, Games[_game].tokenPrice[_tokenId].tokenOwner, Games[_game].tokenPrice[_tokenId].Price));

        erc721Address.transfer(msg.sender, _tokenId);
        resetPrice(_game, _tokenId);
    }
     
     
    function _burnArrayTokenIdSale(address _game, uint256 index)  internal {
        if (index >= Games[_game].tokenIdSale.length) return;

        for (uint i = index; i<Games[_game].tokenIdSale.length-1; i++){
            Games[_game].tokenIdSale[i] = Games[_game].tokenIdSale[i+1];
        }
        delete Games[_game].tokenIdSale[Games[_game].tokenIdSale.length-1];
        Games[_game].tokenIdSale.length--;
    }

    function resetPrice(address _game, uint256 _tokenId) private {
        Games[_game].tokenPrice[_tokenId] = Price(address(0), 0, 0, 0);
        for (uint8 i = 0; i < Games[_game].tokenIdSale.length; i++) {
            if (Games[_game].tokenIdSale[i] == _tokenId) {
                _burnArrayTokenIdSale(_game, i);
            }
        }
        emit _resetPrice(_game, _tokenId);
    }
}