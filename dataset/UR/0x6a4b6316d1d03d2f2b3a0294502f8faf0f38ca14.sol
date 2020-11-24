 

pragma solidity >= 0.5 .0 < 0.7 .0;

 

 
 
 

library SafeMath {

    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

}

 
 
 

contract ERC20Interface {

    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
     
    function purchaseTokens() external payable;
    function purchaseEth(uint tokens) public;
    function sellAllTokens() public;
    function weiToTokens(uint weiPurchase) public view returns(uint);
    function tokensToWei(uint tokens) public view returns(uint);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

 
 
 
 
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

 
 
 
contract _HERTZ is ERC20Interface, Owned {

    using SafeMath
    for uint;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint private _DECIMALSCONSTANT;
    uint public _totalSupply;
    uint public _currentSupply;
    bool constructorLocked = false;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    uint public weiDeposited;

 
 
 
 
    constructor() public onlyOwner{
        if (constructorLocked) revert();
        constructorLocked = true;  

        symbol = "HZ";
        name = "Hertz";
        decimals = 18;
        _DECIMALSCONSTANT = 10 ** uint(decimals);
        _totalSupply = (uint(21000)).mul(_DECIMALSCONSTANT);
        _currentSupply = 0;

         
        emit OwnershipTransferred(msg.sender, address(0));
        owner = address(0);
    }

 
 
 
    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }
    
    
 
 
 
    function currentSupply() public view returns(uint) {
        return _currentSupply;
    }
    

 
 
 
    function balanceOf(address tokenOwner) public view returns(uint balance) {
        return balances[tokenOwner];
    }

 
 
 
 
 
 
    function transfer(address to, uint tokens) public returns(bool success) {
        require(balances[msg.sender] >= tokens && tokens > 0, "Zero transfer or not enough funds");
        require(address(to) != address(0), "No burning allowed");
        require(address(msg.sender) != address(0), "You can't mint this token, purchase it instead");

        uint burn = tokens.div(50);  
        uint send = tokens.sub(burn);
        _transfer(to, send);
        _transfer(address(0), burn);
        return true;
    }


 
 
 
    function _transfer(address to, uint tokens) internal returns(bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        if (address(to) != address(0)) {
            balances[to] = balances[to].add(tokens);
        } else if (address(to) == address(0)) {
            _currentSupply = _currentSupply.sub(tokens);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

 
 
 
 
    function approve(address spender, uint tokens) public returns(bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

 
 
 
 
 
 
 
 
 
 
    function transferFrom(address from, address to, uint tokens) public returns(bool) {
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0, "Zero transfer or not enough (allowed) funds");
        require(address(to) != address(0), "No burning allowed");
        require(address(from) != address(0), "You can't mint this token, purchase it instead");

        uint burn = tokens.div(50);  
        uint send = tokens.sub(burn);
        _transferFrom(from, to, send);
        _transferFrom(from, address(0), burn);
    }

 
 
 
    function _transferFrom(address from, address to, uint tokens) internal returns(bool) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        if (address(to) != address(0)) {
            balances[to] = balances[to].add(tokens);
        } else if (address(to) == address(0)) {
            _currentSupply = _currentSupply.sub(tokens);
        }
        emit Transfer(from, to, tokens);
        return true;
    }

 
 
 
    function allowance(address tokenOwner, address spender) public view returns(uint remaining) {
        return allowed[tokenOwner][spender];
    }

 
 
 
 
 
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns(bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

 
 
 
 
 
     
     
     
     
     
     
     


 
 
 
 
 
    function weiToTokens(uint weiPurchase) public view returns(uint) {
        if(_currentSupply==0 && weiDeposited==0 ) return weiPurchase;  
        if(weiDeposited==0 || _currentSupply==0 || weiPurchase==0) return 0;

        uint ret = (weiPurchase.mul(_currentSupply)).div(weiDeposited);
        return ret;
    }
    
 
 
 
 
 
    function tokensToWei(uint tokens) public view returns(uint){
        if(tokens==0 || weiDeposited==0 || _currentSupply==0) return 0;
        uint ret = (weiDeposited.mul(tokens)).div(_currentSupply);
        ret = ret.sub(ret.div(50));  
        return ret;
    }

 
 
 
 
 
    function purchaseTokens() external payable {
        require(msg.value>0);
        
        uint tokens = weiToTokens(msg.value);
        require(_currentSupply.add(tokens)<=_totalSupply,"We have reached our contract limit");
        require(tokens>0);

         
        emit Transfer(address(0), msg.sender, tokens);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _currentSupply = _currentSupply.add(tokens);

        weiDeposited = weiDeposited.add(msg.value);
    }
    
 
 
 
 
    function purchaseEth(uint tokens) public {
        require(tokens>0);
        uint getWei = tokensToWei(tokens);
        require(getWei>0);
         
        emit Transfer(msg.sender, address(0), tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _currentSupply = _currentSupply.sub(tokens);
        address(msg.sender).transfer(getWei);
        weiDeposited = weiDeposited.sub(getWei);
    }
    
 
 
 
 
    function sellAllTokens() public {
        purchaseEth(balances[msg.sender]);
    }   
}