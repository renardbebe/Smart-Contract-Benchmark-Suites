 

pragma solidity ^0.4.8;

 
 
 
 

 
 
contract ERC20Interface {
     
    function totalSupply() constant returns (uint256 totalSupply);

     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract FOMOCoin is ERC20Interface {
    string public constant symbol = "FOMO";
    string public constant name = "FOMO Coin";
    uint8 public constant decimals = 0;
		uint256 public totalSupply = 42000000;
		uint256 public remainingSupply = 20000000;
		uint256 tokenCost = 1000000000000000;

     
    address public owner = 0x314FA670Cd113e0c4168fe0D62355B314dEa4f06;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

     
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    function FOMOCoin () {
      balances[owner] = 22000000;
    }

    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }

     
    function balanceOf(address _owner) constant returns (uint256 _balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

		function saleInProgress() returns (bool saleInProgress) {
			return remainingSupply > 0;
	  }

		 
		function () payable {
				var purchaseCount = msg.value / tokenCost;
				require(saleInProgress() && purchaseCount <= remainingSupply);
				balances[msg.sender] += purchaseCount;
				remainingSupply -= purchaseCount;
				owner.transfer(msg.value);
		}

		 
		function withdraw(uint256 _amount) onlyOwner {
				msg.sender.transfer(_amount);
		}

		function finalizeSale() onlyOwner {
	    	require(!saleInProgress());
	    	if(remainingSupply > 0) {
	      		balances[owner] += remainingSupply;
	      		remainingSupply = 0;
	    	}
	  }
}