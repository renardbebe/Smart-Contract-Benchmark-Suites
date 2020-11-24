 

pragma solidity ^ 0.4.15;


 
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }


 
contract GodzStartupBasicInformation {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint256 public amount;
    uint256 public reward;  
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function GodzStartupBasicInformation(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        uint256 _amount,
        uint256 _reward,  
        address _GodzSwapTokens  
    ) {
        owner = tx.origin;  
        balanceOf[owner] = initialSupply;

        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;

        amount = _amount;  
        reward = _reward;  

        allowance[owner][_GodzSwapTokens] = initialSupply;  
    }

      
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) revert();                                
        if (balanceOf[msg.sender] < _value) revert();            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();  
        balanceOf[msg.sender] -= _value;                         
        balanceOf[_to] += _value;                                
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function transferFromOrigin(address _to, uint256 _value)  returns (bool success) {
        address origin = tx.origin;
        if (origin == 0x0) revert();
        if (_to == 0x0) revert();                                 
        if (balanceOf[origin] < _value) revert();                 
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        balanceOf[origin] -= _value;                              
        balanceOf[_to] += _value;                                 
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert();                                 
        if (balanceOf[_from] < _value) revert();                  
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();   
        if (_value > allowance[_from][msg.sender]) revert();      
        balanceOf[_from] -= _value;                               
        balanceOf[_to] += _value;                                 
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}