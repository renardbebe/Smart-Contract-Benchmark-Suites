 

pragma solidity 0.4.24;

contract owned {
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract GTFToken is owned {
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    mapping (address => uint256) public freezeOf;

     
    bool suspendTrading;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    event UnFreezeFunds(address target, uint256 value);

     
    event FreezeFunds(address target, uint256 value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    constructor(
    ) public {
        totalSupply = 0 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                     
        name = "Gold Trust Foundation";                                        
        symbol = "GTF";                                    
        owner = 0xea731815ca86b606af3ba268220b93c84dea0ead;
    }
     
    function setSuspendTrading(bool _state) public onlyOwner {
        suspendTrading = _state;
    }
     
    function _transfer(address _from, address _to, uint _value)  internal {
        require(suspendTrading == false);
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= freezeOf[_from]);
        require(balanceOf[_from] - freezeOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
    	require((_value == 0) || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
    public
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

     
    function multiTransfer(address[] memory _to, uint256[] memory _value) public returns (bool success) {
        uint256 i = 0;
        while (i < _to.length) {
            transfer(_to[i], _value[i]);
            i += 1;
        }
        return true;
    }

     
    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[_from] >= freezeOf[_from]);
        require(balanceOf[_from] - freezeOf[_from] >= _value);                 
        balanceOf[_from] -= _value;                          
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }

     
    function multiBurnFrom(address[] memory _from, uint256[] memory _value) public onlyOwner returns (bool success) {
        uint256 i = 0;
        while (i < _from.length) {
            burnFrom(_from[i], _value[i]);
            i += 1;
        }
        return true;
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
    	require(totalSupply + mintedAmount < 10000000000 * 10 ** uint256(decimals));
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

     
    function multiMintToken(address[] memory _from, uint256[] memory _value) public onlyOwner returns (bool success) {
        uint256 i = 0;
        while (i < _from.length) {
            mintToken(_from[i], _value[i]);
            i += 1;
        }
        return true;
    }

     
     
     
    function freezeToken(address target, uint256 _value) onlyOwner public {
        require(balanceOf[target] -freezeOf[target]>= _value);
        freezeOf[target] += _value;
        emit FreezeFunds(target, _value);
    }

     
     
     
    function unfreezeToken(address target, uint256 _value) onlyOwner public {
        require(freezeOf[target] >= _value);
        freezeOf[target] -= _value;
        emit UnFreezeFunds(target, _value);
    }
}