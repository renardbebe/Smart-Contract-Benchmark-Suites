 

pragma solidity ^0.4.19;


contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function takeOwnership(uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


 
contract Ownable {
    address public owner;

     
    function Ownable() public{
        owner = msg.sender;
    }

     
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner{
        require(newOwner != address(0));
        owner = newOwner;
    }
}


 
contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused(){
        require(!paused);
        _;
    }

     
    modifier whenPaused{
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

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
    assert(c >= a);
    return c;
  }
}


contract ChemistryBase is Ownable {
    
    struct Element{
        bytes32 symbol;
    }
   
     

    event Create(address owner, uint256 atomicNumber, bytes32 symbol);
    
     
     
    event Transfer(address from, address to, uint256 tokenId);

     
    
     
    uint256 public tableSize = 173;

     

     
     
    Element[] public elements;

     
     
    mapping (uint256 => address) public elementToOwner;

     
     
    mapping (address => uint256) internal ownersTokenCount;

     
     
     
    mapping (uint256 => address) public elementToApproved;
    
    mapping (address => bool) public authorized;
    
    mapping (uint256 => uint256) public currentPrice;
    
	function addAuthorization (address _authorized) onlyOwner external {
		authorized[_authorized] = true;
	}

	function removeAuthorization (address _authorized) onlyOwner external {
		delete authorized[_authorized];
	}
	
	modifier onlyAuthorized() {
		require(authorized[msg.sender]);
		_;
	}
    
     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        ownersTokenCount[_to]++;
         
        elementToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownersTokenCount[_from]--;
             
            delete elementToApproved[_tokenId];
        }
         
        Transfer(_from, _to, _tokenId);
    }

     
     
     
     
    function _createElement(bytes32 _symbol, uint256 _price)
        internal
        returns (uint256) {
        	    
        address owner = address(this);
        Element memory _element = Element({
            symbol : _symbol
        });
        uint256 newElementId = elements.push(_element) - 1;
        
        currentPrice[newElementId] = _price;
        
         
        Create(owner, newElementId, _symbol);
        
         
         
        _transfer(0, owner, newElementId);

        return newElementId;
    }
    
    function setTableSize(uint256 _newSize) external onlyOwner {
        tableSize = _newSize;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        delete authorized[owner];
        authorized[newOwner] = true;
        super.transferOwnership(newOwner);
    }
}

