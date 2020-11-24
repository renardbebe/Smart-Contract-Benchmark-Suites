 

pragma solidity ^0.4.11;

contract boleno {
    string public constant name = "Boleno";                  
    string public constant symbol = "BLN";                   
    uint8 public constant decimals = 18;                     
    uint256 public totalSupply = 10**25;                     
    address public supplier;                                 
    uint public blnpereth = 50;                              
    uint public bounty = 15;                                 
    bool public sale = false;                                
    bool public referral = false;                            

     
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    mapping (address => uint256) public balances;            
    mapping(address => mapping (address => uint256)) allowed; 

     
    function boleno() {
      supplier = msg.sender;                                 
      balances[supplier] = totalSupply;                      
    }

     
    modifier onlySupplier {
      if (msg.sender != supplier) throw;
      _;
    }

     
    function transfer(address _to, uint256 _value) returns (bool success) {
      if (now < 1502755200 && msg.sender != supplier) throw; 
      if (balances[msg.sender] < _value) throw;             
      if (balances[_to] + _value < balances[_to]) throw;    
      balances[msg.sender] -= _value;                       
      balances[_to] += _value;                              
      Transfer(msg.sender, _to, _value);                    
      return true;                                          
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (now < 1502755200 && _from != supplier) throw;      
      if (balances[_from] < _value) throw;                   
      if(allowed[_from][msg.sender] < _value) throw;         
      if (balances[_to] + _value < balances[_to]) throw;     
      balances[_from] -= _value;                             
      allowed[_from][msg.sender] -= _value;                  
      balances[_to] += _value;                               
      Transfer(_from, _to, _value);                          
      return true;                                           
     }

      
      
      
     function approve(address _spender, uint256 _value) returns (bool success) {
       allowed[msg.sender][_spender] = _value;              
       Approval(msg.sender, _spender, _value);              
       return true;                                         
     }

      
     function allowance(address _owner, address _spender) returns (uint256 bolenos) {
       return allowed[_owner][_spender];                    
     }

     
    function balanceOf(address _owner) returns (uint256 bolenos){
      return balances[_owner];
    }

     

     
    function referral(address referrer) payable {
      if(sale != true) throw;                                
      if(referral != true) throw;                            
      if(balances[referrer] < 100**18) throw;                
      uint256 bolenos = msg.value * blnpereth;               
       
      uint256 purchaserBounty = (bolenos / 100) * (100 + bounty); 
      if(balances[supplier] < purchaserBounty) throw;        
      if (balances[msg.sender] + purchaserBounty < balances[msg.sender]) throw;  
      balances[supplier] -= purchaserBounty;                 
      balances[msg.sender] += purchaserBounty;               
      Transfer(supplier, msg.sender, purchaserBounty);       
       
      uint256 referrerBounty = (bolenos / 100) * bounty;     
      if(balances[supplier] < referrerBounty) throw;         
      if (balances[referrer] + referrerBounty < balances[referrer]) throw;  
      balances[supplier] -= referrerBounty;                  
      balances[referrer] += referrerBounty;                  
      Transfer(supplier, referrer, referrerBounty);          
    }

     
    function setbounty(uint256 newBounty) onlySupplier {
      bounty = newBounty;
    }

     
    function setblnpereth(uint256 newRate) onlySupplier {
      blnpereth = newRate;
    }

     
    function triggerSale(bool newSale) onlySupplier {
      sale = newSale;
    }

     
    function transferSupply(address newSupplier) onlySupplier {
      if (balances[newSupplier] + balances[supplier] < balances[newSupplier]) throw; 
      uint256 supplyValue = balances[supplier];              
      balances[newSupplier] += supplyValue;                  
      balances[supplier] -= supplyValue;                     
      Transfer(supplier, newSupplier, supplyValue);          
      supplier = newSupplier;                                
    }

     
    function claimSale(){
      address dao = 0x400Be625f1308a56C19C38b1A21A50FCE8c62617; 
      dao.transfer(this.balance);                            
    }

     
    function () payable {
      if(sale != true) throw;                                
      uint256 bolenos = msg.value * blnpereth;               
      if(balances[supplier] < bolenos) throw;                
      if (balances[msg.sender] + bolenos < balances[msg.sender]) throw;  
      balances[supplier] -= bolenos;                         
      balances[msg.sender] += bolenos;                       
      Transfer(supplier, msg.sender, bolenos);               
    }
}