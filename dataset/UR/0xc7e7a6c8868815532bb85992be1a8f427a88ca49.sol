 

pragma solidity ^0.5.11;

 
contract SafeMath {
    function mul(uint256 a, uint256 b)pure internal returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)pure internal returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b)pure internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)pure internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract ERC20 {

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract GXP is ERC20, SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    address payable public owner;
    address public _freeze;
    bool public paused = false;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public freezeOf;



     
    event Burn(address indexed from, uint256 value);

     
    event Freeze(address indexed from, uint256 value);

     
    event Unfreeze(address indexed from, uint256 value);

     
    event Pause(address indexed from);

     
    event Unpause(address indexed from);

     
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol,
        address freezeAddr
    ) public {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
        owner = msg.sender;
        _freeze = freezeAddr;
    }


     
    function transfer(address _to, uint256 _value) public returns (bool success)  {
        require(!paused,"contract is paused");
        require(_to != address(0), "ERC20: transfer from the zero address");                              
        require(_value >0);
        require(balanceOf[msg.sender] >= _value,"balance not enouth");            
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = add(balanceOf[_to], _value);                             
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        require(!paused,"contract is paused");
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!paused,"contract is paused");
        require(_to != address(0), "ERC20: transfer from the zero address");                             
        require(_to == msg.sender);
        require(_value >0);
        require(balanceOf[_from] >= _value,"the balance of from address not enough");                  
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
        require(_value <= allowance[_from][msg.sender], "from allowance not enough");      
        balanceOf[_from] = sub(balanceOf[_from], _value);                            
        balanceOf[_to] = add(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(!paused,"contract is paused");
        require(balanceOf[msg.sender] >= _value,"balance not enough");             
        require(_value >0);
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value);                       
        totalSupply = sub(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }

    function freeze(address _address, uint256 _value) public returns (bool success) {
        require(!paused,"contract is paused");
        require(msg.sender == owner|| msg.sender == _freeze,"no permission");
        require(balanceOf[_address] >= _value,"address balance not enough");             
        require(_value >0);
        balanceOf[_address] = sub(balanceOf[_address], _value);                       
        freezeOf[_address] = add(freezeOf[_address], _value);                                 
        emit Freeze(_address, _value);
        return true;
    }

    function unfreeze(address _address, uint256 _value) public returns (bool success) {
        require(!paused,"contract is paused");
        require(msg.sender == owner|| msg.sender == _freeze,"no permission");
        require(freezeOf[_address] >= _value,"freeze balance not enough");             
        require(_value >0);
        freezeOf[_address] = sub(freezeOf[_address], _value);                       
        balanceOf[_address] = add(balanceOf[_address], _value);
        emit Unfreeze(_address, _value);
        return true;
    }

     
    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner,"no permission");
        owner.transfer(amount);
    }

     
    function() external payable {
    }

    function pause() public{
        require(msg.sender == owner|| msg.sender == _freeze,"no permission");
        paused = true;
        emit Pause(msg.sender);
    }
    function unpause() public{
        require(msg.sender == owner|| msg.sender == _freeze,"no permission");
        paused = false;
        emit Unpause(msg.sender);
    }
}