contract ElementTokenImpl is ChemistryBase, ERC721 {

     
    string public constant name = "CryptoChemistry";
    string public constant symbol = "CC";

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('takeOwnership(uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)'));

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return elementToOwner[_tokenId] == _claimant;    
    }

    function _ownerApproved(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return elementToOwner[_tokenId] == _claimant && elementToApproved[_tokenId] == address(0);    
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return elementToApproved[_tokenId] == _claimant;
    }

     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        elementToApproved[_tokenId] = _approved;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownersTokenCount[_owner];
    }

     
     
     
     
    function transfer(address _to, uint256 _tokenId) external {
         
        require(_to != address(0));
         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(address _to, uint256 _tokenId) external {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
    {
         
        require(_to != address(0));
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint256) {
        return elements.length;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = elementToOwner[_tokenId];

        require(owner != address(0));
    }
    
    function takeOwnership(uint256 _tokenId) external {
        address _from = elementToOwner[_tokenId];
        
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_from != address(0));

         
        _transfer(_from, msg.sender, _tokenId);
    }

     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalElements = totalSupply();
            uint256 resultIndex = 0;

            uint256 elementId;

            for (elementId = 0; elementId < totalElements; elementId++) {
                if (elementToOwner[elementId] == _owner) {
                    result[resultIndex] = elementId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
    
}

contract ContractOfSale is ElementTokenImpl {
    using SafeMath for uint256;
    
  	event Sold (uint256 elementId, address oldOwner, address newOwner, uint256 price);
  	
  	uint256 private constant LIMIT_1 = 20 finney;
  	uint256 private constant LIMIT_2 = 500 finney;
  	uint256 private constant LIMIT_3 = 2000 finney;
  	uint256 private constant LIMIT_4 = 5000 finney;
  	
  	 
  	function calculateNextPrice (uint256 _price) public pure returns (uint256 _nextPrice) {
	    if (_price < LIMIT_1) {
	      return _price.mul(2); 
	    } else if (_price < LIMIT_2) {
	      return _price.mul(13500).div(10000); 
	    } else if (_price < LIMIT_3) {
	      return _price.mul(12500).div(10000); 
	    } else if (_price < LIMIT_4) {
	      return _price.mul(11700).div(10000); 
	    } else {
	      return _price.mul(11500).div(10000); 
	    }
  	}

	function _calculateOwnerCut (uint256 _price) internal pure returns (uint256 _devCut) {
		if (_price < LIMIT_1) {
	      return _price.mul(1500).div(10000);  
	    } else if (_price < LIMIT_2) {
	      return _price.mul(500).div(10000);  
	    } else if (_price < LIMIT_3) {
	      return _price.mul(400).div(10000);  
	    } else if (_price < LIMIT_4) {
	      return _price.mul(300).div(10000);  
	    } else {
	      return _price.mul(200).div(10000);  
	    }
  	}

	function buy (uint256 _itemId) external payable{
        uint256 price = currentPrice[_itemId];
	     
        require(currentPrice[_itemId] > 0);
         
        require(elementToOwner[_itemId] != address(0));
         
        require(msg.value >= price);
         
        require(elementToOwner[_itemId] != msg.sender);
         
        require(msg.sender != address(0));
        
        address oldOwner = elementToOwner[_itemId];
         
        address newOwner = msg.sender;
         
         
        uint256 excess = msg.value.sub(price);
         
        _transfer(oldOwner, newOwner, _itemId);
         
        currentPrice[_itemId] = calculateNextPrice(price);
        
        Sold(_itemId, oldOwner, newOwner, price);

        uint256 ownerCut = _calculateOwnerCut(price);

        oldOwner.transfer(price.sub(ownerCut));
        if (excess > 0) {
            newOwner.transfer(excess);
        }
    }
    
	function priceOfElement(uint256 _elementId) external view returns (uint256 _price) {
		return currentPrice[_elementId];
	}

	function priceOfElements(uint256[] _elementIds) external view returns (uint256[] _prices) {
	    uint256 length = _elementIds.length;
	    _prices = new uint256[](length);
	    
	    for(uint256 i = 0; i < length; i++) {
	        _prices[i] = currentPrice[_elementIds[i]];
	    }
	}

	function nextPriceOfElement(uint256 _itemId) public view returns (uint256 _nextPrice) {
		return calculateNextPrice(currentPrice[_itemId]);
	}

}

contract ChemistryCore is ContractOfSale {
    
    function ChemistryCore() public {
        owner = msg.sender;
        authorized[msg.sender] = true;
        
        _createElement("0", 2 ** 255); 
    }
    
    function addElement(bytes32 _symbol) external onlyAuthorized() {
        uint256 elementId = elements.length + 1;
        
        require(currentPrice[elementId] == 0);
        require(elementToOwner[elementId] == address(0));
        require(elementId <= tableSize + 1);
        
        _createElement(_symbol, 1 finney);
    }
    
    function addElements(bytes32[] _symbols) external onlyAuthorized() {
        uint256 elementId = elements.length + 1;
        
        uint256 length = _symbols.length;
        uint256 size = tableSize + 1;
        for(uint256 i = 0; i < length; i ++) {
            
            require(currentPrice[elementId] == 0);
            require(elementToOwner[elementId] == address(0));
            require(elementId <= size);
            
            _createElement(_symbols[i], 1 finney);
            elementId++;
        }
        
    }

    function withdrawAll() onlyOwner() external {
        owner.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) onlyOwner() external {
        owner.transfer(_amount);
    }
    
    function() external payable {
        require(msg.sender == address(this));
    }
    
    function getElementsFromIndex(uint32 indexFrom, uint32 count) external view returns (bytes32[] memory elementsData) {
         
        uint256 lenght = (elements.length - indexFrom >= count ? count : elements.length - indexFrom);
        
        elementsData = new bytes32[](lenght);
        for(uint256 i = 0; i < lenght; i ++) {
            elementsData[i] = elements[indexFrom + i].symbol;
        }
    }
    
    function getElementOwners(uint256[] _elementIds) external view returns (address[] memory owners) {
        uint256 lenght = _elementIds.length;
        owners = new address[](lenght);
        
        for(uint256 i = 0; i < lenght; i ++) {
            owners[i] = elementToOwner[_elementIds[i]];
        }
    }
    
	function getElementView(uint256 _id) external view returns (string symbol) {
		symbol = _bytes32ToString(elements[_id].symbol);
    }
	
	function getElement(uint256 _id) external view returns (bytes32 symbol) {
		symbol = elements[_id].symbol;
    }
    
    function getElements(uint256[] _elementIds) external view returns (bytes32[] memory elementsData) {
        elementsData = new bytes32[](_elementIds.length);
        for(uint256 i = 0; i < _elementIds.length; i++) {
            elementsData[i] = elements[_elementIds[i]].symbol;
        }
    }
    
    function getElementInfoView(uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 _nextPrice, string _symbol) {
	    _price = currentPrice[_itemId];
		return (elementToOwner[_itemId], _price, calculateNextPrice(_price), _bytes32ToString(elements[_itemId].symbol));
	}
    
    function getElementInfo(uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 _nextPrice, bytes32 _symbol) {
	    _price = currentPrice[_itemId];
		return (elementToOwner[_itemId], _price, calculateNextPrice(_price), elements[_itemId].symbol);
	}
    
    function _bytes32ToString(bytes32 data) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint256(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}