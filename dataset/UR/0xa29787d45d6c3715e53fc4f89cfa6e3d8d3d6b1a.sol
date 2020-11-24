 

pragma solidity ^0.5.7;

 
library SafeMath {

     
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
     
   function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
     
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
     
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
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

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Swidex is ERC20Interface, Owned {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    string public name = "Swidex";
    string public symbol = "SWDX";
    uint256 public decimals = 8;
    uint256 public _totalSupply;
    
    uint256 public SWDXPerEther = 2000000e8;
    uint256 public maximumSale = 2000000000e8;
    uint256 public totalSold = 0;
    uint256 public minimumBuy = 1 ether;
    uint256 public maximumBuy = 20 ether;

     
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    
    constructor () public {
        _totalSupply = 5000000000e8;
         
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function () payable external {
        require(msg.value >= minimumBuy && msg.value <= maximumBuy && totalSold <= maximumSale);
        uint256 totalBuy =  (SWDXPerEther.mul(msg.value)).div(1 ether);
        totalSold = totalSold.add(totalBuy);
        doTransfer(owner, msg.sender, totalBuy);
    }
    
     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount) internal {
         
        require((_to != address(0)));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }
    
    function balanceOf(address _owner) view public returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }
     
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        doTransfer(_from, _to, _amount);
        return true;
    }
     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool success) {
         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        ApproveAndCallFallBack spender = ApproveAndCallFallBack(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function withdrawFund() onlyOwner public {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    
    function getForeignTokenBalance(ERC20Interface _tokenContract, address who) view public returns (uint) {
        return _tokenContract.balanceOf(who);
    }
    
    function withdrawForeignTokens(ERC20Interface _tokenContract) onlyOwner public returns (bool) {
        uint256 amount = _tokenContract.balanceOf(address(this));
        return _tokenContract.transfer(owner, amount);
    }
    
    event TransferEther(address indexed _from, address indexed _to, uint256 _value);
    event NewPrice(address indexed _changer, uint256 _lastPrice, uint256 _newPrice);
    event Burn(address indexed _burner, uint256 value);
}