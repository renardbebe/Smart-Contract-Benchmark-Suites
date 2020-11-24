 

pragma solidity ^0.4.25;

 


 

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
 

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
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


 

contract LibertyEcoToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    
    uint256 _totalSupply;
    uint256 public reserveCap = 0;                                   
    uint256 public tokensRemain = 0;                                 
    uint256 public tokensSold = 0;                                   
    uint256 public tokensDistributed = 0;                            

    uint256 public tokensPerEth = 100;                                
    uint256 public EtherInWei = 0;                                   
    
    bool reserveCapped = false;
    address public fundsWallet;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
    
    constructor() public {
        symbol = "LES";                                             
        name = "Liberty EcoToken";                                          
        decimals = 18;                                              
        _totalSupply = 10000000000 * 10**uint(decimals);                
        
        balances[owner] = _totalSupply;                              
        emit Transfer(address(0), owner, _totalSupply);
        
        fundsWallet = msg.sender;                                    
        
        tokensRemain = _totalSupply.sub(reserveCap);
    }


     
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply.sub(balances[address(0)]);
    }


     
    
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return balances[tokenOwner];
    }

     
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
    
    function approve(address spender, uint256 tokens) public returns (bool success) {
        require(spender != address(0));
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
    
    function transferFrom(address _from, address to, uint256 tokens) public returns (bool success) {
        require(_from != address(0) && to != address(0));
        balances[_from] = balances[_from].sub(tokens);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(_from, to, tokens);
        return true;
    }


     
    
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


     
    
    function approveAndCall(address spender, uint256 tokens, bytes memory data) public returns (bool success) {
        require(spender != address(0));
        require(tokens != 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


     
    
    function () external payable {
        require(msg.value != 0);
        if(balances[owner] >= reserveCap) {
            EtherInWei = EtherInWei.add(msg.value);
            uint256 amount = tokensPerEth.mul(msg.value);
            
            require(balances[fundsWallet] >= amount);
            
            balances[fundsWallet] = balances[fundsWallet].sub(amount);
            balances[msg.sender] = balances[msg.sender].add(amount);
            
            emit Transfer(fundsWallet, msg.sender, amount);  
            
             
            fundsWallet.transfer(msg.value);
            
            deductToken(amount);
        }
        
        else {
            revert("Token balance reaches reserve capacity, no more tokens will be given out.");
        }
    }


     
    
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
     
    function deductToken(uint256 amt) private {
        tokensRemain = tokensRemain.sub(amt);
        tokensSold = tokensSold.add(amt);
    }
    
     
    
    function setReserveCap(uint256 tokenAmount) public onlyOwner {
        require(tokenAmount != 0 && reserveCapped != true);
        
        reserveCap = tokenAmount * 10**uint(decimals);
        tokensRemain = balances[owner].sub(reserveCap);
        
        reserveCapped = true;
    }
    
     
    
    function setReserveCapPercentage (uint percentage) public onlyOwner {
        require(percentage != 0 && reserveCapped != true);
        reserveCap = calcSupplyPercentage(percentage);
        tokensRemain = balances[owner].sub(reserveCap);
        
        reserveCapped = true;
    }
    
     
    
    function calcSupplyPercentage(uint256 percent) public view returns (uint256){
        uint256 total = _totalSupply.mul(percent.mul(100)).div(10000);
        
        return total;
    }
    
     
    
    function distributeTokenByAmount(address dist_address, uint256 tokens)public payable onlyOwner returns (bool success){
        require(balances[owner] > 0);
        uint256 tokenToDistribute = tokens * 10**uint(decimals);
        
        require(tokensRemain >= tokenToDistribute);
        
        balances[owner] = balances[owner].sub(tokenToDistribute);
        balances[dist_address] = balances[dist_address].add(tokenToDistribute);
        
        emit Transfer(owner, dist_address, tokenToDistribute);
        
        tokensRemain = tokensRemain.sub(tokenToDistribute);
        tokensDistributed = tokensDistributed.add(tokenToDistribute);
        
        return true;
    }
    
     
    
    function releaseCapByAmount(uint256 tokenAmount) public onlyOwner {
        require(tokenAmount != 0 && reserveCapped == true);
        tokenAmount = tokenAmount * 10**uint(decimals);
        
        require(balances[owner] >= tokenAmount);
        reserveCap = reserveCap.sub(tokenAmount);
        tokensRemain = tokensRemain.add(tokenAmount);
    }
    
    
}