 

pragma solidity ^0.4.24;

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}


contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender; 
    }

     
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0), "Can't transfer to 0x0");
        owner = _to;
        return true;
    }
}


 
contract Oracle is Ownable {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;

     
    function url() public view returns (string);

     
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

     
    function addCurrency(string ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }

     
    function encodeCurrency(string currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32);
        assembly {
            o := mload(add(currency, 32))
        }
    }
    
     
    function decodeCurrency(bytes32 b) public pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }
    
}

contract Engine {
    uint256 public VERSION;
    string public VERSION_NAME;

    enum Status { initial, lent, paid, destroyed }
    struct Approbation {
        bool approved;
        bytes data;
        bytes32 checksum;
    }

    function getTotalLoans() public view returns (uint256);
    function getOracle(uint index) public view returns (Oracle);
    function getBorrower(uint index) public view returns (address);
    function getCosigner(uint index) public view returns (address);
    function ownerOf(uint256) public view returns (address owner);
    function getCreator(uint index) public view returns (address);
    function getAmount(uint index) public view returns (uint256);
    function getPaid(uint index) public view returns (uint256);
    function getDueTime(uint index) public view returns (uint256);
    function getApprobation(uint index, address _address) public view returns (bool);
    function getStatus(uint index) public view returns (Status);
    function isApproved(uint index) public view returns (bool);
    function getPendingAmount(uint index) public returns (uint256);
    function getCurrency(uint index) public view returns (bytes32);
    function cosign(uint index, uint256 cost) external returns (bool);
    function approveLoan(uint index) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
    function takeOwnership(uint256 index) public returns (bool);
    function withdrawal(uint index, address to, uint256 amount) public returns (bool);
    function identifierToIndex(bytes32 signature) public view returns (uint256);
}


 
contract Cosigner {
    uint256 public constant VERSION = 2;
    
     
    function url() external view returns (string);
    
     
    function cost(address engine, uint256 index, bytes data, bytes oracleData) external view returns (uint256);
    
     
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool);
    
     
    function claim(address engine, uint256 index, bytes oracleData) external returns (bool);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }
}


contract SafeWithdraw is Ownable {
     
    function withdrawTokens(Token token, address to, uint256 amountOrId) external onlyOwner returns (bool) {
        require(to != address(0));
        return token.transfer(to, amountOrId);
    }
}

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index);
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
}

contract TokenConverter {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}



interface IERC721Receiver {
    function onERC721Received(
        address _oldOwner,
        uint256 _tokenId,
        bytes   _userData
    ) external returns (bytes4);
}

