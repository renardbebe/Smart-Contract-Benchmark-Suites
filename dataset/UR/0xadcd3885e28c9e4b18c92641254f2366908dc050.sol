 

pragma solidity ^0.5.1;

library SafeMath {

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

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   constructor() public {
      owner = 0xaEE67b1d0F24CB22902e259576fBC8F265B27b70;
    }

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
      require(newOwner != address(0));
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
}

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20Basic,Ownable {
    using SafeMath for uint256;
    
    string public constant name = "NICI-Token";
    string public constant symbol = "NICI";
    uint8 public constant decimals = 18;
    uint256 totalSupply_ = 100000000 * 10**uint(decimals);
    uint256 remainingSupply_;
    
    mapping(address => uint256) balances;
    mapping(address => bool) whitelist;
    
    event whitelisted(address indexed _address,bool status);
    
    constructor() public{
        whitelist[0xB1Eb0465bcf4F0DD0ccB26F151A6c288a0Ca0a6e]=true;
        whitelist[0xaEE67b1d0F24CB22902e259576fBC8F265B27b70]=true;
        balances[0xB1Eb0465bcf4F0DD0ccB26F151A6c288a0Ca0a6e]=10000000 *10**uint(decimals) ;
        emit Transfer(address(this),0xB1Eb0465bcf4F0DD0ccB26F151A6c288a0Ca0a6e,10000000*10**uint(decimals));
        balances[0xaEE67b1d0F24CB22902e259576fBC8F265B27b70]=10000000 *10**uint(decimals);
        emit Transfer(address(this),0xaEE67b1d0F24CB22902e259576fBC8F265B27b70,10000000*10**uint(decimals));
        remainingSupply_ = totalSupply_.sub(20000000*10**uint(decimals));
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_.sub(balances[address(0)]);
    }
    
    function remainingSupply() public view returns(uint256){
        return remainingSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(whitelist[msg.sender] == true);
        require(whitelist[_to] == true);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function whitelisting(address _address) public onlyOwner returns (bool)
    {
        require(_address != address(0));
        whitelist[_address] = true;
        emit whitelisted(_address,true);
        return true;
    }
    
    function whitelistedAddress(address _address) public view returns (bool)
    {
        return whitelist[_address];
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}

contract NiciToken is ERC20, StandardToken {
    mapping (address => mapping (address => uint256)) internal allowed;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(whitelist[_from] == true);
        require(whitelist[_to] == true);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(whitelist[_spender] == true);
        require(whitelist[msg.sender] == true);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        require(whitelist[_spender] == true);
        require(whitelist[msg.sender] == true);
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        require(whitelist[_spender]==true);
        require(whitelist[msg.sender]==true);
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    
    function buy(uint256 _tokenAmount) payable external {
        require(msg.value>0);
        require(_tokenAmount > 0);
        require(remainingSupply_ >= _tokenAmount);
        require(whitelist[msg.sender] == true);
        
        remainingSupply_ = remainingSupply_.sub(_tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(_tokenAmount);
        
        emit Transfer(address(this),msg.sender,_tokenAmount);
        owner.transfer(msg.value);
    }
}