 

 

pragma solidity ^0.4.20;


 
contract ERC721 {
     
    function totalSupply() public view returns (uint total);
    function balanceOf(address _owner) public view returns (uint balance);
    function ownerOf(uint _tokenId) external view returns (address owner);
    function approve(address _to, uint _tokenId) external;
    function transfer(address _to, uint _tokenId) external;
    function transferFrom(address _from, address _to, uint _tokenId) external;

     
    event Transfer(address indexed from, address indexed to, uint tokenId);
    event Approval(address indexed owner, address indexed approved, uint tokenId);
    
}



 
 
contract OwnerBase {

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;
    
     
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCOO whenPaused {
         
        paused = false;
    }
	
	
	 
    function isNotContract(address addr) internal view returns (bool) {
        uint size = 0;
        assembly { 
		    size := extcodesize(addr) 
		} 
        return size == 0;
    }
}




 
contract FighterCamp {
    
     
    function isCamp() public pure returns (bool);
    
     
    function getFighter(uint _tokenId) external view returns (uint32);
    
}

 
 
 
contract RabbitBase is ERC721, OwnerBase, FighterCamp {

     
     
    event Birth(address owner, uint rabbitId, uint32 star, uint32 explosive, uint32 endurance, uint32 nimble, uint64 genes, uint8 isBox);

     
    struct RabbitData {
         
        uint64 genes;
         
        uint32 star;
         
        uint32 explosive;
         
        uint32 endurance;
         
        uint32 nimble;
         
        uint64 birthTime;
    }

     
     
    RabbitData[] rabbits;

     
    mapping (uint => address) rabbitToOwner;

     
     
    mapping (address => uint) howManyDoYouHave;

     
     
     
    mapping (uint => address) public rabbitToApproved;

	
	
     
    function _transItem(address _from, address _to, uint _tokenId) internal {
         
        howManyDoYouHave[_to]++;
         
        rabbitToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            howManyDoYouHave[_from]--;
        }
         
        delete rabbitToApproved[_tokenId];
        
         
		if (_tokenId > 0) {
			emit Transfer(_from, _to, _tokenId);
		}
    }

     
     
     
     
    function _createRabbit(
        uint _star,
        uint _explosive,
        uint _endurance,
        uint _nimble,
        uint _genes,
        address _owner,
		uint8 isBox
    )
        internal
        returns (uint)
    {
        require(_star >= 1 && _star <= 5);
		
		RabbitData memory _tmpRbt = RabbitData({
            genes: uint64(_genes),
            star: uint32(_star),
            explosive: uint32(_explosive),
            endurance: uint32(_endurance),
            nimble: uint32(_nimble),
            birthTime: uint64(now)
        });
        uint newRabbitID = rabbits.push(_tmpRbt) - 1;
        
        
         

         
        emit Birth(
            _owner,
            newRabbitID,
            _tmpRbt.star,
            _tmpRbt.explosive,
            _tmpRbt.endurance,
            _tmpRbt.nimble,
            _tmpRbt.genes,
			isBox
        );

         
         
        if (_owner != address(0)){
            _transItem(0, _owner, newRabbitID);
        } else {
            _transItem(0, ceoAddress, newRabbitID);
        }
        
        
        return newRabbitID;
    }
    
     
     
    function getRabbit(uint _tokenId) external view returns (
        uint32 outStar,
        uint32 outExplosive,
        uint32 outEndurance,
        uint32 outNimble,
        uint64 outGenes,
        uint64 outBirthTime
    ) {
        RabbitData storage rbt = rabbits[_tokenId];
        outStar = rbt.star;
        outExplosive = rbt.explosive;
        outEndurance = rbt.endurance;
        outNimble = rbt.nimble;
        outGenes = rbt.genes;
        outBirthTime = rbt.birthTime;
    }
	
	
    function isCamp() public pure returns (bool){
        return true;
    }
    
    
     
     
    function getFighter(uint _tokenId) external view returns (uint32) {
        RabbitData storage rbt = rabbits[_tokenId];
        uint32 strength = uint32(rbt.explosive + rbt.endurance + rbt.nimble); 
		return strength;
    }

}



 
 
 
 
