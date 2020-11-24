 

pragma solidity ^0.4.24;

 

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

 

contract TokenConverter {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}

 

contract Ownable {
    address public owner;

    event SetOwner(address _owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }

     
    function setOwner(address _to) external onlyOwner returns (bool) {
        require(_to != address(0), "Owner can't be 0x0");
        owner = _to;
        emit SetOwner(_to);
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
    
     
    function url() public view returns (string);
    
     
    function cost(address engine, uint256 index, bytes data, bytes oracleData) public view returns (uint256);
    
     
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool);
    
     
    function claim(address engine, uint256 index, bytes oracleData) external returns (bool);
}

 

contract ERC721 {
     
    
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
   event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

 

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y), "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        uint256 z = x - y;
        return z;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y), "Mult overflow");
        return z;
    }
}

 

 
contract ERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor()
        internal
    {
        _registerInterface(_InterfaceId_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId)
        internal
    {
        require(interfaceId != 0xffffffff, "Can't register 0xffffffff");
        _supportedInterfaces[interfaceId] = true;
    }
}

 

interface URIProvider {
    function tokenURI(uint256 _tokenId) external view returns (string);
}

contract ERC721Base is ERC165 {
    using SafeMath for uint256;

    mapping(uint256 => address) private _holderOf;
    mapping(address => uint256[]) private _assetsOf;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(uint256 => address) private _approval;
    mapping(uint256 => uint256) private _indexOfAsset;

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant ERC721_RECEIVED_LEGACY = 0xf0b9e5ba;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 private constant ERC_721_INTERFACE = 0x80ac58cd;
    bytes4 private constant ERC_721_METADATA_INTERFACE = 0x5b5e139f;
    bytes4 private constant ERC_721_ENUMERATION_INTERFACE = 0x780e9d63;

    constructor(
        string name,
        string symbol
    ) public {
        _name = name;
        _symbol = symbol;

        _registerInterface(ERC_721_INTERFACE);
        _registerInterface(ERC_721_METADATA_INTERFACE);
        _registerInterface(ERC_721_ENUMERATION_INTERFACE);
    }

     
     
     

     
     
     

    event SetURIProvider(address _uriProvider);

    string private _name;
    string private _symbol;

    URIProvider private _uriProvider;

     
    function name() external view returns (string) {
        return _name;
    }

     
    function symbol() external view returns (string) {
        return _symbol;
    }

     
    function tokenURI(uint256 _tokenId) external view returns (string) {
        require(_holderOf[_tokenId] != 0, "Asset does not exist");
        URIProvider provider = _uriProvider;
        return provider == address(0) ? "" : provider.tokenURI(_tokenId);
    }

    function _setURIProvider(URIProvider _provider) internal returns (bool) {
        emit SetURIProvider(_provider);
        _uriProvider = _provider;
        return true;
    }
 
     
     
     

     
     
     

    uint256[] private _allTokens;

    function allTokens() external view returns (uint256[]) {
        return _allTokens;
    }

    function assetsOf(address _owner) external view returns (uint256[]) {
        return _assetsOf[_owner];
    }

     
    function totalSupply() external view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < _allTokens.length, "Index out of bounds");
        return _allTokens[_index];
    }

     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_owner != address(0), "0x0 Is not a valid owner");
        require(_index < _balanceOf(_owner), "Index out of bounds");
        return _assetsOf[_owner][_index];
    }

     
     
     

     
    function ownerOf(uint256 _assetId) external view returns (address) {
        return _ownerOf(_assetId);
    }
    function _ownerOf(uint256 _assetId) internal view returns (address) {
        return _holderOf[_assetId];
    }

     
     
     
     
    function balanceOf(address _owner) external view returns (uint256) {
        return _balanceOf(_owner);
    }
    function _balanceOf(address _owner) internal view returns (uint256) {
        return _assetsOf[_owner].length;
    }

     
     
     

     
    function isApprovedForAll(
        address _operator,
        address _assetHolder
    ) external view returns (bool) {
        return _isApprovedForAll(_operator, _assetHolder);
    }
    function _isApprovedForAll(
        address _operator,
        address _assetHolder
    ) internal view returns (bool) {
        return _operators[_assetHolder][_operator];
    }

     
    function getApprovedAddress(uint256 _assetId) external view returns (address) {
        return _getApprovedAddress(_assetId);
    }
    function _getApprovedAddress(uint256 _assetId) internal view returns (address) {
        return _approval[_assetId];
    }

     
    function isAuthorized(address _operator, uint256 _assetId) external view returns (bool) {
        return _isAuthorized(_operator, _assetId);
    }
    function _isAuthorized(address _operator, uint256 _assetId) internal view returns (bool) {
        require(_operator != 0, "0x0 is an invalid operator");
        address owner = _ownerOf(_assetId);
        if (_operator == owner) {
            return true;
        }
        return _isApprovedForAll(_operator, owner) || _getApprovedAddress(_assetId) == _operator;
    }

     
     
     

     
    function setApprovalForAll(address _operator, bool _authorized) external {
        if (_operators[msg.sender][_operator] != _authorized) {
            _operators[msg.sender][_operator] = _authorized;
            emit ApprovalForAll(_operator, msg.sender, _authorized);
        }
    }

     
    function approve(address _operator, uint256 _assetId) external {
        address holder = _ownerOf(_assetId);
        require(msg.sender == holder || _isApprovedForAll(msg.sender, holder), "msg.sender can't approve");
        if (_getApprovedAddress(_assetId) != _operator) {
            _approval[_assetId] = _operator;
            emit Approval(holder, _operator, _assetId);
        }
    }

     
     
     

    function _addAssetTo(address _to, uint256 _assetId) internal {
         
        _holderOf[_assetId] = _to;

         
        uint256 length = _balanceOf(_to);
        _assetsOf[_to].push(_assetId);
        _indexOfAsset[_assetId] = length;

         
        _allTokens.push(_assetId);
    }

    function _transferAsset(address _from, address _to, uint256 _assetId) internal {
        uint256 assetIndex = _indexOfAsset[_assetId];
        uint256 lastAssetIndex = _balanceOf(_from).sub(1);

        if (assetIndex != lastAssetIndex) {
             
            uint256 lastAssetId = _assetsOf[_from][lastAssetIndex];
             
            _assetsOf[_from][assetIndex] = lastAssetId;
        }

         
        _assetsOf[_from][lastAssetIndex] = 0;
        _assetsOf[_from].length--;

         
        _holderOf[_assetId] = _to;

         
        uint256 length = _balanceOf(_to);
        _assetsOf[_to].push(_assetId);
        _indexOfAsset[_assetId] = length;
    }

    function _clearApproval(address _holder, uint256 _assetId) internal {
        if (_approval[_assetId] != 0) {
            _approval[_assetId] = 0;
            emit Approval(_holder, 0, _assetId);
        }
    }

     
     
     

    function _generate(uint256 _assetId, address _beneficiary) internal {
        require(_holderOf[_assetId] == 0, "Asset already exists");

        _addAssetTo(_beneficiary, _assetId);

        emit Transfer(0x0, _beneficiary, _assetId);
    }

     
     
     

    modifier onlyHolder(uint256 _assetId) {
        require(_ownerOf(_assetId) == msg.sender, "msg.sender Is not holder");
        _;
    }

    modifier onlyAuthorized(uint256 _assetId) {
        require(_isAuthorized(msg.sender, _assetId), "msg.sender Not authorized");
        _;
    }

    modifier isCurrentOwner(address _from, uint256 _assetId) {
        require(_ownerOf(_assetId) == _from, "Not current owner");
        _;
    }

    modifier addressDefined(address _target) {
        require(_target != address(0), "Target can't be 0x0");
        _;
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _assetId) external {
        return _doTransferFrom(_from, _to, _assetId, "", true);
    }

     
    function safeTransferFrom(address _from, address _to, uint256 _assetId, bytes _userData) external {
        return _doTransferFrom(_from, _to, _assetId, _userData, true);
    }

     
    function transferFrom(address _from, address _to, uint256 _assetId) external {
        return _doTransferFrom(_from, _to, _assetId, "", false);
    }

     
    function _doTransferFrom(
        address _from,
        address _to,
        uint256 _assetId,
        bytes _userData,
        bool _doCheck
    )
        internal
        onlyAuthorized(_assetId)
        addressDefined(_to)
        isCurrentOwner(_from, _assetId)
    {
        address holder = _holderOf[_assetId];
        _clearApproval(holder, _assetId);
        _transferAsset(holder, _to, _assetId);

        if (_doCheck && _isContract(_to)) {
             
            uint256 success;
            bytes32 result;
             
             
            (success, result) = _noThrowCall(
                _to,
                abi.encodeWithSelector(
                    ERC721_RECEIVED,
                    msg.sender,
                    holder,
                    _assetId,
                    _userData
                )
            );

            if (success != 1 || result != ERC721_RECEIVED) {
                 
                 
                (success, result) = _noThrowCall(
                    _to,
                    abi.encodeWithSelector(
                        ERC721_RECEIVED_LEGACY,
                        holder,
                        _assetId,
                        _userData
                    )
                );

                require(
                    success == 1 && result == ERC721_RECEIVED_LEGACY,
                    "Contract rejected the token"
                );
            }
        }

        emit Transfer(holder, _to, _assetId);
    }

     
     
     

    function _isContract(address _addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }

    function _noThrowCall(
        address _contract,
        bytes _data
    ) internal returns (uint256 success, bytes32 result) {
        assembly {
            let x := mload(0x40)

            success := call(
                            gas,                   
                            _contract,             
                            0,                     
                            add(0x20, _data),      
                            mload(_data),          
                            x,                     
                            0x20                   
                        )

            result := mload(x)
        }
    }
}

 

