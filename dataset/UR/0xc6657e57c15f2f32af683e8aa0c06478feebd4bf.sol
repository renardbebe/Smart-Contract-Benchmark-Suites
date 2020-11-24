 

 

pragma solidity ^0.4.18;





 
 
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
}





 
contract FoodStore is OwnerBase {
	 
	event Bought(address buyer, uint32 bundles);
	
	
    event ContractUpgrade(address newContract);

	
     
    address public newContractAddress;
    
     
    uint public price = 10 finney;    
    
    
    

     
    function FoodStore() public {
         
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
    }
    
        
     
     
    function buyFood(uint32 _bundles) external payable whenNotPaused returns (bool) {
		require(newContractAddress == address(0));
		
        uint cost = _bundles * price;
		require(msg.value >= cost);
		
         
        uint fundsExcess = msg.value - cost;
        if (fundsExcess > 1 finney) {
            msg.sender.transfer(fundsExcess);
        }
		emit Bought(msg.sender, _bundles);
        return true;
    }
    
    

     
     
    function upgradeContract(address _v2Address) external onlyCOO whenPaused {
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

     
    function withdrawBalance() external onlyCFO {
        address tmp = address(this);
        cfoAddress.transfer(tmp.balance);
    }
}