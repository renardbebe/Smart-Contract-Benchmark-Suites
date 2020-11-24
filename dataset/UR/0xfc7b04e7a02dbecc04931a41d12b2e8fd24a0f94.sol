 

pragma solidity ^0.5.10;

contract EmpowToken {
     
    modifier onlyAdmin(){
        require(msg.sender == owner, "admin required");
        _;
    }
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint256 public decimals;
    address private owner;
    
    constructor ()
    public
    {
        owner = msg.sender;
        symbol = "EM";
        name = "EMPOW";
        decimals = 18;
        totalSupply = 100000000000 * 10**decimals;
        
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

    function transfer(address to, uint256 value) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[to]);
        require(value <= balanceOf[msg.sender], "not enough balance");                  
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(_value <= allowance[_from][msg.sender]);      
        require(_value <= balanceOf[_from]);                  
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_spender]);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function freezeAccount(address target, bool freeze) public onlyAdmin {
        frozenAccount[target] = freeze;
    }
}