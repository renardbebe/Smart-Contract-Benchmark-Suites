 

pragma solidity ^0.4.24;

 
interface IERC165 {

   
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}



 
contract ERC165 is IERC165 {

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
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

   
   

   
}


 
contract IERC721Receiver {
   
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
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

   
   
}


 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}


 
contract ERC721_custom is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;

   
   
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) private _tokenOwner;

   
  mapping (uint256 => address) private _tokenApprovals;

   
  mapping (address => uint256) private _ownedTokensCount;

   
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
   

  constructor()
    public
  {
     
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

   
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
   

    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);

    emit Transfer(from, to, tokenId);
  }
  
  
  
  
    function internal_transferFrom(
        address _from,
        address to,
        uint256 tokenId
    )
    internal
  {
     
    
    

    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
    
     
    if(_ownedTokensCount[_from] > 1) {
    _ownedTokensCount[_from] = _ownedTokensCount[_from] -1;  
     
    
    }
    _tokenOwner[tokenId] = address(0); 
    
    _addTokenTo(to, tokenId);  

    emit Transfer(_from, to, tokenId);
    
  }

   
   

   
   

   
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

   
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
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
  
  

   
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

   
  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}




 
contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}



 
contract ERC721Enumerable_custom is ERC165, ERC721_custom, IERC721Enumerable {
   
  mapping(address => uint256[]) private _ownedTokens;

   
  mapping(uint256 => uint256) private _ownedTokensIndex;

   
  uint256[] private _allTokens;

   
  mapping(uint256 => uint256) private _allTokensIndex;

  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
   

   
  constructor() public {
     
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

   
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

   
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

   
  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

   
  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

   
  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);

     
     
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];

    _ownedTokens[from][tokenIndex] = lastToken;
     
    _ownedTokens[from].length--;

     
     
     

    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);

    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

   
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;

    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}






contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}


contract ERC721Metadata_custom is ERC165, ERC721_custom, IERC721Metadata {
   
  string private _name;

   
  string private _symbol;

   
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;

     
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  function name() external view returns (string) {
    return _name;
  }

  
  function symbol() external view returns (string) {
    return _symbol;
  }

   
  
  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

     
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}


contract ERC721Full_custom is ERC721_custom, ERC721Enumerable_custom, ERC721Metadata_custom {
  constructor(string name, string symbol) ERC721Metadata_custom(name, symbol)
    public
  {
  }
}


interface PlanetCryptoCoin_I {
    function balanceOf(address owner) external returns(uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}

interface PlanetCryptoUtils_I {
    function validateLand(address _sender, int256[] plots_lat, int256[] plots_lng) external returns(bool);
    function validatePurchase(address _sender, uint256 _value, int256[] plots_lat, int256[] plots_lng) external returns(bool);
    function validateTokenPurchase(address _sender, int256[] plots_lat, int256[] plots_lng) external returns(bool);
    function validateResale(address _sender, uint256 _value, uint256 _token_id) external returns(bool);
    function validateLandTakeover(address _sender, uint256 _value, uint256 _token_id) external returns(bool);
     
    function strConcat(string _a, string _b, string _c, string _d, string _e, string _f) external view returns (string);
    function strConcat(string _a, string _b, string _c, string _d, string _e) external view returns (string);
    function strConcat(string _a, string _b, string _c, string _d) external view returns (string);
    function strConcat(string _a, string _b, string _c) external view returns (string);
    function strConcat(string _a, string _b) external view returns (string);
    function int2str(int i) external view returns (string);
    function uint2str(uint i) external view returns (string);
    function substring(string str, uint startIndex, uint endIndex) external view returns (string);
    function utfStringLength(string str) external view returns (uint length);
    function ceil1(int256 a, int256 m) external view returns (int256 );
    function parseInt(string _a, uint _b) external view returns (uint);
    
    function roundLatLngFull(uint8 _zoomLvl, int256 __in) external pure returns(int256);
}

interface PlanetCryptoToken_I {
    
    function all_playerObjects(uint256) external returns(
        address playerAddress,
        uint256 lastAccess,
        uint256 totalEmpireScore,
        uint256 totalLand);
        
    function balanceOf(address) external returns(uint256);
    
    function getAllPlayerObjectLen() external returns(uint256);
    
