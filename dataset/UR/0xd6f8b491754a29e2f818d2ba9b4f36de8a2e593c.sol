 

pragma solidity ^0.4.25;

 

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract EIE {
     
    string public name = 'EasyInvestEternal';
    string public symbol = 'EIE';
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 1000000000000000000000000;
    uint256 public createdAtBlock;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
     
    mapping (address => uint256) public invested;
     
    mapping (address => uint256) public atBlock;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    constructor() public {
        createdAtBlock = block.number;
        balanceOf[msg.sender] = totalSupply;                 
    }
    
    function isFirstWeek() internal view returns (bool) {
        return block.number < createdAtBlock + 5900 * 7;
    }
    
    function _issue(uint _value) internal {
        balanceOf[msg.sender] += _value;
        totalSupply += _value;
        emit Transfer(0, this, _value);
        emit Transfer(this, msg.sender, _value);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_to == address(this)) {
            burn(_value);
        } else {
            _transfer(msg.sender, _to, _value);
        }
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

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, this, _value);
        
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            _issue(amount);
        }
        
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += _value;
        
        return true;
    }

     
    function () external payable {
        if (msg.value > 0 || !isFirstWeek()) {
            revert();
        }
        
        _issue(1000000000000000000);
    }
}