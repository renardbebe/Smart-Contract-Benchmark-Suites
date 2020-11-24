 

pragma solidity ^0.4.21;

 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   
   
   
   
   
}

contract Ownable {
    
	   
	address public hostAddress;
	address public adminAddress;
    
    function Ownable() public {
		hostAddress = msg.sender;
		adminAddress = msg.sender;
    }

    modifier onlyHost() {
        require(msg.sender == hostAddress); 
        _;
    }
	
    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }
	
	 
	modifier onlyHostOrAdmin() {
		require(
		  msg.sender == hostAddress ||
		  msg.sender == adminAddress
		);
		_;
	}

	function setHost(address _newHost) public onlyHost {
		require(_newHost != address(0));

		hostAddress = _newHost;
	}
    
	function setAdmin(address _newAdmin) public onlyHost {
		require(_newAdmin != address(0));

		adminAddress = _newAdmin;
	}
}
 
contract CryptoCollectorContract is ERC721, Ownable {
        
     
        
     
    event NewToken(uint256 tokenId, string name, address owner);
        
     
    event NewTokenOwner(uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name, uint256 tokenId);
    
     
    event NewWildToken(uint256 wildcardPayment);
        
     
    event Transfer(address from, address to, uint256 tokenId);
        
     
      
     
    string public constant NAME = "CryptoCollectorContract";  
    string public constant SYMBOL = "CCC";  
      
	uint256 private killerPriceConversionFee = 0.19 ether; 
	
    uint256 private startingPrice = 0.002 ether; 
    uint256 private firstStepLimit =  0.045 ether;  
    uint256 private secondStepLimit =  0.45 ether;  
    uint256 private thirdStepLimit = 1.00 ether;  
        
     
        
     
     
    mapping (uint256 => address) public cardTokenToOwner;
        
     
     
    mapping (address => uint256) private ownershipTokenCount;
        
     
     
     
    mapping (uint256 => address) public cardTokenToApproved;
        
     
    mapping (uint256 => uint256) private cardTokenToPrice;
        
     
    mapping (uint256 => uint256) private cardTokenToPosition;
    
     
    mapping (address => uint256) public userArreyPosition;
    
     
    mapping (uint256 => uint256) private categoryToPosition;
     
    
     
    uint256 public wildcardTokenId;
    
     
    
	 
    
     
    
	 
	struct Card {
		uint256 token;
		string name;
		string imagepath;
		string category;
		uint256 Iswildcard;
		address owner;
		
	}

    struct CardUser {
		string name;
		string email;
	}
    struct Category {
        uint256 id;
		string name;
	}
	Card[] private cards;
    CardUser[] private cardusers;
    Category[] private categories;
    
    
	 
	 
	function getCard(uint256 _tokenId) public view returns (
		string name,
		uint256 token,
		uint256 price,
		uint256 nextprice,
		string imagepath,
		string category,
		uint256 wildcard,
		address _owner
	) {
	    
	     
         
	    
	    uint256 index = cardTokenToPosition[_tokenId];
	    Card storage card = cards[index];
		name = card.name;
		token = card.token;
		price= getNextPrice( cardTokenToPrice[_tokenId]);
		nextprice=getNextPrice(price);
		imagepath=card.imagepath;
		category=card.category;
		wildcard=card.Iswildcard;
		_owner=card.owner;
		
	}
    
     
	function createToken(string _name,string _imagepath,string _category, uint256 _id) public onlyAdmin {
		_createToken(_name,_imagepath,_category, _id, address(this), startingPrice,0);
	}
	
	function getkillerPriceConversionFee() public view returns(uint256 fee) {
		return killerPriceConversionFee;
		
	}
	
	function getAdmin() public view returns(address _admin) {
		return adminAddress  ;
	}
	 
	function makeWildCardToken(uint256 tokenId) public payable {

        require(msg.value == killerPriceConversionFee);		
		 
		uint256 index = cardTokenToPosition[tokenId];
	     
	    string storage cardCategory=cards[index].category;
	    uint256 totalCards = totalSupply();
        uint256 i=0;
          for (i = 0; i  <= totalCards-1; i++) {
             
             
            if (keccak256(cards[i].category)==keccak256(cardCategory)){
               cards[i].Iswildcard=0;
            }
          }
		cards[index].Iswildcard=1;
		 
		
		 
		 
		 
	}
     
	function setWildCardToken(uint256 tokenId) public onlyAdmin {

		 
		uint256 index = cardTokenToPosition[tokenId];
	     
	    string storage cardCategory=cards[index].category;
	    uint256 totalCards = totalSupply();
        uint256 i=0;
          for (i = 0; i  <= totalCards-1; i++) {
             
             
            if (keccak256(cards[i].category)==keccak256(cardCategory)){
               cards[i].Iswildcard=0;
            }
          }
		cards[index].Iswildcard=1;
		 
		
		wildcardTokenId = tokenId;
		emit NewWildToken(wildcardTokenId);
	}
	
	function IsWildCardCreatedForCategory(string _category) public view returns (bool){
		bool iscreated=false;
		uint256 totalCards = totalSupply();
        uint256 i=0;
          for (i = 0; i  <= totalCards-1; i++) {
             
            if ((keccak256(cards[i].category)==keccak256(_category)) && (cards[i].Iswildcard==1)){
			   iscreated=true;
            }
          }
		return iscreated;
	}
	
	function unsetWildCardToken(uint256 tokenId) public onlyAdmin {
		
		 
		uint256 index = cardTokenToPosition[tokenId];
	     
	    string storage cardCategory=cards[index].category;
	    uint256 totalCards = totalSupply();
        uint256 i=0;
          for (i = 0; i  <= totalCards-1; i++) {
             
            if (keccak256(cards[i].category)==keccak256(cardCategory)){
               cards[i].Iswildcard=0;
            }
          }
		 
		wildcardTokenId = tokenId;
		emit NewWildToken(wildcardTokenId);
	}
	
	function getUser(address _owner) public view returns(
	    string name,
	    string email,
	    uint256 position) 
	    {
	    uint256 index = userArreyPosition[_owner];
	    CardUser storage user = cardusers[index];
		name=user.name;
		email=user.email;
		position=index;
	    
	} 
	function totUsers() public view returns(uint256){
	    return cardusers.length;
	}
	function adduser(string _name,string _email,address userAddress) public{
	    CardUser memory _carduser = CardUser({
		  name:_name,
		  email:_email
		});
		
		uint256 index = cardusers.push(_carduser) - 1;
		userArreyPosition[userAddress] = index;
	}

	function addCategory(string _name,uint256 _id) public{
	    Category memory _category = Category({
	      id:_id,
		  name:_name
		});
		uint256 index = categories.push(_category) - 1;
		categoryToPosition[_id] = index;
	}
		function getTotalCategories() public view returns(
	    uint256) 
	    {
	        return categories.length;
	        
	    }
	function getCategory(uint256 _id) public view returns(
	    string name) 
	    {
	    uint256 index = categoryToPosition[_id];
	    Category storage cat = categories[index];
		name=cat.name;
	} 
		
	function _createToken(string _name,string _imagepath,string _category, uint256 _id, address _owner, uint256 _price,uint256 _IsWildcard) private {
	    
		Card memory _card = Card({
		  name: _name,
		  token: _id,
		  imagepath:_imagepath,
		  category:_category,
		  Iswildcard:_IsWildcard,
		  owner:adminAddress
		});
			
		uint256 index = cards.push(_card) - 1;
		cardTokenToPosition[_id] = index;
		 
		 
		require(_id == uint256(uint32(_id)));

		emit NewToken(_id, _name, _owner);
		cardTokenToPrice[_id] = _price;
		 
		 
		_transfer(address(0), _owner, _id);
	}
	 
	
	 
	
	 
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
      ) public {
         
        require(_owns(msg.sender, _tokenId));
    
        cardTokenToApproved[_tokenId] = _to;
    
        emit Approval(msg.sender, _to, _tokenId);
    }
    
     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    

     
     
     
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = cardTokenToOwner[_tokenId];
        require(owner != address(0));
    }
    
     
     
     
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = cardTokenToOwner[_tokenId];
    
         
        require(_addressNotNull(newOwner));

         
        require(_approved(newOwner, _tokenId));
    
        _transfer(oldOwner, newOwner, _tokenId);
    }
    
     
     
    function totalSupply() public view returns (uint256 total) {
        return cards.length;
    }
    
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
    
        _transfer(_from, _to, _tokenId);
    }

     
     
     
     
    function transfer(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
    
        _transfer(msg.sender, _to, _tokenId);
    }
    
     
	 
	 
	function tokenTransfer(address _to,uint256 _tokenId)  public onlyAdmin{
		address oldOwner = cardTokenToOwner[_tokenId];
		address newOwner = _to;
		uint256 index = cardTokenToPosition[_tokenId];
		cards[index].owner=newOwner;		
		_transfer(oldOwner, newOwner, _tokenId);
	}
	
	
     
    function name() public pure returns (string) {
        return NAME;
    }
    
     
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

	 
	
	 
	
	 
	
	 
	function payout(address _to) public onlyHostOrAdmin {
		_payout(_to);
	}
	
	function _payout(address _to) private {
		if (_to == address(0)) {
			hostAddress.transfer(address(this).balance);
		} else {
			_to.transfer(address(this).balance);
		}
	}
	
	 
	

     

    function contractBalance() public  view returns (uint256 balance) {
        return address(this).balance;
    }


