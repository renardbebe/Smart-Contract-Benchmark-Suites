 

pragma solidity ^0.4.16;

contract BachelorBucks {
    string public standard = 'BBUCK 1.0';
    string public name = 'BachelorBucks';
    string public symbol = 'BBUCK';
    uint8 public decimals = 0;
    uint256 public totalSupply = 1000000000;
    uint256 public initialPrice = 1 ether / 1000;
    uint256 public priceIncreasePerPurchase = 1 ether / 100000;
    uint256 public currentPrice = initialPrice;
    
    address public owner = msg.sender;
    uint256 public creationTime = now;
    
    struct Component {
        string name;
        uint16 index;
        int256 currentSupport;
        uint256 supported;
        uint256 undermined;
    }
    
    struct AddOn {
        string name;
        uint16 index;
        uint256 support;
        uint256 threshold;
        bool completed;
        address winner;
    }
    
    struct Wildcard {
        string name;
        uint16 index;
        uint256 cost;
        uint16 available;
    }
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    uint16 public componentCount = 0;
    mapping (uint16 => Component) public components;
    
    uint16 public addOnCount = 0;
    mapping (uint16 => AddOn) public addOns;
    
    uint16 public wildcardCount = 0;
    mapping (uint16 => Wildcard) public wildcards;
    mapping (address => mapping (uint16 => uint16)) public wildcardsHeld;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Purchase(address indexed from, uint256 value);

     
    event SupportComponent(uint256 componentIdx, address indexed from, uint256 value);
    
     
    event UndermineComponent(uint256 componentIdx, address indexed from, uint256 value);
    
     
    event SupportAddOn(uint256 addOnIdx, address indexed from, uint256 value);
    
     
    event CompleteAddOn(uint256 addOnIdx, address indexed winner);

     
    event CompleteWildcard(uint256 wildcardIdx, address indexed caller);

    modifier onlyByOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier neverByOwner() {
        require(msg.sender != owner);
        _;
    }
    
     
    function BachelorBucks() public {
        balanceOf[msg.sender] = totalSupply;                     
    }
    
    function createComponent(string componentName) public onlyByOwner() returns (bool success) {
        if (componentCount > 65534) revert();
        var component = components[componentCount];
        component.name = componentName;
        component.index = componentCount;
        component.currentSupport = 0;
        component.supported = 0;
        component.undermined = 0;
        componentCount += 1;
        return true;
    }
    
    function createAddOn(string addOnName, uint256 threshold) public onlyByOwner() returns (bool success) {
        if (addOnCount > 65534) revert();
        if (threshold == 0) revert();
        var addOn = addOns[addOnCount];
        addOn.name = addOnName;
        addOn.index = addOnCount;
        addOn.support = 0;
        addOn.threshold = threshold;
        addOn.completed = false;
        addOn.winner = address(0x0);
        addOnCount += 1;
        return true;
    }
    
    function createWildcard(string wildcardName, uint256 cost, uint16 number) public onlyByOwner() returns (bool success) {
        if (wildcardCount > 65534) revert();
        if (number == 0) revert();
        if (cost == 0) revert();
        var wildcard = wildcards[wildcardCount];
        wildcard.name = wildcardName;
        wildcard.index = wildcardCount;
        wildcard.available = number;
        wildcard.cost = cost;
        wildcardCount += 1;
        return true;
    }
    
    function giveMeSomeBBUCKs() public payable returns (bool success) {
        if (msg.value < currentPrice) revert();
        uint256 amount = (msg.value / currentPrice);
        if (balanceOf[owner] < amount) revert();
        balanceOf[owner] -= amount;
        balanceOf[msg.sender] += amount;
        if ((currentPrice + priceIncreasePerPurchase) < currentPrice) return true;  
        currentPrice += priceIncreasePerPurchase;
        return true;
    }
    
    function() public payable { }                                
    
    function getBalance() view public returns (uint256) {
        return balanceOf[msg.sender];
    }
    
    function sweepToOwner() public onlyByOwner() returns (bool success) {
        owner.transfer(this.balance);
        return true;
    }
    
     
    function transfer(address _to, uint256 _value) public {
        if (_to == 0x0) revert();                                
        if (balanceOf[msg.sender] < _value) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        balanceOf[msg.sender] -= _value;                         
        balanceOf[_to] += _value;                                
        Transfer(msg.sender, _to, _value);                       
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if ((_value != 0) && (allowance[msg.sender][_spender] != 0)) revert();
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == 0x0) revert();                                 
        if (balanceOf[_from] < _value) revert();                  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        if (_value > allowance[_from][msg.sender]) revert();      
        balanceOf[_from] -= _value;                               
        balanceOf[_to] += _value;                                 
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

	 
    function supportComponent(uint16 component_idx, uint256 value) public neverByOwner() returns (bool success) {
        if (value == 0) revert();                                        
        if (balanceOf[msg.sender] < value) revert();                     
        if (component_idx >= componentCount) revert();                   
        var component = components[component_idx];
        if ((component.supported + value) < component.supported) revert();                     
        if ((component.currentSupport + int256(value)) < component.currentSupport) revert();   
        balanceOf[msg.sender] -= value;                                  
        component.currentSupport += int256(value);                       
        component.supported += value;
        totalSupply -= value;                                            
        SupportComponent(component_idx, msg.sender, value);
        return true;
    }
    
   
    function undermineComponent(uint16 component_idx, uint256 value) public neverByOwner() returns (bool success) {
        if (value == 0) revert();                                        
        if (balanceOf[msg.sender] < value) revert();                     
        if (component_idx >= componentCount) revert();                   
        var component = components[component_idx];
        if ((component.currentSupport - int256(value)) > component.currentSupport) revert();   
        balanceOf[msg.sender] -= value;                                  
        component.currentSupport -= int256(value);                       
        component.undermined += value;
        totalSupply -= value;                                            
        UndermineComponent(component_idx, msg.sender, value);
        return true;
    }

	 
    function getComponentSupport(uint16 component_idx) view public returns (int256) {
        if (component_idx >= componentCount) return 0;
        return components[component_idx].currentSupport;
    }
    
     
    function supportAddOn(uint16 addOn_idx, uint256 value) public neverByOwner() returns (bool success) {
        if (value == 0) revert();                                        
        if (balanceOf[msg.sender] < value) revert();                     
        if (addOn_idx >= addOnCount) revert();                           
        var addOn = addOns[addOn_idx];
        if (addOn.completed) revert();
        if ((addOn.support + value) < addOn.support) revert();           
        balanceOf[msg.sender] -= value;                                  
        addOn.support += value;                                          
        totalSupply -= value;                                            
        SupportAddOn(addOn_idx, msg.sender, value);
        if (addOn.support < addOn.threshold) return true;               
        addOn.completed = true;
        addOn.winner = msg.sender;
        CompleteAddOn(addOn_idx, addOn.winner);
        return true;
    }
    
     
    function getAddOnSupport(uint16 addOn_idx) view public returns (uint256) {
        if (addOn_idx >= addOnCount) return 0;
        return addOns[addOn_idx].support;
    }
    
     
    function getAddOnNeeded(uint16 addOn_idx) view public returns (uint256) {
        if (addOn_idx >= addOnCount) return 0;
        var addOn = addOns[addOn_idx];
        if (addOn.completed) return 0;
        return addOn.threshold - addOn.support;
    }
    
     
    function getAddOnComplete(uint16 addOn_idx) view public returns (bool) {
        if (addOn_idx >= addOnCount) return false;
        return addOns[addOn_idx].completed;
    }
    
     
    function acquireWildcard(uint16 wildcard_idx) public neverByOwner() returns (bool success) {
        if (wildcard_idx >= wildcardCount) revert();                     
        var wildcard = wildcards[wildcard_idx];
        if (balanceOf[msg.sender] < wildcard.cost) revert();             
        if (wildcard.available < 1) revert();                            
        balanceOf[msg.sender] -= wildcard.cost;                          
        wildcard.available -= 1;                                         
        totalSupply -= wildcard.cost;                                    
        wildcardsHeld[msg.sender][wildcard_idx] += 1;
        CompleteWildcard(wildcard_idx, msg.sender);
        return true;
    }
    
     
    function getWildcardsRemaining(uint16 wildcard_idx) view public returns (uint16) {
        if (wildcard_idx >= wildcardCount) return 0;
        return wildcards[wildcard_idx].available;
    }
}