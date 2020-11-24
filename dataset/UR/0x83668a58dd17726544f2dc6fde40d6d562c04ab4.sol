 

pragma solidity ^0.4.24;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

contract Interacting {
    address private owner = msg.sender;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function sendEther(address _to) external payable onlyOwner {
        require(_to.call.value(msg.value)(''));
    }
    
    function callMethod(address _contract, bytes _extraData) external payable onlyOwner {
        require(_contract.call.value(msg.value)(_extraData));
    }
    
    function withdrawEther(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }
    
    function () external payable {
        
    }
}

contract RGT {
    string public name = 'RGT';
    string public symbol = 'RGT';
    uint8 public decimals = 18;
    uint public k = 10 ** uint(decimals);
    uint public k1000 = k / 1000;
    uint public totalSupply = 1000000000 * k;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => address) public contracts;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
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

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
    function mint(uint _amount) internal {
        _amount = (_amount + 40000) * k1000 * (1 + balanceOf[msg.sender] * 99 / totalSupply);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        require(totalSupply >= _amount);
        emit Transfer(address(0), address(this), _amount);
        emit Transfer(address(this), msg.sender, _amount);
    }
    
    modifier createOwnContractIfNeeded {
        if (contracts[msg.sender] == 0x0) {
            contracts[msg.sender] = new Interacting();
        }
        _;
    }
    
    function sendEther(address _to) external payable createOwnContractIfNeeded {
        uint gas = gasleft();
        Interacting(contracts[msg.sender]).sendEther.value(msg.value)(_to);
        mint(gas - gasleft());
    }
    
    function callMethod(address _contract, bytes _extraData) external payable createOwnContractIfNeeded {
        uint gas = gasleft();
        Interacting(contracts[msg.sender]).callMethod.value(msg.value)(_contract, _extraData);
        mint(gas - gasleft());
    }
    
    function withdrawEther() external payable createOwnContractIfNeeded {
        Interacting(contracts[msg.sender]).withdrawEther(msg.sender);
    }
    
    function () external payable createOwnContractIfNeeded {
        require(msg.value == 0);
        mint(0);
    }
}