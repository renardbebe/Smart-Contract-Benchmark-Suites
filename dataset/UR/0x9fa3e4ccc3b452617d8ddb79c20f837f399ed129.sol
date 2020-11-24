 

pragma solidity ^0.4.23;

 
contract Ownable {
    address public owner;
    address public cfoAddress;

    constructor() public{
        owner = msg.sender;
        cfoAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function setCFO(address newCFO) external onlyOwner {
        require(newCFO != address(0));

        cfoAddress = newCFO;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }


     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

 
contract ParentInterface {
    function transfer(address _to, uint256 _tokenId) external;
    function recommendedPrice(uint16 quality) public pure returns(uint256 price);
    function getPet(uint256 _id) external view returns (uint64 birthTime, uint256 genes,uint64 breedTimeout,uint16 quality,address owner);
}
contract JackpotInterface {
    function addPlayer(address player) external;
    function finished() public returns (bool);
}

contract AccessControl is Pausable {
    ParentInterface public parent;
    JackpotInterface public jackpot;
    
    function setParentAddress(address _address) public whenPaused onlyOwner
    {
        parent = ParentInterface(_address);
    }
    
    function setJackpotAddress(address _address) public whenPaused onlyOwner
    {
        jackpot = JackpotInterface(_address);
    }
}

 
contract Discount is AccessControl {
    uint128[101] public discount;
    
    function setPrice(uint8 _tokenId, uint128 _price) external onlyOwner {
        discount[_tokenId] = _price;
    }
}

contract StoreLimit is AccessControl {
	uint8 public saleLimit = 10;
	
	function setSaleLimit(uint8 _limit) external onlyOwner {
		saleLimit = _limit;
	}
}

contract Store is Discount, StoreLimit {

    constructor(address _presaleAddr) public {
        parent = ParentInterface(_presaleAddr);
        paused = true;
    }
    
	 
    function purchaseParrot(uint256 _tokenId) external payable whenNotPaused
    {
		require(_tokenId <= saleLimit);
		
        uint64 birthTime; uint256 genes; uint64 breedTimeout; uint16 quality; address parrot_owner;
        (birthTime,  genes, breedTimeout, quality, parrot_owner) = parent.getPet(_tokenId);
        
        require(parrot_owner == address(this));
        
        if(discount[_tokenId] == 0)
            require(parent.recommendedPrice(quality) <= msg.value);
        else
            require(discount[_tokenId] <= msg.value);
        
        parent.transfer(msg.sender, _tokenId);
        
        if(!jackpot.finished()) {
            jackpot.addPlayer(msg.sender);
            address(jackpot).transfer(msg.value / 2);
        }
    }
    
    function unpause() public onlyOwner whenPaused {
		require(address(jackpot) != address(0));

        super.unpause();
    }
    
    function gift(uint256 _tokenId, address to) external onlyOwner{
        parent.transfer(to, _tokenId);
    }

    function withdrawBalance(uint256 summ) external onlyCFO {
        cfoAddress.transfer(summ);
    }
}