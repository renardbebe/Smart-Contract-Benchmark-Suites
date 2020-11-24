 

pragma solidity ^0.4.18;

contract Owned {
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function Owned() public {
        owner = msg.sender;
    }
    
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}


contract tokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public ;
} 

contract ERC20Token {
     
     
    uint256 public totalSupply;

     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MayanProtocolContract is ERC20Token, Owned{

     
    string  public constant standard = "Mayan protocol V1.0";
    string  public constant name = "Mayan protocol";
    string  public constant symbol = "MAY";
    uint256 public constant decimals = 6;
    uint256 private constant etherChange = 10**18;
    
     
    uint256 public totalSupply;
    uint256 public totalRemainSupply;
    uint256 public MAYExchangeRate;
    bool    public crowdsaleIsOpen;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    address public multisigAddress;
     
    event mintToken(address indexed _to, uint256 _value);
    event burnToken(address indexed _from, uint256 _value);
    
    function () payable public {
        require (crowdsaleIsOpen == true);
        require(msg.value != 0);
        mintMAYToken(msg.sender, (msg.value * MAYExchangeRate * 10**decimals) / etherChange);
    }
     
    function MayanProtocolContract(uint256 _totalSupply, uint256 _MAYExchangeRate) public {
        owner = msg.sender;
        totalSupply = _totalSupply * 10**decimals;
        MAYExchangeRate = _MAYExchangeRate;
        totalRemainSupply = totalSupply;
        crowdsaleIsOpen = true;
    }
    
    function setMAYExchangeRate(uint256 _MAYExchangeRate) public onlyOwner {
        MAYExchangeRate = _MAYExchangeRate;
    }
    
    function crowdsaleOpen(bool _crowdsaleIsOpen) public {
        crowdsaleIsOpen = _crowdsaleIsOpen;
    }
     
    function MAYTotalSupply() view public returns (uint256) {   
        return totalSupply - totalRemainSupply;
    }

     
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require (balances[msg.sender] >= _value);             
        require (balances[_to] + _value >= balances[_to]);    
        balances[msg.sender] -= _value;                      
        balances[_to] += _value;                             
        emit Transfer(msg.sender, _to, _value);                   
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;           
        emit Approval(msg.sender, _spender, _value);              
        return true;
    }

      
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {            
        tokenRecipient spender = tokenRecipient(_spender);               
        approve(_spender, _value);                                       
        spender.receiveApproval(msg.sender, _value, this, _extraData);   
        return true;     
    }     

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {      
        require (balances[_from] >= _value);                 
        require (balances[_to] + _value >= balances[_to]);   
        require (_value <= allowances[_from][msg.sender]);   
        balances[_from] -= _value;                           
        balances[_to] += _value;                             
        allowances[_from][msg.sender] -= _value;             
        emit Transfer(_from, _to, _value);                        
        return true;     
    }         

          
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {         
        return allowances[_owner][_spender];
    }     
        
     
    function withdraw(address _multisigAddress) public onlyOwner {    
        require(_multisigAddress != 0x0);
        multisigAddress = _multisigAddress;
        address contractAddress = this;
        multisigAddress.transfer(contractAddress.balance);
    }  
    
          
    function mintMAYToken(address _to, uint256 _amount) internal { 
        require (balances[_to] + _amount >= balances[_to]);       
        require (totalRemainSupply >= _amount);
        totalRemainSupply -= _amount;                            
        balances[_to] += _amount;                                
        emit mintToken(_to, _amount);                                 
        emit Transfer(0x0, _to, _amount);                             
    }  
    
    function mintTokens(address _sendTo, uint256 _sendAmount) public onlyOwner {
        mintMAYToken(_sendTo, _sendAmount);
    }
    
     
    function burnTokens(address _addr, uint256 _amount) public onlyOwner {
        require (balances[_addr] >= _amount);                
        totalRemainSupply += _amount;                            
        balances[_addr] -= _amount;                              
        emit burnToken(_addr, _amount);                               
        emit Transfer(_addr, 0x0, _amount);                           
    }
}