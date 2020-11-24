 

pragma solidity ^0.5.10;

 

 

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

    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "must be owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner, "must be new owner");
        
        owner = newOwner;
        newOwner = address(0);

        emit OwnershipTransferred(owner, newOwner);
    }
}

 
 
 

contract GoaToken is ERC20Interface, Owned {

    using SafeMath for uint;

    string constant public symbol       = "GOA";
    string constant public name         = "Goa Token";
    uint constant public decimals       = 18;
    uint constant public MAX_SUPPLY     = 200000 * 10 ** decimals;
    uint constant public ETH_PER_TOKEN  = 0.000001 ether;
    
    uint public totalSupply;  
	uint public mintSupply;  
	
	bool public contractActive;  

    mapping(address => uint) public balanceOf;  
    mapping(address => mapping(address => uint)) public allowance;
    
    event Minted(address indexed newHolder, uint eth, uint tokens);
    event Burned(address indexed burner, uint tokens);

     
    constructor() public {
		contractActive = true;
    }

     
     
     
     

    function transfer(address to, uint tokens) public returns (bool success) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(tokens);
        balanceOf[to] = balanceOf[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

     
     
     
     
     
     

    function approve(address spender, uint tokens) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }

     
     
     
     
     

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balanceOf[from] = balanceOf[from].sub(tokens);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(tokens);
        balanceOf[to] = balanceOf[to].add(tokens);

        emit Transfer(from, to, tokens);

        return true;
    }

     
     
     
     

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

        return true;
    }

     
     
     
     

    function mint(uint fullToken) public payable {
        require(contractActive == true, "token emission has been disabled");
        
        uint _token = fullToken.mul(10 ** decimals);
        uint _newSupply = mintSupply.add(_token);
        require(_newSupply <= MAX_SUPPLY, "no more than 200 000 GOA can be minted");

        uint _ethCost = computeCost(fullToken);
        require(msg.value == _ethCost, "wrong ETH amount for tokens");
        
        owner.transfer(msg.value);
        totalSupply = totalSupply.add(_token);
		mintSupply = _newSupply;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_token);
        
        emit Minted(msg.sender, msg.value, fullToken);
    }
    
	 
	 
	 
	
	function burn(uint fullToken) public returns (bool success) {
		uint _token = fullToken.mul(10 ** decimals);
		require(balanceOf[msg.sender] >= _token, "not enough tokens to burn");
		
	    totalSupply = totalSupply.sub(_token);	
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_token);
		
		emit Burned(msg.sender, fullToken);
		
		return true;
    }
    
     
     
     
     
    
    function burnFrom(address _from, uint fullToken) public returns (bool success) {
        uint _token = fullToken.mul(10 ** decimals);
        require(allowance[_from][msg.sender] >= _token, "allowance too low to burn this many tokens");
        require(balanceOf[_from] >= _token, "not enough tokens to burn");
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_token);
        balanceOf[_from] = balanceOf[_from].sub(_token);
        totalSupply = totalSupply.sub(_token);
        
        emit Burned(_from, fullToken);
        
        return true;
    }
	
	 
	 
	
	function stopEmission() public onlyOwner returns (bool success) {
		contractActive = false;
		
		return true;
	}
	
     
     
    
    function computeSum(uint256 a, uint256 b) public pure returns(uint256) {
        uint256 _sumA = a.mul(a.add(1)).div(2);
        uint256 _sumB = b.mul(b.add(1)).div(2);
        return _sumB.sub(_sumA);
    }
    
     
     
    
    function computeCost(uint256 fullToken) public view returns(uint256) {
        uint256 _intSupply = mintSupply.div(10 ** decimals);
        uint256 _current = fullToken.add(_intSupply);
        uint256 _sum = computeSum(_intSupply, _current);
        return ETH_PER_TOKEN.mul(_sum);
    }
        
     
     

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}