contract ERC721Base {
    using SafeMath for uint256;

    uint256 private _count;

    mapping(uint256 => address) private _holderOf;
    mapping(address => uint256[]) private _assetsOf;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(uint256 => address) private _approval;
    mapping(uint256 => uint256) private _indexOfAsset;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     

     
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }
    function _totalSupply() internal view returns (uint256) {
        return _count;
    }

     
     
     

     
    function ownerOf(uint256 assetId) external view returns (address) {
        return _ownerOf(assetId);
    }
    function _ownerOf(uint256 assetId) internal view returns (address) {
        return _holderOf[assetId];
    }

     
     
     
     
    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }
    function _balanceOf(address owner) internal view returns (uint256) {
        return _assetsOf[owner].length;
    }

     
     
     

     
    function isApprovedForAll(address operator, address assetHolder)
        external view returns (bool)
    {
        return _isApprovedForAll(operator, assetHolder);
    }
    function _isApprovedForAll(address operator, address assetHolder)
        internal view returns (bool)
    {
        return _operators[assetHolder][operator];
    }

     
    function getApprovedAddress(uint256 assetId) external view returns (address) {
        return _getApprovedAddress(assetId);
    }
    function _getApprovedAddress(uint256 assetId) internal view returns (address) {
        return _approval[assetId];
    }

     
    function isAuthorized(address operator, uint256 assetId) external view returns (bool) {
        return _isAuthorized(operator, assetId);
    }
    function _isAuthorized(address operator, uint256 assetId) internal view returns (bool)
    {
        require(operator != 0, "Operator can't be 0");
        address owner = _ownerOf(assetId);
        if (operator == owner) {
            return true;
        }
        return _isApprovedForAll(operator, owner) || _getApprovedAddress(assetId) == operator;
    }

     
     
     

     
    function setApprovalForAll(address operator, bool authorized) external {
        return _setApprovalForAll(operator, authorized);
    }
    function _setApprovalForAll(address operator, bool authorized) internal {
        if (authorized) {
            _addAuthorization(operator, msg.sender);
        } else {
            _clearAuthorization(operator, msg.sender);
        }
        emit ApprovalForAll(operator, msg.sender, authorized);
    }

     
    function approve(address operator, uint256 assetId) external {
        address holder = _ownerOf(assetId);
        require(msg.sender == holder || _isApprovedForAll(msg.sender, holder));
        require(operator != holder);
        if (_getApprovedAddress(assetId) != operator) {
            _approval[assetId] = operator;
            emit Approval(holder, operator, assetId);
        }
    }

    function _addAuthorization(address operator, address holder) private {
        _operators[holder][operator] = true;
    }

    function _clearAuthorization(address operator, address holder) private {
        _operators[holder][operator] = false;
    }

     
     
     

    function _addAssetTo(address to, uint256 assetId) internal {
        _holderOf[assetId] = to;

        uint256 length = _balanceOf(to);

        _assetsOf[to].push(assetId);

        _indexOfAsset[assetId] = length;

        _count = _count.add(1);
    }

    function _removeAssetFrom(address from, uint256 assetId) internal {
        uint256 assetIndex = _indexOfAsset[assetId];
        uint256 lastAssetIndex = _balanceOf(from).sub(1);
        uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

        _holderOf[assetId] = 0;

         
        _assetsOf[from][assetIndex] = lastAssetId;

         
        _assetsOf[from][lastAssetIndex] = 0;
        _assetsOf[from].length--;

         
        if (_assetsOf[from].length == 0) {
            delete _assetsOf[from];
        }

         
        _indexOfAsset[assetId] = 0;
        _indexOfAsset[lastAssetId] = assetIndex;

        _count = _count.sub(1);
    }

    function _clearApproval(address holder, uint256 assetId) internal {
        if (_ownerOf(assetId) == holder && _approval[assetId] != 0) {
            _approval[assetId] = 0;
            emit Approval(holder, 0, assetId);
        }
    }

     
     
     

    function _generate(uint256 assetId, address beneficiary) internal {
        require(_holderOf[assetId] == 0);

        _addAssetTo(beneficiary, assetId);

        emit Transfer(0x0, beneficiary, assetId);
    }

    function _destroy(uint256 assetId) internal {
        address holder = _holderOf[assetId];
        require(holder != 0);

        _removeAssetFrom(holder, assetId);

        emit Transfer(holder, 0x0, assetId);
    }

     
     
     

    modifier onlyHolder(uint256 assetId) {
        require(_ownerOf(assetId) == msg.sender, "Not holder");
        _;
    }

    modifier onlyAuthorized(uint256 assetId) {
        require(_isAuthorized(msg.sender, assetId), "Not authorized");
        _;
    }

    modifier isCurrentOwner(address from, uint256 assetId) {
        require(_ownerOf(assetId) == from, "Not current owner");
        _;
    }

     
    function safeTransferFrom(address from, address to, uint256 assetId) external {
        return _doTransferFrom(from, to, assetId, "", true);
    }

     
    function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) external {
        return _doTransferFrom(from, to, assetId, userData, true);
    }

     
    function transferFrom(address from, address to, uint256 assetId) external {
        return _doTransferFrom(from, to, assetId, "", false);
    }

    function _doTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        onlyAuthorized(assetId)
        internal
    {
        _moveToken(from, to, assetId, userData, doCheck);
    }

    function _moveToken(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        isCurrentOwner(from, assetId)
        internal
    {
        address holder = _holderOf[assetId];
        _removeAssetFrom(holder, assetId);
        _clearApproval(holder, assetId);
        _addAssetTo(to, assetId);

        if (doCheck && _isContract(to)) {
             
            bytes4 ERC721_RECEIVED = bytes4(0xf0b9e5ba);
            require(
                IERC721Receiver(to).onERC721Received(
                    holder, assetId, userData
                ) == ERC721_RECEIVED
            , "Contract onERC721Received failed");
        }

        emit Transfer(holder, to, assetId);
    }

     

     
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {

        if (_interfaceID == 0xffffffff) {
            return false;
        }
        return _interfaceID == 0x01ffc9a7 || _interfaceID == 0x80ac58cd;
    }

     
     
     

    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}


