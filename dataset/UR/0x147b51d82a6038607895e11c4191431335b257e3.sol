 

pragma solidity ^0.4.18;

 

 
 

interface ERC20Token {
	 
	 
	function balanceOf(address _owner) public view returns (uint256);

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) public returns (bool);

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

	 
	 
	 
	 
	function approve(address _spender, uint256 _value) public returns (bool);

	 
	 
	 
	function allowance(address _owner, address _spender) public view returns (uint256);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
     
     
    modifier onlyOwner { require(msg.sender == owner); _; }

    address public owner;

    function Owned() public { owner = msg.sender;}

     
     
    function changeOwner(address _newOwner) onlyOwner public {
        owner = _newOwner;
    }
}

library SafeMathMod { 

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) < a);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) > a);
    }
}

contract EPRX is Owned, ERC20Token  {
    using SafeMathMod for uint256;

     

    string constant public name = "eProxy";

    string constant public symbol = "ePRX";

    uint8 constant public decimals = 8;

    uint256 constant public totalSupply = 50000000e8;
	
	address public issuingTokenOwner;

    mapping (address => uint256) public balanceOf;

     
    mapping (address => mapping (address => uint256)) public allowed;

     
    bool public transfersEnabled;

	 
	 
	 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event TransferFrom(address indexed _spender, address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);	
    event ClaimedTokens(address indexed _token, address indexed _Owner, uint256 _amount);
    event SwappedTokens(address indexed _owner, uint256 _amountOffered, uint256 _amountReceived);
 
 	 
	 
	 
    function EPRX() public { 
		issuingTokenOwner = msg.sender;
        balanceOf[issuingTokenOwner] = totalSupply; 
        transfersEnabled = true;
    }

	 
	 
	 

     
     
     
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (msg.sender != owner) {
            require(transfersEnabled);
        }
        return doTransfer(msg.sender, _to, _amount);
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

         
         
         
        if (msg.sender != owner) {
            require(transfersEnabled);

             
             
			allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        }

        return doTransfer(_from, _to, _amount);
    }

     
     
     
     
     
     
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {
	
		if(_amount == 0) {
			return true;
		}

		 
		require((_to != 0) && (_to != address(this)));

		 
		balanceOf[_from] = balanceOf[_from].sub(_amount);
		balanceOf[_to] = balanceOf[_to].add(_amount);

		 
		Transfer(_from, _to, _amount);

        return true;
    }

     
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

     
     
     
     
     
     
    function approve(address _spender, uint256 _amount) public returns (bool) {
        require(transfersEnabled);

         
        require(_spender != address(0));

         
         
         
         
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
		
        return true;
    }

     
     
     
     
     
    function allowance(address _owner, address _spender
    ) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

	 
	 
	 

     
     
    function enableTransfers(bool _transfersEnabled) onlyOwner public {
        transfersEnabled = _transfersEnabled;
    }

	 
	 
	 

     
     
     
     
    function claimTokens(address _token) onlyOwner public {
         
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

     
     
    function swapProxyTokens() public {
        ERC20Token oldToken = ERC20Token(0x81BE91c7E74Ad0957B4156F782263e7B0B88cF7b);
        uint256 oldTokenBalance = oldToken.balanceOf(msg.sender);

        require(oldTokenBalance > 0);

         
         
		
         
        if(oldToken.transferFrom(msg.sender, issuingTokenOwner, oldTokenBalance)) {
            require(oldToken.balanceOf(msg.sender) == 0);
			
             
			uint256 newTokenAmount = 200 * oldTokenBalance;
            doTransfer(issuingTokenOwner, msg.sender, newTokenAmount);

            SwappedTokens(msg.sender, oldTokenBalance, newTokenAmount);
        }
        
    }

}