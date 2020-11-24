 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract ZazToken {
     
    string public name = "ZAZ TOKEN";
    string public symbol = "ZTZ";
    uint8 public decimals = 0;
     
    uint256 public totalSupply;
    uint256 public zazSupply = 20000000;
    uint256 public price ;
    address public creator;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    
     
    function ZazToken() public {
        totalSupply = zazSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;     
        creator = msg.sender;
    }
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
      
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    
    
     
    function () payable internal {
        
        if (price >= 0 ether && price < 0.005 ether){
        uint ammount = 500;                   
        uint ammountRaised;                                     
        amountRaised += msg.value;                             
        require(balanceOf[creator] >= ammount);                
        require(msg.value < 0.1 ether);                         
        balanceOf[msg.sender] += ammount;                   
        balanceOf[creator] -= ammount;                         
        Transfer(creator, msg.sender, ammount);                
        creator.transfer(ammountRaised);
        }
        if (price >= 0.005 ether && price < 0.03 ether){
        uint amount = 2000;                   
        uint amountRaised;                                     
        amountRaised += msg.value;                             
        require(balanceOf[creator] >= amount);                
        require(msg.value < 0.1 ether);                         
        balanceOf[msg.sender] += amount;                   
        balanceOf[creator] -= amount;                         
        Transfer(creator, msg.sender, amount);                
        creator.transfer(amountRaised);
        }
         if (price >= 0.03 ether){
        uint amnount = 10000;                   
        uint amnountRaised;                                     
        amountRaised += msg.value;                             
        require(balanceOf[creator] >= amnount);                
        require(msg.value < 0.1 ether);                         
        balanceOf[msg.sender] += amnount;                   
        balanceOf[creator] -= amnount;                         
        Transfer(creator, msg.sender, amnount);                
        creator.transfer(amnountRaised);
        }
    }

 }