contract RabbitOwnership is RabbitBase {

     
    string public name;
    string public symbol;
    
     
    function isERC721() public pure returns (bool) {
        return true;
    }

     
     
     

     
     
     
    function _owns(address _owner, uint _tokenId) internal view returns (bool) {
        return rabbitToOwner[_tokenId] == _owner;
    }

     
     
     
    function _approvedFor(address _claimant, uint _tokenId) internal view returns (bool) {
        return rabbitToApproved[_tokenId] == _claimant;
    }

     
     
     
     
     
    function _approve(uint _tokenId, address _to) internal {
        rabbitToApproved[_tokenId] = _to;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint count) {
        return howManyDoYouHave[_owner];
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
		
		 
		require(_to != address(this));
        
         
        require(_owns(msg.sender, _tokenId));
        
         
        _transItem(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {   
        require(_owns(msg.sender, _tokenId));     
        require(msg.sender != _to);      

         
        _approve(_tokenId, _to);

         
        emit Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
        
         
        require(_owns(_from, _tokenId));
        
         
        require(_approvedFor(msg.sender, _tokenId));
        
         
        _transItem(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return rabbits.length - 1;
    }

     
     
    function ownerOf(uint _tokenId)
        external
        view
        returns (address owner)
    {
        owner = rabbitToOwner[_tokenId];

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint[] ownerTokens) {
        uint tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint totalCats = totalSupply();
            uint resultIndex = 0;

             
             
            uint rabbitId;

            for (rabbitId = 1; rabbitId <= totalCats; rabbitId++) {
                if (rabbitToOwner[rabbitId] == _owner) {
                    result[resultIndex] = rabbitId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

}

 
contract RabbitMinting is RabbitOwnership {
    
     
    uint public priceStar5Now = 1 ether;
    
     
    uint public priceStar4 = 100 finney;
    
     
    uint public priceStar3 = 5 finney;    
    
    
    uint private priceStar5Min = 1 ether;
    uint private priceStar5Add = 2 finney;
    
     
    uint public priceBox1 = 10 finney;
    uint public box1Star5 = 50;
    uint public box1Star4 = 500;
	
	 
	uint public priceBox2 = 100 finney;
    uint public box2Star5 = 500;
	
    
    
     
    uint public constant LIMIT_STAR5 = 2000;
	
	 
    uint public constant LIMIT_STAR4 = 20000;
    
     
    uint public constant LIMIT_PROMO = 5000;
    
     
    uint public CREATED_STAR5;
	
	 
    uint public CREATED_STAR4;
    
     
    uint public CREATED_PROMO;
    
     
    uint private secretKey = 392828872;
    
     
    bool private box1OnSale = true;
	
	 
    bool private box2OnSale = true;
	
	 
	mapping(uint => uint8) usedSignId;
   
    
     
    function setBaseInfo(uint val, bool _onSale1, bool _onSale2) external onlyCOO {
        secretKey = val;
		box1OnSale = _onSale1;
        box2OnSale = _onSale2;
    }
    
     
    function createPromoRabbit(uint _star, address _owner) whenNotPaused external onlyCOO {
        require (_owner != address(0));
        require(CREATED_PROMO < LIMIT_PROMO);
       
        if (_star == 5){
            require(CREATED_STAR5 < LIMIT_STAR5);
        } else if (_star == 4){
            require(CREATED_STAR4 < LIMIT_STAR4);
        }
        CREATED_PROMO++;
        
        _createRabbitInGrade(_star, _owner, 0);
    }
    
    
    
     
    function _createRabbitInGrade(uint _star, address _owner, uint8 isBox) internal {
        uint _genes = uint(keccak256(uint(_owner) + secretKey + rabbits.length));
        uint _explosive = 50;
        uint _endurance = 50;
        uint _nimble = 50;
        
        if (_star < 5) {
            uint tmp = _genes; 
            tmp = uint(keccak256(tmp));
            _explosive =  1 + 10 * (_star - 1) + tmp % 10;
            tmp = uint(keccak256(tmp));
            _endurance = 1 + 10 * (_star - 1) + tmp % 10;
            tmp = uint(keccak256(tmp));
            _nimble = 1 + 10 * (_star - 1) + tmp % 10;
        } 
		
		uint64 _geneShort = uint64(_genes);
		if (_star == 5){
			CREATED_STAR5++;
			priceStar5Now = priceStar5Min + priceStar5Add * CREATED_STAR5;
			_geneShort = uint64(_geneShort - _geneShort % 2000 + CREATED_STAR5);
		} else if (_star == 4){
			CREATED_STAR4++;
		} 
		
        _createRabbit(
            _star, 
            _explosive, 
            _endurance, 
            _nimble, 
            _geneShort, 
            _owner,
			isBox);
    }
    
    
        
     
     
    function buyOneRabbit(uint _star) external payable whenNotPaused returns (bool) {
		require(isNotContract(msg.sender));
		
        uint tmpPrice = 0;
        if (_star == 5){
            tmpPrice = priceStar5Now;
			require(CREATED_STAR5 < LIMIT_STAR5);
        } else if (_star == 4){
            tmpPrice = priceStar4;
			require(CREATED_STAR4 < LIMIT_STAR4);
        } else if (_star == 3){
            tmpPrice = priceStar3;
        } else {
			revert();
		}
        
        require(msg.value >= tmpPrice);
        _createRabbitInGrade(_star, msg.sender, 0);
        
         
        uint fundsExcess = msg.value - tmpPrice;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
        return true;
    }
    
    
        
     
    function buyBox1() external payable whenNotPaused returns (bool) {
		require(isNotContract(msg.sender));
        require(box1OnSale);
        require(msg.value >= priceBox1);
		
        uint tempVal = uint(keccak256(uint(msg.sender) + secretKey + rabbits.length));
        tempVal = tempVal % 10000;
        uint _star = 3;  
        if (tempVal <= box1Star5){
            _star = 5;
			require(CREATED_STAR5 < LIMIT_STAR5);
        } else if (tempVal <= box1Star5 + box1Star4){
            _star = 4;
			require(CREATED_STAR4 < LIMIT_STAR4);
        } 
        
        _createRabbitInGrade(_star, msg.sender, 2);
        
         
        uint fundsExcess = msg.value - priceBox1;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
        return true;
    }
	
	    
     
    function buyBox2() external payable whenNotPaused returns (bool) {
		require(isNotContract(msg.sender));
        require(box2OnSale);
        require(msg.value >= priceBox2);
		
        uint tempVal = uint(keccak256(uint(msg.sender) + secretKey + rabbits.length));
        tempVal = tempVal % 10000;
        uint _star = 4;  
        if (tempVal <= box2Star5){
            _star = 5;
			require(CREATED_STAR5 < LIMIT_STAR5);
        } else {
			require(CREATED_STAR4 < LIMIT_STAR4);
		}
        
        _createRabbitInGrade(_star, msg.sender, 3);
        
         
        uint fundsExcess = msg.value - priceBox2;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
        return true;
    }
	
}





 
contract RabbitAuction is RabbitMinting {
    
     
    event AuctionCreated(uint tokenId, uint startingPrice, uint endingPrice, uint duration, uint startTime, uint32 explosive, uint32 endurance, uint32 nimble, uint32 star);
    event AuctionSuccessful(uint tokenId, uint totalPrice, address winner);
    event AuctionCancelled(uint tokenId);
	event UpdateComplete(address account, uint tokenId);
    
     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
        uint64 startedAt;
    }

     
     
    uint public masterCut = 200;

     
    mapping (uint => Auction) tokenIdToAuction;
    
    
     
     
     
     
     
     
    function createAuction(
        uint _tokenId,
        uint _startingPrice,
        uint _endingPrice,
        uint _duration
    )
        external whenNotPaused
    {
		require(isNotContract(msg.sender));
        require(_endingPrice >= 1 finney);
        require(_startingPrice >= _endingPrice);
        require(_duration <= 100 days); 
        require(_owns(msg.sender, _tokenId));
        
		 
        _transItem(msg.sender, this, _tokenId);
        
        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }
    
    
     
     
    function getAuctionData(uint _tokenId) external view returns (
        address seller,
        uint startingPrice,
        uint endingPrice,
        uint duration,
        uint startedAt,
        uint currentPrice
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.startedAt > 0);
        seller = auction.seller;
        startingPrice = auction.startingPrice;
        endingPrice = auction.endingPrice;
        duration = auction.duration;
        startedAt = auction.startedAt;
        currentPrice = _calcCurrentPrice(auction);
    }

     
     
     
    function bid(uint _tokenId) external payable whenNotPaused {
		require(isNotContract(msg.sender));
		
         
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.startedAt > 0);

         
        uint price = _calcCurrentPrice(auction);
        require(msg.value >= price);

         
        address seller = auction.seller;
		
		 
		require(_owns(this, _tokenId));

         
         
        delete tokenIdToAuction[_tokenId];

        if (price > 0) {
             
            uint auctioneerCut = price * masterCut / 10000;
            uint sellerProceeds = price - auctioneerCut;
			require(sellerProceeds <= price);

             
            seller.transfer(sellerProceeds);
        }

         
        uint bidExcess = msg.value - price;

         
		if (bidExcess >= 1 finney) {
			msg.sender.transfer(bidExcess);
		}

         
        emit AuctionSuccessful(_tokenId, price, msg.sender);
        
         
        _transItem(this, msg.sender, _tokenId);
    }

     
     
     
     
     
    function cancelAuction(uint _tokenId) external whenNotPaused {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(auction.startedAt > 0);
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId);
    }

     
     
     
     
    function cancelAuctionByMaster(uint _tokenId)
        external onlyCOO whenPaused
    {
        _cancelAuction(_tokenId);
    }
	
    
     
     
     
    function _addAuction(uint _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;
        
        RabbitData storage rdata = rabbits[_tokenId];

        emit AuctionCreated(
            uint(_tokenId),
            uint(_auction.startingPrice),
            uint(_auction.endingPrice),
            uint(_auction.duration),
            uint(_auction.startedAt),
            uint32(rdata.explosive),
            uint32(rdata.endurance),
            uint32(rdata.nimble),
            uint32(rdata.star)
        );
    }

     
    function _cancelAuction(uint _tokenId) internal {
	    Auction storage auction = tokenIdToAuction[_tokenId];
		_transItem(this, auction.seller, _tokenId);
        delete tokenIdToAuction[_tokenId];
        emit AuctionCancelled(_tokenId);
    }

     
    function _calcCurrentPrice(Auction storage _auction)
        internal
        view
        returns (uint outPrice)
    {
        int256 duration = _auction.duration;
        int256 price0 = _auction.startingPrice;
        int256 price2 = _auction.endingPrice;
        require(duration > 0);
        
        int256 secondsPassed = int256(now) - int256(_auction.startedAt);
        require(secondsPassed >= 0);
        if (secondsPassed < _auction.duration) {
            int256 priceChanged = (price2 - price0) * secondsPassed / duration;
            int256 currentPrice = price0 + priceChanged;
            outPrice = uint(currentPrice);
        } else {
            outPrice = _auction.endingPrice;
        }
    }
    
	
	
	
	 
     
	 
	 
	function transferOnError(address _to, uint _tokenId) external onlyCOO {
		require(_owns(this, _tokenId));		
		Auction storage auction = tokenIdToAuction[_tokenId];
		require(auction.startedAt == 0);
		
		_transItem(this, _to, _tokenId);
	}
	
	
	 
	function getFreeRabbit(uint32 _star, uint _taskId, uint8 v, bytes32 r, bytes32 s) external {
		require(usedSignId[_taskId] == 0);
		uint[2] memory arr = [_star, _taskId];
		string memory text = uint2ToStr(arr);
		address signer = verify(text, v, r, s);
		require(signer == cooAddress);
		
		_createRabbitInGrade(_star, msg.sender, 4);
		usedSignId[_taskId] = 1;
	}
	
	
	 
	function setRabbitData(
		uint _tokenId, 
		uint32 _explosive, 
		uint32 _endurance, 
		uint32 _nimble,
		uint _taskId,
		uint8 v, 
		bytes32 r, 
		bytes32 s
	) external {
		require(usedSignId[_taskId] == 0);
		
		Auction storage auction = tokenIdToAuction[_tokenId];
		require (auction.startedAt == 0);
		
		uint[5] memory arr = [_tokenId, _explosive, _endurance, _nimble, _taskId];
		string memory text = uint5ToStr(arr);
		address signer = verify(text, v, r, s);
		require(signer == cooAddress);
		
		RabbitData storage rdata = rabbits[_tokenId];
		rdata.explosive = _explosive;
		rdata.endurance = _endurance;
		rdata.nimble = _nimble;
		rabbits[_tokenId] = rdata;		
		
		usedSignId[_taskId] = 1;
		emit UpdateComplete(msg.sender, _tokenId);
	}
	
	 
	function verify(string text, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {		
		bytes32 hash = keccak256(text);
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		bytes32 prefixedHash = keccak256(prefix, hash);
		address tmp = ecrecover(prefixedHash, v, r, s);
		return tmp;
	}
    
	 
    function uint2ToStr(uint[2] arr) internal pure returns (string){
    	uint length = 0;
    	uint i = 0;
    	uint val = 0;
    	for(; i < arr.length; i++){
    		val = arr[i];
    		while(val >= 10) {
    			length += 1;
    			val = val / 10;
    		}
    		length += 1; 
    		length += 1; 
    	}
    	length -= 1; 
    	
    	 
    	bytes memory bstr = new bytes(length);
        uint k = length - 1;
        int j = int(arr.length - 1);
    	while (j >= 0) {
    		val = arr[uint(j)];
    		if (val == 0) {
    			bstr[k] = byte(48);
    			if (k > 0) {
    			    k--;
    			}
    		} else {
    		    while (val != 0){
    				bstr[k] = byte(48 + val % 10);
    				val /= 10;
    				if (k > 0) {
        			    k--;
        			}
    			}
    		}
    		
    		if (j > 0) {  
				assert(k > 0);
    			bstr[k] = byte(44);
    			k--;
    		}
    		
    		j--;
    	}
    	
        return string(bstr);
    }
	
	 
    function uint5ToStr(uint[5] arr) internal pure returns (string){
    	uint length = 0;
    	uint i = 0;
    	uint val = 0;
    	for(; i < arr.length; i++){
    		val = arr[i];
    		while(val >= 10) {
    			length += 1;
    			val = val / 10;
    		}
    		length += 1; 
    		length += 1; 
    	}
    	length -= 1; 
    	
    	 
    	bytes memory bstr = new bytes(length);
        uint k = length - 1;
        int j = int(arr.length - 1);
    	while (j >= 0) {
    		val = arr[uint(j)];
    		if (val == 0) {
    			bstr[k] = byte(48);
    			if (k > 0) {
    			    k--;
    			}
    		} else {
    		    while (val != 0){
    				bstr[k] = byte(48 + val % 10);
    				val /= 10;
    				if (k > 0) {
        			    k--;
        			}
    			}
    		}
    		
    		if (j > 0) {  
				assert(k > 0);
    			bstr[k] = byte(44);
    			k--;
    		}
    		
    		j--;
    	}
    	
        return string(bstr);
    }

}


 
 
 
 
contract RabbitCore is RabbitAuction {
    
    event ContractUpgrade(address newContract);

     
    address public newContractAddress;

     
    function RabbitCore(string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
        
         
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        
         
        _createRabbit(5, 50, 50, 50, 1, msg.sender, 0);
    }
    

     
     
    function upgradeContract(address _v2Address) external onlyCOO whenPaused {
         
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }


     
     
     
     
     
    function unpause() public onlyCOO {
        require(newContractAddress == address(0));
        
         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        address tmp = address(this);
        cfoAddress.transfer(tmp.balance);
    }
}