 

pragma solidity ^0.4.19;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() internal {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
 
 
 
 


contract MineBlocks is Ownable {
  uint256 public totalSupply;
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping(address => uint256) holded;

  event Transfer(address indexed from, address indexed to, uint256 value);

 event Approval(address indexed owner, address indexed spender, uint256 value);

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    holded[_to]=block.number;
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    holded[_to]=block.number;
    balances[_to] = balances[_to].add(_value);

    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

    string public constant standard = "ERC20 MineBlocks";

     
    string public name;
    string public symbol;
    uint8 public constant decimals = 8;  

     
    uint256 public constant minPrice = 10e12;
    uint256 public buyPrice = minPrice;

    uint256 public tokenReward = 0;
     
    uint256 private constant tokenUnit = uint256(10)**decimals;
    
     
     
    address public mineblocksAddr = 0x0d518b5724C6aee0c7F1B2eB1D89d62a2a7b1b58;

     
    event LogDeposit(address sender, uint amount);

     
    function MineBlocks(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        balances[msg.sender] = initialSupply;  
        totalSupply = initialSupply;   
        name = tokenName;              
        symbol = tokenSymbol;          

    }

    function () public payable {
        buy();    
    }
    

    modifier status() {
        _;   

		if(balances[this]>900000000000000){
			buyPrice=1500000000000000;
		}else if(balances[this]>800000000000000 && balances[this]<=900000000000000){

			buyPrice=2000000000000000;
		}else if(balances[this]>700000000000000 && balances[this]<=800000000000000){

			buyPrice=2500000000000000;
		}else if(balances[this]>600000000000000 && balances[this]<=700000000000000){

			buyPrice=3000000000000000;
		}else{

			buyPrice=4000000000000000;
		}

        
    }

    function deposit() public payable status returns(bool success) {
         
        assert (this.balance + msg.value >= this.balance);  
   		tokenReward=this.balance/totalSupply;
         
        LogDeposit(msg.sender, msg.value);
        
        return true;
    }

	function withdrawReward() public status{

		
		   if(block.number-holded[msg.sender]>172800){  

			holded[msg.sender]=block.number;

			 
			msg.sender.transfer(tokenReward*balances[msg.sender]);
			
			 
			LogWithdrawal(msg.sender, tokenReward*balances[msg.sender]);

		}
	}


	event LogWithdrawal(address receiver, uint amount);
	
	function withdraw(uint value) public onlyOwner {
		 
		msg.sender.transfer(value);
		 
		LogWithdrawal(msg.sender, value);
	}

    function buy() public payable status{
        require (msg.sender.balance >= msg.value);   
        assert (msg.sender.balance + msg.value >= msg.sender.balance);  
         
        uint256 tokenAmount = (msg.value / buyPrice)*tokenUnit ;   

        this.transfer(msg.sender, tokenAmount);
        mineblocksAddr.transfer(msg.value);
    }


     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner returns (bool success) {    

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}


contract tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public ; 
}