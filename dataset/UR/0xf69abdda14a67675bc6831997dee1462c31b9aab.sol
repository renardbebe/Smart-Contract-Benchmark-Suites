 

pragma solidity ^0.4.21;

interface ERC223ReceivingContract { 
    function tokenFallback(address _from, uint _value, bytes _data) external;
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract AlphaToken is Ownable {
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    mapping(address => uint) balances;  
    mapping(address => mapping (address => uint256)) allowed;

    string _name;
    string _symbol;
    uint8 DECIMALS = 18;
     
    uint256 _totalSupply;
    uint256 _saledTotal = 0;
    uint256 _amounToSale = 0;
    uint _buyPrice = 4500;
    uint256 _totalEther = 0;

    function AlphaToken(
        string tokenName,
        string tokenSymbol
    ) public 
    {
        _totalSupply = 4000000000 * 10 ** uint256(DECIMALS);   
        _amounToSale = _totalSupply;
        _saledTotal = 0;
        _name = tokenName;                                        
        _symbol = tokenSymbol;                                    
        owner = msg.sender;
    }

    function name() public constant returns (string) {
        return _name;
    }

    function symbol() public constant returns (string) {
        return _symbol;
    }

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }

    function buyPrice() public constant returns (uint256) {
        return _buyPrice;
    }
    
    function decimals() public constant returns (uint8) {
        return DECIMALS;
    }

    function _transfer(address _from, address _to, uint _value, bytes _data) internal {
        uint codeLength;
        require (_to != 0x0);
        require(balances[_from]>=_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool ok) {
         
         
        _transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
     
    function transfer(address _to, uint _value) public returns(bool ok) {
        bytes memory empty;
        _transfer(msg.sender, _to, _value, empty);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(balances[msg.sender]>=tokens);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) onlyOwner public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        bytes memory empty;
        _transfer(_from, _to, _value, empty);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }
    
     
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function setPrices(uint256 newBuyPrice) onlyOwner public {
        _buyPrice = newBuyPrice;
    }

     
    function buyCoin() payable public returns (bool ok) {
        uint amount = ((msg.value * _buyPrice) * 10 ** uint256(DECIMALS))/1000000000000000000;                
        require ((_amounToSale - _saledTotal)>=amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        _saledTotal = _saledTotal.add(amount);
        _totalEther += msg.value;
        return true;
    }

    function dispatchTo(address target, uint256 amount) onlyOwner public returns (bool ok) {
        require ((_amounToSale - _saledTotal)>=amount);
        balances[target] = balances[target].add(amount);
        _saledTotal = _saledTotal.add(amount);
        return true;
    }

    function withdrawTo(address _target, uint256 _value) onlyOwner public returns (bool ok) {
        require(_totalEther <= _value);
        _totalEther -= _value;
        _target.transfer(_value);
        return true;
    }
    
    function () payable public {
    }

}