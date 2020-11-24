 

pragma solidity ^0.4.25;
 

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
    assert(c >= a && c>=b);
    return c;
  }
}

contract WeaponTokenize {
  event GameProprietaryDataUpdated(uint weaponId, string gameData);
  event PublicDataUpdated(uint weaponId, string publicData);
  event OwnerProprietaryDataUpdated(uint weaponId, string ownerProprietaryData);
  event WeaponAdded(uint weaponId, string gameData, string publicData, string ownerData);
  function updateOwnerOfWeapon (uint, address) public  returns(bool res);
  function getOwnerOf (uint _weaponId) public view returns(address _owner) ;
}

contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool success);
  function balanceOf(address _sender) public returns (uint _bal);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  event Transfer(address indexed from, address indexed to, uint tokens);
      function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract TradeWeapon {
  using SafeMath for uint;
   
  address public owner;
  WeaponTokenize public weaponTokenize;
  ERC20Interface public RCCToken;
  uint public rate = 100;  
  uint public commssion_n = 50;  
  uint public commssion_d = 100;
  bool public saleDisabled = false;
  bool public ethSaleDisabled = false;

   
  uint public totalOrdersPlaced = 0;
  uint public totalOrdersCancelled = 0;
  uint public totalOrdersMatched = 0;

  struct item{
    uint sellPrice;
    uint commssion;
    address seller;
  }

   
  mapping (uint => item) public weaponDetail;
   
  uint totalWeaponOnSale;
   
  mapping(uint => uint) public indexToWeaponId;
   
  mapping(uint => uint) public weaponIdToIndex;
   
  mapping (uint => bool) public isOnSale;
   
  mapping (address => mapping(address => bool)) private operators;
  
   
  event OrderPlaced(address _seller, address _placedBy, uint _weaponId, uint _sp);
  event OderUpdated(address _seller, address _placedBy, uint _weaponId, uint _sp);
  event OrderCacelled(address _placedBy, uint _weaponId);
  event OrderMatched(address _buyer, address _seller, uint _sellPrice, address _placedBy, uint _commssion, string _payType);
  
  constructor (address _tokenizeAddress, address _rccAddress) public{
    owner = msg.sender;
    weaponTokenize =  WeaponTokenize(_tokenizeAddress);
    RCCToken = ERC20Interface(_rccAddress);
  }

  modifier onlyOwnerOrOperator(uint _weaponId) {
    address weaponOwner = weaponTokenize.getOwnerOf(_weaponId);
    require (
      (msg.sender == weaponOwner ||
      checkOperator(weaponOwner, msg.sender)
      ), '2');
    _;
  }

  modifier onlyIfOnSale(uint _weaponId) {
    require(isOnSale[_weaponId], '3');
    _;
  }

  modifier ifSaleLive(){
    require(!saleDisabled, '6');
    _;
  }

  modifier ifEthSaleLive() {
    require(!ethSaleDisabled, '7');
    _;
  }

  modifier onlyOwner() {
    require (msg.sender == owner, '1');
    _;
  }

   
                     
   

  function updateRate(uint _newRate) onlyOwner public {
    rate = _newRate;
  }

  function updateCommission(uint _commssion_n, uint _commssion_d) onlyOwner public {
    commssion_n = _commssion_n;
    commssion_d = _commssion_d;
  }

  function disableSale() public onlyOwner {
    saleDisabled = true;
  }

  function enableSale() public onlyOwner {
    saleDisabled = false;
  }

  function disableEthSale() public onlyOwner {
    ethSaleDisabled = false;
  }

  function enableEthSale() public onlyOwner {
    ethSaleDisabled = true;
  }

   
                     
   

  function addOperator(address newOperator) public{
    operators[msg.sender][newOperator] =  true;
  }

  function removeOperator(address _operator) public {
    operators[msg.sender][_operator] =  false;
  }



  function sellWeapon(uint _weaponId, uint _sellPrice) ifSaleLive onlyOwnerOrOperator(_weaponId) public {
     
    require( ! isOnSale[_weaponId], '4');
     
    address weaponOwner = weaponTokenize.getOwnerOf(_weaponId);
     
    uint _commssion = calculateCommission(_sellPrice);
    
    item memory testItem = item(_sellPrice, _commssion, weaponOwner);
     
    putWeaponOnSale(_weaponId, testItem);
     
    emit OrderPlaced(weaponOwner, msg.sender, _weaponId, _sellPrice);
  }

  function updateSale(uint _weaponId, uint _sellPrice) ifSaleLive onlyIfOnSale(_weaponId) onlyOwnerOrOperator(_weaponId) public {
     
    uint _commssion = calculateCommission(_sellPrice);
     
    address weaponOwner = weaponTokenize.getOwnerOf(_weaponId);
    item memory testItem = item(_sellPrice ,_commssion, weaponOwner);
    weaponDetail[_weaponId] = testItem;
    emit OderUpdated(weaponOwner, msg.sender, _weaponId, _sellPrice);
  }


  function cancelSale(uint _weaponId) ifSaleLive onlyIfOnSale(_weaponId) onlyOwnerOrOperator(_weaponId) public {
    (address weaponOwner,,) = getWeaponDetails(_weaponId);
    removeWeaponFromSale(_weaponId);
    totalOrdersCancelled = totalOrdersCancelled.add(1);
    weaponTokenize.updateOwnerOfWeapon(_weaponId, weaponOwner);
    emit OrderCacelled(msg.sender, _weaponId);
  }

  function buyWeaponWithRCC(uint _weaponId, address _buyer) ifSaleLive onlyIfOnSale(_weaponId) public{
    if (_buyer != address(0)){
      buywithRCC(_weaponId, _buyer);
    }else{
      buywithRCC(_weaponId, msg.sender);
    }
  }

  function buyWeaponWithEth(uint _weaponId, address _buyer) ifSaleLive ifEthSaleLive onlyIfOnSale(_weaponId) public payable {
    if (_buyer != address(0)){
      buywithEth(_weaponId, _buyer, msg.value);
    }else{
      buywithEth(_weaponId, msg.sender, msg.value);
    }
  }


   
                     
   

  function buywithRCC(uint _weaponId, address _buyer) internal {
     
    (address seller, uint spOfWeapon, uint commssion) = getWeaponDetails(_weaponId);
     
    uint allowance = RCCToken.allowance(_buyer, address(this));
     
    uint sellersPrice = spOfWeapon.sub(commssion);
    require(allowance >= spOfWeapon, '5');
     
    removeWeaponFromSale(_weaponId);
     
    if(spOfWeapon > 0){
      RCCToken.transferFrom(_buyer, seller, sellersPrice);
    }
    if(commssion > 0){
      RCCToken.transferFrom(_buyer, owner, commssion);
    }
     
	  totalOrdersMatched = totalOrdersMatched.add(1);
     
    weaponTokenize.updateOwnerOfWeapon(_weaponId, _buyer);
    emit OrderMatched(_buyer, seller, spOfWeapon, msg.sender, commssion, 'RCC');
  }

  function buywithEth(uint _weaponId, address _buyer, uint weiPaid) internal {
     
    require ( rate > 0, '8');

     
    (address seller, uint spOfWeapon, uint commssion) = getWeaponDetails(_weaponId);

     
    uint spInWei = spOfWeapon.div(rate);
    require(spInWei > 0, '9');
    require(weiPaid == spInWei, '10');
    uint sellerPrice = spOfWeapon.sub(commssion);

     
    require (RCCToken.balanceOf(address(this)) >= sellerPrice, '11');
    RCCToken.transfer(seller, sellerPrice);

     
     

     
    removeWeaponFromSale(_weaponId);

     
	  totalOrdersMatched = totalOrdersMatched.add(1);

     
    weaponTokenize.updateOwnerOfWeapon(_weaponId, _buyer);
    emit OrderMatched(_buyer, seller, spOfWeapon,  msg.sender, commssion, 'ETH');
  } 

  function putWeaponOnSale(uint _weaponId, item memory _testItem) internal {
     
    weaponTokenize.updateOwnerOfWeapon(_weaponId, address(this));
     
    indexToWeaponId[totalWeaponOnSale.add(1)] = _weaponId;
     
    weaponIdToIndex[_weaponId] = totalWeaponOnSale.add(1);
     
    totalWeaponOnSale = totalWeaponOnSale.add(1);
     
    weaponDetail[_weaponId] = _testItem;
     
    isOnSale[_weaponId] = true;
     
    totalOrdersPlaced = totalOrdersPlaced.add(1);
  }

  function removeWeaponFromSale(uint _weaponId) internal {
     
    isOnSale[_weaponId] = false;
     
    weaponDetail[_weaponId] = item(0, 0,address(0));
    uint indexOfDeletedWeapon = weaponIdToIndex[_weaponId];
    if(indexOfDeletedWeapon != totalWeaponOnSale){
      uint weaponAtLastIndex = indexToWeaponId[totalWeaponOnSale];
       
      weaponIdToIndex[weaponAtLastIndex] = indexOfDeletedWeapon;
      indexToWeaponId[indexOfDeletedWeapon] = weaponAtLastIndex;
       
      weaponIdToIndex[_weaponId] = 0;
      indexToWeaponId[totalWeaponOnSale] = 0;
    } else{
      weaponIdToIndex[_weaponId] = 0;
      indexToWeaponId[indexOfDeletedWeapon] = 0;
    }
    totalWeaponOnSale = totalWeaponOnSale.sub(1);
  }

   
                     
   

  function getWeaponDetails (uint _weaponId) public view returns (address, uint, uint) {
    item memory currentItem = weaponDetail[_weaponId];
    return (currentItem.seller, currentItem.sellPrice, currentItem.commssion);
  }

  function calculateCommission (uint _amount) public view returns (uint) {
    return _amount.mul(commssion_n).div(commssion_d).div(100);
  }

  function getTotalWeaponOnSale() public view returns (uint) {
    return totalWeaponOnSale;
  }

  function getWeaponAt(uint index) public view returns(address, uint, uint, uint) {
    uint weaponId =  indexToWeaponId[index];
    item memory currentItem = weaponDetail[weaponId];
    return (currentItem.seller, currentItem.sellPrice, currentItem.commssion, weaponId);
  }

  function checkOperator(address _user, address _operator) public view returns (bool){
    return operators[_user][_operator];
  }

}