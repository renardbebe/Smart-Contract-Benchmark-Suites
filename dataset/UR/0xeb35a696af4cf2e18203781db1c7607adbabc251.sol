 

pragma solidity ^0.4.18;

contract CryptoLandmarks {
    using SafeMath for uint256;

     
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

     
    event LandmarkSold(uint256 tokenId, uint256 price, uint256 nextPrice, address prevOwner, address owner);
    
     
    event PriceChanged(uint256 tokenId, uint256 price);

     
    event LandmarkCreated(uint256 tokenId, uint256 groupId, uint256 price, address owner);

   
    string public constant NAME = "CryptoLandmarks.co Landmarks"; 
    string public constant SYMBOL = "LANDMARK"; 

     
    uint256 private startingPrice = 0.03 ether;
     
    uint256 private ambassadorStartingPrice = 3 ether;

     
    uint256 public transactions = 0;

     
    address public ceo;
    address public coo;

    uint256[] private landmarks;
    
     
    mapping (uint256 => uint256) landmarkToMaxPrice;
    mapping (uint256 => uint256) landmarkToPrice;
    
     
    mapping (uint256 => address) landmarkToOwner;
    
     
     
     
    mapping (uint256 => uint256) landmarkToAmbassador;
    
     
    mapping (uint256 => uint256) groupLandmarksCount;

     
    mapping (address => uint256) public withdrawCooldown;

    mapping (uint256 => address) landmarkToApproved;
    mapping (address => uint256) landmarkOwnershipCount;


    function CryptoLandmarks() public {
        ceo = msg.sender;
        coo = msg.sender;
    }

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price < 0.2 ether)
            return _price.mul(2);  
        if (_price < 4 ether)
            return _price.mul(17).div(10);  
        if (_price < 15 ether)
            return _price.mul(141).div(100);  
        else
            return _price.mul(134).div(100);  
    }

    function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
        if (_price < 0.2 ether)
            return 5;  
        if (_price < 4 ether)
            return 4;  
        if (_price < 15 ether)
            return 3;  
        else
            return 2;  
    }   

     
    function buy(uint256 _tokenId) public payable {
        address oldOwner = landmarkToOwner[_tokenId];
        require(oldOwner != msg.sender);
        require(msg.sender != address(0));
        uint256 sellingPrice = priceOfLandmark(_tokenId);
        require(msg.value >= sellingPrice);

         
        uint256 excess = msg.value.sub(sellingPrice);

         
        uint256 groupId = landmarkToAmbassador[_tokenId];

         
        uint256 groupMembersCount = groupLandmarksCount[groupId];

         
        uint256 devCut = calculateDevCut(sellingPrice);

         
        uint256 payment;
        
        if (_tokenId < 1000) {
             
            payment = sellingPrice.mul(SafeMath.sub(95, devCut)).div(100);
        } else {
             
            payment = sellingPrice.mul(SafeMath.sub(90, devCut)).div(100);
        }

         
        uint256 feeGroupMember = (sellingPrice.mul(5).div(100)).div(groupMembersCount);


        for (uint i = 0; i < totalSupply(); i++) {
            uint id = landmarks[i];
            if ( landmarkToAmbassador[id] == groupId ) {
                if ( _tokenId == id) {
                     
                    oldOwner.transfer(payment);
                }
                if (groupId == id && _tokenId >= 1000) {
                     
                    landmarkToOwner[id].transfer(sellingPrice.mul(5).div(100));
                }

                 
                 
                landmarkToOwner[id].transfer(feeGroupMember);
            }
        }
        
        uint256 nextPrice = calculateNextPrice(sellingPrice);

         
        landmarkToPrice[_tokenId] = nextPrice;

         
        landmarkToMaxPrice[_tokenId] = nextPrice;

         
        _transfer(oldOwner, msg.sender, _tokenId);

         
        if (excess > 0) {
            msg.sender.transfer(excess);
        }

         
        transactions++;

         
        LandmarkSold(_tokenId, sellingPrice, nextPrice, oldOwner, msg.sender);
    }


     
    function changePrice(uint256 _tokenId, uint256 _price) public {
         
        require(landmarkToOwner[_tokenId] == msg.sender);

         
        require(landmarkToMaxPrice[_tokenId] >= _price);

         
        landmarkToPrice[_tokenId] = _price;
        
         
        PriceChanged(_tokenId, _price);
    }

    function createLandmark(uint256 _tokenId, uint256 _groupId, address _owner, uint256 _price) public onlyCOO {
         
        if (_price <= 0 && _tokenId >= 1000) {
            _price = startingPrice;
        } else if (_price <= 0 && _tokenId < 1000) {
            _price = ambassadorStartingPrice;
        }
        if (_owner == address(0)) {
            _owner = coo;
        }

        if (_tokenId < 1000) {
            _groupId == _tokenId;
        }

        landmarkToPrice[_tokenId] = _price;
        landmarkToMaxPrice[_tokenId] = _price;
        landmarkToAmbassador[_tokenId] = _groupId;
        groupLandmarksCount[_groupId]++;
        _transfer(address(0), _owner, _tokenId);

        landmarks.push(_tokenId);

        LandmarkCreated(_tokenId, _groupId, _price, _owner);
    }

    function getLandmark(uint256 _tokenId) public view returns (
        uint256 ambassadorId,
        uint256 sellingPrice,
        uint256 maxPrice,
        uint256 nextPrice,
        address owner
    ) {
        ambassadorId = landmarkToAmbassador[_tokenId];
        sellingPrice = landmarkToPrice[_tokenId];
        maxPrice = landmarkToMaxPrice[_tokenId];
        nextPrice = calculateNextPrice(sellingPrice);
        owner = landmarkToOwner[_tokenId];
    }

    function priceOfLandmark(uint256 _tokenId) public view returns (uint256) {
        return landmarkToPrice[_tokenId];
    }


    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }
    modifier onlyCOO() {
        require(msg.sender == coo);
        _;
    }
    modifier onlyCLevel() {
        require(
            msg.sender == ceo ||
            msg.sender == coo
        );
        _;
    }
    modifier notCLevel() {
        require(
            msg.sender != ceo ||
            msg.sender != coo
        );
        _;
    }

     
    function withdrawBalance() external notCLevel {
         
        require(landmarkOwnershipCount[msg.sender] >= 3);
        
         
        require(withdrawCooldown[msg.sender] <= now);

         
        require(transactions >= 10);

        uint256 balance = this.balance;

         
        require(balance >= 0.3 ether);

        uint256 senderCut = balance.mul(3).div(1000).mul(landmarkOwnershipCount[msg.sender]);
        
         
        msg.sender.transfer(senderCut);

         
        withdrawCooldown[msg.sender] = now + 1 weeks;

         
        ceo.transfer(balance.sub(senderCut));

         
        transactions = 0;

    }

    function transferOwnership(address newOwner) public onlyCEO {
        if (newOwner != address(0)) {
            ceo = newOwner;
        }
    }

    function setCOO(address newCOO) public onlyCOO {
        if (newCOO != address(0)) {
            coo = newCOO;
        }
    }

    function _transfer(address _from, address _to, uint256 _tokenId) private {
        landmarkOwnershipCount[_to]++;
        landmarkToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            landmarkOwnershipCount[_from]--;
            delete landmarkToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

     
    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return landmarks.length;
    }

    function name() public pure returns (string) {
        return NAME;
    }

    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return landmarkOwnershipCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = landmarkToOwner[_tokenId];
        require(owner != address(0));
    }
    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(landmarkToOwner[_tokenId] == msg.sender);

        _transfer(msg.sender, _to, _tokenId);
    }
    function approve(address _to, uint256 _tokenId) public {
        require(landmarkToOwner[_tokenId] == msg.sender);
        landmarkToApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(landmarkToApproved[_tokenId] == _to);
        require(_to != address(0));
        require(landmarkToOwner[_tokenId] == _from);

        _transfer(_from, _to, _tokenId);
    }

    function tokensOfOwner(address _owner) public view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount);
        uint256 total = totalSupply();
        uint256 resultIndex = 0;

        for(uint256 i = 0; i <= total; i++) {
            if (landmarkToOwner[i] == _owner) {
                result[resultIndex] = i;
                resultIndex++;
            }
        }
        return result;
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