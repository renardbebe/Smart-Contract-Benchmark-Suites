 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


pragma solidity ^0.4.24;

 
library SafeMath {

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

 
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

     
    function unpause() onlyOwner whenPaused public returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint);
    function allowance(address tokenOwner, address spender) public constant returns (uint);
    function transfer(address to, uint tokens) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool);

    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function decimals() public constant returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract ERC223 is ERC20Interface {
    function transfer(address to, uint value, bytes data) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

 
contract ERC223ReceivingContract {
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
    function doTransfer(address _to, uint256 _index) public returns (uint256 price, address owner);
}

contract CardMakerCake is ERC223, Pausable {

    using SafeMath for uint256;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) internal allowed;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    string private tokenURI_ = "";

    event Burn(address indexed burner, uint256 value);

    constructor() public {
        tokenURI_ = "cardmaker.io";
        name = "CardMaker Alchemists Knowledge Energy (CardMaker Token)";
        symbol = "CAKE";
        decimals = 18;
        totalSupply = 10000 * 10000 * 50 * 10 ** uint(decimals);
        balances[msg.sender] = totalSupply;
    }

    function tokenURI() external view returns (string) {
        return tokenURI_;
    }

     
    function name() public constant returns (string) {
        return name;
    }
     
    function symbol() public constant returns (string) {
        return symbol;
    }
     
    function decimals() public constant returns (uint8) {
        return decimals;
    }
     
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

     
    function transfer(address _to, uint _value, bytes _data) public whenNotPaused returns (bool) {
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
     
    function transfer(address _to, uint _value) public whenNotPaused returns (bool) {
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
         
            length := extcodesize(_addr)
        }
        return (length>0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool) {

        ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
        uint256 price;
        address owner;
        (price, owner) = receiver.doTransfer(msg.sender, bytesToUint(_data));

        if (balanceOf(msg.sender) < price) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(price);
        balances[owner] = balanceOf(owner).add(price);
        receiver.tokenFallback(msg.sender, price, _data);
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }

    function allowance(address _tokenOwner, address _spender) public constant returns (uint) {
        return allowed[_tokenOwner][_spender];
    }

    function burn(uint256 _value) public returns (bool) {
        require (_value > 0);
         
        require (balanceOf(msg.sender) >= _value);
         
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
         
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function bytesToUint(bytes b) private pure returns (uint result) {
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function approve(address _spender, uint _tokens) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    function transferFrom(address _from, address _to, uint _tokens) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_tokens <= balances[_from]);
        require(_tokens <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool){
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}