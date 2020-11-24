 

pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract SafeERC20 {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
     
    uint256 public _totalSupply;

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping(address => uint256)) allowed;
    

    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
    
         
     
     
     
    function transfer(address to, uint256 value) public {
        require (
            balanceOf[msg.sender] >= value && value > 0
        );
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        Transfer(msg.sender, to, value);
    }

     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public {
        require (
            allowed[from][msg.sender] >= value && balanceOf[from] >= value && value > 0
        );
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
    }

     
     
     
     
     
    function approve(address spender, uint256 value) public {
        require (
            balanceOf[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }

     
     
     
     
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }

     
     
     

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract BITTOToken is SafeERC20, owned {

    using SafeMath for uint256;



     
    string public name = "BITTO";
    string public symbol = "BITTO";
    uint256 public decimals = 18;

    uint256 public _totalSupply = 33000000e18;
    address multisig = 0x228C8c3D0878b0d3ce72381b8CC92396A03f399e;

    

     
    uint public price = 800;


    uint256 public fundRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


     
     
     
    function BITTOToken() public {
 
        balanceOf[multisig] = _totalSupply;

    }

    function transfertoken (uint256 _amount, address recipient) public onlyOwner {
         require(recipient != 0x0);
         require(balanceOf[owner] >= _amount);
         balanceOf[owner] = balanceOf[owner].sub(_amount);
         balanceOf[recipient] = balanceOf[recipient].add(_amount);

    }
    
    function burn(uint256 _amount) public onlyOwner{
        require(balanceOf[owner] >= _amount);
        balanceOf[owner] -= _amount;
        _totalSupply -= _amount;
    }
     
     
    function () public payable {
        tokensale(msg.sender);
        
    }
     
    
    function updatePrice (uint _newpice) public onlyOwner {
        price = _newpice;
    }
     
     
     
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);


        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(price);

         
        fundRaised = fundRaised.add(weiAmount);

        balanceOf[owner] = balanceOf[owner].sub(tokens);
        balanceOf[recipient] = balanceOf[recipient].add(tokens);



        TokenPurchase(msg.sender, recipient, weiAmount, tokens);
        forwardFunds();
    }

     
     
    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

}