 

pragma solidity ^0.4.24;

 
 
 
 
 
 

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract AEL {
     
    string public name = "AELEUS";
    string public symbol = "AEL";
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
    uint256 public tokenSupply = 200000000;
    uint public presale;
    uint public coresale;
    
    address public creator;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    
     
    function AEL() public {
        totalSupply = tokenSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;     
        creator = msg.sender;
        presale = now + 21 days;
        coresale = now + 41 days;
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
      
    }

     
    
    
   function transfer(address[] _to, uint256[] _value) public {
    for (uint256 i = 0; i < _to.length; i++)  {
        _transfer(msg.sender, _to[i], _value[i]);
        }
    }


     
    function () payable internal {
        uint amount;                   
        uint amountRaised;

        if (now <= presale) {
            amount = msg.value * 15000;
        } else if (now > presale && now <= coresale) {
            amount = msg.value * 13000;
        } else if (now > coresale) {
            amount = msg.value * 10000;
        }
        

                                             
        amountRaised += msg.value;                             
        require(balanceOf[creator] >= amount);                
        balanceOf[msg.sender] += amount;                   
        balanceOf[creator] -= amount;                         
        Transfer(creator, msg.sender, amount);                
        creator.transfer(amountRaised);
    }

 }