contract LandMarket {
    struct Auction {
         
        bytes32 id;
         
        address seller;
         
        uint256 price;
         
        uint256 expiresAt;
    }

    mapping (uint256 => Auction) public auctionByAssetId;
    function executeOrder(uint256 assetId, uint256 price) public;
}

contract Land {
    function updateLandData(int x, int y, string data) public;
    function decodeTokenId(uint value) view public returns (int, int);
    function safeTransferFrom(address from, address to, uint256 assetId) public;
    function ownerOf(uint256 landID) public view returns (address);
}

 
contract MortgageManager is Cosigner, ERC721Base, SafeWithdraw, BytesUtils {
    using SafeMath for uint256;

    uint256 constant internal PRECISION = (10**18);
    uint256 constant internal RCN_DECIMALS = 18;

    bytes32 public constant MANA_CURRENCY = 0x4d414e4100000000000000000000000000000000000000000000000000000000;
    uint256 public constant REQUIRED_ALLOWANCE = 1000000000 * 10**18;

    function name() public pure returns (string _name) {
        _name = "Decentraland RCN Mortgage";
    }

    function symbol() public pure returns (string _symbol) {
        _symbol = "LAND-RCN-Mortgage";
    }

    event RequestedMortgage(uint256 _id, address _borrower, address _engine, uint256 _loanId, uint256 _landId, uint256 _deposit, address _tokenConverter);
    event StartedMortgage(uint256 _id);
    event CanceledMortgage(address _from, uint256 _id);
    event PaidMortgage(address _from, uint256 _id);
    event DefaultedMortgage(uint256 _id);
    event UpdatedLandData(address _updater, uint256 _parcel, string _data);
    event SetCreator(address _creator, bool _status);

    Token public rcn;
    Token public mana;
    Land public land;
    LandMarket public landMarket;
    
    constructor(Token _rcn, Token _mana, Land _land, LandMarket _landMarket) public {
        rcn = _rcn;
        mana = _mana;
        land = _land;
        landMarket = _landMarket;
        mortgages.length++;
    }

    enum Status { Pending, Ongoing, Canceled, Paid, Defaulted }

    struct Mortgage {
        address owner;
        Engine engine;
        uint256 loanId;
        uint256 deposit;
        uint256 landId;
        uint256 landCost;
        Status status;
         
        TokenConverter tokenConverter;
    }

    uint256 internal flagReceiveLand;

    Mortgage[] public mortgages;

    mapping(address => bool) public creators;

    mapping(uint256 => uint256) public mortgageByLandId;
    mapping(address => mapping(uint256 => uint256)) public loanToLiability;

    function url() external view returns (string) {
        return "";
    }

     
    function setCreator(address creator, bool authorized) external onlyOwner returns (bool) {
        emit SetCreator(creator, authorized);
        creators[creator] = authorized;
        return true;
    }

     
    function cost(address, uint256, bytes, bytes) external view returns (uint256) {
        return 0;
    }

     
    function requestMortgage(
        Engine engine,
        bytes32 loanIdentifier,
        uint256 deposit,
        uint256 landId,
        TokenConverter tokenConverter
    ) external returns (uint256 id) {
        return requestMortgageId(engine, engine.identifierToIndex(loanIdentifier), deposit, landId, tokenConverter);
    }

     
    function requestMortgageId(
        Engine engine,
        uint256 loanId,
        uint256 deposit,
        uint256 landId,
        TokenConverter tokenConverter
    ) public returns (uint256 id) {
         
        require(engine.getCurrency(loanId) == MANA_CURRENCY, "Loan currency is not MANA");
        address borrower = engine.getBorrower(loanId);
        require(engine.getStatus(loanId) == Engine.Status.initial, "Loan status is not inital");
        require(msg.sender == engine.getBorrower(loanId) ||
               (msg.sender == engine.getCreator(loanId) && creators[msg.sender]),
            "Creator should be borrower or authorized");
        require(engine.isApproved(loanId), "Loan is not approved");
        require(rcn.allowance(borrower, this) >= REQUIRED_ALLOWANCE, "Manager cannot handle borrower's funds");
        require(tokenConverter != address(0), "Token converter not defined");
        require(loanToLiability[engine][loanId] == 0, "Liability for loan already exists");

         
        uint256 landCost;
        (, , landCost, ) = landMarket.auctionByAssetId(landId);
        uint256 loanAmount = engine.getAmount(loanId);

         
         
        require((loanAmount + deposit) >= ((landCost / 10) * 11), "Not enought total amount");

         
        require(mana.transferFrom(msg.sender, this, deposit), "Error pulling mana");

         
        id = mortgages.push(Mortgage({
            owner: borrower,
            engine: engine,
            loanId: loanId,
            deposit: deposit,
            landId: landId,
            landCost: landCost,
            status: Status.Pending,
            tokenConverter: tokenConverter
        })) - 1;

        loanToLiability[engine][loanId] = id;

        emit RequestedMortgage({
            _id: id,
            _borrower: borrower,
            _engine: engine,
            _loanId: loanId,
            _landId: landId,
            _deposit: deposit,
            _tokenConverter: tokenConverter
        });
    }

     
    function cancelMortgage(uint256 id) external returns (bool) {
        Mortgage storage mortgage = mortgages[id];
        
         
        require(msg.sender == mortgage.owner, "Only the owner can cancel the mortgage");
        require(mortgage.status == Status.Pending, "The mortgage is not pending");
        
        mortgage.status = Status.Canceled;

         
        require(mana.transfer(msg.sender, mortgage.deposit), "Error returning MANA");

        emit CanceledMortgage(msg.sender, id);
        return true;
    }

     
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool) {
         
        Mortgage storage mortgage = mortgages[uint256(readBytes32(data, 0))];
        
         
         
        require(mortgage.engine == engine, "Engine does not match");
        require(mortgage.loanId == index, "Loan id does not match");
        require(mortgage.status == Status.Pending, "Mortgage is not pending");

         
        mortgage.status = Status.Ongoing;

         
        _generate(uint256(readBytes32(data, 0)), mortgage.owner);

         
        uint256 loanAmount = convertRate(engine.getOracle(index), engine.getCurrency(index), oracleData, engine.getAmount(index));
        require(rcn.transferFrom(mortgage.owner, this, loanAmount), "Error pulling RCN from borrower");
        
         
         
        uint256 boughtMana = convertSafe(mortgage.tokenConverter, rcn, mana, loanAmount);
        delete mortgage.tokenConverter;

         
        uint256 currentLandCost;
        (, , currentLandCost, ) = landMarket.auctionByAssetId(mortgage.landId);
        require(currentLandCost <= mortgage.landCost, "Parcel is more expensive than expected");
        
         
        require(mana.approve(landMarket, currentLandCost));
        flagReceiveLand = mortgage.landId;
        landMarket.executeOrder(mortgage.landId, currentLandCost);
        require(mana.approve(landMarket, 0));
        require(flagReceiveLand == 0, "ERC721 callback not called");
        require(land.ownerOf(mortgage.landId) == address(this), "Error buying parcel");

         
         
        uint256 totalMana = boughtMana.add(mortgage.deposit);        

         
        require(mana.transfer(mortgage.owner, totalMana.sub(currentLandCost)), "Error returning MANA");
        
         
        require(mortgage.engine.cosign(index, 0), "Error performing cosign");
        
         
        mortgageByLandId[mortgage.landId] = uint256(readBytes32(data, 0));

         
        emit StartedMortgage(uint256(readBytes32(data, 0)));

        return true;
    }

     
    function convertSafe(
        TokenConverter converter,
        Token from,
        Token to,
        uint256 amount
    ) internal returns (uint256 bought) {
        require(from.approve(converter, amount));
        uint256 prevBalance = to.balanceOf(this);
        bought = converter.convert(from, to, amount, 1);
        require(to.balanceOf(this).sub(prevBalance) >= bought, "Bought amount incorrect");
        require(from.approve(converter, 0));
    }

     
    function claim(address engine, uint256 loanId, bytes) external returns (bool) {
        uint256 mortgageId = loanToLiability[engine][loanId];
        Mortgage storage mortgage = mortgages[mortgageId];

         
        require(mortgage.status == Status.Ongoing, "Mortgage not ongoing");
        require(mortgage.loanId == loanId, "Mortgage don't match loan id");

        if (mortgage.engine.getStatus(loanId) == Engine.Status.paid || mortgage.engine.getStatus(loanId) == Engine.Status.destroyed) {
             
            require(_isAuthorized(msg.sender, mortgageId), "Sender not authorized");

            mortgage.status = Status.Paid;
             
            land.safeTransferFrom(this, msg.sender, mortgage.landId);
            emit PaidMortgage(msg.sender, mortgageId);
        } else if (isDefaulted(mortgage.engine, loanId)) {
             
            require(msg.sender == mortgage.engine.ownerOf(loanId), "Sender not lender");
            
            mortgage.status = Status.Defaulted;
             
            land.safeTransferFrom(this, msg.sender, mortgage.landId);
            emit DefaultedMortgage(mortgageId);
        } else {
            revert("Mortgage not defaulted/paid");
        }

         
        _destroy(mortgageId);

         
        delete mortgageByLandId[mortgage.landId];

        return true;
    }

     
    function isDefaulted(Engine engine, uint256 index) public view returns (bool) {
        return engine.getStatus(index) == Engine.Status.lent &&
            engine.getDueTime(index).add(7 days) <= block.timestamp;
    }

     
    function onERC721Received(uint256 _tokenId, address, bytes) external returns (bytes4) {
        if (msg.sender == address(land) && flagReceiveLand == _tokenId) {
            flagReceiveLand = 0;
            return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
        }
    }

     
    function onERC721Received(address, uint256 _tokenId, bytes) external returns (bytes4) {
        if (msg.sender == address(land) && flagReceiveLand == _tokenId) {
            flagReceiveLand = 0;
            return bytes4(keccak256("onERC721Received(address,uint256,bytes)"));
        }
    }

     
    function getData(uint256 id) public pure returns (bytes o) {
        assembly {
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(32, 0x20), 0x1f), not(0x1f))))
            mstore(o, 32)
            mstore(add(o, 32), id)
        }
    }
    
     
    function updateLandData(uint256 id, string data) external returns (bool) {
        Mortgage memory mortgage = mortgages[id];
        require(_isAuthorized(msg.sender, id), "Sender not authorized");
        int256 x;
        int256 y;
        (x, y) = land.decodeTokenId(mortgage.landId);
        land.updateLandData(x, y, data);
        emit UpdatedLandData(msg.sender, id, data);
        return true;
    }

     
    function convertRate(Oracle oracle, bytes32 currency, bytes data, uint256 amount) internal returns (uint256) {
        if (oracle == address(0)) {
            return amount;
        } else {
            uint256 rate;
            uint256 decimals;
            
            (rate, decimals) = oracle.getRate(currency, data);

            require(decimals <= RCN_DECIMALS, "Decimals exceeds max decimals");
            return (amount.mult(rate).mult((10**(RCN_DECIMALS-decimals)))) / PRECISION;
        }
    }
}