contract SafeWithdraw is Ownable {
    function withdrawTokens(Token token, address to, uint256 amount) external onlyOwner returns (bool) {
        require(to != address(0), "Can't transfer to address 0x0");
        return token.transfer(to, amount);
    }
    
    function withdrawErc721(ERC721Base token, address to, uint256 id) external onlyOwner returns (bool) {
        require(to != address(0), "Can't transfer to address 0x0");
        token.transferFrom(this, to, id);
    }
    
    function withdrawEth(address to, uint256 amount) external onlyOwner returns (bool) {
        to.transfer(amount);
        return true;
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

contract Land is ERC721 {
    function updateLandData(int x, int y, string data) public;
    function decodeTokenId(uint value) view public returns (int, int);
    function safeTransferFrom(address from, address to, uint256 assetId) public;
    function ownerOf(uint256 landID) public view returns (address);
    function setUpdateOperator(uint256 assetId, address operator) external;
}

 
contract MortgageManager is Cosigner, ERC721Base, SafeWithdraw, BytesUtils {
    uint256 constant internal PRECISION = (10**18);
    uint256 constant internal RCN_DECIMALS = 18;

    bytes32 public constant MANA_CURRENCY = 0x4d414e4100000000000000000000000000000000000000000000000000000000;
    uint256 public constant REQUIRED_ALLOWANCE = 1000000000 * 10**18;

    event RequestedMortgage(
        uint256 _id,
        address _borrower,
        address _engine,
        uint256 _loanId,
        address _landMarket,
        uint256 _landId,
        uint256 _deposit,
        address _tokenConverter
    );

    event ReadedOracle(
        address _oracle,
        bytes32 _currency,
        uint256 _decimals,
        uint256 _rate
    );

    event StartedMortgage(uint256 _id);
    event CanceledMortgage(address _from, uint256 _id);
    event PaidMortgage(address _from, uint256 _id);
    event DefaultedMortgage(uint256 _id);
    event UpdatedLandData(address _updater, uint256 _parcel, string _data);
    event SetCreator(address _creator, bool _status);
    event SetEngine(address _engine, bool _status);

    Token public rcn;
    Token public mana;
    Land public land;
    
    constructor(
        Token _rcn,
        Token _mana,
        Land _land
    ) public ERC721Base("Decentraland RCN Mortgage", "LAND-RCN-M") {
        rcn = _rcn;
        mana = _mana;
        land = _land;
        mortgages.length++;
    }

    enum Status { Pending, Ongoing, Canceled, Paid, Defaulted }

    struct Mortgage {
        LandMarket landMarket;
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
    mapping(address => bool) public engines;

    mapping(uint256 => uint256) public mortgageByLandId;
    mapping(address => mapping(uint256 => uint256)) public loanToLiability;

    function url() public view returns (string) {
        return "";
    }

    function setEngine(address engine, bool authorized) external onlyOwner returns (bool) {
        emit SetEngine(engine, authorized);
        engines[engine] = authorized;
        return true;
    }

    function setURIProvider(URIProvider _provider) external onlyOwner returns (bool) {
        return _setURIProvider(_provider);
    }

     
    function setCreator(address creator, bool authorized) external onlyOwner returns (bool) {
        emit SetCreator(creator, authorized);
        creators[creator] = authorized;
        return true;
    }

     
    function cost(address, uint256, bytes, bytes) public view returns (uint256) {
        return 0;
    }

     
    function requestMortgage(
        Engine engine,
        bytes32 loanIdentifier,
        uint256 deposit,
        LandMarket landMarket,
        uint256 landId,
        TokenConverter tokenConverter
    ) external returns (uint256 id) {
        return requestMortgageId(engine, landMarket, engine.identifierToIndex(loanIdentifier), deposit, landId, tokenConverter);
    }

     
    function requestMortgageId(
        Engine engine,
        LandMarket landMarket,
        uint256 loanId,
        uint256 deposit,
        uint256 landId,
        TokenConverter tokenConverter
    ) public returns (uint256 id) {
         
        require(engine.getCurrency(loanId) == MANA_CURRENCY, "Loan currency is not MANA");
        address borrower = engine.getBorrower(loanId);

        require(engines[engine], "Engine not authorized");
        require(engine.getStatus(loanId) == Engine.Status.initial, "Loan status is not inital");
        require(
            msg.sender == borrower || (msg.sender == engine.getCreator(loanId) && creators[msg.sender]),
            "Creator should be borrower or authorized"
        );
        require(engine.isApproved(loanId), "Loan is not approved");
        require(rcn.allowance(borrower, this) >= REQUIRED_ALLOWANCE, "Manager cannot handle borrower's funds");
        require(tokenConverter != address(0), "Token converter not defined");
        require(loanToLiability[engine][loanId] == 0, "Liability for loan already exists");

         
        uint256 landCost;
        (, , landCost, ) = landMarket.auctionByAssetId(landId);
        uint256 loanAmount = engine.getAmount(loanId);

         
        require(loanAmount + deposit >= landCost, "Not enought total amount");

         
        require(mana.transferFrom(msg.sender, this, deposit), "Error pulling mana");
        
         
        id = mortgages.push(Mortgage({
            owner: borrower,
            engine: engine,
            loanId: loanId,
            deposit: deposit,
            landMarket: landMarket,
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
            _landMarket: landMarket,
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
        require(engines[engine], "Engine not authorized");

         
        mortgage.status = Status.Ongoing;

         
        _generate(uint256(readBytes32(data, 0)), mortgage.owner);

         
        uint256 loanAmount = convertRate(engine.getOracle(index), engine.getCurrency(index), oracleData, engine.getAmount(index));
        require(rcn.transferFrom(mortgage.owner, this, loanAmount), "Error pulling RCN from borrower");
        
         
         
        uint256 boughtMana = convertSafe(mortgage.tokenConverter, rcn, mana, loanAmount);
        delete mortgage.tokenConverter;

         
        uint256 currentLandCost;
        (, , currentLandCost, ) = mortgage.landMarket.auctionByAssetId(mortgage.landId);
        require(currentLandCost <= mortgage.landCost, "Parcel is more expensive than expected");
        
         
        require(mana.approve(mortgage.landMarket, currentLandCost), "Error approving mana transfer");
        flagReceiveLand = mortgage.landId;
        mortgage.landMarket.executeOrder(mortgage.landId, currentLandCost);
        require(mana.approve(mortgage.landMarket, 0), "Error removing approve mana transfer");
        require(flagReceiveLand == 0, "ERC721 callback not called");
        require(land.ownerOf(mortgage.landId) == address(this), "Error buying parcel");

         
        land.setUpdateOperator(mortgage.landId, mortgage.owner);

         
         
        uint256 totalMana = boughtMana.add(mortgage.deposit);        
        uint256 rest = totalMana.sub(currentLandCost);

         
        require(mana.transfer(mortgage.owner, rest), "Error returning MANA");
        
         
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
        require(from.approve(converter, amount), "Error approve convert safe");
        uint256 prevBalance = to.balanceOf(this);
        bought = converter.convert(from, to, amount, 1);
        require(to.balanceOf(this).sub(prevBalance) >= bought, "Bought amount incorrect");
        require(from.approve(converter, 0), "Error remove approve convert safe");
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

     
    function onERC721Received(address, address, uint256 _tokenId, bytes) external returns (bytes4) {
        if (msg.sender == address(land) && flagReceiveLand == _tokenId) {
            flagReceiveLand = 0;
            return bytes4(0x150b7a02);
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
        require(_isAuthorized(msg.sender, id), "Sender not authorized");
        (int256 x, int256 y) = land.decodeTokenId(mortgages[id].landId);
        land.updateLandData(x, y, data);
        emit UpdatedLandData(msg.sender, id, data);
        return true;
    }

     
    function convertRate(Oracle oracle, bytes32 currency, bytes data, uint256 amount) internal returns (uint256) {
        if (oracle == address(0)) {
            return amount;
        } else {
            (uint256 rate, uint256 decimals) = oracle.getRate(currency, data);
            emit ReadedOracle(oracle, currency, decimals, rate);
            require(decimals <= RCN_DECIMALS, "Decimals exceeds max decimals");
            return amount.mult(rate.mult(10**(RCN_DECIMALS-decimals))) / PRECISION;
        }
    }

     
     
     
    function _doTransferFrom(
        address _from,
        address _to,
        uint256 _assetId,
        bytes _userData,
        bool _doCheck
    )
        internal
    {
        ERC721Base._doTransferFrom(_from, _to, _assetId, _userData, _doCheck);
        land.setUpdateOperator(mortgages[_assetId].landId, _to);
    }
}

 

interface NanoLoanEngine {
    function createLoan(address _oracleContract, address _borrower, bytes32 _currency, uint256 _amount, uint256 _interestRate,
        uint256 _interestRatePunitory, uint256 _duesIn, uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256);
    function getIdentifier(uint256 index) public view returns (bytes32);
    function registerApprove(bytes32 identifier, uint8 v, bytes32 r, bytes32 s) public returns (bool);
    function pay(uint index, uint256 _amount, address _from, bytes oracleData) public returns (bool);
    function rcn() public view returns (Token);
    function getOracle(uint256 index) public view returns (Oracle);
    function getAmount(uint256 index) public view returns (uint256);
    function getCurrency(uint256 index) public view returns (bytes32);
    function convertRate(Oracle oracle, bytes32 currency, bytes data, uint256 amount) public view returns (uint256);
    function lend(uint index, bytes oracleData, Cosigner cosigner, bytes cosignerData) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
}

 

library LrpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a < b) { 
            return a;
        } else { 
            return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a > b) { 
            return a;
        } else { 
            return b; 
        }
    }
}

 

contract ConverterRamp is Ownable {
    using LrpSafeMath for uint256;

    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    uint256 public constant AUTO_MARGIN = 1000001;

    uint256 public constant I_MARGIN_SPEND = 0;
    uint256 public constant I_MAX_SPEND = 1;
    uint256 public constant I_REBUY_THRESHOLD = 2;

    uint256 public constant I_ENGINE = 0;
    uint256 public constant I_INDEX = 1;

    uint256 public constant I_PAY_AMOUNT = 2;
    uint256 public constant I_PAY_FROM = 3;

    uint256 public constant I_LEND_COSIGNER = 2;

    event RequiredRebuy(address token, uint256 amount);
    event Return(address token, address to, uint256 amount);
    event OptimalSell(address token, uint256 amount);
    event RequiredRcn(uint256 required);
    event RunAutoMargin(uint256 loops, uint256 increment);

    function pay(
        TokenConverter converter,
        Token fromToken,
        bytes32[4] loanParams,
        bytes oracleData,
        uint256[3] convertRules
    ) external payable returns (bool) {
        Token rcn = NanoLoanEngine(address(loanParams[I_ENGINE])).rcn();

        uint256 initialBalance = rcn.balanceOf(this);
        uint256 requiredRcn = getRequiredRcnPay(loanParams, oracleData);
        emit RequiredRcn(requiredRcn);

        uint256 optimalSell = getOptimalSell(converter, fromToken, rcn, requiredRcn, convertRules[I_MARGIN_SPEND]);
        emit OptimalSell(fromToken, optimalSell);

        pullAmount(fromToken, optimalSell);
        uint256 bought = convertSafe(converter, fromToken, rcn, optimalSell);

         
        require(
            executeOptimalPay({
                params: loanParams,
                oracleData: oracleData,
                rcnToPay: bought
            }),
            "Error paying the loan"
        );

        require(
            rebuyAndReturn({
                converter: converter,
                fromToken: rcn,
                toToken: fromToken,
                amount: rcn.balanceOf(this) - initialBalance,
                spentAmount: optimalSell,
                convertRules: convertRules
            }),
            "Error rebuying the tokens"
        );

        require(rcn.balanceOf(this) == initialBalance, "Converter balance has incremented");
        return true;
    }

    function requiredLendSell(
        TokenConverter converter,
        Token fromToken,
        bytes32[3] loanParams,
        bytes oracleData,
        bytes cosignerData,
        uint256[3] convertRules
    ) external view returns (uint256) {
        Token rcn = NanoLoanEngine(address(loanParams[0])).rcn();
        return getOptimalSell(
            converter,
            fromToken,
            rcn,
            getRequiredRcnLend(loanParams, oracleData, cosignerData),
            convertRules[I_MARGIN_SPEND]
        );
    }

    function requiredPaySell(
        TokenConverter converter,
        Token fromToken,
        bytes32[4] loanParams,
        bytes oracleData,
        uint256[3] convertRules
    ) external view returns (uint256) {
        Token rcn = NanoLoanEngine(address(loanParams[0])).rcn();
        return getOptimalSell(
            converter,
            fromToken,
            rcn,
            getRequiredRcnPay(loanParams, oracleData),
            convertRules[I_MARGIN_SPEND]
        );
    }

    function lend(
        TokenConverter converter,
        Token fromToken,
        bytes32[3] loanParams,
        bytes oracleData,
        bytes cosignerData,
        uint256[3] convertRules
    ) external payable returns (bool) {
        Token rcn = NanoLoanEngine(address(loanParams[0])).rcn();
        uint256 initialBalance = rcn.balanceOf(this);
        uint256 requiredRcn = getRequiredRcnLend(loanParams, oracleData, cosignerData);
        emit RequiredRcn(requiredRcn);

        uint256 optimalSell = getOptimalSell(converter, fromToken, rcn, requiredRcn, convertRules[I_MARGIN_SPEND]);
        emit OptimalSell(fromToken, optimalSell);

        pullAmount(fromToken, optimalSell);      
        uint256 bought = convertSafe(converter, fromToken, rcn, optimalSell);

         
        require(rcn.approve(address(loanParams[0]), bought));
        require(executeLend(loanParams, oracleData, cosignerData), "Error lending the loan");
        require(rcn.approve(address(loanParams[0]), 0));
        require(executeTransfer(loanParams, msg.sender), "Error transfering the loan");

        require(
            rebuyAndReturn({
                converter: converter,
                fromToken: rcn,
                toToken: fromToken,
                amount: rcn.balanceOf(this) - initialBalance,
                spentAmount: optimalSell,
                convertRules: convertRules
            }),
            "Error rebuying the tokens"
        );

        require(rcn.balanceOf(this) == initialBalance);
        return true;
    }

    function pullAmount(
        Token token,
        uint256 amount
    ) private {
        if (token == ETH_ADDRESS) {
            require(msg.value >= amount, "Error pulling ETH amount");
            if (msg.value > amount) {
                msg.sender.transfer(msg.value - amount);
            }
        } else {
            require(token.transferFrom(msg.sender, this, amount), "Error pulling Token amount");
        }
    }

    function transfer(
        Token token,
        address to,
        uint256 amount
    ) private {
        if (token == ETH_ADDRESS) {
            to.transfer(amount);
        } else {
            require(token.transfer(to, amount), "Error sending tokens");
        }
    }

    function rebuyAndReturn(
        TokenConverter converter,
        Token fromToken,
        Token toToken,
        uint256 amount,
        uint256 spentAmount,
        uint256[3] memory convertRules
    ) internal returns (bool) {
        uint256 threshold = convertRules[I_REBUY_THRESHOLD];
        uint256 bought = 0;

        if (amount != 0) {
            if (amount > threshold) {
                bought = convertSafe(converter, fromToken, toToken, amount);
                emit RequiredRebuy(toToken, amount);
                emit Return(toToken, msg.sender, bought);
                transfer(toToken, msg.sender, bought);
            } else {
                emit Return(fromToken, msg.sender, amount);
                transfer(fromToken, msg.sender, amount);
            }
        }

        uint256 maxSpend = convertRules[I_MAX_SPEND];
        require(spentAmount.safeSubtract(bought) <= maxSpend || maxSpend == 0, "Max spend exceeded");
        
        return true;
    } 

    function getOptimalSell(
        TokenConverter converter,
        Token fromToken,
        Token toToken,
        uint256 requiredTo,
        uint256 extraSell
    ) internal returns (uint256 sellAmount) {
        uint256 sellRate = (10 ** 18 * converter.getReturn(toToken, fromToken, requiredTo)) / requiredTo;
        if (extraSell == AUTO_MARGIN) {
            uint256 expectedReturn = 0;
            uint256 optimalSell = applyRate(requiredTo, sellRate);
            uint256 increment = applyRate(requiredTo / 100000, sellRate);
            uint256 returnRebuy;
            uint256 cl;

            while (expectedReturn < requiredTo && cl < 10) {
                optimalSell += increment;
                returnRebuy = converter.getReturn(fromToken, toToken, optimalSell);
                optimalSell = (optimalSell * requiredTo) / returnRebuy;
                expectedReturn = returnRebuy;
                cl++;
            }
            emit RunAutoMargin(cl, increment);

            return optimalSell;
        } else {
            return applyRate(requiredTo, sellRate).safeMult(uint256(100000).safeAdd(extraSell)) / 100000;
        }
    }

    function convertSafe(
        TokenConverter converter,
        Token fromToken,
        Token toToken,
        uint256 amount
    ) internal returns (uint256 bought) {
        if (fromToken != ETH_ADDRESS) require(fromToken.approve(converter, amount));
        uint256 prevBalance = toToken != ETH_ADDRESS ? toToken.balanceOf(this) : address(this).balance;
        uint256 sendEth = fromToken == ETH_ADDRESS ? amount : 0;
        uint256 boughtAmount = converter.convert.value(sendEth)(fromToken, toToken, amount, 1);
        require(
            boughtAmount == (toToken != ETH_ADDRESS ? toToken.balanceOf(this) : address(this).balance) - prevBalance,
            "Bought amound does does not match"
        );
        if (fromToken != ETH_ADDRESS) require(fromToken.approve(converter, 0));
        return boughtAmount;
    }

    function executeOptimalPay(
        bytes32[4] memory params,
        bytes oracleData,
        uint256 rcnToPay
    ) internal returns (bool) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        Oracle oracle = engine.getOracle(index);

        uint256 toPay;

        if (oracle == address(0)) {
            toPay = rcnToPay;
        } else {
            uint256 rate;
            uint256 decimals;
            bytes32 currency = engine.getCurrency(index);

            (rate, decimals) = oracle.getRate(currency, oracleData);
            toPay = (rcnToPay * (10 ** (18 - decimals + (18 * 2)) / rate)) / 10 ** 18;
        }

        Token rcn = engine.rcn();
        require(rcn.approve(engine, rcnToPay));
        require(engine.pay(index, toPay, address(params[I_PAY_FROM]), oracleData), "Error paying the loan");
        require(rcn.approve(engine, 0));
        
        return true;
    }

    function executeLend(
        bytes32[3] memory params,
        bytes oracleData,
        bytes cosignerData
    ) internal returns (bool) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        return engine.lend(index, oracleData, Cosigner(address(params[I_LEND_COSIGNER])), cosignerData);
    }

    function executeTransfer(
        bytes32[3] memory params,
        address to
    ) internal returns (bool) {
        return NanoLoanEngine(address(params[0])).transfer(to, uint256(params[1]));
    }

    function applyRate(
        uint256 amount,
        uint256 rate
    ) pure internal returns (uint256) {
        return amount.safeMult(rate) / 10 ** 18;
    }

    function getRequiredRcnLend(
        bytes32[3] memory params,
        bytes oracleData,
        bytes cosignerData
    ) internal returns (uint256 required) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        Cosigner cosigner = Cosigner(address(params[I_LEND_COSIGNER]));

        if (cosigner != address(0)) {
            required += cosigner.cost(engine, index, cosignerData, oracleData);
        }
        required += engine.convertRate(engine.getOracle(index), engine.getCurrency(index), oracleData, engine.getAmount(index));
    }
    
    function getRequiredRcnPay(
        bytes32[4] memory params,
        bytes oracleData
    ) internal returns (uint256) {
        NanoLoanEngine engine = NanoLoanEngine(address(params[I_ENGINE]));
        uint256 index = uint256(params[I_INDEX]);
        uint256 amount = uint256(params[I_PAY_AMOUNT]);
        return engine.convertRate(engine.getOracle(index), engine.getCurrency(index), oracleData, amount);
    }

    function sendTransaction(
        address to,
        uint256 value,
        bytes data
    ) external onlyOwner returns (bool) {
        return to.call.value(value)(data);
    }

    function() external {}
}

 

 
contract MortgageHelper is Ownable {
    using LrpSafeMath for uint256;

    MortgageManager public mortgageManager;
    NanoLoanEngine public nanoLoanEngine;
    Token public rcn;
    Token public mana;
    LandMarket public landMarket;
    TokenConverter public tokenConverter;
    ConverterRamp public converterRamp;

    address public manaOracle;
    uint256 public requiredTotal = 105;

    uint256 public rebuyThreshold = 0.001 ether;
    uint256 public marginSpend = 500;
    uint256 public maxSpend = 300;

    bytes32 public constant MANA_CURRENCY = 0x4d414e4100000000000000000000000000000000000000000000000000000000;

    event NewMortgage(address borrower, uint256 loanId, uint256 landId, uint256 mortgageId);
    event PaidLoan(address engine, uint256 loanId, uint256 amount);

    event SetRebuyThreshold(uint256 _prev, uint256 _new);
    event SetMarginSpend(uint256 _prev, uint256 _new);
    event SetMaxSpend(uint256 _prev, uint256 _new);
    event SetRequiredTotal(uint256 _prev, uint256 _new);

    event SetTokenConverter(address _prev, address _new);
    event SetConverterRamp(address _prev, address _new);
    event SetManaOracle(address _manaOracle);
    event SetEngine(address _engine);
    event SetLandMarket(address _landMarket);
    event SetMortgageManager(address _mortgageManager);

    constructor(
        MortgageManager _mortgageManager,
        NanoLoanEngine _nanoLoanEngine,
        LandMarket _landMarket,
        address _manaOracle,
        TokenConverter _tokenConverter,
        ConverterRamp _converterRamp
    ) public {
        mortgageManager = _mortgageManager;
        nanoLoanEngine = _nanoLoanEngine;
        rcn = _mortgageManager.rcn();
        mana = _mortgageManager.mana();
        landMarket = _landMarket;
        manaOracle = _manaOracle;
        tokenConverter = _tokenConverter;
        converterRamp = _converterRamp;

         
        require(_nanoLoanEngine.rcn() == rcn, "RCN Mismatch");
        require(_mortgageManager.engines(_nanoLoanEngine), "Engine is not approved");
        require(_isContract(mana), "MANA should be a contract");
        require(_isContract(rcn), "RCN should be a contract");
        require(_isContract(_tokenConverter), "Token converter should be a contract");
        require(_isContract(_landMarket), "Land market should be a contract");
        require(_isContract(_converterRamp), "Converter ramp should be a contract");
        require(_isContract(_manaOracle), "MANA Oracle should be a contract");
        require(_isContract(_mortgageManager), "Mortgage manager should be a contract");

        emit SetConverterRamp(converterRamp, _converterRamp);
        emit SetTokenConverter(tokenConverter, _tokenConverter);

        emit SetEngine(_nanoLoanEngine);
        emit SetLandMarket(_landMarket);
        emit SetMortgageManager(_mortgageManager);
        emit SetManaOracle(_manaOracle);

        emit SetMaxSpend(0, maxSpend);
        emit SetMarginSpend(0, marginSpend);
        emit SetRebuyThreshold(0, rebuyThreshold);
        emit SetRequiredTotal(0, requiredTotal);
    }

     
    function createLoan(uint256[6] memory params, string metadata) internal returns (uint256) {
        return nanoLoanEngine.createLoan(
            manaOracle,
            msg.sender,
            MANA_CURRENCY,
            params[0],
            params[1],
            params[2],
            params[3],
            params[4],
            params[5],
            metadata
        );
    }

     
    function setMaxSpend(uint256 _maxSpend) external onlyOwner returns (bool) {
        emit SetMaxSpend(maxSpend, _maxSpend);
        maxSpend = _maxSpend;
        return true;
    }

     
    function setRequiredTotal(uint256 _requiredTotal) external onlyOwner returns (bool) {
        emit SetRequiredTotal(requiredTotal, _requiredTotal);
        requiredTotal = _requiredTotal;
        return true;
    }


     
    function setConverterRamp(ConverterRamp _converterRamp) external onlyOwner returns (bool) {
        require(_isContract(_converterRamp), "Should be a contract");
        emit SetConverterRamp(converterRamp, _converterRamp);
        converterRamp = _converterRamp;
        return true;
    }

     
    function setRebuyThreshold(uint256 _rebuyThreshold) external onlyOwner returns (bool) {
        emit SetRebuyThreshold(rebuyThreshold, _rebuyThreshold);
        rebuyThreshold = _rebuyThreshold;
        return true;
    }

     
    function setMarginSpend(uint256 _marginSpend) external onlyOwner returns (bool) {
        emit SetMarginSpend(marginSpend, _marginSpend);
        marginSpend = _marginSpend;
        return true;
    }

     
    function setTokenConverter(TokenConverter _tokenConverter) external onlyOwner returns (bool) {
        require(_isContract(_tokenConverter), "Should be a contract");
        emit SetTokenConverter(tokenConverter, _tokenConverter);
        tokenConverter = _tokenConverter;
        return true;
    }

    function setManaOracle(address _manaOracle) external onlyOwner returns (bool) {
        require(_isContract(_manaOracle), "Should be a contract");
        emit SetManaOracle(_manaOracle);
        manaOracle = _manaOracle;
        return true;
    }

    function setEngine(NanoLoanEngine _engine) external onlyOwner returns (bool) {
        require(_isContract(_engine), "Should be a contract");
        emit SetEngine(_engine);
        nanoLoanEngine = _engine;
        return true;
    }

    function setLandMarket(LandMarket _landMarket) external onlyOwner returns (bool) {
        require(_isContract(_landMarket), "Should be a contract");
        emit SetLandMarket(_landMarket);
        landMarket = _landMarket;
        return true;
    }

    function setMortgageManager(MortgageManager _mortgageManager) external onlyOwner returns (bool) {
        require(_isContract(_mortgageManager), "Should be a contract");
        emit SetMortgageManager(_mortgageManager);
        mortgageManager = _mortgageManager;
        return true;
    }

     
    function requestMortgage(
        uint256[6] loanParams,
        string metadata,
        uint256 landId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
         
        uint256 loanId = createLoan(loanParams, metadata);

         
        NanoLoanEngine _nanoLoanEngine = nanoLoanEngine;

         
        require(_nanoLoanEngine.registerApprove(_nanoLoanEngine.getIdentifier(loanId), v, r, s), "Signature not valid");

         
        uint256 requiredDeposit = ((readLandCost(landId) * requiredTotal) / 100) - _nanoLoanEngine.getAmount(loanId);
        
         
        Token _mana = mana;
        _tokenTransferFrom(_mana, msg.sender, this, requiredDeposit);
        require(_mana.approve(mortgageManager, requiredDeposit), "Error approve MANA transfer");

         
        uint256 mortgageId = mortgageManager.requestMortgageId(
            Engine(_nanoLoanEngine),
            landMarket,
            loanId,
            requiredDeposit, 
            landId,
            tokenConverter
        );

        require(_mana.approve(mortgageManager, 0), "Error remove approve MANA transfer");

        emit NewMortgage(msg.sender, loanId, landId, mortgageId);
        
        return mortgageId;
    }

    function readLandCost(uint256 _landId) internal view returns (uint256 landCost) {
        (, , landCost, ) = landMarket.auctionByAssetId(_landId);
    }

     
    function pay(address engine, uint256 loan, uint256 amount) external returns (bool) {
        emit PaidLoan(engine, loan, amount);

        bytes32[4] memory loanParams = [
            bytes32(engine),
            bytes32(loan),
            bytes32(amount),
            bytes32(msg.sender)
        ];

        uint256[3] memory converterParams = [
            marginSpend,
            amount.safeMult(uint256(100000).safeAdd(maxSpend)) / 100000,
            rebuyThreshold
        ];

        require(address(converterRamp).delegatecall(
            bytes4(0x86ee863d),
            address(tokenConverter),
            address(mana),
            loanParams,
            0x140,
            converterParams,
            0x0
        ), "Error delegate pay call");
    }

    function _tokenTransferFrom(Token token, address from, address to, uint256 amount) internal {
        require(token.balanceOf(from) >= amount, "From balance is not enough");
        require(token.allowance(from, address(this)) >= amount, "Allowance is not enough");
        require(token.transferFrom(from, to, amount), "Transfer failed");
    }

    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}