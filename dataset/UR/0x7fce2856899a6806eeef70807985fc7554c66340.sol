 

pragma solidity ^0.4.11;

 
contract SafeMath {
     

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }
}


 
interface Token {

     
     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract StandardToken is Token {

     
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
             
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
             
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

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}


 
contract CLPToken is StandardToken, SafeMath {

    string public name = "CLP Token";
    string public symbol = "CLP";
	uint public decimals = 9;

     
     
    address public founder = 0x0;
	
     
	uint public month6companyUnlock = 1525132801;  
	uint public month12companyUnlock = 1541030401;  
	uint public month18companyUnlock = 1556668801;  
	uint public month24companyUnlock = 1572566401;  
    uint public year1Unlock = 1541030401;  
    uint public year2Unlock = 1572566401;  
    uint public year3Unlock = 1604188801;  
    uint public year4Unlock = 1635724801;  

     
    bool public allocated1Year = false;
    bool public allocated2Year = false;
    bool public allocated3Year = false;
    bool public allocated4Year = false;
	
	bool public allocated6Months = false;
    bool public allocated12Months = false;
    bool public allocated18Months = false;
    bool public allocated24Months = false;

     
	uint currentTokenSaled = 0;
    uint public totalTokensSale = 87000000 * 10**decimals;
    uint public totalTokensReserve = 39000000 * 10**decimals; 
    uint public totalTokensCompany = 24000000 * 10**decimals;

    event Buy(address indexed sender, uint eth, uint fbt);
    event Withdraw(address indexed sender, address to, uint eth);
    event AllocateTokens(address indexed sender);

    function CLPToken() {
         
        founder = msg.sender;
    }

	 
    function allocateReserveCompanyTokens() {
        require(msg.sender==founder);
        uint tokens = 0;

        if(block.timestamp > month6companyUnlock && !allocated6Months)
        {
            allocated6Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > month12companyUnlock && !allocated12Months)
        {
            allocated12Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > month18companyUnlock && !allocated18Months)
        {
            allocated18Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > month24companyUnlock && !allocated24Months)
        {
            allocated24Months = true;
            tokens = safeDiv(totalTokensCompany, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else revert();

        AllocateTokens(msg.sender);
    }

     
    function allocateReserveTokens() {
        require(msg.sender==founder);
        uint tokens = 0;

        if(block.timestamp > year1Unlock && !allocated1Year)
        {
            allocated1Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year2Unlock && !allocated2Year)
        {
            allocated2Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year3Unlock && !allocated3Year)
        {
            allocated3Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else if(block.timestamp > year4Unlock && !allocated4Year)
        {
            allocated4Year = true;
            tokens = safeDiv(totalTokensReserve, 4);
            balances[founder] = safeAdd(balances[founder], tokens);
            totalSupply = safeAdd(totalSupply, tokens);
        }
        else revert();

        AllocateTokens(msg.sender);
    }


    
    function changeFounder(address newFounder) {
        require(msg.sender==founder);
        founder = newFounder;
    }

	 
    function getTotalCurrentSaled() constant returns (uint256 currentTokenSaled)  {
		require(msg.sender==founder);
		
		return currentTokenSaled;
    }

    
    function addInvestorList(address investor, uint256 amountToken)  returns (bool success) {
		require(msg.sender==founder);
		
		if(currentTokenSaled + amountToken <= totalTokensSale)
		{
			balances[investor] = safeAdd(balances[investor], amountToken);
			currentTokenSaled = safeAdd(currentTokenSaled, amountToken);
			totalSupply = safeAdd(totalSupply, amountToken);
			return true;
		}
		else
		{
		    return false;
		}
    }
}