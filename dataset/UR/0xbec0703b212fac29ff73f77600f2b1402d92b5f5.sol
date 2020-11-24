 

pragma solidity ^0.4.24;

 

 

contract ERC721 {

  function approve(address _to, uint _tokenId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _tokenId) public view returns (address addr);
  function takeOwnership(uint _tokenId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _tokenId) public;
  function transfer(address _to, uint _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint tokenId);
  event Approval(address indexed owner, address indexed approved, uint tokenId);

}

contract XYZethrDividendCards is ERC721 {
    using SafeMath for uint;

   

   
  event Birth(uint tokenId, string name, address owner);

   
  event TokenSold(uint tokenId, uint oldPrice, uint newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint tokenId);

   

   
  string public constant NAME           = "XYZethrDividendCard";
  string public constant SYMBOL         = "XYZDC";
  address public         BANKROLL;

   

   
   

  mapping (uint => address) public      divCardIndexToOwner;

   

  mapping (uint => uint) public         divCardRateToIndex;

   
   

  mapping (address => uint) private     ownershipDivCardCount;

   
   
   

  mapping (uint => address) public      divCardIndexToApproved;

   

  mapping (uint => uint) private        divCardIndexToPrice;

  mapping (address => bool) internal    administrators;

  address public                        creator;
  bool    public                        onSale;

   

  struct Card {
    string name;
    uint percentIncrease;
  }

  Card[] private divCards;

  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  constructor (address _bankroll) public {
    creator = msg.sender;
    BANKROLL = _bankroll;

    createDivCard("2%", 1 ether, 2);
    divCardRateToIndex[2] = 0;

    createDivCard("5%", 1 ether, 5);
    divCardRateToIndex[5] = 1;

    createDivCard("10%", 1 ether, 10);
    divCardRateToIndex[10] = 2;

    createDivCard("15%", 1 ether, 15);
    divCardRateToIndex[15] = 3;

    createDivCard("20%", 1 ether, 20);
    divCardRateToIndex[20] = 4;

    createDivCard("25%", 1 ether, 25);
    divCardRateToIndex[25] = 5;

    createDivCard("33%", 1 ether, 33);
    divCardRateToIndex[33] = 6;

    createDivCard("MASTER", 5 ether, 10);
    divCardRateToIndex[999] = 7;

	onSale = false;

    administrators[msg.sender] = true; 


  }

   

     
    modifier isNotContract()
    {
        require (msg.sender == tx.origin);
        _;
    }

	 
	modifier hasStarted()
    {
		require (onSale == true);
		_;
	}

	modifier isAdmin()
    {
	    require(administrators[msg.sender]);
	    _;
    }

   
   
    function setBankroll(address where)
        isAdmin
    {
        BANKROLL = where;
    }

   
   
   
   
   
  function approve(address _to, uint _tokenId)
    public
    isNotContract
  {
     
    require(_owns(msg.sender, _tokenId));

    divCardIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner)
    public
    view
    returns (uint balance)
  {
    return ownershipDivCardCount[_owner];
  }

   
  function createDivCard(string _name, uint _price, uint _percentIncrease)
    public
    onlyCreator
  {
    _createDivCard(_name, BANKROLL, _price, _percentIncrease);
  }

	 
	function startCardSale()
        public
        onlyCreator
    {
		onSale = true;
	}

   
   
  function getDivCard(uint _divCardId)
    public
    view
    returns (string divCardName, uint sellingPrice, address owner)
  {
    Card storage divCard = divCards[_divCardId];
    divCardName = divCard.name;
    sellingPrice = divCardIndexToPrice[_divCardId];
    owner = divCardIndexToOwner[_divCardId];
  }

  function implementsERC721()
    public
    pure
    returns (bool)
  {
    return true;
  }

   
  function name()
    public
    pure
    returns (string)
  {
    return NAME;
  }

   
   
   
  function ownerOf(uint _divCardId)
    public
    view
    returns (address owner)
  {
    owner = divCardIndexToOwner[_divCardId];
    require(owner != address(0));
	return owner;
  }

   
  function purchase(uint _divCardId)
    public
    payable
    hasStarted
    isNotContract
  {
    address oldOwner  = divCardIndexToOwner[_divCardId];
    address newOwner  = msg.sender;

     
    uint currentPrice = divCardIndexToPrice[_divCardId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= currentPrice);

     
     
     
    uint percentIncrease = divCards[_divCardId].percentIncrease;
    uint previousPrice   = SafeMath.mul(currentPrice, 100).div(100 + percentIncrease);

     
    uint totalProfit     = SafeMath.sub(currentPrice, previousPrice);
    uint oldOwnerProfit  = SafeMath.div(totalProfit, 2);
    uint bankrollProfit  = SafeMath.sub(totalProfit, oldOwnerProfit);
    oldOwnerProfit       = SafeMath.add(oldOwnerProfit, previousPrice);

     
    uint purchaseExcess  = SafeMath.sub(msg.value, currentPrice);

     
    divCardIndexToPrice[_divCardId] = SafeMath.div(SafeMath.mul(currentPrice, (100 + percentIncrease)), 100);

     
    _transfer(oldOwner, newOwner, _divCardId);

     
    BANKROLL.send(bankrollProfit);
    oldOwner.send(oldOwnerProfit);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint _divCardId)
    public
    view
    returns (uint price)
  {
    return divCardIndexToPrice[_divCardId];
  }

  function setCreator(address _creator)
    public
    onlyCreator
  {
    require(_creator != address(0));

    creator = _creator;
  }

   
  function symbol()
    public
    pure
    returns (string)
  {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint _divCardId)
    public
    isNotContract
  {
    address newOwner = msg.sender;
    address oldOwner = divCardIndexToOwner[_divCardId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _divCardId));

    _transfer(oldOwner, newOwner, _divCardId);
  }

   
   
  function totalSupply()
    public
    view
    returns (uint total)
  {
    return divCards.length;
  }

   
   
   
   
  function transfer(address _to, uint _divCardId)
    public
    isNotContract
  {
    require(_owns(msg.sender, _divCardId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _divCardId);
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint _divCardId)
    public
    isNotContract
  {
    require(_owns(_from, _divCardId));
    require(_approved(_to, _divCardId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _divCardId);
  }

  function receiveDividends(uint _divCardRate)
    public
    payable
  {
    uint _divCardId = divCardRateToIndex[_divCardRate];
    address _regularAddress = divCardIndexToOwner[_divCardId];
    address _masterAddress = divCardIndexToOwner[7];

    uint toMaster = msg.value.div(2);
    uint toRegular = msg.value.sub(toMaster);

    _masterAddress.send(toMaster);
    _regularAddress.send(toRegular);
  }

   
   
  function _addressNotNull(address _to)
    private
    pure
    returns (bool)
  {
    return _to != address(0);
  }

   
  function _approved(address _to, uint _divCardId)
    private
    view
    returns (bool)
  {
    return divCardIndexToApproved[_divCardId] == _to;
  }

   
  function _createDivCard(string _name, address _owner, uint _price, uint _percentIncrease)
    private
  {
    Card memory _divcard = Card({
      name: _name,
      percentIncrease: _percentIncrease
    });
    uint newCardId = divCards.push(_divcard) - 1;

     
     
    require(newCardId == uint(uint32(newCardId)));

    emit Birth(newCardId, _name, _owner);

    divCardIndexToPrice[newCardId] = _price;

     
    _transfer(BANKROLL, _owner, newCardId);
  }

   
  function _owns(address claimant, uint _divCardId)
    private
    view
    returns (bool)
  {
    return claimant == divCardIndexToOwner[_divCardId];
  }

   
  function _transfer(address _from, address _to, uint _divCardId)
    private
  {
     
    ownershipDivCardCount[_to]++;
     
    divCardIndexToOwner[_divCardId] = _to;

     
    if (_from != address(0)) {
      ownershipDivCardCount[_from]--;
       
      delete divCardIndexToApproved[_divCardId];
    }

     
    emit Transfer(_from, _to, _divCardId);
  }
}

 
library SafeMath {

   
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

   
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}