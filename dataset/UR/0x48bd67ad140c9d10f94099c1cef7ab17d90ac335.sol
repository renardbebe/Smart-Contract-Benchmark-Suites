 

pragma solidity ^0.4.16;

 
contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract LBN is SafeMath {
    string public constant name = "Leber Network";
    string public constant symbol = "LBN";
    uint8 public constant decimals = 18;

    uint256 public totalSupply = 100000000 * (10 ** uint256(decimals));
    uint256 public airdropSupply = 9000000 * (10 ** uint256(decimals));

    uint256 public airdropCount;
    mapping(address => bool) airdropTouched;

    uint256 public constant airdropCountLimit1 = 20000;
    uint256 public constant airdropCountLimit2 = 20000;

    uint256 public constant airdropNum1 = 300 * (10 ** uint256(decimals));
    uint256 public constant airdropNum2 = 150 * (10 ** uint256(decimals));

    address public owner;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    event Freeze(address indexed from, uint256 value);

     
    event Unfreeze(address indexed from, uint256 value);

     
    function LBN() public {
        owner = msg.sender;

        airdropCount = 0;
        balanceOf[address(this)] = airdropSupply;
        balanceOf[msg.sender] = totalSupply - airdropSupply;
    }

     
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply, _value);                                 
        Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);
        require(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }

     
    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner);
        owner.transfer(amount);
    }

    function () external payable {
        require(balanceOf[address(this)] > 0);
        require(!airdropTouched[msg.sender]);
        require(airdropCount < airdropCountLimit1 + airdropCountLimit2);

        airdropTouched[msg.sender] = true;
        airdropCount = SafeMath.safeAdd(airdropCount, 1);

        if (airdropCount <= airdropCountLimit1) {
            _transfer(address(this), msg.sender, airdropNum1);
        } else if (airdropCount <= airdropCountLimit1 + airdropCountLimit2) {
            _transfer(address(this), msg.sender, airdropNum2); 
        }
    }

    function _transfer(address _from, address _to, uint _value) internal {     
        require(balanceOf[_from] >= _value);                
        require(balanceOf[_to] + _value > balanceOf[_to]);  
   
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                          
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
         
        Transfer(_from, _to, _value);
    }
}