    function getToken(uint256 _token_id, bool isBasic) external returns(
        address token_owner,
        bytes32  name,
        uint256 orig_value,
        uint256 current_value,
        uint256 empire_score,
        int256[] plots_lat,
        int256[] plots_lng
        );
        
    
    function tax_distributed() external returns(uint256);
    function tax_fund() external returns(uint256);
    
    function taxEarningsAvailable() external returns(uint256);
    
    function tokens_rewards_allocated() external returns(uint256);
    function tokens_rewards_available() external returns(uint256);
    
    function total_empire_score() external returns(uint256);
    function total_land_sold() external returns(uint256);
    function total_trades() external returns(uint256);
    function totalSupply() external returns(uint256);
    function current_plot_price() external returns(uint256);
    
    
}


library Percent {

  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }
 
}



contract PlanetCryptoToken is ERC721Full_custom{
    
    using Percent for Percent.percent;
    
    
     
        
    event referralPaid(address indexed search_to,
                    address to, uint256 amnt, uint256 timestamp);
    
    event issueCoinTokens(address indexed searched_to, 
                    address to, uint256 amnt, uint256 timestamp);
    
    event landPurchased(uint256 indexed search_token_id, address indexed search_buyer, 
            uint256 token_id, address buyer, bytes32 name, int256 center_lat, int256 center_lng, uint256 size, uint256 bought_at, uint256 empire_score, uint256 timestamp);
    
    event taxDistributed(uint256 amnt, uint256 total_players, uint256 timestamp);
    
    event cardBought(
                    uint256 indexed search_token_id, address indexed search_from, address indexed search_to,
                    uint256 token_id, address from, address to, 
                    bytes32 name,
                    uint256 orig_value, 
                    uint256 new_value,
                    uint256 empireScore, uint256 newEmpireScore, uint256 timestamp);

    event cardChange(
            uint256 indexed search_token_id,
            address indexed search_owner, 
            uint256 token_id,
            address owner, uint256 changeType, bytes32 data, uint256 timestamp);
            

     
    address owner;
    address devBankAddress;  
    address tokenBankAddress; 

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier validateLand(int256[] plots_lat, int256[] plots_lng) {
        
        require(planetCryptoUtils_interface.validateLand(msg.sender, plots_lat, plots_lng) == true, "Some of this land already owned!");

        
        _;
    }
    
    modifier validatePurchase(int256[] plots_lat, int256[] plots_lng) {

        require(planetCryptoUtils_interface.validatePurchase(msg.sender, msg.value, plots_lat, plots_lng) == true, "Not enough ETH!");
        _;
    }
    
    
    modifier validateTokenPurchase(int256[] plots_lat, int256[] plots_lng) {

        require(planetCryptoUtils_interface.validateTokenPurchase(msg.sender, plots_lat, plots_lng) == true, "Not enough COINS to buy these plots!");
        

        

        require(planetCryptoCoin_interface.transferFrom(msg.sender, tokenBankAddress, plots_lat.length) == true, "Token transfer failed");
        
        
        _;
    }
    
    
    modifier validateResale(uint256 _token_id) {
        require(planetCryptoUtils_interface.validateResale(msg.sender, msg.value, _token_id) == true, "Not enough ETH to buy this card!");
        _;
    }
    
    
    modifier updateUsersLastAccess() {
        
        uint256 allPlyersIdx = playerAddressToPlayerObjectID[msg.sender];
        if(allPlyersIdx == 0){

            all_playerObjects.push(player(msg.sender,now,0,0));
            playerAddressToPlayerObjectID[msg.sender] = all_playerObjects.length-1;
        } else {
            all_playerObjects[allPlyersIdx].lastAccess = now;
        }
        
        _;
    }
    
     
    struct plotDetail {
        bytes32 name;
        uint256 orig_value;
        uint256 current_value;
        uint256 empire_score;
        int256[] plots_lat;
        int256[] plots_lng;
        bytes32 img;
    }
    
    struct plotBasic {
        int256 lat;
        int256 lng;
    }
    
    struct player {
        address playerAddress;
        uint256 lastAccess;
        uint256 totalEmpireScore;
        uint256 totalLand;
        
        
    }
    

     
    address planetCryptoCoinAddress = 0xA1c8031EF18272d8BfeD22E1b61319D6d9d2881B;  
     
    PlanetCryptoCoin_I internal planetCryptoCoin_interface;
    

    address planetCryptoUtilsAddress = 0x40089b9f4d5eb36d62548133f32e52b14fa54c52;  
     
    PlanetCryptoUtils_I internal planetCryptoUtils_interface;
    
    
    
     
    Percent.percent private m_newPlot_devPercent = Percent.percent(75,100);  
    Percent.percent private m_newPlot_taxPercent = Percent.percent(25,100);  
    
    Percent.percent private m_resalePlot_devPercent = Percent.percent(10,100);  
    Percent.percent private m_resalePlot_taxPercent = Percent.percent(10,100);  
    Percent.percent private m_resalePlot_ownerPercent = Percent.percent(80,100);  
    
     
     
     
    
    Percent.percent private m_refPercent = Percent.percent(5,100);  
    
    Percent.percent private m_empireScoreMultiplier = Percent.percent(150,100);  
    Percent.percent private m_resaleMultipler = Percent.percent(200,100);  

    

    
    
    uint256 public devHoldings = 0;  


    mapping(address => uint256) internal playersFundsOwed;




     
    uint256 public tokens_rewards_available;
    uint256 public tokens_rewards_allocated;
    
     
    uint256 public min_plots_purchase_for_token_reward = 10;
    uint256 public plots_token_reward_divisor = 10;
    
    
     
    uint256 public current_plot_price = 20000000000000000;
    uint256 public price_update_amount = 2000000000000;
    uint256 public cardChangeNameCost = 50000000000000000;
    uint256 public cardImageCost = 100000000000000000;

    uint256 public current_plot_empire_score = 100;

    string public baseURI = 'https: 
    
    
    uint256 public tax_fund = 0;
    uint256 public tax_distributed = 0;


     
    uint256 public tokenIDCount = 0;
    bool public game_started = false;
    uint256 public total_land_sold = 0;
    uint256 public total_trades = 0;
    uint256 internal tax_carried_forward = 0;
    
    uint256 public total_empire_score; 
    player[] public all_playerObjects;
    mapping(address => uint256) internal playerAddressToPlayerObjectID;
    
    
    
    
    plotDetail[] plotDetails;
    mapping(uint256 => uint256) internal tokenIDplotdetailsIndexId;  



    
    mapping(int256 => mapping(int256 => uint256)) internal latlngTokenID_grids;
     
     
     
    
    
    
    mapping(uint8 => mapping(int256 => mapping(int256 => uint256))) internal latlngTokenID_zoomAll;

    mapping(uint8 => mapping(uint256 => plotBasic[])) internal tokenIDlatlngLookup_zoomAll;


    PlanetCryptoToken internal planetCryptoToken_I = PlanetCryptoToken(0x1806B3527C18Fb532C46405f6f014C1F381b499A);
     
    
    constructor() ERC721Full_custom("PlanetCrypto", "PLANET") public {
        owner = msg.sender;
        tokenBankAddress = owner;
        devBankAddress = owner;
        planetCryptoCoin_interface = PlanetCryptoCoin_I(planetCryptoCoinAddress);
        planetCryptoUtils_interface = PlanetCryptoUtils_I(planetCryptoUtilsAddress);
        all_playerObjects.push(player(address(0x0),0,0,0));
        playerAddressToPlayerObjectID[address(0x0)] = 0;
        
        
    
        total_trades = planetCryptoToken_I.total_trades();
        total_land_sold = planetCryptoToken_I.total_land_sold();
        total_empire_score = planetCryptoToken_I.total_empire_score();
        tokens_rewards_available = planetCryptoToken_I.tokens_rewards_available();
        tokens_rewards_allocated = planetCryptoToken_I.tokens_rewards_allocated();
        tax_distributed = planetCryptoToken_I.tax_distributed();
        tax_fund = 0;
        current_plot_price = planetCryptoToken_I.current_plot_price();
        

        
    }
    
    function initPlayers(uint32 _start, uint32 _end) public onlyOwner {
        require(game_started == false);
        
        for(uint32 c=_start; c< _end+1; c++){
            transferPlayer(uint256(c));
        }
    }
    
    function transferPlayer(uint256 _player_id) internal {
        (address _playerAddress, uint256 _uint1, uint256 _uint2, uint256 _uint3) 
            =  planetCryptoToken_I.all_playerObjects(_player_id);
        

        all_playerObjects.push(
                player(
                    _playerAddress,
                    _uint1,
                    _uint2,
                    _uint3
                    )
                );
        playerAddressToPlayerObjectID[_playerAddress] = all_playerObjects.length-1;
    }
    
    
    function transferTokens(uint256 _start, uint256 _end) public onlyOwner {
        require(game_started == false);
        
        for(uint256 c=_start; c< _end+1; c++) {
            
            (
                address _playerAddress,
                bytes32 name,
                uint256 orig_value,
                uint256 current_value,
                uint256 empire_score,
                int256[] memory plots_lat,
                int256[] memory plots_lng
            ) = 
                planetCryptoToken_I.getToken(c, false);
    

            transferCards(c, _playerAddress, name, orig_value, current_value, empire_score, plots_lat, plots_lng);
        }
        
    }
    
    

    
    function transferCards(
                            uint256 _cardID,
                            address token_owner,
                            bytes32 name,
                            uint256 orig_value,
                            uint256 current_value,
                            uint256 empire_score,
                            int256[] memory plots_lat,
                            int256[] memory plots_lng
                            ) internal {

        

       
        _mint(token_owner, _cardID);
        tokenIDCount = tokenIDCount + 1;
            
        plotDetails.push(plotDetail(
            name,
            orig_value,
            current_value,
            empire_score,
            plots_lat, plots_lng, ''
        ));
        
        tokenIDplotdetailsIndexId[_cardID] = plotDetails.length-1;
        
        
        setupPlotOwnership(_cardID, plots_lat, plots_lng);
        
        

    }
    

    function tokenURI(uint256 tokenId) external view returns (string) {
        require(_exists(tokenId));
        return planetCryptoUtils_interface.strConcat(baseURI, 
                    planetCryptoUtils_interface.uint2str(tokenId));
    }


    function getToken(uint256 _tokenId, bool isBasic) public view returns(
        address token_owner,
        bytes32 name,
        uint256 orig_value,
        uint256 current_value,
        uint256 empire_score,
        int256[] plots_lat,
        int256[] plots_lng
        ) {
        token_owner = ownerOf(_tokenId);
        plotDetail memory _plotDetail = plotDetails[tokenIDplotdetailsIndexId[_tokenId]];
        name = _plotDetail.name;
        empire_score = _plotDetail.empire_score;
        orig_value = _plotDetail.orig_value;
        current_value = _plotDetail.current_value;
        if(!isBasic){
            plots_lat = _plotDetail.plots_lat;
            plots_lng = _plotDetail.plots_lng;
        }
    }
    function getTokenEnhanced(uint256 _tokenId, bool isBasic) public view returns(
        address token_owner,
        bytes32 name,
        bytes32 img,
        uint256 orig_value,
        uint256 current_value,
        uint256 empire_score,
        int256[] plots_lat,
        int256[] plots_lng
        ) {
        token_owner = ownerOf(_tokenId);
        plotDetail memory _plotDetail = plotDetails[tokenIDplotdetailsIndexId[_tokenId]];
        name = _plotDetail.name;
        img = _plotDetail.img;
        empire_score = _plotDetail.empire_score;
        orig_value = _plotDetail.orig_value;
        current_value = _plotDetail.current_value;
        if(!isBasic){
            plots_lat = _plotDetail.plots_lat;
            plots_lng = _plotDetail.plots_lng;
        }
    }
    

    function taxEarningsAvailable() public view returns(uint256) {
        return playersFundsOwed[msg.sender];
    }

    function withdrawTaxEarning() public {
        uint256 taxEarnings = playersFundsOwed[msg.sender];
        playersFundsOwed[msg.sender] = 0;
        tax_fund = tax_fund.sub(taxEarnings);
        
        if(!msg.sender.send(taxEarnings)) {
            playersFundsOwed[msg.sender] = playersFundsOwed[msg.sender] + taxEarnings;
            tax_fund = tax_fund.add(taxEarnings);
        }
    }

    function buyLandWithTokens(bytes32 _name, int256[] _plots_lat, int256[] _plots_lng)
     validateTokenPurchase(_plots_lat, _plots_lng) validateLand(_plots_lat, _plots_lng) updateUsersLastAccess() public {
        require(_name.length > 4);
        

        processPurchase(_name, _plots_lat, _plots_lng); 
        game_started = true;
    }
    

    
    function buyLand(bytes32 _name, 
            int256[] _plots_lat, int256[] _plots_lng,
            address _referrer
            )
                validatePurchase(_plots_lat, _plots_lng) 
                validateLand(_plots_lat, _plots_lng) 
                updateUsersLastAccess()
                public payable {
        require(_name.length > 4);
       
         
        uint256 _runningTotal = msg.value;
        
        _runningTotal = _runningTotal.sub(processReferer(_referrer));
        

        tax_fund = tax_fund.add(m_newPlot_taxPercent.mul(_runningTotal));
        
        
        processDevPayment(_runningTotal, m_newPlot_devPercent);
        

        processPurchase(_name, _plots_lat, _plots_lng);
        
        calcPlayerDivs(m_newPlot_taxPercent.mul(_runningTotal));
        
        game_started = true;
        
        if(_plots_lat.length >= min_plots_purchase_for_token_reward
            && tokens_rewards_available > 0) {
                
            uint256 _token_rewards = _plots_lat.length / plots_token_reward_divisor;
            if(_token_rewards > tokens_rewards_available)
                _token_rewards = tokens_rewards_available;
                
                
            planetCryptoCoin_interface.transfer(msg.sender, _token_rewards);
                
            emit issueCoinTokens(msg.sender, msg.sender, _token_rewards, now);
            tokens_rewards_allocated = tokens_rewards_allocated + _token_rewards;
            tokens_rewards_available = tokens_rewards_available - _token_rewards;
        }
    
    }
    
    function processReferer(address _referrer) internal returns(uint256) {
        uint256 _referrerAmnt = 0;
        if(_referrer != msg.sender && _referrer != address(0)) {
            _referrerAmnt = m_refPercent.mul(msg.value);
            if(_referrer.send(_referrerAmnt)) {
                emit referralPaid(_referrer, _referrer, _referrerAmnt, now);
                 
            }
        }
        return _referrerAmnt;
    }
    
    
    function processDevPayment(uint256 _runningTotal, Percent.percent storage _percent) internal {
        if(!devBankAddress.send(_percent.mul(_runningTotal))){
            devHoldings = devHoldings.add(_percent.mul(_runningTotal));
        }
    }
    
     
    function buyCard(uint256 _token_id, address _referrer) updateUsersLastAccess() public payable {
        
        
         
        
        if(planetCryptoUtils_interface.validateResale(msg.sender, msg.value, _token_id) == false) {
            if(planetCryptoUtils_interface.validateLandTakeover(msg.sender, msg.value, _token_id) == false) {
                revert("Cannot Buy this Card Yet!");
            }
        }
        
        processBuyCard(_token_id, _referrer);

    }
    
    
    
    function processBuyCard(uint256 _token_id, address _referrer) internal {
         
        uint256 _runningTotal = msg.value;
        _runningTotal = _runningTotal.sub(processReferer(_referrer));
        
        tax_fund = tax_fund.add(m_resalePlot_taxPercent.mul(_runningTotal));
        
        processDevPayment(_runningTotal, m_resalePlot_devPercent);

        address from = ownerOf(_token_id);
        
        if(!from.send(m_resalePlot_ownerPercent.mul(_runningTotal))) {
            playersFundsOwed[from] = playersFundsOwed[from].add(m_resalePlot_ownerPercent.mul(_runningTotal));
        }
        
        
        process_swap(from,msg.sender,_token_id);
        internal_transferFrom(from, msg.sender, _token_id);
        

         
        uint256 _empireScore = plotDetails[tokenIDplotdetailsIndexId[_token_id]].empire_score;  
        uint256 _newEmpireScore = m_empireScoreMultiplier.mul(_empireScore);
        uint256 _origValue = plotDetails[tokenIDplotdetailsIndexId[_token_id]].current_value;
        

        all_playerObjects[playerAddressToPlayerObjectID[msg.sender]].totalEmpireScore
            = all_playerObjects[playerAddressToPlayerObjectID[msg.sender]].totalEmpireScore + (_newEmpireScore - _empireScore);
        
        plotDetails[tokenIDplotdetailsIndexId[_token_id]].empire_score = _newEmpireScore;

        total_empire_score = total_empire_score + (_newEmpireScore - _empireScore);
        
        plotDetails[tokenIDplotdetailsIndexId[_token_id]].current_value = 
            m_resaleMultipler.mul(plotDetails[tokenIDplotdetailsIndexId[_token_id]].current_value);
        
        total_trades = total_trades + 1;
        
        
        calcPlayerDivs(m_resalePlot_taxPercent.mul(_runningTotal));
        
        
        plotDetail memory _plot =plotDetails[tokenIDplotdetailsIndexId[_token_id]];
       
        emit cardBought(_token_id, from, ownerOf(_token_id),
                    _token_id, from, ownerOf(_token_id), 
                    _plot.name,
                    _origValue, 
                    _plot.current_value,
                    _empireScore, 
                    _plot.empire_score, 
                    now);
    }
    
    
    
    function processPurchase(bytes32 _name, 
            int256[] _plots_lat, int256[] _plots_lng) internal {
    
        tokenIDCount = tokenIDCount + 1;
        
         
        _mint(msg.sender, tokenIDCount);
        

           
            
        plotDetails.push(plotDetail(
            _name,
            current_plot_price * _plots_lat.length,
            current_plot_price * _plots_lat.length,
            current_plot_empire_score * _plots_lng.length,
            _plots_lat, _plots_lng, ''
        ));

        
        tokenIDplotdetailsIndexId[tokenIDCount] = plotDetails.length-1;
        
        
        
        setupPlotOwnership(tokenIDCount, _plots_lat, _plots_lng);
        
        
        
        uint256 _playerObject_idx = playerAddressToPlayerObjectID[msg.sender];
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore + (current_plot_empire_score * _plots_lng.length);
            
        total_empire_score = total_empire_score + (current_plot_empire_score * _plots_lng.length);
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand + _plots_lat.length;
            
        
        emit landPurchased(
                tokenIDCount, msg.sender,
                tokenIDCount, msg.sender, _name, _plots_lat[0], _plots_lng[0], _plots_lat.length, current_plot_price, (current_plot_empire_score * _plots_lng.length), now);


        current_plot_price = current_plot_price + (price_update_amount * _plots_lat.length);
        total_land_sold = total_land_sold + _plots_lat.length;

    }

    function updateCardDetail(uint256 _token_id, uint256 _updateType, bytes32 _data) public payable {
        require(msg.sender == ownerOf(_token_id));
        if(_updateType == 1) {
             
            require(msg.value == cardImageCost);
            
            plotDetails[
                    tokenIDplotdetailsIndexId[_token_id]
                        ].img = _data;

        }
        if(_updateType == 2) {
             
            require(_data.length > 4);
            require(msg.value == cardChangeNameCost);
            plotDetails[
                    tokenIDplotdetailsIndexId[_token_id]
                        ].name = _data;
        }
        
        
        processDevPayment(msg.value,m_newPlot_devPercent);
         
        
        emit cardChange(
            _token_id,
            msg.sender, 
            _token_id, msg.sender, _updateType, _data, now);
            
    }
    
    
    


    
    
    function calcPlayerDivs(uint256 _value) internal {
         
         
        if(game_started) {
            uint256 _totalDivs = 0;
            uint256 _totalPlayers = 0;
            
            uint256 _taxToDivide = _value + tax_carried_forward;
            
             
            for(uint256 c=1; c< all_playerObjects.length; c++) {
                
                 
                
                uint256 _playersPercent 
                    = (all_playerObjects[c].totalEmpireScore*10000000 / total_empire_score * 10000000) / 10000000;
                    
                uint256 _playerShare = _taxToDivide / 10000000 * _playersPercent;
                

                
                if(_playerShare > 0) {
                    
                    
                    playersFundsOwed[all_playerObjects[c].playerAddress] = playersFundsOwed[all_playerObjects[c].playerAddress].add(_playerShare);
                    tax_distributed = tax_distributed.add(_playerShare);
                    
                    _totalDivs = _totalDivs + _playerShare;
                    _totalPlayers = _totalPlayers + 1;
                
                }
            }

            tax_carried_forward = 0;
            emit taxDistributed(_totalDivs, _totalPlayers, now);

        } else {
             
            tax_carried_forward = tax_carried_forward + _value;
        }
    }
    

    
    
    function setupPlotOwnership(uint256 _token_id, int256[] _plots_lat, int256[] _plots_lng) internal {

       for(uint256 c=0;c< _plots_lat.length;c++) {
         
            latlngTokenID_grids[_plots_lat[c]]
                [_plots_lng[c]] = _token_id;
                

            
        }
       


        for(uint8 zoomC = 1; c < 5; c++) {
            setupZoomLvl(zoomC,_plots_lat[0], _plots_lng[0], _token_id);  
        }

      
    }




    function setupZoomLvl(uint8 zoom, int256 lat, int256 lng, uint256 _token_id) internal  {
        
        lat = planetCryptoUtils_interface.roundLatLngFull(zoom, lat);
        lng = planetCryptoUtils_interface.roundLatLngFull(zoom, lng);
        
        
      
        
        latlngTokenID_zoomAll[zoom][lat][lng] = _token_id;
        tokenIDlatlngLookup_zoomAll[zoom][_token_id].push(
            plotBasic(lat,lng)
            );
 
        
        
    }




    


    function getAllPlayerObjectLen() public view returns(uint256){
        return all_playerObjects.length;
    }
    

    function queryMap(uint8 zoom, int256[] lat_rows, int256[] lng_columns) public view returns(string _outStr) {
        
        
        for(uint256 y=0; y< lat_rows.length; y++) {

            for(uint256 x=0; x< lng_columns.length; x++) {
                
                
                
                if(zoom == 0){
                    if(latlngTokenID_grids[lat_rows[y]][lng_columns[x]] > 0){
                        
                        
                      _outStr = planetCryptoUtils_interface.strConcat(
                            _outStr, '[', planetCryptoUtils_interface.int2str(lat_rows[y]) , ':', planetCryptoUtils_interface.int2str(lng_columns[x]) );
                      _outStr = planetCryptoUtils_interface.strConcat(_outStr, ':', 
                                    planetCryptoUtils_interface.uint2str(latlngTokenID_grids[lat_rows[y]][lng_columns[x]]), ']');
                    }
                    
                } else {
                     
                    if(latlngTokenID_zoomAll[zoom][lat_rows[y]][lng_columns[x]] > 0){
                      _outStr = planetCryptoUtils_interface.strConcat(_outStr, '[', planetCryptoUtils_interface.int2str(lat_rows[y]) , ':', planetCryptoUtils_interface.int2str(lng_columns[x]) );
                      _outStr = planetCryptoUtils_interface.strConcat(_outStr, ':', 
                                    planetCryptoUtils_interface.uint2str(latlngTokenID_zoomAll[zoom][lat_rows[y]][lng_columns[x]]), ']');
                    }
                    
                }
                 
                
            }
        }
        
         
    }
     
    function queryPlotExists(uint8 zoom, int256[] lat_rows, int256[] lng_columns) public view returns(bool) {
        
        
        for(uint256 y=0; y< lat_rows.length; y++) {

            for(uint256 x=0; x< lng_columns.length; x++) {
                
                if(zoom == 0){
                    if(latlngTokenID_grids[lat_rows[y]][lng_columns[x]] > 0){
                        return true;
                    } 
                } else {
                    if(latlngTokenID_zoomAll[zoom][lat_rows[y]][lng_columns[x]] > 0){

                        return true;
                        
                    }                     
                }
           
                
            }
        }
        
        return false;
    }

    

    

   




     
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
         
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }
    


    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(msg.sender, tokenId));
        require(to != address(0));
        
        process_swap(from,to,tokenId);
        
        super.transferFrom(from, to, tokenId);

    }
    
    function process_swap(address from, address to, uint256 tokenId) internal {

        
         
        uint256 _empireScore;
        uint256 _size;
        
         
        _empireScore = plotDetails[tokenIDplotdetailsIndexId[tokenId]].empire_score;
        _size = plotDetails[tokenIDplotdetailsIndexId[tokenId]].plots_lat.length;
        
        uint256 _playerObject_idx = playerAddressToPlayerObjectID[from];
        
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore - _empireScore;
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand - _size;
            
         
        _playerObject_idx = playerAddressToPlayerObjectID[to];
        
         
        if(_playerObject_idx == 0){
            all_playerObjects.push(player(to,now,0,0));
            playerAddressToPlayerObjectID[to] = all_playerObjects.length-1;
            _playerObject_idx = all_playerObjects.length-1;
        }
        
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore + _empireScore;
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand + _size;
    }


   


     
    function p_update_action(uint256 _type, address _address, uint256 _val, string _strVal) public onlyOwner {
        if(_type == 0){
            owner = _address;    
        }
        if(_type == 1){
            tokenBankAddress = _address;    
        }
        if(_type == 2) {
            devBankAddress = _address;
        }
        if(_type == 3) {
            cardChangeNameCost = _val;    
        }
        if(_type == 4) {
            cardImageCost = _val;    
        }
        if(_type == 5) {
            baseURI = _strVal;
        }
        if(_type == 6) {
            price_update_amount = _val;
        }
        if(_type == 7) {
            current_plot_empire_score = _val;    
        }
        if(_type == 8) {
            planetCryptoCoinAddress = _address;
            if(address(planetCryptoCoinAddress) != address(0)){ 
                planetCryptoCoin_interface = PlanetCryptoCoin_I(planetCryptoCoinAddress);
            }
        }
        if(_type ==9) {
            planetCryptoUtilsAddress = _address;
            if(address(planetCryptoUtilsAddress) != address(0)){ 
                planetCryptoUtils_interface = PlanetCryptoUtils_I(planetCryptoUtilsAddress);
            }            
        }
        if(_type == 10) {
            m_newPlot_devPercent = Percent.percent(_val,100);    
        }
        if(_type == 11) {
            m_newPlot_taxPercent = Percent.percent(_val,100);    
        }
        if(_type == 12) {
            m_resalePlot_devPercent = Percent.percent(_val,100);    
        }
        if(_type == 13) {
            m_resalePlot_taxPercent = Percent.percent(_val,100);    
        }
        if(_type == 14) {
            m_resalePlot_ownerPercent = Percent.percent(_val,100);    
        }
        if(_type == 15) {
            m_refPercent = Percent.percent(_val,100);    
        }
        if(_type == 16) {
            m_empireScoreMultiplier = Percent.percent(_val, 100);    
        }
        if(_type == 17) {
            m_resaleMultipler = Percent.percent(_val, 100);    
        }
        if(_type == 18) {
            tokens_rewards_available = _val;    
        }
        if(_type == 19) {
            tokens_rewards_allocated = _val;    
        }
        if(_type == 20) {
             
            plotDetails[
                    tokenIDplotdetailsIndexId[_val]
                        ].img = '';
                        
            emit cardChange(
                _val,
                msg.sender, 
                _val, msg.sender, 1, '', now);
        }

        
        if(_type == 99) {
             
        
            address _token_owner = ownerOf(_val);
             
            processBurn(_token_owner, _val);
        
        }
    }
    
    function burn(uint256 _token_id) public {
        require(msg.sender == ownerOf(_token_id));
        
        uint256 _cardSize = plotDetails[tokenIDplotdetailsIndexId[_token_id]].plots_lat.length;
        
         
        processBurn(msg.sender, _token_id);
        
         
        planetCryptoCoin_interface.transfer(msg.sender, _cardSize);
        
        
        
    }
    
    function processBurn(address _token_owner, uint256 _val) internal {
        _burn(_token_owner, _val);

        


         
        uint256 _empireScore;
        uint256 _size;
        

        _empireScore = plotDetails[tokenIDplotdetailsIndexId[_val]].empire_score;
        _size = plotDetails[tokenIDplotdetailsIndexId[_val]].plots_lat.length;
        
        total_land_sold = total_land_sold - _size;
        total_empire_score = total_empire_score - _empireScore;
        
        uint256 _playerObject_idx = playerAddressToPlayerObjectID[_token_owner];
        
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore - _empireScore;
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand - _size;
            
            
        for(uint256 c=0;c < plotDetails[tokenIDplotdetailsIndexId[_val]].plots_lat.length; c++) {
            latlngTokenID_grids[
                     
                    plotDetails[tokenIDplotdetailsIndexId[_val]].plots_lat[c]
                ]
                [
                     
                    plotDetails[tokenIDplotdetailsIndexId[_val]].plots_lng[c]
                ] = 0;
        }

        
  
        for(uint8 zoom=1; zoom < 5; zoom++) {
            plotBasic[] storage _plotBasicList = tokenIDlatlngLookup_zoomAll[zoom][_val];
            for(c=0; c< _plotBasicList.length; c++) {
                delete latlngTokenID_zoomAll[zoom][
                    _plotBasicList[c].lat
                    ][
                        _plotBasicList[c].lng
                        ];
                        
                delete _plotBasicList[c];
            }
        }
        
        
        delete plotDetails[tokenIDplotdetailsIndexId[_val]];
        tokenIDplotdetailsIndexId[_val] = 0;
         
        
        


    }

    function p_withdrawDevHoldings() public {
        require(msg.sender == devBankAddress);
        uint256 _t = devHoldings;
        devHoldings = 0;
        if(!devBankAddress.send(devHoldings)){
            devHoldings = _t;
        }
    }




    function m() public {
        
    }
    
}