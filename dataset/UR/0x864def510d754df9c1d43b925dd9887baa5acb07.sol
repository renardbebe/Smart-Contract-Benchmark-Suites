 

pragma solidity ^0.4.11;
contract owned {
    address public owner;
    address public authorisedContract;
    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyAuthorisedAddress{
        require(msg.sender == authorisedContract);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
    modifier onlyPayloadSize(uint size) {
     assert(msg.data.length == size + 4);
     _;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract MyToken is owned {
     
    string public name = "DankToken";
    string public symbol = "DANK";
    uint8 public decimals = 18;
    uint256 _totalSupply;
    uint256 public amountRaised = 0;
    uint256 public amountOfTokensPerEther = 500;
         
    mapping (address => bool) public frozenAccounts;
          
    mapping (address => uint256) _balanceOf;
    mapping (address => mapping (address => uint256)) _allowance;
    bool public crowdsaleClosed = false;
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenFunds(address target, bool frozen);
     
    function MyToken() {
        _balanceOf[msg.sender] = 4000000000000000000000;              
        _totalSupply = 4000000000000000000000;                 
        Transfer(this, msg.sender,4000000000000000000000);
    }
    function changeAuthorisedContract(address target) onlyOwner
    {
        authorisedContract = target;
    }
    function() payable{
        require(!crowdsaleClosed);
        uint amount = msg.value;
        amountRaised += amount;
        uint256 totalTokens = amount * amountOfTokensPerEther;
        _balanceOf[msg.sender] += totalTokens;
        _totalSupply += totalTokens;
        Transfer(this,msg.sender, totalTokens);
    }
     function totalSupply() constant returns (uint TotalSupply){
        TotalSupply = _totalSupply;
     }
      function balanceOf(address _owner) constant returns (uint balance) {
        return _balanceOf[_owner];
     }
     function closeCrowdsale() onlyOwner{
         crowdsaleClosed = true;
     }
     function openCrowdsale() onlyOwner{
         crowdsaleClosed = false;
     }
     function changePrice(uint newAmountOfTokensPerEther) onlyOwner{
         require(newAmountOfTokensPerEther <= 500);
         amountOfTokensPerEther = newAmountOfTokensPerEther;
     }
     function withdrawal(uint256 amountOfWei) onlyOwner{
         if(owner.send(amountOfWei)){}
     }
     function freezeAccount(address target, bool freeze) onlyAuthorisedAddress
     {
         frozenAccounts[target] = freeze;
         FrozenFunds(target, freeze);
     } 
     
     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2*32) {
        require(!frozenAccounts[msg.sender]);
        require(_balanceOf[msg.sender] > _value);           
        require(_balanceOf[_to] + _value > _balanceOf[_to]);  
        _balanceOf[msg.sender] -= _value;                      
        _balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }
     
    function approve(address _spender, uint256 _value)onlyPayloadSize(2*32)
        returns (bool success)  {
        _allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    } 

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success)  {
        require(!frozenAccounts[_from]);
        require(_balanceOf[_from] > _value);                  
        require(_balanceOf[_to] + _value > _balanceOf[_to]);   
        require(_allowance[_from][msg.sender] >= _value);      
        _balanceOf[_from] -= _value;                            
        _balanceOf[_to] += _value;                              
        _allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return _allowance[_owner][_spender];
    }
}