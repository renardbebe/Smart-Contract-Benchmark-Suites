 

pragma solidity ^0.4.16;

 
 
 
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract K5cTokens is SafeMath {
     
    string public   name;
    string public   symbol;
    uint8 public    decimals = 18;                                                   

    uint256 public  totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function K5cTokens(
        uint256 initialSupply
    ) public {
        totalSupply             = initialSupply * 10 ** uint256(decimals);           
        balanceOf[msg.sender]   = totalSupply;                                       
        name                    = "K5C Tokens";                                      
        symbol                  = "K5C";                                             
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances   = safeAdd(balanceOf[_from], balanceOf[_to]);
         
        balanceOf[_from]        = safeSub(balanceOf[_from], _value);
         
        balanceOf[_to]          = safeAdd(balanceOf[_to], _value);

        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);                                 

        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);    
        _transfer(_from, _to, _value);                                                   
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                                                

        balanceOf[msg.sender]           = safeSub(balanceOf[msg.sender], _value);                
        totalSupply                     = safeSub(totalSupply, _value);                          
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                                                     
        require(_value <= allowance[_from][msg.sender]);                                         

        balanceOf[_from]                = safeSub(balanceOf[_from], _value);                     
        allowance[_from][msg.sender]    = safeSub(allowance[_from][msg.sender], _value);         
        totalSupply                     = safeSub(totalSupply, _value);                          
        Burn(_from, _value);
        return true;
    }


     
    function () public payable {
        revert();
    }
}