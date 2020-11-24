 

pragma solidity ^0.5.0;

 
 
 
 
 
 
 


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint _value) public returns (bool success);
    function approve(address spender, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed tokenOwner, address indexed spender, uint _value);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address _from, uint256 _value, address token, bytes memory data) public;
}


 
 
 
contract Owned {
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


 
 
 
 
contract Opennity is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _initialTokenNumber;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint exchangerToken;
    uint reservedToken;
    uint developedToken;
    
    address public constant developed1Address     = 0xcFCb491953Da1d10D037165dFa1298D00773fcA7;
    address public constant developed2Address     = 0xA123BceDB9d2E4b09c8962C62924f091380E1Ad7;
    address public constant developed3Address     = 0x51aeD4EDC28aad15C353D958c5A813aa21F351b6;
    address public constant exchangedAddress     = 0xe65B9A91C1B084BE1A2dA89A62F5E9792f3fD9B7;

     
     
     
    constructor() public {
        symbol = "OPNN";
        name = "Opennity Token";
        decimals = 18;
        _initialTokenNumber = 1000000000;
        _totalSupply = _initialTokenNumber * 10 ** uint(decimals);
        
        reservedToken = _totalSupply * 40 / 100;   
        
        developedToken = _totalSupply * 10 / 100;  
        
        exchangerToken = _totalSupply * 30 / 100;  

        balances[owner] = reservedToken;
        emit Transfer(address(0), owner, reservedToken);

        balances[exchangedAddress] = exchangerToken;
        emit Transfer(address(0), exchangedAddress, exchangerToken);
        
        balances[developed1Address] = developedToken;
        emit Transfer(address(0), developed1Address, developedToken);
        balances[developed2Address] = developedToken;
        emit Transfer(address(0), developed2Address, developedToken);
        balances[developed3Address] = developedToken;
        emit Transfer(address(0), developed3Address, developedToken);
        
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


     
     
     
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }


     
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address _spender, uint _value) public returns (bool success) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_to != address(0)); 
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }


     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }


     
     
     
     
     
    function approveAndCall(address _spender, uint _value, bytes memory data) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, address(this), data);
        return true;
    }


     
     
     
    function () external payable {
        revert();
    }


     
     
     
    function transferAnyERC20Token(address _tokenAddress, uint _value) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _value);
    }
}