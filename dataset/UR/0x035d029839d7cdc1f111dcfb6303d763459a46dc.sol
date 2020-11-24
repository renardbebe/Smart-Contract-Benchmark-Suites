 

pragma solidity ^0.4.18;

 
 
 

contract AccessControl {
       
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused = false;

     
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

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
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

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}

pragma solidity ^0.4.18;

contract EggFactory is AccessControl{
    
    event EggOpened(address eggOwner, uint256 eggId, uint256 amount);
    event EggBought(address eggOwner, uint256 eggId, uint256 amount);
    
     
     
    bool public isEggFactory = true;

    address public vaultAddress;

     
    struct EggScheme{
        uint256 id;
        uint256 stock;  
        uint256 purchased;  
        uint256 customGene;  
        uint256 maxAllowedToBuy;  
        
        uint256 increase;  
        uint256 price;  
        
        bool active;  
        bool open;  
        bool isEggScheme;
    }

     
     
    mapping (uint256 => EggScheme) public eggs;
    uint256[] public eggsIndexes;
    
    uint256[] public activeEggs;
    mapping (uint256 => uint256) indexesActiveEggs;

     
     
    mapping ( address => mapping ( uint256 => uint256 ) ) public eggsOwned;
    

     
    function EggFactory(address _vaultAddress) public {
        vaultAddress = _vaultAddress;
        ceoAddress = msg.sender;
    }

     
    function eggExists( uint _eggId) internal view returns(bool) {
        return eggs[_eggId].isEggScheme;
    }

    function listEggsIds() external view returns(uint256[]){
        return eggsIndexes;
    }
    
    function listActiveEggs() external view returns(uint256[]){
        return activeEggs;
    }

     
    function getPurchased(uint256 _eggId) external view returns(uint256){
        return eggs[_eggId].purchased;
    }

     
    function setVaultAddress(address _vaultAddress) public onlyCEO returns (bool) {
        require( _vaultAddress != address(0x0) );
        vaultAddress = _vaultAddress;
    }
    
    function setActiveStatusEgg( uint256 _eggId, bool state ) public onlyCEO returns (bool){
        require(eggExists(_eggId));
        eggs[_eggId].active = state;

        if(state) {
            uint newIndex = activeEggs.push(_eggId);
            indexesActiveEggs[_eggId] = uint256(newIndex-1);
        }
        else {
            indexesActiveEggs[activeEggs[activeEggs.length-1]] = indexesActiveEggs[_eggId];
            activeEggs[indexesActiveEggs[_eggId]] = activeEggs[activeEggs.length-1]; 
            delete activeEggs[activeEggs.length-1];
            activeEggs.length--;
        }
        
        return true;
    }
    
    function setOpenStatusEgg( uint256 _eggId, bool state ) public onlyCEO returns (bool){
        require(eggExists(_eggId));
        eggs[_eggId].open = state;
        return true;
    }

     
    function createEggScheme( uint256 _eggId, uint256 _stock, uint256 _maxAllowedToBuy, uint256 _customGene, uint256 _price, uint256 _increase, bool _active, bool _open ) public onlyCEO returns (bool){
        require(!eggExists(_eggId));
        
        eggs[_eggId].isEggScheme = true;
        
        eggs[_eggId].id = _eggId;
        eggs[_eggId].stock = _stock;
        eggs[_eggId].maxAllowedToBuy = _maxAllowedToBuy;
        eggs[_eggId].purchased = 0;
        eggs[_eggId].customGene = _customGene;
        eggs[_eggId].price = _price;
        eggs[_eggId].increase = _increase;
        
        setActiveStatusEgg(_eggId,_active);
        setOpenStatusEgg(_eggId,_open);
        
        eggsIndexes.push(_eggId);
        return true;
    }

    function buyEgg(uint256 _eggId, uint256 _amount) public payable returns(bool){
        require(eggs[_eggId].active == true);
        require((currentEggPrice(_eggId)*_amount) == msg.value);
        require(eggs[_eggId].maxAllowedToBuy == 0 || _amount<=eggs[_eggId].maxAllowedToBuy);
        require(eggs[_eggId].stock == 0 || eggs[_eggId].purchased+_amount<=eggs[_eggId].stock);  
        
        vaultAddress.transfer(msg.value);  
        
        eggs[_eggId].purchased += _amount;
        eggsOwned[msg.sender][_eggId] += _amount;

        emit EggBought(msg.sender, _eggId, _amount);
    } 
    
    function currentEggPrice( uint256 _eggId ) public view returns (uint256) {
        return eggs[_eggId].price + (eggs[_eggId].purchased * eggs[_eggId].increase);
    }
    
    function openEgg(uint256 _eggId, uint256 _amount) external {
        require(eggs[_eggId].open == true);
        require(eggsOwned[msg.sender][_eggId] >= _amount);
        
        eggsOwned[msg.sender][_eggId] -= _amount;
        emit EggOpened(msg.sender, _eggId, _amount);
    }
}