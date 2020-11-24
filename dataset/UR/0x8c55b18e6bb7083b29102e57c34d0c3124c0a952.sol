 

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

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
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

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
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
    require(to != address(0));

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
     
    
    require(to != address(0));

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

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
     
    safeTransferFrom(from, to, tokenId, "");
  }

   
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
     
    require(_checkOnERC721Received(from, to, tokenId, _data));
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

  
  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

  
  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
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

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
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
                    uint256 empireScore, uint256 newEmpireScore, uint256 now);

     
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
    

     
    address planetCryptoCoinAddress = 0xa1c8031ef18272d8bfed22e1b61319d6d9d2881b;
    PlanetCryptoCoin_I internal planetCryptoCoin_interface;
    

    address planetCryptoUtilsAddress = 0x19BfDF25542F1380790B6880ad85D6D5B02fee32;
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

    uint256 public current_plot_empire_score = 100;

    
    
    uint256 public tax_fund = 0;
    uint256 public tax_distributed = 0;


     
    uint256 public total_land_sold = 0;
    uint256 public total_trades = 0;

    
    uint256 public total_empire_score; 
    player[] public all_playerObjects;
    mapping(address => uint256) internal playerAddressToPlayerObjectID;
    
    
    
    
    plotDetail[] plotDetails;
    mapping(uint256 => uint256) internal tokenIDplotdetailsIndexId;  



    
    mapping(int256 => mapping(int256 => uint256)) internal latlngTokenID_grids;
    mapping(uint256 => plotBasic[]) internal tokenIDlatlngLookup;
    
    
    
    mapping(uint8 => mapping(int256 => mapping(int256 => uint256))) internal latlngTokenID_zoomAll;

    mapping(uint8 => mapping(uint256 => plotBasic[])) internal tokenIDlatlngLookup_zoomAll;


   
    
    constructor() ERC721Full_custom("PlanetCrypto", "PTC") public {
        owner = msg.sender;
        tokenBankAddress = owner;
        devBankAddress = owner;
        planetCryptoCoin_interface = PlanetCryptoCoin_I(planetCryptoCoinAddress);
        planetCryptoUtils_interface = PlanetCryptoUtils_I(planetCryptoUtilsAddress);
        
         

        all_playerObjects.push(player(address(0x0),0,0,0));
        playerAddressToPlayerObjectID[address(0x0)] = 0;
    }

    

    

    function getToken(uint256 _tokenId, bool isBasic) public view returns(
        address token_owner,
        bytes32  name,
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
        } else {
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
        uint256 _referrerAmnt = 0;
        if(_referrer != msg.sender && _referrer != address(0)) {
            _referrerAmnt = m_refPercent.mul(msg.value);
            if(_referrer.send(_referrerAmnt)) {
                emit referralPaid(_referrer, _referrer, _referrerAmnt, now);
                _runningTotal = _runningTotal.sub(_referrerAmnt);
            }
        }
        
        tax_fund = tax_fund.add(m_newPlot_taxPercent.mul(_runningTotal));
        
        
        
        if(!devBankAddress.send(m_newPlot_devPercent.mul(_runningTotal))){
            devHoldings = devHoldings.add(m_newPlot_devPercent.mul(_runningTotal));
        }
        
        
        

        processPurchase(_name, _plots_lat, _plots_lng);
        
        calcPlayerDivs(m_newPlot_taxPercent.mul(_runningTotal));
        
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
    
    

    function buyCard(uint256 _token_id, address _referrer) validateResale(_token_id) updateUsersLastAccess() public payable {
        
        
         
        uint256 _runningTotal = msg.value;
        uint256 _referrerAmnt = 0;
        if(_referrer != msg.sender && _referrer != address(0)) {
            _referrerAmnt = m_refPercent.mul(msg.value);
            if(_referrer.send(_referrerAmnt)) {
                emit referralPaid(_referrer, _referrer, _referrerAmnt, now);
                _runningTotal = _runningTotal.sub(_referrerAmnt);
            }
        }
        
        
        tax_fund = tax_fund.add(m_resalePlot_taxPercent.mul(_runningTotal));
        
        
        
        if(!devBankAddress.send(m_resalePlot_devPercent.mul(_runningTotal))){
            devHoldings = devHoldings.add(m_resalePlot_devPercent.mul(_runningTotal));
        }
        
        

        address from = ownerOf(_token_id);
        
        if(!from.send(m_resalePlot_ownerPercent.mul(_runningTotal))) {
            playersFundsOwed[from] = playersFundsOwed[from].add(m_resalePlot_ownerPercent.mul(_runningTotal));
        }
        
        

        our_transferFrom(from, msg.sender, _token_id);
        

        plotDetail memory _plotDetail = plotDetails[tokenIDplotdetailsIndexId[_token_id]];
        uint256 _empireScore = _plotDetail.empire_score;
        uint256 _newEmpireScore = m_empireScoreMultiplier.mul(_empireScore);
        uint256 _origValue = _plotDetail.current_value;
        
        uint256 _playerObject_idx = playerAddressToPlayerObjectID[msg.sender];
        

        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore + (_newEmpireScore - _empireScore);
        
        
        plotDetails[tokenIDplotdetailsIndexId[_token_id]].empire_score = _newEmpireScore;

        total_empire_score = total_empire_score + (_newEmpireScore - _empireScore);
        
        plotDetails[tokenIDplotdetailsIndexId[_token_id]].current_value = 
            m_resaleMultipler.mul(plotDetails[tokenIDplotdetailsIndexId[_token_id]].current_value);
        
        total_trades = total_trades + 1;
        
        
        calcPlayerDivs(m_resalePlot_taxPercent.mul(_runningTotal));
        
        
         
        emit cardBought(_token_id, from, msg.sender,
                    _token_id, from, msg.sender, 
                    _plotDetail.name,
                    _origValue, 
                    msg.value,
                    _empireScore, _newEmpireScore, now);
    }
    
    function processPurchase(bytes32 _name, 
            int256[] _plots_lat, int256[] _plots_lng) internal {
    
        uint256 _token_id = totalSupply().add(1);
        _mint(msg.sender, _token_id);
        

        

        uint256 _empireScore =
                    current_plot_empire_score * _plots_lng.length;
            
            
        plotDetails.push(plotDetail(
            _name,
            current_plot_price * _plots_lat.length,
            current_plot_price * _plots_lat.length,
            _empireScore,
            _plots_lat, _plots_lng
        ));
        
        tokenIDplotdetailsIndexId[_token_id] = plotDetails.length-1;
        
        
        setupPlotOwnership(_token_id, _plots_lat, _plots_lng);
        
        
        
        uint256 _playerObject_idx = playerAddressToPlayerObjectID[msg.sender];
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore + _empireScore;
            
        total_empire_score = total_empire_score + _empireScore;
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand + _plots_lat.length;
            
        
        emit landPurchased(
                _token_id, msg.sender,
                _token_id, msg.sender, _name, _plots_lat[0], _plots_lng[0], _plots_lat.length, current_plot_price, _empireScore, now);


        current_plot_price = current_plot_price + (price_update_amount * _plots_lat.length);
        total_land_sold = total_land_sold + _plots_lat.length;
        
    }




    uint256 internal tax_carried_forward = 0;
    
    function calcPlayerDivs(uint256 _value) internal {
         
        if(totalSupply() > 1) {
            uint256 _totalDivs = 0;
            uint256 _totalPlayers = 0;
            
            uint256 _taxToDivide = _value + tax_carried_forward;
            
             
            for(uint256 c=1; c< all_playerObjects.length; c++) {
                
                 
                
                uint256 _playersPercent 
                    = (all_playerObjects[c].totalEmpireScore*10000000 / total_empire_score * 10000000) / 10000000;
                uint256 _playerShare = _taxToDivide / 10000000 * _playersPercent;
                
                 
                 
                
                if(_playerShare > 0) {
                    
                    incPlayerOwed(all_playerObjects[c].playerAddress,_playerShare);
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
    
    
    function incPlayerOwed(address _playerAddr, uint256 _amnt) internal {
        playersFundsOwed[_playerAddr] = playersFundsOwed[_playerAddr].add(_amnt);
        tax_distributed = tax_distributed.add(_amnt);
    }
    
    
    function setupPlotOwnership(uint256 _token_id, int256[] _plots_lat, int256[] _plots_lng) internal {

       for(uint256 c=0;c< _plots_lat.length;c++) {
         
             
            latlngTokenID_grids[_plots_lat[c]]
                [_plots_lng[c]] = _token_id;
                
             
            tokenIDlatlngLookup[_token_id].push(plotBasic(
                _plots_lat[c], _plots_lng[c]
            ));
            
        }
       
        
        int256 _latInt = _plots_lat[0];
        int256 _lngInt = _plots_lng[0];



        setupZoomLvl(1,_latInt, _lngInt, _token_id);  
        setupZoomLvl(2,_latInt, _lngInt, _token_id);  
        setupZoomLvl(3,_latInt, _lngInt, _token_id);  
        setupZoomLvl(4,_latInt, _lngInt, _token_id);  

      
    }

    function setupZoomLvl(uint8 zoom, int256 lat, int256 lng, uint256 _token_id) internal  {
        
        lat = roundLatLng(zoom, lat);
        lng  = roundLatLng(zoom, lng); 
        
        
        uint256 _remover = 5;
        if(zoom == 1)
            _remover = 5;
        if(zoom == 2)
            _remover = 4;
        if(zoom == 3)
            _remover = 3;
        if(zoom == 4)
            _remover = 2;
        
        string memory _latStr;   
        string memory _lngStr;  

        
        
        bool _tIsNegative = false;
        
        if(lat < 0) {
            _tIsNegative = true;   
            lat = lat * -1;
        }
        _latStr = planetCryptoUtils_interface.int2str(lat);
        _latStr = planetCryptoUtils_interface.substring(_latStr,0,planetCryptoUtils_interface.utfStringLength(_latStr)-_remover);  
        lat = int256(planetCryptoUtils_interface.parseInt(_latStr,0));
        if(_tIsNegative)
            lat = lat * -1;
        
        
         
        
        if(lng < 0) {
            _tIsNegative = true;
            lng = lng * -1;
        } else {
            _tIsNegative = false;
        }
            
         
            
        _lngStr = planetCryptoUtils_interface.int2str(lng);
        
        _lngStr = planetCryptoUtils_interface.substring(_lngStr,0,planetCryptoUtils_interface.utfStringLength(_lngStr)-_remover);
        
        lng = int256(planetCryptoUtils_interface.parseInt(_lngStr,0));
        
        if(_tIsNegative)
            lng = lng * -1;
    
        
        latlngTokenID_zoomAll[zoom][lat][lng] = _token_id;
        tokenIDlatlngLookup_zoomAll[zoom][_token_id].push(plotBasic(lat,lng));
        
      
   
        
        
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

    
    function roundLatLng(uint8 _zoomLvl, int256 _in) internal view returns(int256) {
        int256 multipler = 100000;
        if(_zoomLvl == 1)
            multipler = 100000;
        if(_zoomLvl == 2)
            multipler = 10000;
        if(_zoomLvl == 3)
            multipler = 1000;
        if(_zoomLvl == 4)
            multipler = 100;
        if(_zoomLvl == 5)
            multipler = 10;
        
        if(_in > 0){
             
            _in = planetCryptoUtils_interface.ceil1(_in, multipler);
        } else {
            _in = _in * -1;
            _in = planetCryptoUtils_interface.ceil1(_in, multipler);
            _in = _in * -1;
        }
        
        return (_in);
        
    }
    

   




     
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
         
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }
    
    function our_transferFrom(address from, address to, uint256 tokenId) internal {
         
        process_swap(from,to,tokenId);
        
        internal_transferFrom(from, to, tokenId);
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
        
        plotDetail memory _plotDetail = plotDetails[tokenIDplotdetailsIndexId[tokenId]];
        _empireScore = _plotDetail.empire_score;
        _size = _plotDetail.plots_lat.length;
        
        uint256 _playerObject_idx = playerAddressToPlayerObjectID[from];
        
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore - _empireScore;
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand - _size;
            
         
        
        _playerObject_idx = playerAddressToPlayerObjectID[to];
        
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore + _empireScore;
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand + _size;
    }


    function burnToken(uint256 _tokenId) external onlyOwner {
        address _token_owner = ownerOf(_tokenId);
        _burn(_token_owner, _tokenId);
        
        
         
        uint256 _empireScore;
        uint256 _size;
        
        plotDetail memory _plotDetail = plotDetails[tokenIDplotdetailsIndexId[_tokenId]];
        _empireScore = _plotDetail.empire_score;
        _size = _plotDetail.plots_lat.length;
        
        uint256 _playerObject_idx = playerAddressToPlayerObjectID[_token_owner];
        
        all_playerObjects[_playerObject_idx].totalEmpireScore
            = all_playerObjects[_playerObject_idx].totalEmpireScore - _empireScore;
            
        all_playerObjects[_playerObject_idx].totalLand
            = all_playerObjects[_playerObject_idx].totalLand - _size;
            
       
        
        for(uint256 c=0;c < tokenIDlatlngLookup[_tokenId].length; c++) {
            latlngTokenID_grids[
                    tokenIDlatlngLookup[_tokenId][c].lat
                ][tokenIDlatlngLookup[_tokenId][c].lng] = 0;
        }
        delete tokenIDlatlngLookup[_tokenId];
        
        
        
         
         
        uint256 oldIndex = tokenIDplotdetailsIndexId[_tokenId];
        if(oldIndex != plotDetails.length-1) {
            plotDetails[oldIndex] = plotDetails[plotDetails.length-1];
        }
        plotDetails.length--;
        

        delete tokenIDplotdetailsIndexId[_tokenId];



        for(uint8 zoom=1; zoom < 5; zoom++) {
            plotBasic[] storage _plotBasicList = tokenIDlatlngLookup_zoomAll[zoom][_tokenId];
            for(uint256 _plotsC=0; c< _plotBasicList.length; _plotsC++) {
                delete latlngTokenID_zoomAll[zoom][
                    _plotBasicList[_plotsC].lat
                    ][
                        _plotBasicList[_plotsC].lng
                        ];
                        
                delete _plotBasicList[_plotsC];
            }
            
        }
    
    



    }    



     
    function p_update_action(uint256 _type, address _address) public onlyOwner {
        if(_type == 0){
            owner = _address;    
        }
        if(_type == 1){
            tokenBankAddress = _address;    
        }
        if(_type == 2) {
            devBankAddress = _address;
        }
    }


    function p_update_priceUpdateAmount(uint256 _price_update_amount) public onlyOwner {
        price_update_amount = _price_update_amount;
    }
    function p_update_currentPlotEmpireScore(uint256 _current_plot_empire_score) public onlyOwner {
        current_plot_empire_score = _current_plot_empire_score;
    }
    function p_update_planetCryptoCoinAddress(address _planetCryptoCoinAddress) public onlyOwner {
        planetCryptoCoinAddress = _planetCryptoCoinAddress;
        if(address(planetCryptoCoinAddress) != address(0)){ 
            planetCryptoCoin_interface = PlanetCryptoCoin_I(planetCryptoCoinAddress);
        }
    }
    function p_update_planetCryptoUtilsAddress(address _planetCryptoUtilsAddress) public onlyOwner {
        planetCryptoUtilsAddress = _planetCryptoUtilsAddress;
        if(address(planetCryptoUtilsAddress) != address(0)){ 
            planetCryptoUtils_interface = PlanetCryptoUtils_I(planetCryptoUtilsAddress);
        }
    }
    function p_update_mNewPlotDevPercent(uint256 _newPercent) onlyOwner public {
        m_newPlot_devPercent = Percent.percent(_newPercent,100);
    }
    function p_update_mNewPlotTaxPercent(uint256 _newPercent) onlyOwner public {
        m_newPlot_taxPercent = Percent.percent(_newPercent,100);
    }
    function p_update_mResalePlotDevPercent(uint256 _newPercent) onlyOwner public {
        m_resalePlot_devPercent = Percent.percent(_newPercent,100);
    }
    function p_update_mResalePlotTaxPercent(uint256 _newPercent) onlyOwner public {
        m_resalePlot_taxPercent = Percent.percent(_newPercent,100);
    }
    function p_update_mResalePlotOwnerPercent(uint256 _newPercent) onlyOwner public {
        m_resalePlot_ownerPercent = Percent.percent(_newPercent,100);
    }
    function p_update_mRefPercent(uint256 _newPercent) onlyOwner public {
        m_refPercent = Percent.percent(_newPercent,100);
    }
    function p_update_mEmpireScoreMultiplier(uint256 _newPercent) onlyOwner public {
        m_empireScoreMultiplier = Percent.percent(_newPercent, 100);
    }
    function p_update_mResaleMultipler(uint256 _newPercent) onlyOwner public {
        m_resaleMultipler = Percent.percent(_newPercent, 100);
    }
    function p_update_tokensRewardsAvailable(uint256 _tokens_rewards_available) onlyOwner public {
        tokens_rewards_available = _tokens_rewards_available;
    }
    function p_update_tokensRewardsAllocated(uint256 _tokens_rewards_allocated) onlyOwner public {
        tokens_rewards_allocated = _tokens_rewards_allocated;
    }
    function p_withdrawDevHoldings() public {
        require(msg.sender == devBankAddress);
        uint256 _t = devHoldings;
        devHoldings = 0;
        if(!devBankAddress.send(devHoldings)){
            devHoldings = _t;
        }
    }


    function stringToBytes32(string memory source) internal returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }

    function m() public {
        
    }
    
}