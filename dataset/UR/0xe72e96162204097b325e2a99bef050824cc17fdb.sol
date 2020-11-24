 

pragma solidity ^0.4.16;

    contract owned {
        address public owner;

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract MyTestToken is owned {
     
    mapping (address => uint256) public balanceOf;
    bool b_enableTransfer = true;
    uint256 creationDate;
    string public name;
    string public symbol;
    uint8 public decimals = 18;    
    uint256 public totalSupply;
    uint8 public tipoCongelamento = 0;
         
         
        
    event Transfer(address indexed from, address indexed to, uint256 value);        

     
    function MyTestToken (
                           uint256 initialSupply,
                           string tokenName,
                           string tokenSymbol
        ) owned() public 
    {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;               
        creationDate = now;
        name = tokenName;
        symbol = tokenSymbol;
    }

     
    function transfer2(address _to, uint256 _value) public
    {
        require(b_enableTransfer); 
         
         
        
        _transfer(_to, _value);
    }

    function transfer(address _to, uint256 _value) public
    {
         
         
         
        if(tipoCongelamento == 0)  
        {
            _transfer(_to, _value);
        }
        if(tipoCongelamento == 1)  
        {
            if(now >= creationDate + 10 * 1 minutes) _transfer(_to, _value);
        }
        if(tipoCongelamento == 2)  
        {
            if(now >= creationDate + 30 * 1 minutes) _transfer(_to, _value);
        }        
        if(tipoCongelamento == 3)  
        {
            if(now >= creationDate + 1 * 1 hours) _transfer(_to, _value);
        }        
        if(tipoCongelamento == 4)  
        {
            if(now >= creationDate + 2 * 1 hours) _transfer(_to, _value);
        }        
        if(tipoCongelamento == 5)  
        {
            if(now >= creationDate + 1 * 1 days) _transfer(_to, _value);
        }        
        if(tipoCongelamento == 6)  
        {
            if(now >= creationDate + 2 * 1 days) _transfer(_to, _value);
        }        
    }

    function freezingStatus() view public returns (string)
    {
         
         
        
        if(tipoCongelamento == 0) return ( "Tokens free to transfer!");
        if(tipoCongelamento == 1) return ( "Tokens frozen by 10 minutes.");
        if(tipoCongelamento == 2) return ( "Tokens frozen by 30 minutes.");
        if(tipoCongelamento == 3) return ( "Tokens frozen by 1 hour.");
        if(tipoCongelamento == 4) return ( "Tokens frozen by 2 hours.");        
        if(tipoCongelamento == 5) return ( "Tokens frozen by 1 day.");        
        if(tipoCongelamento == 6) return ( "Tokens frozen by 2 days.");                

    }

    function setFreezingStatus(uint8 _mode) onlyOwner public
    {
        require(_mode>=0 && _mode <=6);
        tipoCongelamento = _mode;
    }

    function _transfer(address _to, uint256 _value) private 
    {
        require(balanceOf[msg.sender] >= _value);            
        require(balanceOf[_to] + _value >= balanceOf[_to]);  
        
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                            
        Transfer(msg.sender, _to, _value);
    }
    
    function enableTransfer(bool _enableTransfer) onlyOwner public
    {
        b_enableTransfer = _enableTransfer;
    }
}