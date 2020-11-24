 

 
 


 

pragma solidity ^0.4.15;

 
contract ERC20 {
    function totalSupply() constant returns (uint256 currentSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

 
contract SafeMath {

  function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
  }

  function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
  }

  function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0) || (z / x == y));
      return z;
  }
}

contract Klein is ERC20, owned, SafeMath {
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => mapping (address => mapping (uint256 => bool))) specificAllowed;
    
                                                                     
    string public constant zonesSwarmAddress = "0a52f265d8d60a89de41a65069fa472ac3b130c269b4788811220b6546784920";
    address public constant theRiver = 0x8aDE9bCdA847852DE70badA69BBc9358C1c7B747;                       
    string public constant name = "Digital Zone of Immaterial Pictorial Sensibility";
    string public constant symbol = "IKB";
    uint256 public constant decimals = 0;
    uint256 public maxSupplyPossible;
    uint256 public initialPrice = 10**17;                               
    uint256 public currentSeries;    
    uint256 public issuedToDate;
    uint256 public totalSold;
    uint256 public burnedToDate;
    bool first = true;
                                                                     
                                                                     
    struct IKBSeries {
        uint256 price;
        uint256 seriesSupply;
    }

    IKBSeries[8] public series;                                      

    struct record {
        address addr;
        uint256 price;
        bool burned;
    }

    record[101] public records;                                      
    
    event UpdateRecord(uint indexed IKBedition, address holderAddress, uint256 price, bool burned);
    event SeriesCreated(uint indexed seriesNum);
    event SpecificApproval(address indexed owner, address indexed spender, uint256 indexed edition);
    
    function Klein() {
        currentSeries = 0;
        series[0] = IKBSeries(initialPrice, 31);                     
    
        for(uint256 i = 1; i < series.length; i++){                     
            series[i] = IKBSeries(series[i-1].price*2, 10);
        }     
        
        maxSupplyPossible = 101;
    }
    
    function() payable {
        buy();
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function specificApprove(address _spender, uint256 _edition) returns (bool success) {
        specificAllowed[msg.sender][_spender][_edition] = true;
        SpecificApproval(msg.sender, _spender, _edition);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

     
    function totalSupply() constant returns (uint _currentSupply) {
      return (issuedToDate - burnedToDate);
    }

    function issueNewSeries() onlyOwner returns (bool success){
        require(balances[this] <= 0);                             
        require(currentSeries < 7);
        
        if(!first){
            currentSeries++;                                         
        } else if (first){
            first=false;                                             
        } 
         
        balances[this] = safeAdd(balances[this], series[currentSeries].seriesSupply);
        issuedToDate = safeAdd(issuedToDate, series[currentSeries].seriesSupply);
        SeriesCreated(currentSeries);
        return true;
    }
    
    function buy() payable returns (bool success){
        require(balances[this] > 0);
        require(msg.value >= series[currentSeries].price);
        uint256 amount = msg.value / series[currentSeries].price;       
        uint256 receivable = msg.value;
        if (balances[this] < amount) {                               
            receivable = safeMult(balances[this], series[currentSeries].price);
            uint256 returnable = safeSubtract(msg.value, receivable);
            amount = balances[this];
            msg.sender.transfer(returnable);             
        }
        
        if (receivable % series[currentSeries].price > 0) assert(returnChange(receivable));
        
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);                              
        balances[this] = safeSubtract(balances[this], amount);       
        Transfer(this, msg.sender, amount);                          

        for(uint k = 0; k < amount; k++){                            
            records[totalSold] = record(msg.sender, series[currentSeries].price, false);
            totalSold++;
        }
        
        return true;                                    
    }

    function returnChange(uint256 _receivable) internal returns (bool success){
        uint256 change = _receivable % series[currentSeries].price;
        msg.sender.transfer(change);
        return true;
    }
                                                                     
    function transfer(address _to, uint _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(_value > 0); 
        uint256 recordsChanged = 0;

        for(uint k = 0; k < records.length; k++){                  
            if(records[k].addr == msg.sender && recordsChanged < _value) {
                records[k].addr = _to;                             
                recordsChanged++;                                  
                UpdateRecord(k, _to, records[k].price, records[k].burned);
            }
        }

        balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value); 
        require(allowed[_from][msg.sender] >= _value); 
        require(_value > 0);
        uint256 recordsChanged = 0;
        
        for(uint256 k = 0; k < records.length; k++){                  
            if(records[k].addr == _from && recordsChanged < _value) {
                records[k].addr = _to;                             
                recordsChanged++;                                  
                UpdateRecord(k, _to, records[k].price, records[k].burned);
            }
        }
        
        balances[_from] = safeSubtract(balances[_from], _value);
        allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value); 
        Transfer(_from, _to, _value);
        return true;     
    }   
                                                                     
    function specificTransfer(address _to, uint _edition) returns (bool success) {
        require(balances[msg.sender] > 0);
        require(records[_edition].addr == msg.sender); 
        balances[msg.sender] = safeSubtract(balances[msg.sender], 1);
        balances[_to] = safeAdd(balances[_to], 1);
        records[_edition].addr = _to;                            
        
        Transfer(msg.sender, _to, 1);
        UpdateRecord(_edition, _to, records[_edition].price, records[_edition].burned);
        return true;
    }
    
    function specificTransferFrom(address _from, address _to, uint _edition) returns (bool success){
        require(balances[_from] > 0);
        require(records[_edition].addr == _from);
        require(specificAllowed[_from][msg.sender][_edition]);
        balances[_from] = safeSubtract(balances[_from], 1);
        balances[_to] = safeAdd(balances[_to], 1);
        specificAllowed[_from][msg.sender][_edition] = false;
        records[_edition].addr = _to;                            
        
        Transfer(msg.sender, _to, 1);
        UpdateRecord(_edition, _to, records[_edition].price, records[_edition].burned);
        return true;
    }
                                                                     
    function getTokenHolder(uint searchedRecord) public constant returns(address){
        return records[searchedRecord].addr;
    }
    
    function getHolderEditions(address _holder) public constant returns (uint256[] _editions) {
        uint256[] memory editionsOwned = new uint256[](balances[_holder]);
        uint256 index;
        for(uint256 k = 0; k < records.length; k++) {
            if(records[k].addr == _holder) {
                editionsOwned[index] = k;
                index++;
            }
        }
        return editionsOwned;
    }
                                                                     
    function redeemEther() onlyOwner returns (bool success) {
        owner.transfer(this.balance);  
        return true;
    }
                                                                     
    function fund() payable onlyOwner returns (bool success) {
        return true;
    }
    
    function ritual(uint256 _edition) returns (bool success){
        require(records[_edition].addr == msg.sender); 
        require(!records[_edition].burned);
        uint256 halfTheGold = records[_edition].price / 2;
        require(this.balance >= halfTheGold);
        
        records[_edition].addr = 0xdead;
        records[_edition].burned = true;
        burnedToDate++;
        balances[msg.sender] = safeSubtract(balances[msg.sender], 1);
        theRiver.transfer(halfTheGold);                              
        return true;
    }
}