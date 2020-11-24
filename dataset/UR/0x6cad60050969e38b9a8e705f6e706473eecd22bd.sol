 

contract Math {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract Token {
     
     
    uint256 public totalSupply;
    uint256 public totalDividends;
    uint public voteEnds = 1;
     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

    function voteBalance(address _owner) constant returns (uint256 balance);

    function voteCount(address _proposal) constant returns (uint256 count);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
contract StandardToken is Token {

    struct Account {
        uint votes;
        uint lastVote;
        uint lastDividends;
    }

    modifier voteUpdater(address _to, address _from) {
        if (accounts[_from].lastVote == voteEnds) {
            if (accounts[_to].lastVote < voteEnds) {
                accounts[_to].votes = balances[_to];
                accounts[_to].lastVote = voteEnds;
            }
        } else if (accounts[_from].lastVote < voteEnds) {
            accounts[_from].votes = balances[_from];
            accounts[_from].lastVote = voteEnds;
            if (accounts[_to].lastVote < voteEnds) {
                accounts[_to].votes = balances[_to];
                accounts[_to].lastVote = voteEnds;
            }
        }
        _;

    }
    modifier updateAccount(address account) {
      var owing = dividendsOwing(account);
      if(owing > 0) {
        account.send(owing);
        accounts[account].lastDividends = totalDividends;
      }
      _;
    }
    function dividendsOwing(address account) internal returns(uint) {
      var newDividends = totalDividends - accounts[account].lastDividends;
      return (balances[account] * newDividends) / totalSupply;
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function voteCount(address _proposal) constant returns (uint256 count) {
        return votes[_proposal];
    }
    function voteBalance(address _owner) constant returns (uint256 balance)
    {
        return accounts[_owner].votes;

    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) 
    updateAccount(msg.sender)
    voteUpdater(_to, msg.sender)
    returns (bool success) 
    {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value)
    updateAccount(msg.sender) 
    voteUpdater(_to, _from)
    returns (bool success) 
    {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => Account) accounts;
    mapping (address => uint ) votes;
}
contract SISA is StandardToken, Math {


	string constant public name = "SISA Token";
	string constant public symbol = "SISA";
	uint constant public decimals = 18;

	address public ico_tokens = 0x1111111111111111111111111111111111111111;
	address public preICO_tokens = 0x2222222222222222222222222222222222222222;
	address public bounty_funds;
	address public founder;
	address public admin;
	address public team_funds;
	address public issuer;
	address public preseller;





	function () payable {
	  totalDividends += msg.value;
	   
	}


	modifier onlyFounder() {
	     
	    if (msg.sender != founder) {
	        throw;
	    }
	    _;
	}
	modifier onlyAdmin() {
	     
	    if (msg.sender != admin) {
	        throw;
	    }
	    _;
	}
    modifier onlyIssuer() {
         
        if (msg.sender != issuer) {
            throw;
        }
        _;
    }


    function castVote(address proposal) 
    	public
    {
    	if (accounts[msg.sender].lastVote < voteEnds) {
    		accounts[msg.sender].votes = balances[msg.sender];
    		accounts[msg.sender].lastVote = voteEnds;

    	} else if (accounts[msg.sender].votes == 0 ) {
    		throw;
    	}
    	votes[proposal] = accounts[msg.sender].votes;
    	accounts[msg.sender].votes = 0;
    	
    }
    function callVote() 
    	public
    	onlyAdmin
    	returns (bool)
    {
    	voteEnds = now + 7 days;

    }
    function issueTokens(address _for, uint256 amount)
        public
        onlyIssuer
        returns (bool)
    {
        if(allowed[ico_tokens][issuer] >= amount) { 
            transferFrom(ico_tokens, _for, amount);

             
            return true;
        } else {
            throw;
        }
    }
    function changePreseller(address newAddress)
        external
        onlyAdmin
        returns (bool)
    {    
        delete allowed[preICO_tokens][preseller];
        preseller = newAddress;

        allowed[preICO_tokens][preseller] = balanceOf(preICO_tokens);

        return true;
    }
    function changeIssuer(address newAddress)
        external
        onlyAdmin
        returns (bool)
    {    
        delete allowed[ico_tokens][issuer];
        issuer = newAddress;

        allowed[ico_tokens][issuer] = balanceOf(ico_tokens);

        return true;
    }
	function SISA(address _founder, address _admin, address _bounty, address _team) {
		founder = _founder;
		admin = _admin;
		bounty_funds = _bounty;
		team_funds = _team;
		totalSupply = 50000000 * 1 ether;
		balances[preICO_tokens] = 5000000 * 1 ether;
		balances[bounty_funds] += 3000000 * 1 ether;
		balances[team_funds] += 7000000 * 1 ether;
		balances[ico_tokens] = 32500000 * 1 ether;



	}

}