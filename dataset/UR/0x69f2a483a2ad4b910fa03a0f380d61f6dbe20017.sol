 

 

 
 

pragma solidity ^0.4.4;  

contract CoiniaVy {
    struct Shareholder {
        string name;  
        string id;  
        uint shares;  
        bool limited;  
    }
    
    string public standard = 'Token 0.1';
    address[] public projectManagers;  
    address[] public treasuryManagers;  
    uint public totalSupply = 10000;  
    string public home = "PL 18, 30101 Forssa, FINLAND";
    string public industry = "64190 Muu pankkitoiminta / Financial service nec";
    mapping (address => Shareholder) public shareholders;
    
     
    string public name = "Coinia Vy";
    string public symbol = "CIA";
    uint8 public decimals = 0;
    
     
    event Transfer (address indexed from, address indexed to, uint shares);
    event ChangedName (address indexed who, string to);
    event ChangedId (address indexed who, string to);
    event Resigned (address indexed who);
    event SetLimited (address indexed who, bool limited);
    event SetIndustry (string indexed newIndustry);
    event SetHome (string indexed newHome);
    event SetName (string indexed newName);
    event AddedManager (address indexed manager);
    
     
    modifier ifAuthorised {
        if (shareholders[msg.sender].shares == 0)
            throw;

        _;
    }
    
     
    modifier ifGeneralPartner {
        if (shareholders[msg.sender].limited == true)
            throw;

        _;
    }
    
     
    function CoiniaVy () {
        shareholders[this] = Shareholder (name, "2755797-6", 0, false);
        shareholders[msg.sender] = Shareholder ("Coinia OÜ", "14111022", totalSupply, false);
    }
    
     
     
    function balanceOf(address target) constant returns(uint256 balance) {
        return shareholders[target].shares;
    }
    
     
     
     
     
    function transfer (address target, uint256 amount) ifAuthorised {
        if (amount == 0 || shareholders[msg.sender].shares < amount)
            throw;
        
        shareholders[msg.sender].shares -= amount;
        if (shareholders[target].shares > 0) {
            shareholders[target].shares += amount;
        } else {
            shareholders[target].shares = amount;
            shareholders[target].limited = true;
        }
        
        Transfer (msg.sender, target, amount);
    }
    
     
     
    function changeName (string newName) ifAuthorised {
        shareholders[msg.sender].name = newName;
        
        ChangedName (msg.sender, newName);
    }
    
     
     
    function changeId (string newId) ifAuthorised {
        shareholders[msg.sender].id = newId;
        
        ChangedId (msg.sender, newId);
    }
    
     
     
    function resign () {
        if (bytes(shareholders[msg.sender].name).length == 0 || shareholders[msg.sender].shares > 0)
            throw;
            
        shareholders[msg.sender].name = "Resigned member";
        shareholders[msg.sender].id = "Resigned member";
        
        Resigned (msg.sender);
    }
    
     
     
     
     
    function setLimited (address target, bool isLimited) ifAuthorised ifGeneralPartner {
        shareholders[target].limited = isLimited;
        
        SetLimited (target, isLimited);
    }
    
     
     
    function setIndustry (string newIndustry) ifAuthorised ifGeneralPartner {
        industry = newIndustry;
        
        SetIndustry (newIndustry);
    }
    
     
     
    function setHome (string newHome) ifAuthorised ifGeneralPartner {
        home = newHome;
        
        SetHome (newHome);
    }
    
     
     
    function setName (string newName) ifAuthorised ifGeneralPartner {
        shareholders[this].name = newName;
        name = newName;
        
        SetName (newName);
    }
    
     
     
    function addTreasuryManager (address newManager) ifAuthorised ifGeneralPartner {
        treasuryManagers.push (newManager);
        
        AddedManager (newManager);
    }
    
     
     
    function addProjectManager (address newManager) ifAuthorised ifGeneralPartner {
        projectManagers.push (newManager);
        
        AddedManager (newManager);
    }
    
     
    function () {
        throw;
    }
}