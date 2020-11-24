 

pragma solidity ^0.4.22;


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BitGuildToken {
     
    string public name = "BitGuild PLAT";
    string public symbol = "PLAT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals);  

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function BitGuildToken() public {
        balanceOf[msg.sender] = totalSupply;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}


 
contract BitGuildAccessAdmin {
    address public owner;
    address[] public operators;

    uint public MAX_OPS = 20;  

    mapping(address => bool) public isOperator;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyOperator() {
        require(
            isOperator[msg.sender] || msg.sender == owner,
            "Permission denied. Must be an operator or the owner."
        );
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "Invalid new owner address."
        );
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

     
    function addOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "Invalid new operator address."
        );

         
        require(
            !isOperator[_newOperator],
            "New operator exists."
        );

         
        require(
            operators.length < MAX_OPS,
            "Overflow."
        );

        operators.push(_newOperator);
        isOperator[_newOperator] = true;

        emit OperatorAdded(_newOperator);
    }

     
    function removeOperator(address _operator) public onlyOwner {
         
        require(
            operators.length > 0,
            "No operator."
        );

         
        require(
            isOperator[_operator],
            "Not an operator."
        );

         
         
         
        address lastOperator = operators[operators.length - 1];
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                operators[i] = lastOperator;
            }
        }
        operators.length -= 1;  

        isOperator[_operator] = false;
        emit OperatorRemoved(_operator);
    }

     
    function removeAllOps() public onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            isOperator[operators[i]] = false;
        }
        operators.length = 0;
    }
}


 
contract BitGuildWhitelist is BitGuildAccessAdmin {
    uint public total = 0;
    mapping (address => bool) public isWhitelisted;

    event AddressWhitelisted(address indexed addr, address operator);
    event AddressRemovedFromWhitelist(address indexed addr, address operator);

     
    modifier onlyWhitelisted(address _address) {
        require(
            isWhitelisted[_address],
            "Address is not on the whitelist."
        );
        _;
    }

     
    function () external payable {
        revert();
    }

     
    function addToWhitelist(address _newAddr) public onlyOperator {
        require(
            _newAddr != address(0),
            "Invalid new address."
        );

         
        require(
            !isWhitelisted[_newAddr],
            "Address is already whitelisted."
        );

        isWhitelisted[_newAddr] = true;
        total++;
        emit AddressWhitelisted(_newAddr, msg.sender);
    }

     
    function removeFromWhitelist(address _addr) public onlyOperator {
        require(
            _addr != address(0),
            "Invalid address."
        );

         
        require(
            isWhitelisted[_addr],
            "Address not in whitelist."
        );

        isWhitelisted[_addr] = false;
        if (total > 0) {
            total--;
        }
        emit AddressRemovedFromWhitelist(_addr, msg.sender);
    }

     
    function whitelistAddresses(address[] _addresses, bool _whitelisted) public onlyOperator {
        for (uint i = 0; i < _addresses.length; i++) {
            address addr = _addresses[i];
            if (isWhitelisted[addr] == _whitelisted) continue;
            if (_whitelisted) {
                addToWhitelist(addr);
            } else {
                removeFromWhitelist(addr);
            }
        }
    }
}

 
contract BitGuildFeeProvider is BitGuildAccessAdmin {
     
    uint constant NO_FEE = 10000;

     
    uint defaultPercentFee = 500;  

    mapping(bytes32 => uint) public customFee;   

    event LogFeeChanged(uint newPercentFee, uint oldPercentFee, address operator);
    event LogCustomFeeChanged(uint newPercentFee, uint oldPercentFee, address buyer, address seller, address token, address operator);

     
    function () external payable {
        revert();
    }

     
    function updateFee(uint _newFee) public onlyOperator {
        require(_newFee >= 0 && _newFee <= 10000, "Invalid percent fee.");

        uint oldPercentFee = defaultPercentFee;
        defaultPercentFee = _newFee;

        emit LogFeeChanged(_newFee, oldPercentFee, msg.sender);
    }

     
    function updateCustomFee(uint _newFee, address _currency, address _buyer, address _seller, address _token) public onlyOperator {
        require(_newFee >= 0 && _newFee <= 10000, "Invalid percent fee.");

        bytes32 key = _getHash(_currency, _buyer, _seller, _token);
        uint oldPercentFee = customFee[key];
        customFee[key] = _newFee;

        emit LogCustomFeeChanged(_newFee, oldPercentFee, _buyer, _seller, _token, msg.sender);
    }

     
    function getFee(uint _price, address _currency, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        bytes32 key = _getHash(_currency, _buyer, _seller, _token);
        uint customPercentFee = customFee[key];
        (percent, fee) = _getFee(_price, customPercentFee);
    }

    function _getFee(uint _price, uint _percentFee) internal view returns(uint percent, uint fee) {
        require(_price >= 0, "Invalid price.");

        percent = _percentFee;

         
        if (_percentFee == 0) {
            percent = defaultPercentFee;
        }

         
        if (_percentFee == NO_FEE) {
            percent = 0;
            fee = 0;
        } else {
            fee = _safeMul(_price, percent) / 10000;  
        }
    }

     
    function _getHash(address _currency, address _buyer, address _seller, address _token) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_currency, _buyer, _seller, _token));
    }

     
    function _safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
}

