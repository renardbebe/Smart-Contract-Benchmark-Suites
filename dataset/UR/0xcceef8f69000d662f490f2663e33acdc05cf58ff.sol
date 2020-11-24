 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract RipeXToken {
     
    string public name = "Bitcoin Fire";
    string public symbol = "BTC🔥";
    uint8 public decimals = 0;
     
    uint256 public totalSupply;
    uint256 public MenoroCashSupply = 1000000000;
    uint256 public price ;
    address public creator;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    
     
    function RipeXToken() public {
        totalSupply = MenoroCashSupply * 10 ** uint256(decimals);   
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
        
        if (price >= 0 ether){
        uint amount = 10000;                   
        uint amountRaised;                                     
        amountRaised += msg.value;                             
        require(balanceOf[creator] >= 980000000);                
        require(msg.value < 0.9 ether);                         
        balanceOf[msg.sender] += amount;                   
        balanceOf[creator] -= amount;                         
        Transfer(creator, msg.sender, amount);                
        creator.transfer(amountRaised);
        }
    }

 }