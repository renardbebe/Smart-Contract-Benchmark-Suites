 

 
 

pragma solidity 0.4.19;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
     
    function withdrawAll() public onlyOwner {
        owner.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) public onlyOwner {
        require(_amount <= this.balance);
        owner.transfer(_amount);
    }

    function contractBalance() public view returns (uint256) {
        return this.balance;
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

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


 
contract ReentrancyGuard {

     
    bool private reentrancyLock = false;

     
    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}


 
contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function takeOwnership(uint256 _tokenId) public;
}


 
 
contract OwnTheDayContract is ERC721, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    event Bought (uint256 indexed _dayIndex, address indexed _owner, uint256 _price);
    event Sold (uint256 indexed _dayIndex, address indexed _owner, uint256 _price);

     
    uint256 private totalTokens;
    bool private migrationFinished = false;

     
    mapping (uint256 => address) public tokenOwner;

     
    mapping (uint256 => address) public tokenApprovals;

     
    mapping (address => uint256[]) public ownedTokens;

     
    mapping(uint256 => uint256) public ownedTokensIndex;

     
     
    mapping (uint256 => uint256) public dayIndexToPrice;

     
     
     

     
    mapping (address => string) public ownerAddressToName;

     
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    modifier onlyDuringMigration() {
        require(!migrationFinished);
        _;
    }

    function name() public pure returns (string _name) {
        return "OwnTheDay.io Days";
    }

    function symbol() public pure returns (string _symbol) {
        return "DAYS";
    }

     
     
    function assignInitialDays(address _to, uint256 _tokenId, uint256 _price) public onlyOwner onlyDuringMigration {
        require(msg.sender != address(0));
        require(_to != address(0));
        require(_tokenId >= 0 && _tokenId < 366);
        require(_price >= 1 finney);
        dayIndexToPrice[_tokenId] = _price;
        _mint(_to, _tokenId);
    }

    function finishMigration() public onlyOwner {
        require(!migrationFinished);
        migrationFinished = true;
    }

    function isMigrationFinished() public view returns (bool) {
        return migrationFinished;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalTokens;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return ownedTokens[_owner].length;
    }

     
    function tokensOf(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        return owner;
    }

     
    function approvedFor(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

     
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        clearApprovalAndTransfer(msg.sender, _to, _tokenId);
    }

     
    function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        if (approvedFor(_tokenId) != 0 || _to != 0) {
            tokenApprovals[_tokenId] = _to;
            Approval(owner, _to, _tokenId);
        }
    }

     
    function takeOwnership(uint256 _tokenId) public {
        require(isApprovedFor(msg.sender, _tokenId));
        clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

     
    function calculateOwnerCut(uint256 _price) public pure returns (uint256) {
        if (_price > 5000 finney) {
            return _price.mul(2).div(100);
        } else if (_price > 500 finney) {
            return _price.mul(3).div(100);
        } else if (_price > 250 finney) {
            return _price.mul(4).div(100);
        }
        return _price.mul(5).div(100);
    }

     
    function calculatePriceIncrease(uint256 _price) public pure returns (uint256) {
        if (_price > 5000 finney) {
            return _price.mul(15).div(100);
        } else if (_price > 2500 finney) {
            return _price.mul(18).div(100);
        } else if (_price > 500 finney) {
            return _price.mul(26).div(100);
        } else if (_price > 250 finney) {
            return _price.mul(36).div(100);
        }
        return _price;  
    }

     
    function getPriceByDayIndex(uint256 _dayIndex) public view returns (uint256) {
        require(_dayIndex >= 0 && _dayIndex < 366);
        uint256 price = dayIndexToPrice[_dayIndex];
        if (price == 0) { price = 1 finney; }
        return price;
    }

     
    function setAccountNickname(string _nickname) public whenNotPaused {
        require(msg.sender != address(0));
        require(bytes(_nickname).length > 0);
        ownerAddressToName[msg.sender] = _nickname;
    }

     
     
    function claimDay(uint256 _dayIndex) public nonReentrant whenNotPaused payable {
        require(msg.sender != address(0));
        require(_dayIndex >= 0 && _dayIndex < 366);

        address buyer = msg.sender;
        address seller = tokenOwner[_dayIndex];
        require(msg.sender != seller);  

        uint256 amountPaid = msg.value;
        uint256 purchasePrice = dayIndexToPrice[_dayIndex];
        if (purchasePrice == 0) {
            purchasePrice = 1 finney;  
        }
        require(amountPaid >= purchasePrice);

         
        uint256 changeToReturn = 0;
        if (amountPaid > purchasePrice) {
            changeToReturn = amountPaid.sub(purchasePrice);
            amountPaid -= changeToReturn;
        }

         
        uint256 priceIncrease = calculatePriceIncrease(purchasePrice);
        uint256 newPurchasePrice = purchasePrice.add(priceIncrease);
        dayIndexToPrice[_dayIndex] = newPurchasePrice;

         
         
         
        uint256 ownerCut = calculateOwnerCut(amountPaid);
        uint256 salePrice = amountPaid.sub(ownerCut);

         
        Bought(_dayIndex, buyer, purchasePrice);
        Sold(_dayIndex, seller, purchasePrice);

         
        if (seller == address(0)) {
            _mint(buyer, _dayIndex);
        } else {
            clearApprovalAndTransfer(seller, buyer, _dayIndex);
        }

         
        if (seller != address(0)) {
            seller.transfer(salePrice);
        }
        if (changeToReturn > 0) {
            buyer.transfer(changeToReturn);
        }
    }

     
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addToken(_to, _tokenId);
        Transfer(0x0, _to, _tokenId);
    }

     
    function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
        return approvedFor(_tokenId) == _owner;
    }

     
    function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_to != ownerOf(_tokenId));
        require(ownerOf(_tokenId) == _from);

        clearApproval(_from, _tokenId);
        removeToken(_from, _tokenId);
        addToken(_to, _tokenId);
        Transfer(_from, _to, _tokenId);
    }

     
    function clearApproval(address _owner, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _owner);
        tokenApprovals[_tokenId] = 0;
        Approval(_owner, 0, _tokenId);
    }

     
    function addToken(address _to, uint256 _tokenId) private {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        uint256 length = balanceOf(_to);
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
        totalTokens = totalTokens.add(1);
    }

     
    function removeToken(address _from, uint256 _tokenId) private {
        require(ownerOf(_tokenId) == _from);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = balanceOf(_from).sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        tokenOwner[_tokenId] = 0;
        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
         
         
         
         

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
        totalTokens = totalTokens.sub(1);
    }
}