function getNextPrice(uint256 sellingPrice) private view returns (uint256){
   
      
    if (sellingPrice < firstStepLimit) {
       
      sellingPrice = Helper.div(Helper.mul(sellingPrice, 300), 93);
    } else if (sellingPrice < secondStepLimit) {
       
      sellingPrice= Helper.div(Helper.mul(sellingPrice, 200), 93);
    } else if (sellingPrice < thirdStepLimit) {
       
      sellingPrice = Helper.div(Helper.mul(sellingPrice, 120), 93);
    } else {
       
      sellingPrice = Helper.div(Helper.mul(sellingPrice, 115), 93);
    }
    return sellingPrice;
} 

 
function nextPriceOf(uint256 _tokenId) public view returns (uint256 price){
    uint256 sellingPrice=cardTokenToPrice[_tokenId];
      
    if (sellingPrice < firstStepLimit) {
       
      sellingPrice = Helper.div(Helper.mul(sellingPrice, 300), 93);
    } else if (sellingPrice < secondStepLimit) {
       
      sellingPrice= Helper.div(Helper.mul(sellingPrice, 200), 93);
    } else if (sellingPrice < thirdStepLimit) {
       
      sellingPrice = Helper.div(Helper.mul(sellingPrice, 120), 93);
    } else {
       
      sellingPrice = Helper.div(Helper.mul(sellingPrice, 115), 93);
    }
    return sellingPrice;
} 

  function changePrice(uint256 _tokenId,uint256 _price) public onlyAdmin
  {
	     
		cardTokenToPrice[_tokenId] =_price;
	
  }

  function transferToken(address _to, uint256 _tokenId) public onlyAdmin {
    address oldOwner = cardTokenToOwner[_tokenId];
    address newOwner = _to;
	uint256 index = cardTokenToPosition[_tokenId];
	 
	cards[index].owner=newOwner;
    _transfer(oldOwner, newOwner, _tokenId); 
    
  }

   
  function numberOfTokens() public view returns (uint256) {
    return cards.length;
  }
  
 function purchase(uint256 _tokenId) public payable {
    address oldOwner = cardTokenToOwner[_tokenId];
    address newOwner = msg.sender;
    
	
	 
    require(oldOwner != address(0));

    uint256 sellingPrice =msg.value; 

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    
     
    cardTokenToPrice[_tokenId] =getNextPrice(sellingPrice);

    _transfer(oldOwner, newOwner, _tokenId);

	 
    address wildcardOwner =GetWildCardOwner(_tokenId) ; 
	uint256 wildcardPayment=uint256(Helper.div(Helper.mul(sellingPrice, 4), 100));  
	uint256 payment=uint256(Helper.div(Helper.mul(sellingPrice, 90), 100));  
    if (wildcardOwner != address(0)) {
		wildcardOwner.transfer(wildcardPayment);  
		sellingPrice=sellingPrice - wildcardPayment;  
    }
	
     
	 
    if (oldOwner != address(this)) {
		oldOwner.transfer(payment);  
    }
	 
     
	uint256 index = cardTokenToPosition[_tokenId];
	 
	cards[index].owner=newOwner;
    emit NewTokenOwner(sellingPrice, cardTokenToPrice[_tokenId], oldOwner, newOwner, cards[index].name, _tokenId);
	 
  }
  

function GetWildCardOwner(uint256 _tokenId) public view returns (address _cardowner){
		uint256 index=	cardTokenToPosition[_tokenId];
		string storage cardCategory=cards[index].category;
		
	    uint256 totalCards = totalSupply();
        uint256 i=0;
          for (i = 0; i  <= totalCards-1; i++) {
             
            if ((keccak256(cards[i].category)==keccak256(cardCategory)) && cards[i].Iswildcard==1){
               return cards[i].owner;
            }
          }
}
  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return cardTokenToPrice[_tokenId];
  }



   
   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalCards = totalSupply();
      uint256 resultIndex = 0;

      uint256 index;
      for (index = 0; index <= totalCards-1; index++) {
        if (cardTokenToOwner[cards[index].token] == _owner) {
          result[resultIndex] = cards[index].token;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return cardTokenToApproved[_tokenId] == _to;
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == cardTokenToOwner[_tokenId];
  }


   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    cardTokenToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete cardTokenToApproved[_tokenId];
    }

     
    emit Transfer(_from, _to, _tokenId);
  }
  

    function CryptoCollectorContract() public {
    }
    
}

library Helper {

   
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
    assert(c >= a);
    return c;
  }
}