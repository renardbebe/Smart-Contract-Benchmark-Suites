 

pragma solidity ^0.4.18;

contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Owned() public{
        owner = msg.sender;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


contract tokenRecipient { 
  function receiveApproval (address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) public constant  returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract OntologyNetworkContract is ERC20Token, Owned{

     
    string  public constant standard = "Ontology Network";
    string  public constant name = "Ontology Network";
    string  public constant symbol = "ONT";
    uint256 public constant decimals = 6;
    uint256 private constant etherChange = 10**18;
    
     
    uint256 public totalSupply;
    uint256 public totalRemainSupply;
    uint256 public ONTExchangeRate;
    bool    public crowdsaleIsOpen;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    address public multisigAddress;
     
    event mintToken(address indexed _to, uint256 _value);
    event burnToken(address indexed _from, uint256 _value);
    
    function () payable public {
        require (crowdsaleIsOpen == true);
        require(msg.value != 0);
        mintONTToken(msg.sender, (msg.value * ONTExchangeRate * 10**decimals) / etherChange);
    }
     
    function OntologyNetworkContract(uint256 _totalSupply, uint256 __ONTExchangeRate) public {
        owner = msg.sender;
        totalSupply = _totalSupply * 10**decimals;
        ONTExchangeRate = __ONTExchangeRate;
        totalRemainSupply = totalSupply;
        crowdsaleIsOpen = true;
    }
    
    function setONTExchangeRate(uint256 _ONTExchangeRate) public onlyOwner {
        ONTExchangeRate = _ONTExchangeRate;
    }
    
    function crowdsaleOpen(bool _crowdsaleIsOpen) public {
        crowdsaleIsOpen = _crowdsaleIsOpen;
    }
     
    function ONTTotalSupply() public constant returns (uint256)  {   
        return totalSupply - totalRemainSupply ;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (balances[msg.sender] > _value);             
        require (balances[_to] + _value > balances[_to]);    
        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                   
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;           
        Approval(msg.sender, _spender, _value);              
        return true;
    }

      
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {            
        tokenRecipient spender = tokenRecipient(_spender);               
        approve(_spender, _value);                                       
        spender.receiveApproval(msg.sender, _value, this, _extraData);   
        return true;     
    }     

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {      
        require (balances[_from] > _value);                 
        require (balances[_to] + _value > balances[_to]);   
        require (_value > allowances[_from][msg.sender]);   
        balances[_from] -= _value;                           
        balances[_to] += _value;                             
        allowances[_from][msg.sender] -= _value;             
        Transfer(_from, _to, _value);                        
        return true;     
    }         

          
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {         
        return allowances[_owner][_spender];
    }     
        
     
    function withdraw(address _multisigAddress) public onlyOwner {    
        require(_multisigAddress != 0x0);
        multisigAddress = _multisigAddress;
        multisigAddress.transfer(this.balance);
    }  
    
          
    function mintONTToken(address _to, uint256 _amount) internal { 
        require (balances[_to] + _amount > balances[_to]);       
        require (totalRemainSupply > _amount);
        totalRemainSupply -= _amount;                            
        balances[_to] += _amount;                                
        mintToken(_to, _amount);                                 
        Transfer(0x0, _to, _amount);                             
    }  
    
    function mintTokens(address _sendTo, uint256 _sendAmount)public onlyOwner {
        mintONTToken(_sendTo, _sendAmount);
    }
    
     
    function burnTokens(address _addr, uint256 _amount)public onlyOwner {
        require (balances[msg.sender] < _amount);                
        totalRemainSupply += _amount;                            
        balances[_addr] -= _amount;                              
        burnToken(_addr, _amount);                               
        Transfer(_addr, 0x0, _amount);                           
    }
}