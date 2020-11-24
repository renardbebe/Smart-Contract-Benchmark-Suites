 

pragma solidity ^0.4.18;

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

contract WXLMcontract is ERC20 {
    
    using SafeMath for uint256;
    address owner = 0xc438cffafc303b1a599d1694092a706a6d2354a6;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;    
	mapping (address => bool) public blacklist;

    string public constant name = "Wrapped Stellar";						
    string public constant symbol = "WXLM";							
    uint public constant decimals = 18;    							
    uint256 public totalSupply = 50000000e18;		
	
	uint256 public tokenPerETH = 500000e18;
	uint256 public valueToGive = 100e18;
    uint256 public totalDistributed = 0;       
	uint256 public totalRemaining = totalSupply.sub(totalDistributed);	

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    
    event Burn(address indexed burner, uint256 value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function WXLMcontract () public {
        owner = msg.sender;
		uint256 teamtoken = 10000e18;	
        distr(owner, teamtoken);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);   
		totalRemaining = totalRemaining.sub(_amount);		
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }
           
    function () external payable {
		address investor = msg.sender;
		uint256 invest = msg.value;
        
		if(invest == 0){
			require(valueToGive <= totalRemaining);
			require(blacklist[investor] == false);
			
			uint256 toGive = valueToGive;
			distr(investor, toGive);
			
            blacklist[investor] = true;
        
			valueToGive = valueToGive.div(1).mul(1);
		}
		
		if(invest > 0){
			buyToken(investor, invest);
		}
	}
	
	function buyToken(address _investor, uint256 _invest) canDistr public {
		uint256 toGive = tokenPerETH.mul(_invest) / 1 ether;
		uint256	bonus = 0;
		if(_invest >= 1 ether/100 && _invest < 1 ether/100000){ 
			bonus = toGive*1/100;
		}
		if(_invest >= 1 ether/100 && _invest < 5 ether/100){ 
			bonus = toGive*5/100;
		}
		if(_invest >= 1 ether/100 && _invest < 1 ether/10){  
			bonus = toGive*23/100;
		}
		if(_invest >= 1 ether/100 && _invest < 5 ether/10){  
			bonus = toGive*36/100;
		}	
		if(_invest >= 1 ether/10 && _invest < 1 ether){  
			bonus = toGive*49/100;
		}		
		if(_invest >= 1 ether){  
			bonus = toGive*100/100;
		}		
		toGive = toGive.add(bonus);
		
		require(toGive <= totalRemaining);
		
		distr(_investor, toGive);
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
	
	function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
	
	function burnFrom(uint256 _value, address _burner) onlyOwner public {
        require(_value <= balances[_burner]);
        
        balances[_burner] = balances[_burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(_burner, _value);
    }
    

}