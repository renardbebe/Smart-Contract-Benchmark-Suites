 

pragma solidity ^0.5.0;
 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setup() public;

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
 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}
 
contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
     
}

 
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
contract VitalikSteward {
    
     
    using SafeMath for uint256;
    
    uint256 public price;  
    IERC721Full public assetToken;  
    
    uint256 public totalCollected;  
    uint256 public currentCollected;  
    uint256 public timeLastCollected;  
    uint256 public deposit;

    address payable public organization;  
    uint256 public organizationFund;
    
    mapping (address => bool) public patrons;
    mapping (address => uint256) public timeHeld;

    uint256 public timeAcquired;
    
     
    uint256 patronageNumerator = 300000000000;
    uint256 patronageDenominator = 1000000000000;

    enum StewardState { Foreclosed, Owned }
    StewardState public state;

    constructor(address payable _organization, address _assetToken) public {
        assetToken = IERC721Full(_assetToken);
        assetToken.setup();
        organization = _organization;
        state = StewardState.Foreclosed;
    } 

    event LogBuy(address indexed owner, uint256 indexed price);
    event LogPriceChange(uint256 indexed newPrice);
    event LogForeclosure(address indexed prevOwner);
    event LogCollection(uint256 indexed collected);
    
    modifier onlyPatron() {
        require(msg.sender == assetToken.ownerOf(42), "Not patron");
        _;
    }

    modifier onlyReceivingOrganization() {
        require(msg.sender == organization, "Not organization");
        _;
    }

    modifier collectPatronage() {
       _collectPatronage(); 
       _;
    }

    function changeReceivingOrganization(address payable _newReceivingOrganization) public onlyReceivingOrganization {
        organization = _newReceivingOrganization;
    }

     
    function patronageOwed() public view returns (uint256 patronageDue) {
        return price.mul(now.sub(timeLastCollected)).mul(patronageNumerator)
            .div(patronageDenominator).div(365 days);
    }

    function patronageOwedWithTimestamp() public view returns (uint256 patronageDue, uint256 timestamp) {
        return (patronageOwed(), now);
    }

    function foreclosed() public view returns (bool) {
         
         
         
        uint256 collection = patronageOwed();
        if(collection >= deposit) {
            return true;
        } else {
            return false;
        }
    }

     
    function depositAbleToWithdraw() public view returns (uint256) {
        uint256 collection = patronageOwed();
        if(collection >= deposit) {
            return 0;
        } else {
            return deposit.sub(collection);
        }
    }

     
    function foreclosureTime() public view returns (uint256) {
         
        uint256 pps = price.mul(patronageNumerator).div(patronageDenominator).div(365 days);
        return now + depositAbleToWithdraw().div(pps);  
    }

     
    function _collectPatronage() public {
         
        if (state == StewardState.Owned) {
            uint256 collection = patronageOwed();
            
             
            if (collection >= deposit) {
                 
                timeLastCollected = timeLastCollected.add(((now.sub(timeLastCollected)).mul(deposit).div(collection)));
                collection = deposit;  

                _foreclose();
            } else  {
                 
                timeLastCollected = now;
                currentCollected = currentCollected.add(collection);
            }
            
            deposit = deposit.sub(collection);
            totalCollected = totalCollected.add(collection);
            organizationFund = organizationFund.add(collection);
            emit LogCollection(collection);
        }
    }
    
     
    function depositWei() public payable collectPatronage {
        require(state != StewardState.Foreclosed, "Foreclosed");
        deposit = deposit.add(msg.value);
    }
    
    function buy(uint256 _newPrice) public payable collectPatronage {
        require(_newPrice > 0, "Price is zero");
        require(msg.value > price, "Not enough");  
        address currentOwner = assetToken.ownerOf(42);

        if (state == StewardState.Owned) {
            uint256 totalToPayBack = price;
            if(deposit > 0) {
                totalToPayBack = totalToPayBack.add(deposit);
            }  
    
             
            address payable payableCurrentOwner = address(uint160(currentOwner));
            payableCurrentOwner.transfer(totalToPayBack);
        } else if(state == StewardState.Foreclosed) {
            state = StewardState.Owned;
            timeLastCollected = now;
        }
        
        deposit = msg.value.sub(price);
        transferAssetTokenTo(currentOwner, msg.sender, _newPrice);
        emit LogBuy(msg.sender, _newPrice);
    }

    function changePrice(uint256 _newPrice) public onlyPatron collectPatronage {
        require(state != StewardState.Foreclosed, "Foreclosed");
        require(_newPrice != 0, "Incorrect Price");
        
        price = _newPrice;
        emit LogPriceChange(price);
    }
    
    function withdrawDeposit(uint256 _wei) public onlyPatron collectPatronage returns (uint256) {
        _withdrawDeposit(_wei);
    }

    function withdrawOrganizationFunds() public {
        require(msg.sender == organization, "Not organization");
        organization.transfer(organizationFund);
        organizationFund = 0;
    }

    function exit() public onlyPatron collectPatronage {
        _withdrawDeposit(deposit);
    }

     

    function _withdrawDeposit(uint256 _wei) internal {
         
        require(deposit >= _wei, 'Withdrawing too much');

        deposit = deposit.sub(_wei);
        msg.sender.transfer(_wei);  

        if(deposit == 0) {
            _foreclose();
        }
    }

    function _foreclose() internal {
         
        address currentOwner = assetToken.ownerOf(42);
        transferAssetTokenTo(currentOwner, address(this), 0);
        state = StewardState.Foreclosed;
        currentCollected = 0;

        emit LogForeclosure(currentOwner);
    }

    function transferAssetTokenTo(address _currentOwner, address _newOwner, uint256 _newPrice) internal {
         
        timeHeld[_currentOwner] = timeHeld[_currentOwner].add((timeLastCollected.sub(timeAcquired)));
        
        assetToken.transferFrom(_currentOwner, _newOwner, 42);

        price = _newPrice;
        timeAcquired = now;
        patrons[_newOwner] = true;
    }
}