 

 

 

pragma solidity ^0.5.7;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 

pragma solidity ^0.5.7;

 
contract IProperties {
     
    event OwnerChanged(address newOwner);

     
    event ManagerSet(address manager, bool status);

     
    event PropertyCreated(
        uint256 propertyId,
        uint256 allocationCapacity,
        string title,
        string location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT,
        uint256 dateAdded
    );

     
    event PropertyStatusUpdated(uint256 propertyId, uint256 status);

     
    event PropertyInvested(uint256 propertyId, uint256 tokens);

     
    event InvestmentContractStatusSet(address investmentContract, bool status);

     
    event PropertyUpdated(uint256 propertyId);

     
    function changeOwner(address newOwner) external;

     
    function setManager(address manager, bool status) external;

     
    function createProperty(
        uint256 allocationCapacity,
        string memory title,
        string memory location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 totalAllowedATinvestments,
        address AT
    ) public returns (bool);

     
    function updatePropertyStatus(uint256 propertyId, uint256 status) external;

     
    function invest(address investor, uint256 propertyId, uint256 shares)
        public
        returns (bool);

     
    function setInvestmentContractStatus(
        address investmentContract,
        bool status
    ) external;

     
    function getProperty(uint256 propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        );

     
    function getPropertyInvestors(uint256 propertyId, uint256 from, uint256 to)
        public
        view
        returns (address[] memory);

     
    function getTotalAndHolderShares(uint256 propertyId, address holder)
        public
        view
        returns (uint256 totalShares, uint256 holderShares);
}

 

pragma solidity ^0.5.7;



 
contract IERC721Receiver {
     
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
}

library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
 
contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) internal _supportedInterfaces;

     
    constructor() public {
        _registerInterface(_InterfaceId_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}
contract IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;
}
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping(uint256 => address) private _tokenOwner;

     
    mapping(uint256 => address) private _tokenApprovals;

     
    mapping(address => uint256) private _ownedTokensCount;

     
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
     

    constructor() public {
         
        _registerInterface(_InterfaceId_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));

        _clearApproval(from, tokenId);
        _removeTokenFrom(from, tokenId);
        _addTokenTo(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
    {
         
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        transferFrom(from, to, tokenId);
         
        require(_checkAndCallSafeTransfer(from, to, tokenId, _data));
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
         
         
         
        return (
            spender == owner ||
                getApproved(tokenId) == spender ||
                isApprovedForAll(owner, spender)
        );
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        _clearApproval(owner, tokenId);
        _removeTokenFrom(owner, tokenId);
        emit Transfer(owner, address(0), tokenId);
    }

     
    function _clearApproval(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }

     
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }

     
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }

     
    function _checkAndCallSafeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        );
        return (retval == _ERC721_RECEIVED);
    }
}
 

