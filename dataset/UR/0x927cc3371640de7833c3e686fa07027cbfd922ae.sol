 

pragma solidity 0.4.24;


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

contract AltcoinToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
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

contract MIKRONOMY is ERC20, Owned {
    
    using SafeMath for uint256;
    address owner = msg.sender;
		
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;    

    string public constant name = "MIKRONOMY";
    string public constant symbol = "MKN";
    uint public constant decimals = 0;
    
    uint256 public totalSupply =  1000000000;
    uint256 public totalDistributed = 0; 
    uint256 public minContribution = 1 ether / 10;  
	
	
	uint256 public tokensPerEth = 30000;
	
    
	 
	 
	 
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();

    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event TokensPerEthUpdated(uint _tokensPerEth);
    
    event Burn(address indexed burner, uint256 value);
	
	event Sent(address from, address to, uint amount);
	
	
	 
	 
	 
    bool public distributionOpen = false;
    
    
    
     
     
     
    constructor() public {        
        balances[owner] = totalSupply;     
    }
    
     
     
     
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }

    modifier canDistr() {
        require(distributionOpen);
        _;
    }
	
	function openDistribution() onlyOwner public returns (bool) {
        distributionOpen = true;
        return true;
    }
    
    function closeDistribution() onlyOwner public returns (bool) {
        distributionOpen = false;
        return true;
    }
    
    function changeMinContribution(uint256 _minContribution) onlyOwner public returns (bool) {
        minContribution = _minContribution;
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        balances[owner] = balances[owner].sub(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }
	
	function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
    
   
    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    function () external payable {
				
		 
		if (msg.sender == owner && msg.value == 0){
			withdraw();
		}
		
		if(msg.sender != owner){
		
			if ( distributionOpen == false ){
				revert('Token distribution is closed');
			}

			getTokens();
			
		}
     }
    
    function getTokens() payable canDistr  public {
        uint256 tokens = 0;

        require( msg.value >= minContribution );

        require( msg.value > 0 );
        
        tokens = tokensPerEth.mul(msg.value) / 1 ether;
        address investor = msg.sender;
        
       
        
        if( balances[owner] < tokens ){
			revert('Insufficient Token Balance or Sold Out.');
		}
        
        if (tokens < 0){
			revert();
		}
        
        totalDistributed += tokens;
        
        if (tokens > 0) {
           distr(investor, tokens);           
        }


    }
	
	
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        AltcoinToken t = AltcoinToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
    
    function withdrawAltcoinTokens(address _tokenContract) onlyOwner public returns (bool) {
        AltcoinToken token = AltcoinToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
	
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function airdrop(address source, address[] dests, uint256[] values, uint256 available_for_airdrop)  onlyOwner public returns (bool success) {
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            if(available_for_airdrop >= values[i]){
                available_for_airdrop.sub(values[i]);
                uint256 tokens_to_transfer = values[i];
                transferFrom(source,dests[i],tokens_to_transfer);
            }
        }
        
        return true;
	}


    
    
}