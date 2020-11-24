 

pragma solidity ^0.4.19;

contract SafeMath {

     
     
     
     
     
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
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
}

contract XCToken is StandardToken,SafeMath,Ownable {

     
    string public constant name = "XC.COM(XC Program)";
    string public constant symbol = "XC";
    uint256 public constant decimals = 8;
    string public version = "1.0";
    
     
    uint256 public constant tokenCreationCap = 2000 * (10**6) * 10**decimals;
     
    uint256 public constant tokenCreationInit = 1000 * (10**6) * 10**decimals;
     
    uint256 public constant tokenMintCap = 1000 * (10**6) * 10**decimals;
     
    uint256 public tokenMintedSupply;
    
    address public initDepositAccount;
    address public mintDepositAccount;
    
	bool public mintFinished;
	
	event Mint(uint256 amount);
	event MintFinished();

    function XCToken(
        address _initFundDepositAccount,
        address _mintFundDepositAccount
        ) {
        initDepositAccount = _initFundDepositAccount;
        mintDepositAccount = _mintFundDepositAccount;
        balances[initDepositAccount] = tokenCreationInit;
        totalSupply = tokenCreationInit;
        tokenMintedSupply = 0;
        mintFinished = false;
    }
    
    modifier canMint() {
		if(mintFinished) throw;
		_;
	}
	
     
	function remainMintTokenAmount() constant returns (uint256 remainMintTokenAmount) {
	    return safeSub(tokenMintCap, tokenMintedSupply);
	}

	 
	function mint(uint256 _tokenAmount) onlyOwner canMint returns (bool) {
		if(_tokenAmount <= 0) throw;
		uint256 checkedSupply = safeAdd(tokenMintedSupply, _tokenAmount);
		if(checkedSupply > tokenMintCap) throw;
		if(checkedSupply == tokenMintCap){  
		    mintFinished = true;
		    MintFinished();
		}
		tokenMintedSupply = checkedSupply;
		totalSupply = safeAdd(totalSupply, _tokenAmount);
		balances[mintDepositAccount] = safeAdd(balances[mintDepositAccount], _tokenAmount);
		Mint(_tokenAmount);
		return true;
	}
	
	 
    function () external {
        throw;
    }
	
}