pragma solidity ^0.4.24;

interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
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
}

 
 
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

 
contract BitGuildMarketplace is BitGuildAccessAdmin {
     
     
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
     
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

     
    BitGuildToken public PLAT = BitGuildToken(0x7E43581b19ab509BCF9397a2eFd1ab10233f27dE);  
    BitGuildWhitelist public Whitelist = BitGuildWhitelist(0xA8CedD578fed14f07C3737bF42AD6f04FAAE3978);  
    BitGuildFeeProvider public FeeProvider = BitGuildFeeProvider(0x58D36571250D91eF5CE90869E66Cd553785364a2);  
     
     
     

    uint public defaultExpiry = 7 days;   

    enum Currency { PLAT, ETH }
    struct Listing {
        Currency currency;       
        address seller;          
        address token;           
        uint tokenId;            
        uint price;              
        uint createdAt;          
        uint expiry;             
    }

    mapping(bytes32 => Listing) public listings;

    event LogListingCreated(address _seller, address _contract, uint _tokenId, uint _createdAt, uint _expiry);
    event LogListingExtended(address _seller, address _contract, uint _tokenId, uint _createdAt, uint _expiry);
    event LogItemSold(address _buyer, address _seller, address _contract, uint _tokenId, uint _price, Currency _currency, uint _soldAt);
    event LogItemWithdrawn(address _seller, address _contract, uint _tokenId, uint _withdrawnAt);
    event LogItemExtended(address _contract, uint _tokenId, uint _modifiedAt, uint _expiry);

    modifier onlyWhitelisted(address _contract) {
        require(Whitelist.isWhitelisted(_contract), "Contract not in whitelist.");
        _;
    }

     
    function () external payable {
        revert();
    }

     
    function getHashKey(address _contract, uint _tokenId) public pure returns(bytes32 key) {
        key = _getHashKey(_contract, _tokenId);
    }

     
     
     
     
    function getFee(uint _price, address _currency, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        (percent, fee) = FeeProvider.getFee(_price, _currency, _buyer, _seller, _token);
    }

     
     
     
     
     
    function onERC721Received(address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED_OLD;
    }

     
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED;
    }

     
     
     
    function extendItem(address _contract, uint _tokenId) public onlyWhitelisted(_contract) returns(bool) {
        bytes32 key = _getHashKey(_contract, _tokenId);
        address seller = listings[key].seller;

        require(seller == msg.sender, "Only seller can extend listing.");
        require(listings[key].expiry > 0, "Item not listed.");

        listings[key].expiry = now + defaultExpiry;

        emit LogListingExtended(seller, _contract, _tokenId, listings[key].createdAt, listings[key].expiry);

        return true;
    }

     
     
     
    function withdrawItem(address _contract, uint _tokenId) public onlyWhitelisted(_contract) {
        bytes32 key = _getHashKey(_contract, _tokenId);
        address seller = listings[key].seller;

        require(seller == msg.sender, "Only seller can withdraw listing.");

         
        ERC721 gameToken = ERC721(_contract);
        gameToken.safeTransferFrom(this, seller, _tokenId);

        emit LogItemWithdrawn(seller, _contract, _tokenId, now);

         
        delete(listings[key]);
    }

     
     
     
     
     
     
    function buyWithETH(address _token, uint _tokenId) public onlyWhitelisted(_token) payable {
        _buy(_token, _tokenId, Currency.ETH, msg.value, msg.sender);
    }

     
     
     
     
     
     
    function receiveApproval(address _buyer, uint _value, BitGuildToken _PLAT, bytes _extraData) public {
        require(_extraData.length > 0, "No extraData provided.");
         
        require(msg.sender == address(PLAT), "Unauthorized PLAT contract address.");

        address token;
        uint tokenId;
        (token, tokenId) = _decodeBuyData(_extraData);

        _buy(token, tokenId, Currency.PLAT, _value, _buyer);
    }

     
     
     
     
    function updateFeeProvider(address _newAddr) public onlyOperator {
        require(_newAddr != address(0), "Invalid contract address.");
        FeeProvider = BitGuildFeeProvider(_newAddr);
    }

     
    function updateWhitelist(address _newAddr) public onlyOperator {
        require(_newAddr != address(0), "Invalid contract address.");
        Whitelist = BitGuildWhitelist(_newAddr);
    }

     
    function updateExpiry(uint _days) public onlyOperator {
        require(_days > 0, "Invalid number of days.");
        defaultExpiry = _days * 1 days;
    }

     
    function withdrawETH() public onlyOwner payable {
        msg.sender.transfer(msg.value);
    }

     
    function withdrawPLAT() public onlyOwner payable {
        uint balance = PLAT.balanceOf(this);
        PLAT.transfer(msg.sender, balance);
    }

     
     
     
    function _getHashKey(address _contract, uint _tokenId) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_contract, _tokenId));
    }

     
    function _newListing(address _seller, address _contract, uint _tokenId, uint _price, Currency _currency) internal {
        bytes32 key = _getHashKey(_contract, _tokenId);
        uint createdAt = now;
        uint expiry = now + defaultExpiry;
        listings[key].currency = _currency;
        listings[key].seller = _seller;
        listings[key].token = _contract;
        listings[key].tokenId = _tokenId;
        listings[key].price = _price;
        listings[key].createdAt = createdAt;
        listings[key].expiry = expiry;

        emit LogListingCreated(_seller, _contract, _tokenId, createdAt, expiry);
    }

     
     
    function _deposit(address _seller, address _contract, uint _tokenId, bytes _extraData) internal onlyWhitelisted(_contract) {
        uint price;
        uint currencyUint;
        (currencyUint, price) = _decodePriceData(_extraData);
        Currency currency = Currency(currencyUint);

        require(price > 0, "Invalid price.");

        _newListing(_seller, _contract, _tokenId, price, currency);
    }

     
    function _buy(address _token, uint _tokenId, Currency _currency, uint _price, address _buyer) internal {
        bytes32 key = _getHashKey(_token, _tokenId);
        Currency currency = listings[key].currency;
        address seller = listings[key].seller;

        address currencyAddress = _currency == Currency.PLAT ? address(PLAT) : address(0);

        require(currency == _currency, "Wrong currency.");
        require(_price > 0 && _price == listings[key].price, "Invalid price.");
        require(listings[key].expiry > now, "Item expired.");

        ERC721 gameToken = ERC721(_token);
        require(gameToken.ownerOf(_tokenId) == address(this), "Item is not available.");

        if (_currency == Currency.PLAT) {
             
            require(PLAT.transferFrom(_buyer, address(this), _price), "PLAT payment transfer failed.");
        }

         
        gameToken.safeTransferFrom(this, _buyer, _tokenId);

        uint fee;
        (,fee) = getFee(_price, currencyAddress, _buyer, seller, _token);  

        if (_currency == Currency.PLAT) {
            PLAT.transfer(seller, _price - fee);
        } else {
            require(seller.send(_price - fee) == true, "Transfer to seller failed.");
        }

         
        emit LogItemSold(_buyer, seller, _token, _tokenId, _price, currency, now);

         
        delete(listings[key]);
    }

    function _decodePriceData(bytes _extraData) internal pure returns(uint _currency, uint _price) {
         
        uint256 offset = 64;
        _price = _bytesToUint256(offset, _extraData);
        offset -= 32;
        _currency = _bytesToUint256(offset, _extraData);
    }

    function _decodeBuyData(bytes _extraData) internal pure returns(address _contract, uint _tokenId) {
         
        uint256 offset = 64;
        _tokenId = _bytesToUint256(offset, _extraData);
        offset -= 32;
        _contract = _bytesToAddress(offset, _extraData);
    }

     
    function _bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

     
    function _bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
}