contract Properties is IProperties, ERC721 {
    enum Status {INVESTABLE, UNINVESTABLE}  

    mapping(address => bool) public managers;  
    mapping(address => bool) public investmentContracts;  

     
    struct Property {
        uint256 id;  
        uint256 currentAllocation;  
        string title;  
        string location;  
        uint256 marketValue;  
        uint256 maxInvestedATperInvestor;  
        uint256 allocationCapacity;  
        address AT;  
        uint256 dateAdded;  
        Status status;  
        address[] investors;  
        mapping(address => uint256) investments;  
    }

    mapping(uint256 => Property) public properties;  
    uint256 propertyCount = 0;  

    address public owner;  

     
    constructor() public {
        owner = msg.sender;  
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can call this function");
        _;
    }

     
    modifier onlyManager() {
        require(managers[msg.sender], "Only managers can call this function.");
        _;
    }

     
    modifier onlyInvestmentContracts() {
        require(
            investmentContracts[msg.sender],
            "Only investment contracts are allowed to call this function."
        );
        _;
    }

     
    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0x0), "Owner address is invalid.");
        owner = newOwner;

        emit OwnerChanged(newOwner);
    }

     
    function setManager(address manager, bool status) external onlyOwner {
        require(manager != address(0x0), "Manager address is invalid.");
        require(managers[manager] != status, "Provided status is already set.");

        managers[manager] = status;

        emit ManagerSet(manager, status);
    }

     
    function createProperty(
        uint256 currentAllocation,
        string memory title,
        string memory location,
        uint256 marketValue,
        uint256 maxInvestedATperInvestor,
        uint256 allocationCapacity,
        address AT
    ) public onlyManager returns (bool) {
        propertyCount = propertyCount + 1;

        Property memory newProperty = Property(
            propertyCount,
            currentAllocation,
            title,
            location,
            marketValue,
            maxInvestedATperInvestor,
            allocationCapacity,
            AT,
            now,
            Status.INVESTABLE,
            new address[](0)
        );

        properties[propertyCount] = newProperty;

        emit PropertyCreated(
            propertyCount,
            currentAllocation,
            title,
            location,
            marketValue,
            maxInvestedATperInvestor,
            allocationCapacity,
            AT,
            now
        );

        return true;
    }

     
    function updateProperty(uint256 propertyId, uint256 marketValue, address AT)
        public
        onlyManager
        returns (bool)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property storage property = properties[propertyId];
        property.marketValue = marketValue;
        property.AT = AT;

        emit PropertyUpdated(propertyId);
    }

     
    function updatePropertyStatus(uint256 propertyId, uint256 status)
        external
        onlyManager
    {
        require(propertyId >= 0, "Property ID is invalid.");
        require(
            properties[propertyId].status != Status(status),
            "This status is already set."
        );

        properties[propertyId].status = Status(status);

        emit PropertyStatusUpdated(propertyId, status);
    }

     
    function invest(address investor, uint256 propertyId, uint256 shares)
        public
        onlyInvestmentContracts
        returns (bool)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property storage property = properties[propertyId];

        require(uint8(property.status) == 0, "property is not investable");

        require(
            property.investments[investor].add(shares) <=
                property.maxInvestedATperInvestor,
            "Amount of shares exceed the maximum allowed limit per investor."
        );
        require(
            shares.add(property.currentAllocation) <=
                property.allocationCapacity,
            "Amount of shares exceed the maximum allowed capacity."
        );

        property.currentAllocation = property.currentAllocation.add(shares);

        if (property.investments[investor] == 0) {
            property.investors.push(investor);
        }

        property.investments[investor] = property.investments[investor].add(
            shares
        );

        emit PropertyInvested(propertyId, shares);

        return true;

    }

     
    function setInvestmentContractStatus(
        address investmentContract,
        bool status
    ) external onlyManager {
        require(
            investmentContract != address(0),
            "investmentContract address cannot be zero address."
        );
        require(
            investmentContracts[investmentContract] != status,
            "the status is already set."
        );

        investmentContracts[investmentContract] = status;

        emit InvestmentContractStatusSet(investmentContract, status);
    }

     
    function getProperty(uint256 propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint8
        )
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property memory property = properties[propertyId];

        return (
            property.id,
            property.currentAllocation,
            property.title,
            property.location,
            property.marketValue,
            property.maxInvestedATperInvestor,
            property.allocationCapacity,
            property.AT,
            property.dateAdded,
            uint8(property.status)
        );
    }

     
    function getPropertyInvestors(uint256 propertyId, uint256 from, uint256 to)
        public
        view
        returns (address[] memory)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property memory property = properties[propertyId];

        uint256 length = to - from;

        address[] memory investors = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            investors[i] = property.investors[from + i];
        }

        return investors;
    }

     
    function getTotalAndHolderShares(uint256 propertyId, address holder)
        public
        view
        returns (uint256 totalShares, uint256 holderShares)
    {
        require(propertyId >= 0, "Property ID is invalid.");

        Property storage property = properties[propertyId];

        totalShares = property.allocationCapacity;
        holderShares = property.investments[holder];
    }

}