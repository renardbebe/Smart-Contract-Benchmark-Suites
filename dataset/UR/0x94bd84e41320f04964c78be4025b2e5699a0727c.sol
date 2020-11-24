 

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

 

contract HumanStandardToken is StandardToken {

    function () {
         
        throw;
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H0.1';        

    function HumanStandardToken(
        ) {
        balances[msg.sender] = 100000000000;                
        totalSupply = 100000000000;                         
        name = "EXRP Network Original";                                    
        decimals = 0;                             
        symbol = "EXRN";                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

contract ExrnSale {

	address public owner;
	uint256 public rate = 100 * 1e5;
	HumanStandardToken public token = HumanStandardToken(0x607122D68925c9D5DEDDdE4B284fdef81aD27AF6);

	function withdraw() public {

        require(msg.sender == owner);
		msg.sender.transfer((address(this)).balance);
	}

	function() payable public {

		require(msg.value >= 100 finney);

        uint256 exrnBuying = (msg.value * rate) / 1e18;
        uint256 exrnBought = 0;
        uint256 exrnAvailable = token.balanceOf(address(this));
        uint256 returningEth = 0;

        if (exrnAvailable == 0)
        	revert();

        bool saleFinished = false;

        if (exrnBuying >= exrnAvailable) {
        	saleFinished = true;
        	Finish();
        }

        if (exrnBuying > exrnAvailable) {
            returningEth = ((exrnBuying - exrnAvailable) * 1e18) / rate;
            exrnBuying = exrnAvailable;
        }

        exrnBought = exrnBuying;
        token.transfer(msg.sender, exrnBought);

        if (returningEth > 0)
            msg.sender.transfer(returningEth);

        Purchase(msg.sender, exrnBought, returningEth);
    }

    function ExrnSale() public {

    	owner = msg.sender;
    	Start();
    }

    event Start();
    event Purchase(address indexed _buyer, uint256 _exrnBought, uint256 _ethReturned);
    event Finish();
}