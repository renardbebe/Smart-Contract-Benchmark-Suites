 

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

pragma solidity ^0.5.0;


 
library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC165 is IERC165 {
     
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

     
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
         
         
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.0;







 
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

 

pragma solidity ^0.5.0;


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity ^0.5.0;




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
     
    string private _name;

     
    string private _symbol;

     
    mapping(uint256 => string) private _tokenURIs;

     
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

     
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;


 
contract Pausable is PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;





 




contract IRandomBuffValue {
    function randomValue(uint keyid,uint random) public view returns(uint);
}




contract SuperplayerRandomValueBase is Ownable {
  using SafeMath for uint256;
  struct ValueByWeight {
    uint value;
    uint weight;
  }

  mapping(uint => ValueByWeight[] ) randomvalueTable  ;
  mapping(uint => uint ) randomvalueTableWeights  ;

  function randomValue (uint keyid,uint random ) public view returns(uint rv){
      rv = _randomValue(keyid,  random% randomvalueTableWeights[keyid] +1 );
  }


  function getRandomValueConf(uint keyid) public view returns( uint[]memory values,uint[] memory weights){
    ValueByWeight[] memory vs  =randomvalueTable[keyid];
    values = new uint[](vs.length);
    weights = new uint[](vs.length);
    for(uint i = 0 ;i < vs.length;++i) {
      values[i]=vs[i].value;
      weights[i]=vs[i].weight;
    }
  }

  function addRandomValuesforRTable(uint keyid, uint[] memory values,uint[] memory weights) public onlyOwner {
    _addRandomValuesforRTable(keyid,values,weights);
  }


  function _randomValue (uint keyid,uint weight ) internal view returns(uint randomValue){
    ValueByWeight[] memory vs  =randomvalueTable[keyid];
    uint sum ;
    for (uint i = 0;i < vs.length ; i++){
      ValueByWeight memory vw  = vs[i];
      sum += vw.weight;
      if( weight  <=  sum ){
        return vw.value;
      }
    }
    return vs[vs.length -1].value ;
  }

 function _addRandomValuesforRTable(uint keyid, uint[] memory values,uint[] memory weights) internal {
    require(randomvalueTableWeights[keyid]  == 0 );
    for( uint i = 0; i < values.length;++i) {
      ValueByWeight memory vw  = ValueByWeight({
        value : values[i],
        weight: weights[i]
      });
      randomvalueTable[keyid].push(vw);
      randomvalueTableWeights[keyid] += weights[i];
    }
  }
}







contract SuperplayerRandomEquipmentBase  is Ownable{

  using SafeMath for uint256;

   
   

   
  struct Equipment {
    string key;
    uint weight;
    uint[] randomKeyIds; 
    uint maxCnt;
  }




  mapping(uint256 => uint256 ) equipsCurrCnt;

  Equipment[] private equips;
  uint256 TotalEquipNum;  

  IRandomBuffValue  insRandomBuff;
   

  constructor(address insRandomBuffAddr) public{
    insRandomBuff = IRandomBuffValue(insRandomBuffAddr);
  }

  function getRandomEquipment(uint256 seed) public view returns(uint blockNo,string memory ekey,uint[] memory randomProps)  {
    uint TotalWeight = _getTotalWeight();
    require(TotalWeight>0);
    uint random = getRandom(seed);
    uint equipIndex = getRandomEquipIndexByWeight(  random % TotalWeight  + 1) ;
     
    Equipment memory  equip =  equips[equipIndex];

     
    randomProps = new uint[](equip.randomKeyIds.length);
    for(uint i=0;i< randomProps.length ; i++) {
      uint keyid = equip.randomKeyIds[i] ;
      uint rv = insRandomBuff.randomValue(keyid,  (random >>i ) );
      randomProps[i] = rv;
    }
    blockNo = block.number;
    ekey = equip.key;
  }


  function getRandom(uint256 seed) internal view returns (uint256){
    return uint256(keccak256(abi.encodePacked(block.timestamp, seed,block.difficulty)));
  }



  function addEquipToPool(string memory key,uint[] memory randomKeyIds,uint weight,uint maxCnt) public  onlyOwner{
    _addEquipToPool(key,randomKeyIds,weight,maxCnt);
  }


   
  function getCurrentQty() public view returns( uint[] memory ukeys,uint[] memory maxCnt,uint[] memory currentCnt ){
    ukeys = new uint[](TotalEquipNum);
    maxCnt = new uint[](TotalEquipNum);
    currentCnt = new uint[](TotalEquipNum);

    for (uint i = 0;i < TotalEquipNum ; i++){
      uint ukey = uint256(keccak256(abi.encodePacked(bytes(equips[i].key))));
      ukeys[i] =  ukey;
      maxCnt[i] = equips[i].maxCnt;
      currentCnt[i] = equipsCurrCnt[ukey];
    }
  }

   
  function getEquipmentConf(uint equipIndex) public view returns( string memory key,uint weight,uint[] memory randomKeyIds){
    Equipment memory  equip =  equips[equipIndex];
    key = equip.key;
    weight = equip.weight;
    randomKeyIds = equip.randomKeyIds;
  }


  function getRandomEquipIndexByWeight( uint weight ) internal view returns (uint) {
    uint TotalWeight = _getTotalWeight();
    require( weight <= TotalWeight );
    uint sum ;
    for (uint i = 0;i < TotalEquipNum ; i++){
     uint256 uintkey = uint256(keccak256(abi.encodePacked(bytes(equips[i].key))));
     if (equips[i].maxCnt > equipsCurrCnt[ uintkey ]) {
        sum += equips[i].weight;
        if( weight  <=  sum ){
          return i;
        }
     }
    }
    return TotalEquipNum -1 ;
  }


  function _addEquipToPool(string memory key,uint[] memory randomKeyIds,uint weight,uint maxCnt) internal {
    Equipment memory newEquip = Equipment({
      key : key,
      randomKeyIds : randomKeyIds,
      weight : weight,
      maxCnt : maxCnt
    });
    equips.push(newEquip);
    TotalEquipNum = TotalEquipNum.add(1);
  }


  function _incrCurrentEquipCnt(string memory key) internal {
     uint256 uintkey = uint256(keccak256(abi.encodePacked(bytes(key))));
     equipsCurrCnt[uintkey] = equipsCurrCnt[uintkey]  + 1;
  }

  function _getTotalWeight( ) internal view returns(uint) {
    uint res = 0;
    for (uint i = 0;i < TotalEquipNum ; i++){
     uint256 uintkey = uint256(keccak256(abi.encodePacked(bytes(equips[i].key))));
     if (equips[i].maxCnt > equipsCurrCnt[ uintkey ]) {
       res += equips[i].weight;
     }
    }
    return res;
  }

}

contract SuperPlayerGachaWithRecommendReward  is Ownable  {

  mapping(uint=> address) recommendRecord;


  function addRecommend(string memory key,address payable to ) public  onlyOwner{
     uint256 uintkey = uint256(keccak256(abi.encodePacked(bytes(key))));
     recommendRecord[uintkey] = to;
  }


  function getRecommendAddress( string memory key ) public view returns(address) {
    return _getRecommendAddress(key);
  }

  function _getRecommendAddress( string memory key ) internal view returns(address) {
     uint256 uintkey = uint256(keccak256(abi.encodePacked(bytes(key))));
     return recommendRecord[uintkey];
  }



}

contract SuperPlayerGachaTest  is SuperplayerRandomEquipmentBase ,SuperPlayerGachaWithRecommendReward{

  using SafeMath for uint256;

  uint256 recommendRatio = 3000;  
  event Draw(string key);

  constructor(address insRandomBuffAddr) SuperplayerRandomEquipmentBase(insRandomBuffAddr) public{

    feeForOne = 66 finney ;
    feeForTen = 594 finney;
  }

  uint256  public feeForOne;
  uint256 public feeForTen;




  function gacha (uint seed,string memory from) public payable  {
     require( msg.value >= feeForOne );
     uint blockNo;
     string memory key;
     uint[] memory equips;
     (blockNo,  key,  equips)  = this.getRandomEquipment(seed );
    
   emit Draw(key);
      
    _incrCurrentEquipCnt(key);


      
     msg.sender.transfer(msg.value.sub(feeForOne));

      
     address payable recommendAddress = address(uint160(_getRecommendAddress(from)));
     if(recommendAddress != address(0)) {
       recommendAddress.transfer( feeForOne.mul(recommendRatio).div(10000));
     }

  }

  function gacha10 (uint seed,string memory from) public payable  {
     require( msg.value >= feeForTen );
     uint blockNo;
     string memory key;
     uint[] memory equips;
     for (uint i=0 ;i<10;++i) {
      (blockNo,  key,  equips)  = this.getRandomEquipment(seed+i );
      
      _incrCurrentEquipCnt(key);
      emit Draw(key);

     }
      
     

      
     address payable recommendAddress = address(uint160(_getRecommendAddress(from)));
     if(recommendAddress != address(0)) {
       recommendAddress.transfer( feeForTen.mul(recommendRatio).div(10000));
     }
  }

  function withdraw( address payable to )  public onlyOwner{
    require(to == msg.sender);  
    to.transfer((address(this).balance ));
  }
}

 

pragma solidity ^0.5.0;






 







 
contract EquipGeneratorWhitelist is Ownable {
  mapping(address => string) public whitelist;
  mapping(string => address)  cat2address;

  event WhitelistedAddressAdded(address addr,string category);
  event WhitelistedAddressRemoved(address addr);

   
  modifier canGenerate() {
     
    require(bytes(whitelist[msg.sender]).length >0 );
    _;
  }

   
  function addAddressToWhitelist(address addr,string memory category) onlyOwner internal returns(bool success) {
    require( bytes(category).length > 0 );
    if (bytes(whitelist[addr]).length == 0) {
      require( cat2address[category] == address(0));
      whitelist[addr] = category;
      emit WhitelistedAddressAdded(addr,category);
      success = true;
    }
  }


   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    string storage category = whitelist[addr];
    if (bytes(category).length != 0) {
      delete cat2address[category] ;
      delete whitelist[addr]  ;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }



}



contract SuperplayerEquipmentInterface {
  function createEquip(address to, string memory key, uint[] memory randomProps )  public returns(uint256);
}

contract SuperplayerRandomEquipmentInterface {
  function getRandomEquipment(uint256 seed) public view returns(uint blockNo,string memory ekey,uint[] memory randomProps) ;
}

   
contract SuperplayerEquipmentV001 is EquipGeneratorWhitelist,ERC721 ,ERC721Metadata("SuperPlayerEquipment","SPE") {

  using SafeMath for uint256;

  enum EquipmentPart {Weapon ,Head,Coat,Pants ,Shoes ,Bag}
  enum EquipmentRareness {Blue,Purple, Orange,Red }

  struct Equipment {
    string key;  
 
  
    uint[] randomProperties;
    uint[] advancedProperties;  
  }



  event Birth(address where,uint256 tokenId , string key,  uint[] randomProps);
  event GetAdvancedProperties(address where,uint256 tokenId,uint[] advancedProps);


  mapping (uint256 => uint256) private typeLimitsMap;
  mapping (uint256 => uint256) private typeCurrCntMap;

  uint256 TotalEquipNum;  


  Equipment[] private equips;

  constructor() public{

  }

  function totalSupply() public view returns (uint) {
    return TotalEquipNum;
  }

  function addEquipmentGenerator(address addr, string memory category) onlyOwner public returns(bool success){
    return addAddressToWhitelist(addr,category);
  }

  function removeEquipmentGenerator(address addr) onlyOwner public returns(bool success){
    return removeAddressFromWhitelist(addr);
  }

  function setLimit(string memory key, uint256 limit) onlyOwner public {
    uint256 uintkey =  uint256(keccak256(abi.encodePacked(bytes(key))));
     
    require( typeLimitsMap[uintkey] == uint256(0) ) ;
    typeLimitsMap[ uintkey ] = limit;
  }

  function setLimits(uint256[] memory uintkeys, uint256[] memory limits) onlyOwner public {
    require(uintkeys.length == limits.length);
    uint len = uintkeys.length;
    for (uint i = 0;i < len ; i++){
     
      uint256 uintkey = uintkeys[i];
      if( typeLimitsMap[ uintkey]  == 0 ) {
        typeLimitsMap[ uintkey ] = limits[i];
      }
    }
  }



  function getLimit(string memory key)  public view returns(uint256 current, uint256 limit){
    uint256 uintkey = uint256(keccak256(abi.encodePacked(bytes(key))));
    current = typeCurrCntMap[uintkey];
    limit = typeLimitsMap[uintkey];
  }

   
  function createEquip(address to, string memory key, uint[] memory randomProps) canGenerate public returns(uint256){
    uint256 uintkey =  uint256(keccak256(abi.encodePacked(bytes(key))));
    uint256 currentTypCnt = typeCurrCntMap[uintkey]; 

     
    require(currentTypCnt < typeLimitsMap[uintkey]) ;

    uint[] memory emptyProps = new uint[](0); 
    Equipment memory newEquip = Equipment({
      key : key,
      randomProperties : randomProps,
      advancedProperties : emptyProps
    });
    TotalEquipNum = TotalEquipNum.add(1);
    uint256 newEquipId = equips.push(newEquip).sub(1);
    emit Birth(msg.sender,newEquipId,key,randomProps);
    _mint(to,newEquipId);

    typeCurrCntMap[uintkey] =  currentTypCnt + 1;

    return newEquipId;
  }


  function accquireAdvancedProps(uint256 tokenId,uint[] memory advancedProps) canGenerate public  {
    require(tokenId < TotalEquipNum );
    require( _isApprovedOrOwner( msg.sender,tokenId));
    Equipment storage equip = equips[tokenId];
    equip.advancedProperties = advancedProps;
  }

  function getEquip(uint256 idx) public view returns(
    string memory key,
    uint[] memory randomProps,
    uint[] memory advancedProperties
  ){
      require(idx < TotalEquipNum);
      Equipment storage equip = equips[idx];
      key = equip.key;
      randomProps = equip.randomProperties;
      advancedProperties = equip.advancedProperties;
  }
}




 

 

pragma solidity ^0.5.0;







contract SuperplayerRandomValueV001 is SuperplayerRandomValueBase {

   
  function initRtables1() public  onlyOwner{
    _initRtables1();
  }
  function initRtables2() public  onlyOwner{
    _initRtables2();
  }
  function initRtables3() public  onlyOwner{
    _initRtables3();
  }



  function _initRtables1 () internal {

uint[] memory v112 = new uint[](7);
uint[] memory w112  = new uint[](7);
v112[0]= 1001; w112[0]=40;
v112[1]= 1005; w112[1]=10;
v112[2]= 1006; w112[2]=10;
v112[3]= 1008; w112[3]=10;
v112[4]= 1009; w112[4]=10;
v112[5]= 1010; w112[5]=10;
v112[6]= 1007; w112[6]=10;
_addRandomValuesforRTable(112,v112,w112);

uint[] memory v144 = new uint[](7);
uint[] memory w144  = new uint[](7);
v144[0]= 1001; w144[0]=15;
v144[1]= 1005; w144[1]=5;
v144[2]= 1006; w144[2]=5;
v144[3]= 1008; w144[3]=5;
v144[4]= 1009; w144[4]=5;
v144[5]= 1010; w144[5]=60;
v144[6]= 1007; w144[6]=5;
_addRandomValuesforRTable(144,v144,w144);

uint[] memory v243 = new uint[](8);
uint[] memory w243  = new uint[](8);
v243[0]= 2002; w243[0]=12;
v243[1]= 2003; w243[1]=8;
v243[2]= 2004; w243[2]=5;
v243[3]= 2001; w243[3]=13;
v243[4]= 2008; w243[4]=6;
v243[5]= 2007; w243[5]=6;
v243[6]= 2005; w243[6]=30;
v243[7]= 2006; w243[7]=20;
_addRandomValuesforRTable(243,v243,w243);

uint[] memory v114 = new uint[](7);
uint[] memory w114  = new uint[](7);
v114[0]= 1001; w114[0]=30;
v114[1]= 1005; w114[1]=10;
v114[2]= 1006; w114[2]=10;
v114[3]= 1008; w114[3]=10;
v114[4]= 1009; w114[4]=10;
v114[5]= 1010; w114[5]=20;
v114[6]= 1007; w114[6]=10;
_addRandomValuesforRTable(114,v114,w114);

uint[] memory v121 = new uint[](6);
uint[] memory w121  = new uint[](6);
v121[0]= 1001; w121[0]=14;
v121[1]= 1002; w121[1]=40;
v121[2]= 1003; w121[2]=10;
v121[3]= 1008; w121[3]=12;
v121[4]= 1009; w121[4]=12;
v121[5]= 1010; w121[5]=12;
_addRandomValuesforRTable(121,v121,w121);

uint[] memory v123 = new uint[](7);
uint[] memory w123  = new uint[](7);
v123[0]= 1001; w123[0]=30;
v123[1]= 1005; w123[1]=10;
v123[2]= 1006; w123[2]=10;
v123[3]= 1008; w123[3]=13;
v123[4]= 1009; w123[4]=12;
v123[5]= 1010; w123[5]=13;
v123[6]= 1007; w123[6]=12;
_addRandomValuesforRTable(123,v123,w123);

uint[] memory v132 = new uint[](7);
uint[] memory w132  = new uint[](7);
v132[0]= 1001; w132[0]=50;
v132[1]= 1005; w132[1]=9;
v132[2]= 1006; w132[2]=9;
v132[3]= 1008; w132[3]=8;
v132[4]= 1009; w132[4]=8;
v132[5]= 1010; w132[5]=8;
v132[6]= 1007; w132[6]=8;
_addRandomValuesforRTable(132,v132,w132);

uint[] memory v244 = new uint[](7);
uint[] memory w244  = new uint[](7);
v244[0]= 2002; w244[0]=12;
v244[1]= 2003; w244[1]=8;
v244[2]= 2004; w244[2]=5;
v244[3]= 2001; w244[3]=15;
v244[4]= 2008; w244[4]=10;
v244[5]= 2007; w244[5]=10;
v244[6]= 2010; w244[6]=40;
_addRandomValuesforRTable(244,v244,w244);

uint[] memory v212 = new uint[](8);
uint[] memory w212  = new uint[](8);
v212[0]= 2002; w212[0]=30;
v212[1]= 2003; w212[1]=10;
v212[2]= 2004; w212[2]=10;
v212[3]= 2001; w212[3]=30;
v212[4]= 2008; w212[4]=5;
v212[5]= 2007; w212[5]=5;
v212[6]= 2009; w212[6]=5;
v212[7]= 2005; w212[7]=5;
_addRandomValuesforRTable(212,v212,w212);

uint[] memory v145 = new uint[](7);
uint[] memory w145  = new uint[](7);
v145[0]= 1001; w145[0]=15;
v145[1]= 1005; w145[1]=5;
v145[2]= 1006; w145[2]=5;
v145[3]= 1008; w145[3]=5;
v145[4]= 1009; w145[4]=60;
v145[5]= 1010; w145[5]=5;
v145[6]= 1007; w145[6]=5;
_addRandomValuesforRTable(145,v145,w145);

  }

  function _initRtables2 () internal {


uint[] memory v221 = new uint[](6);
uint[] memory w221  = new uint[](6);
v221[0]= 2002; w221[0]=35;
v221[1]= 2003; w221[1]=12;
v221[2]= 2004; w221[2]=13;
v221[3]= 2001; w221[3]=20;
v221[4]= 2008; w221[4]=10;
v221[5]= 2007; w221[5]=10;
_addRandomValuesforRTable(221,v221,w221);

uint[] memory v232 = new uint[](8);
uint[] memory w232  = new uint[](8);
v232[0]= 2002; w232[0]=15;
v232[1]= 2003; w232[1]=8;
v232[2]= 2004; w232[2]=7;
v232[3]= 2001; w232[3]=34;
v232[4]= 2008; w232[4]=9;
v232[5]= 2007; w232[5]=9;
v232[6]= 2009; w232[6]=9;
v232[7]= 2005; w232[7]=9;
_addRandomValuesforRTable(232,v232,w232);

uint[] memory v242 = new uint[](8);
uint[] memory w242  = new uint[](8);
v242[0]= 2002; w242[0]=12;
v242[1]= 2003; w242[1]=8;
v242[2]= 2004; w242[2]=5;
v242[3]= 2001; w242[3]=35;
v242[4]= 2008; w242[4]=10;
v242[5]= 2007; w242[5]=10;
v242[6]= 2009; w242[6]=10;
v242[7]= 2005; w242[7]=10;
_addRandomValuesforRTable(242,v242,w242);

uint[] memory v124 = new uint[](7);
uint[] memory w124  = new uint[](7);
v124[0]= 1001; w124[0]=30;
v124[1]= 1005; w124[1]=10;
v124[2]= 1006; w124[2]=10;
v124[3]= 1008; w124[3]=10;
v124[4]= 1009; w124[4]=10;
v124[5]= 1010; w124[5]=20;
v124[6]= 1007; w124[6]=10;
_addRandomValuesforRTable(124,v124,w124);

uint[] memory v131 = new uint[](6);
uint[] memory w131  = new uint[](6);
v131[0]= 1001; w131[0]=10;
v131[1]= 1002; w131[1]=40;
v131[2]= 1002; w131[2]=20;
v131[3]= 1008; w131[3]=10;
v131[4]= 1009; w131[4]=10;
v131[5]= 1010; w131[5]=10;
_addRandomValuesforRTable(131,v131,w131);

uint[] memory v135 = new uint[](7);
uint[] memory w135  = new uint[](7);
v135[0]= 1001; w135[0]=20;
v135[1]= 1005; w135[1]=8;
v135[2]= 1006; w135[2]=8;
v135[3]= 1008; w135[3]=8;
v135[4]= 1009; w135[4]=40;
v135[5]= 1010; w135[5]=8;
v135[6]= 1007; w135[6]=8;
_addRandomValuesforRTable(135,v135,w135);

uint[] memory v231 = new uint[](6);
uint[] memory w231  = new uint[](6);
v231[0]= 2002; w231[0]=40;
v231[1]= 2003; w231[1]=15;
v231[2]= 2004; w231[2]=15;
v231[3]= 2001; w231[3]=15;
v231[4]= 2008; w231[4]=7;
v231[5]= 2007; w231[5]=8;
_addRandomValuesforRTable(231,v231,w231);

uint[] memory v141 = new uint[](6);
uint[] memory w141  = new uint[](6);
v141[0]= 1001; w141[0]=10;
v141[1]= 1002; w141[1]=45;
v141[2]= 1002; w141[2]=25;
v141[3]= 1008; w141[3]=7;
v141[4]= 1009; w141[4]=7;
v141[5]= 1010; w141[5]=6;
_addRandomValuesforRTable(141,v141,w141);

uint[] memory v142 = new uint[](7);
uint[] memory w142  = new uint[](7);
v142[0]= 1001; w142[0]=60;
v142[1]= 1005; w142[1]=7;
v142[2]= 1006; w142[2]=7;
v142[3]= 1008; w142[3]=7;
v142[4]= 1009; w142[4]=7;
v142[5]= 1010; w142[5]=6;
v142[6]= 1007; w142[6]=6;
_addRandomValuesforRTable(142,v142,w142);

uint[] memory v111 = new uint[](6);
uint[] memory w111  = new uint[](6);
v111[0]= 1001; w111[0]=14;
v111[1]= 1002; w111[1]=40;
v111[2]= 1003; w111[2]=10;
v111[3]= 1008; w111[3]=12;
v111[4]= 1009; w111[4]=12;
v111[5]= 1010; w111[5]=12;
_addRandomValuesforRTable(111,v111,w111);

  }

  function _initRtables3 () internal {


uint[] memory v113 = new uint[](7);
uint[] memory w113  = new uint[](7);
v113[0]= 1001; w113[0]=30;
v113[1]= 1005; w113[1]=10;
v113[2]= 1006; w113[2]=10;
v113[3]= 1008; w113[3]=13;
v113[4]= 1009; w113[4]=12;
v113[5]= 1010; w113[5]=13;
v113[6]= 1007; w113[6]=12;
_addRandomValuesforRTable(113,v113,w113);

uint[] memory v115 = new uint[](7);
uint[] memory w115  = new uint[](7);
v115[0]= 1001; w115[0]=30;
v115[1]= 1005; w115[1]=10;
v115[2]= 1006; w115[2]=10;
v115[3]= 1008; w115[3]=20;
v115[4]= 1009; w115[4]=10;
v115[5]= 1010; w115[5]=10;
v115[6]= 1007; w115[6]=10;
_addRandomValuesforRTable(115,v115,w115);

uint[] memory v222 = new uint[](8);
uint[] memory w222  = new uint[](8);
v222[0]= 2002; w222[0]=20;
v222[1]= 2003; w222[1]=10;
v222[2]= 2004; w222[2]=10;
v222[3]= 2001; w222[3]=32;
v222[4]= 2008; w222[4]=7;
v222[5]= 2007; w222[5]=7;
v222[6]= 2009; w222[6]=7;
v222[7]= 2005; w222[7]=7;
_addRandomValuesforRTable(222,v222,w222);

uint[] memory v245 = new uint[](7);
uint[] memory w245  = new uint[](7);
v245[0]= 2002; w245[0]=12;
v245[1]= 2003; w245[1]=8;
v245[2]= 2004; w245[2]=5;
v245[3]= 2001; w245[3]=15;
v245[4]= 2008; w245[4]=10;
v245[5]= 2007; w245[5]=10;
v245[6]= 2009; w245[6]=40;
_addRandomValuesforRTable(245,v245,w245);

uint[] memory v133 = new uint[](7);
uint[] memory w133  = new uint[](7);
v133[0]= 1001; w133[0]=8;
v133[1]= 1005; w133[1]=40;
v133[2]= 1006; w133[2]=20;
v133[3]= 1008; w133[3]=8;
v133[4]= 1009; w133[4]=8;
v133[5]= 1010; w133[5]=8;
v133[6]= 1007; w133[6]=8;
_addRandomValuesforRTable(133,v133,w133);

uint[] memory v134 = new uint[](7);
uint[] memory w134  = new uint[](7);
v134[0]= 1001; w134[0]=20;
v134[1]= 1005; w134[1]=8;
v134[2]= 1006; w134[2]=8;
v134[3]= 1008; w134[3]=8;
v134[4]= 1009; w134[4]=8;
v134[5]= 1010; w134[5]=40;
v134[6]= 1007; w134[6]=8;
_addRandomValuesforRTable(134,v134,w134);

uint[] memory v241 = new uint[](6);
uint[] memory w241  = new uint[](6);
v241[0]= 2002; w241[0]=50;
v241[1]= 2003; w241[1]=15;
v241[2]= 2004; w241[2]=15;
v241[3]= 2001; w241[3]=10;
v241[4]= 2008; w241[4]=5;
v241[5]= 2007; w241[5]=5;
_addRandomValuesforRTable(241,v241,w241);

uint[] memory v122 = new uint[](7);
uint[] memory w122  = new uint[](7);
v122[0]= 1001; w122[0]=40;
v122[1]= 1005; w122[1]=10;
v122[2]= 1006; w122[2]=10;
v122[3]= 1008; w122[3]=10;
v122[4]= 1009; w122[4]=10;
v122[5]= 1010; w122[5]=10;
v122[6]= 1007; w122[6]=1;
_addRandomValuesforRTable(122,v122,w122);

uint[] memory v125 = new uint[](7);
uint[] memory w125  = new uint[](7);
v125[0]= 1001; w125[0]=30;
v125[1]= 1005; w125[1]=10;
v125[2]= 1006; w125[2]=10;
v125[3]= 1008; w125[3]=20;
v125[4]= 1009; w125[4]=10;
v125[5]= 1010; w125[5]=10;
v125[6]= 1007; w125[6]=10;
_addRandomValuesforRTable(125,v125,w125);

uint[] memory v211 = new uint[](6);
uint[] memory w211  = new uint[](6);
v211[0]= 2002; w211[0]=30;
v211[1]= 2003; w211[1]=10;
v211[2]= 2004; w211[2]=10;
v211[3]= 2001; w211[3]=30;
v211[4]= 2008; w211[4]=10;
v211[5]= 2007; w211[5]=10;
_addRandomValuesforRTable(211,v211,w211);

uint[] memory v143 = new uint[](7);
uint[] memory w143  = new uint[](7);
v143[0]= 1001; w143[0]=8;
v143[1]= 1005; w143[1]=45;
v143[2]= 1006; w143[2]=25;
v143[3]= 1008; w143[3]=6;
v143[4]= 1009; w143[4]=6;
v143[5]= 1010; w143[5]=5;
v143[6]= 1007; w143[6]=5;
_addRandomValuesforRTable(143,v143,w143);
  }








}



contract SuperplayerRandomEquipmentV001  is SuperplayerRandomEquipmentBase{


  constructor(address insRandomBuffAddr) SuperplayerRandomEquipmentBase(insRandomBuffAddr) public{

  }



  function initEquipmentPools() public  onlyOwner{
    _initEquipmentPools();
  }

  function _initEquipmentPools () internal {


uint[] memory ppurple_shoes_range_nft = new uint[](6);
ppurple_shoes_range_nft[0] = 244;
ppurple_shoes_range_nft[1] = 244;
ppurple_shoes_range_nft[2] = 244;
ppurple_shoes_range_nft[3] = 244;
ppurple_shoes_range_nft[4] = 244;
ppurple_shoes_range_nft[5] = 244;
_addEquipToPool("purple_shoes_range_nft",ppurple_shoes_range_nft,2300,40);


uint[] memory pblue_weapon_gun_gray_shotgun = new uint[](4);
pblue_weapon_gun_gray_shotgun[0] = 131;
pblue_weapon_gun_gray_shotgun[1] = 131;
pblue_weapon_gun_gray_shotgun[2] = 131;
pblue_weapon_gun_gray_shotgun[3] = 131;
_addEquipToPool("blue_weapon_gun_gray_shotgun",pblue_weapon_gun_gray_shotgun,5000,100);


uint[] memory pblue_leg_hp = new uint[](5);
pblue_leg_hp[0] = 231;
pblue_leg_hp[1] = 231;
pblue_leg_hp[2] = 231;
pblue_leg_hp[3] = 231;
pblue_leg_hp[4] = 231;
_addEquipToPool("blue_leg_hp",pblue_leg_hp,10000,200);


uint[] memory ppurple_weapon_gun_catapult_auto_eth = new uint[](5);
ppurple_weapon_gun_catapult_auto_eth[0] = 142;
ppurple_weapon_gun_catapult_auto_eth[1] = 142;
ppurple_weapon_gun_catapult_auto_eth[2] = 142;
ppurple_weapon_gun_catapult_auto_eth[3] = 142;
ppurple_weapon_gun_catapult_auto_eth[4] = 142;
_addEquipToPool("purple_weapon_gun_catapult_auto_eth",ppurple_weapon_gun_catapult_auto_eth,1000,20);


uint[] memory pblue_weapongun_gun_sniper_laser = new uint[](4);
pblue_weapongun_gun_sniper_laser[0] = 134;
pblue_weapongun_gun_sniper_laser[1] = 134;
pblue_weapongun_gun_sniper_laser[2] = 134;
pblue_weapongun_gun_sniper_laser[3] = 134;
_addEquipToPool("blue_weapongun_gun_sniper_laser",pblue_weapongun_gun_sniper_laser,5000,100);


uint[] memory pblue_weapongun_gun_black_hand = new uint[](4);
pblue_weapongun_gun_black_hand[0] = 135;
pblue_weapongun_gun_black_hand[1] = 135;
pblue_weapongun_gun_black_hand[2] = 135;
pblue_weapongun_gun_black_hand[3] = 135;
_addEquipToPool("blue_weapongun_gun_black_hand",pblue_weapongun_gun_black_hand,5000,100);


uint[] memory pblue_leg_damage = new uint[](5);
pblue_leg_damage[0] = 232;
pblue_leg_damage[1] = 232;
pblue_leg_damage[2] = 232;
pblue_leg_damage[3] = 232;
pblue_leg_damage[4] = 232;
_addEquipToPool("blue_leg_damage",pblue_leg_damage,10000,200);


uint[] memory pblue_helmet_hp = new uint[](5);
pblue_helmet_hp[0] = 231;
pblue_helmet_hp[1] = 231;
pblue_helmet_hp[2] = 231;
pblue_helmet_hp[3] = 231;
pblue_helmet_hp[4] = 231;
_addEquipToPool("blue_helmet_hp",pblue_helmet_hp,10000,200);


uint[] memory pblue_helmet_damage = new uint[](5);
pblue_helmet_damage[0] = 232;
pblue_helmet_damage[1] = 232;
pblue_helmet_damage[2] = 232;
pblue_helmet_damage[3] = 232;
pblue_helmet_damage[4] = 232;
_addEquipToPool("blue_helmet_damage",pblue_helmet_damage,10000,200);


uint[] memory ppurple_body_crit_nft = new uint[](6);
ppurple_body_crit_nft[0] = 243;
ppurple_body_crit_nft[1] = 243;
ppurple_body_crit_nft[2] = 243;
ppurple_body_crit_nft[3] = 243;
ppurple_body_crit_nft[4] = 243;
ppurple_body_crit_nft[5] = 243;
_addEquipToPool("purple_body_crit_nft",ppurple_body_crit_nft,2300,40);


uint[] memory ppurple_shoes_crit_nft = new uint[](6);
ppurple_shoes_crit_nft[0] = 243;
ppurple_shoes_crit_nft[1] = 243;
ppurple_shoes_crit_nft[2] = 243;
ppurple_shoes_crit_nft[3] = 243;
ppurple_shoes_crit_nft[4] = 243;
ppurple_shoes_crit_nft[5] = 243;
_addEquipToPool("purple_shoes_crit_nft",ppurple_shoes_crit_nft,2300,40);


uint[] memory ppurple_leg_range_nft = new uint[](6);
ppurple_leg_range_nft[0] = 244;
ppurple_leg_range_nft[1] = 244;
ppurple_leg_range_nft[2] = 244;
ppurple_leg_range_nft[3] = 244;
ppurple_leg_range_nft[4] = 244;
ppurple_leg_range_nft[5] = 244;
_addEquipToPool("purple_leg_range_nft",ppurple_leg_range_nft,2300,40);


uint[] memory ppurple_body_hp_nft = new uint[](6);
ppurple_body_hp_nft[0] = 241;
ppurple_body_hp_nft[1] = 241;
ppurple_body_hp_nft[2] = 241;
ppurple_body_hp_nft[3] = 241;
ppurple_body_hp_nft[4] = 241;
ppurple_body_hp_nft[5] = 241;
_addEquipToPool("purple_body_hp_nft",ppurple_body_hp_nft,2300,40);


uint[] memory pblue_weapon_gun_gray_sniper = new uint[](4);
pblue_weapon_gun_gray_sniper[0] = 133;
pblue_weapon_gun_gray_sniper[1] = 133;
pblue_weapon_gun_gray_sniper[2] = 133;
pblue_weapon_gun_gray_sniper[3] = 133;
_addEquipToPool("blue_weapon_gun_gray_sniper",pblue_weapon_gun_gray_sniper,5000,100);


uint[] memory pblue_shoes_damage = new uint[](5);
pblue_shoes_damage[0] = 232;
pblue_shoes_damage[1] = 232;
pblue_shoes_damage[2] = 232;
pblue_shoes_damage[3] = 232;
pblue_shoes_damage[4] = 232;
_addEquipToPool("blue_shoes_damage",pblue_shoes_damage,10000,200);


uint[] memory pblue_body_hp = new uint[](5);
pblue_body_hp[0] = 231;
pblue_body_hp[1] = 231;
pblue_body_hp[2] = 231;
pblue_body_hp[3] = 231;
pblue_body_hp[4] = 231;
_addEquipToPool("blue_body_hp",pblue_body_hp,10000,200);


uint[] memory pblue_shoes_hp = new uint[](5);
pblue_shoes_hp[0] = 231;
pblue_shoes_hp[1] = 231;
pblue_shoes_hp[2] = 231;
pblue_shoes_hp[3] = 231;
pblue_shoes_hp[4] = 231;
_addEquipToPool("blue_shoes_hp",pblue_shoes_hp,10000,200);


uint[] memory ppurple_leg_hp_nft = new uint[](6);
ppurple_leg_hp_nft[0] = 241;
ppurple_leg_hp_nft[1] = 241;
ppurple_leg_hp_nft[2] = 241;
ppurple_leg_hp_nft[3] = 241;
ppurple_leg_hp_nft[4] = 241;
ppurple_leg_hp_nft[5] = 241;
_addEquipToPool("purple_leg_hp_nft",ppurple_leg_hp_nft,2300,40);


uint[] memory ppurple_shoes_hp_nft = new uint[](6);
ppurple_shoes_hp_nft[0] = 241;
ppurple_shoes_hp_nft[1] = 241;
ppurple_shoes_hp_nft[2] = 241;
ppurple_shoes_hp_nft[3] = 241;
ppurple_shoes_hp_nft[4] = 241;
ppurple_shoes_hp_nft[5] = 241;
_addEquipToPool("purple_shoes_hp_nft",ppurple_shoes_hp_nft,2300,40);


uint[] memory ppurple_leg_crit_nft = new uint[](6);
ppurple_leg_crit_nft[0] = 243;
ppurple_leg_crit_nft[1] = 243;
ppurple_leg_crit_nft[2] = 243;
ppurple_leg_crit_nft[3] = 243;
ppurple_leg_crit_nft[4] = 243;
ppurple_leg_crit_nft[5] = 243;
_addEquipToPool("purple_leg_crit_nft",ppurple_leg_crit_nft,2300,40);


uint[] memory ppurple_helmet_crit_nft = new uint[](6);
ppurple_helmet_crit_nft[0] = 243;
ppurple_helmet_crit_nft[1] = 243;
ppurple_helmet_crit_nft[2] = 243;
ppurple_helmet_crit_nft[3] = 243;
ppurple_helmet_crit_nft[4] = 243;
ppurple_helmet_crit_nft[5] = 243;
_addEquipToPool("purple_helmet_crit_nft",ppurple_helmet_crit_nft,2300,40);


uint[] memory ppurple_body_range_nft = new uint[](6);
ppurple_body_range_nft[0] = 244;
ppurple_body_range_nft[1] = 244;
ppurple_body_range_nft[2] = 244;
ppurple_body_range_nft[3] = 244;
ppurple_body_range_nft[4] = 244;
ppurple_body_range_nft[5] = 244;
_addEquipToPool("purple_body_range_nft",ppurple_body_range_nft,2300,40);


uint[] memory pblue_body_damage = new uint[](5);
pblue_body_damage[0] = 232;
pblue_body_damage[1] = 232;
pblue_body_damage[2] = 232;
pblue_body_damage[3] = 232;
pblue_body_damage[4] = 232;
_addEquipToPool("blue_body_damage",pblue_body_damage,10000,200);


uint[] memory ppurple_weapon_gun_fire_eth = new uint[](5);
ppurple_weapon_gun_fire_eth[0] = 141;
ppurple_weapon_gun_fire_eth[1] = 141;
ppurple_weapon_gun_fire_eth[2] = 141;
ppurple_weapon_gun_fire_eth[3] = 141;
ppurple_weapon_gun_fire_eth[4] = 141;
_addEquipToPool("purple_weapon_gun_fire_eth",ppurple_weapon_gun_fire_eth,1000,20);


uint[] memory ppurple_helmet_hp_nft = new uint[](6);
ppurple_helmet_hp_nft[0] = 241;
ppurple_helmet_hp_nft[1] = 241;
ppurple_helmet_hp_nft[2] = 241;
ppurple_helmet_hp_nft[3] = 241;
ppurple_helmet_hp_nft[4] = 241;
ppurple_helmet_hp_nft[5] = 241;
_addEquipToPool("purple_helmet_hp_nft",ppurple_helmet_hp_nft,2300,40);


uint[] memory ppurple_helmet_range_nft = new uint[](6);
ppurple_helmet_range_nft[0] = 244;
ppurple_helmet_range_nft[1] = 244;
ppurple_helmet_range_nft[2] = 244;
ppurple_helmet_range_nft[3] = 244;
ppurple_helmet_range_nft[4] = 244;
ppurple_helmet_range_nft[5] = 244;
_addEquipToPool("purple_helmet_range_nft",ppurple_helmet_range_nft,2300,40);


uint[] memory ppurple_weapon_gun_rocket_eth = new uint[](5);
ppurple_weapon_gun_rocket_eth[0] = 144;
ppurple_weapon_gun_rocket_eth[1] = 144;
ppurple_weapon_gun_rocket_eth[2] = 144;
ppurple_weapon_gun_rocket_eth[3] = 144;
ppurple_weapon_gun_rocket_eth[4] = 144;
_addEquipToPool("purple_weapon_gun_rocket_eth",ppurple_weapon_gun_rocket_eth,1000,20);


uint[] memory pblue_weapon_gun_gray_auto = new uint[](4);
pblue_weapon_gun_gray_auto[0] = 132;
pblue_weapon_gun_gray_auto[1] = 132;
pblue_weapon_gun_gray_auto[2] = 132;
pblue_weapon_gun_gray_auto[3] = 132;
_addEquipToPool("blue_weapon_gun_gray_auto",pblue_weapon_gun_gray_auto,5000,100);


  }


}


contract SuperPlayerGachaPresell  is SuperplayerRandomEquipmentV001 ,SuperPlayerGachaWithRecommendReward {

  using SafeMath for uint256;
  SuperplayerEquipmentInterface spIns;

  uint256 recommendRatio = 3000;  

  constructor(address equipAddr, address randomAddr) SuperplayerRandomEquipmentV001(randomAddr) public{
    spIns = SuperplayerEquipmentInterface(equipAddr);

    feeForOne = 66 finney ;
    feeForTen = 594 finney;
  }

  uint256  public feeForOne;
  uint256 public feeForTen;




  function gacha (uint seed,string memory from) public payable  {
     require( msg.value >= feeForOne );
     uint blockNo;
     string memory key;
     uint[] memory equips;
     (blockNo,  key,  equips)  = this.getRandomEquipment(seed );
     _incrCurrentEquipCnt(key);
     spIns.createEquip(msg.sender,key,equips);
      
     msg.sender.transfer(msg.value.sub(feeForOne));
      
     address payable recommendAddress = address(uint160(_getRecommendAddress(from)));
     if(recommendAddress != address(0)) {
       recommendAddress.transfer( feeForOne.mul(recommendRatio).div(10000));
     }

  }

  function gacha10 (uint seed,string memory from) public payable  {
     require( msg.value >= feeForTen );
     uint blockNo;
     string memory key;
     uint[] memory equips;
     for (uint i=0 ;i<10;++i) {
      (blockNo,  key,  equips)  = this.getRandomEquipment(seed+i );
      _incrCurrentEquipCnt(key);
      spIns.createEquip(msg.sender,key,equips);
     }
     msg.sender.transfer(msg.value.sub(feeForTen));
      
     address payable recommendAddress = address(uint160(_getRecommendAddress(from)));
     if(recommendAddress != address(0)) {
       recommendAddress.transfer( feeForTen.mul(recommendRatio).div(10000));
     }
  }


  function withdraw( address payable to )  public onlyOwner{
    require(to == msg.sender);  
    to.transfer((address(this).balance ));
  }

}